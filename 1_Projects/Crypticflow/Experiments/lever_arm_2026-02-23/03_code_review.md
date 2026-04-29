# CrypticFlow 코드 구현 문제점 리뷰

**작성**: code-reviewer agent (oh-my-claudecode:quality-reviewer, Opus)
**날짜**: 2026-02-23
**검토 파일**: encoder.py, crypticflow.py, losses.py, transformer.py
**팀**: crypticflow-lever-arm

---

## 요약

| 항목 | 평가 |
|------|------|
| 전체 | POOR |
| Logic | fail |
| Error Handling | warn |
| Design | fail |
| Maintainability | warn |

---

## Critical Issues

### 1. `encoder.py:217-254` — NERF Decoder Fixed-Frame 초기화 → Rotation Mismatch [CRITICAL]

```python
n0  = torch.zeros(3, dtype=dtype, device=device)          # (0, 0, 0)
ca0 = torch.stack([dist_nca[0], zero, zero])               # (d, 0, 0)
c0  = ca0 + torch.stack([
    -dist_cac[0] * torch.cos(tau[0]),
     dist_cac[0] * torch.sin(tau[0]),
     zero,
])
```

- `center=True` (line 253-254)는 translation만 제거 — rotation은 제거하지 않음
- 예측된 holo와 실제 holo가 **다른 rotational frame**에 있음
- Kabsch가 이를 보정하지만, gradient는 SVD alignment + 전체 795-atom NERF chain을 역전파해야 함
- **이것이 전체 lever arm / gradient explosion 딜레마의 아키텍처적 근본 원인**

### 2. `encoder.py:227-249` — Sequential NERF Error Accumulation (Lever-Arm Effect) [CRITICAL]

```python
for i in range(L - 1):
    n_new = place_dihedral(coords[-3], coords[-2], coords[-1], ...)
    ca_new = place_dihedral(coords[-2], coords[-1], n_new, ...)
    c_new = place_dihedral(coords[-1], n_new, ca_new, ...)
    coords.extend([n_new, ca_new, c_new])
```

- 265잔기 × 3원자 = **795개 순차 place_dihedral 호출**
- 잔기 i의 각도 오차 δθ가 잔기 L-1의 displacement를 `δθ × 3.8 × (L-1)` Å만큼 증폭
- δθ=0.01 rad, L=265이면 → 체인 끝에서 ~10 Å 오차
- 역전파 시 gradient magnitude도 동일하게 증폭 → 폭발

### 3. `losses.py:199,203,217` — Kabsch SVD Gradient Pathology [CRITICAL]

**(a) SVD gradient singularity (line 199)**:
```python
U, S, Vh = torch.linalg.svd(H)
```
Singular value 간 차이가 작을 때 gradient ∝ `1/(s_i - s_j)` → 수치적 무한대. 795원자 covariance matrix에서는 near-degenerate singular value가 흔함.

**(b) Reflection sign discontinuity (lines 203-206)**:
```python
d = torch.linalg.det(Vh.T @ U.T)
sign[2] = torch.where(d < 0, ...)
```
`d=0`에서 gradient 방향이 급격히 반전 → 훈련 불안정.

**(c) sqrt gradient guard 누락 (line 217)**:
```python
rmsd = torch.sqrt((diff ** 2).sum(dim=-1).mean())
```
RMSD → 0일 때 gradient → ∞. `+ 1e-8` 추가 필요.

### 4. `crypticflow.py:280-289` — 1-Step Euler Amplification [CRITICAL]

```python
dt = 1.0 - t_i                                    # line 281
backbone_1_pred_i = backbone_t_i + dt * v_pred_i   # line 282
```

- Beta(2.0, 5.0) 샘플링: mode ≈ 0.14, 50% 확률로 t < 0.29 → `dt > 0.71`
- t≈0이면 dt≈1.0이므로 v_pred의 작은 오차가 크게 증폭됨
- 이후 NERF decoder (lever arm) → Kabsch SVD 통과: **삼중 증폭 cascade**

### 5. `crypticflow.py:262-294` — 극단적 Loss Scale 불균형 [CRITICAL]

```python
loss_backbone_weighted = self.backbone_loss_weight * loss_backbone    # ~0.0004 rad
coord_rmsd_weighted = self.coord_loss_weight * coord_rmsd              # ~24 Å
total_loss = loss_backbone_weighted + coord_rmsd_weighted
```

- **비율 ~60,000:1 ~ 125,000:1** (라디안 vs Å 단위)
- `coord_loss_weight=0.01`이어도 coord term이 600배 dominant
- Adaptive loss balancing, gradient scaling, loss normalization 모두 없음

### 6. `crypticflow.py:282-288` — 훈련 경로에서 Bond Length 미클램프 [HIGH]

```python
backbone_1_pred_wrapped = torch.where(
    self._is_angular.unsqueeze(0),
    torch.atan2(...),
    backbone_1_pred_i   # distance cols: NO clamp
)
pred_coords_list.append(self.decoder(backbone_1_pred_wrapped, center=True))
```

- ODE solver(`ode_solver.py:39`)는 `clamp(min=0.0)` 적용하지만 훈련 경로는 미적용
- 음수 bond length → degenerate geometry → NaN 기여

---

## Design Issues

### 7. `encoder.py:68,71` — place_dihedral epsilon masking이 zero-norm 벡터 오류 숨김 [MEDIUM]

```python
bc_unit = bc / (torch.linalg.norm(bc, dim=-1, keepdim=True) + 1e-8)
n       = n / (torch.linalg.norm(n, dim=-1, keepdim=True) + 1e-8)
```

- collinear 원자 → cross product 0벡터 → `1e-8`로 나누면 임의 방향 unit vector 반환
- 오류 신호 없이 NERF chain 전체에 잘못된 좌표가 전파됨

### 8. `transformer.py:643-647` — adaLN-Zero Hard Clamp → Dead Gradient Zone [MEDIUM]

```python
gamma1 = torch.clamp(gamma1, min=-2.0, max=2.0)
alpha1 = torch.clamp(alpha1, min=-1.0, max=1.0)
```

- 범위 밖에서 gradient = 0 → dead zone
- alpha [-1, 1] clamp: residual scaling을 최대 1x로 제한 — 표준 DiT에는 없는 제약

**수정**:
```python
gamma1 = 2.0 * torch.tanh(gamma1 / 2.0)
alpha1 = torch.tanh(alpha1)
```

### 9. `transformer.py:871-901` — ESM/Featurizer Mean Pooling → Residue 정보 소실 [MEDIUM]

```python
esm_mean = esm_valid.mean(dim=0)   # (N+2, 1536) → (1536,)
feat_mean = feat_valid.mean(dim=0) # (N, 76) → (76,)
```

- 265개 잔기의 정보가 하나의 global vector로 압축
- 국소 구조 변화 (5/265 잔기 루프 재배치)는 conditioning signal에서 260/265으로 희석
- lever arm effect와 연관: 모델이 어느 잔기를 얼마나 바꿀지 모름

### 10. `crypticflow.py:319-337` — _interpolate_backbone 설계 취약성 [LOW]

- distance 보간은 수학적으로 정확함 (선형 보간, 결과 항상 양수)
- 단, `_is_angular` boolean mask가 부정확하면 distance cols에 angular wrapping 적용될 수 있음 → 잠재적 오류

### 11. `transformer.py:93-94,118` — GaussianFourierProjection 이중 2π 스케일링 [LOW]

```python
W = torch.randn(embed_dim // 2) * scale   # scale = 2*pi
x_proj = x.unsqueeze(-1) * self.W.to(x.device) * 2 * torch.pi
```

- W ~ N(0, (2π)²) → forward에서 다시 × 2π → 실효 스케일 (2π)³ ≈ 248
- [-π, π] 범위의 각도 feature에 과도하게 고주파 Fourier feature 생성

---

## Positive Observations

1. **모듈 분리**: encoder / transformer / losses / crypticflow / ode_solver — SRP 준수
2. **올바른 angular wrapping**: `torch.atan2(sin, cos)` 방식이 `_interpolate_backbone`, `_backbone_diff`, ODE solver 전반에 걸쳐 일관적
3. **Feature mask 처리 철저**: terminal residue의 미정의 각도 (phi[0], psi[-1] 등) mask가 pipeline 전체에 전파됨
4. **Radian-aware loss**: `radian_smooth_l1_loss`가 각도 feature와 distance feature를 올바르게 분리 처리
5. **ODE solver clamp/wrap 적용**: inference 경로에서는 bond length clamping이 올바르게 구현됨
6. **adaLN-Zero 초기화**: modulation weight zero-init (line 611-612)이 DiT 훈련 안정화 전략에 따름

---

## Root Cause Analysis: The Lever-Arm Dilemma

근본 문제: **내부좌표 표현과 Cartesian-space 정확도 간의 해결 불가능한 긴장**

**Path A (Vanilla, Job 399)**: angle velocity loss로만 학습 → 모델이 angular error를 최소화 (0.0004 rad) → NERF가 작은 angular error를 Cartesian displacement로 lever-arm 증폭 → RMSD 발산

**Path B (Coord loss, Jobs 401/403)**: Cartesian RMSD loss 추가 → (1) Kabsch SVD gradient singularity, (2) 795원자 NERF chain gradient 폭발, (3) dt≈1.0 velocity error 증폭의 삼중 cascade → 수치 불안정

**딜레마는 아키텍처적**: 내부좌표가 translational/rotational DOF를 제거하는 것은 바람직하지만, NERF map의 Jacobian condition number가 chain 길이에 따라 성장하므로, 긴 chain에서 이 map을 통한 gradient 기반 최적화는 근본적으로 불안정하다.

---

## 수정 권고사항 (우선순위순)

| 우선순위 | 위치 | 수정 내용 |
|---------|------|-----------|
| Critical | `crypticflow.py:287` | bond length clamp: `backbone_1_pred_wrapped[:, 6:].clamp_(min=0.1)` |
| Critical | `losses.py:217` | sqrt epsilon: `torch.sqrt(x.mean() + 1e-8)` |
| Critical | `crypticflow.py` | position-weighted angle loss: 잔기 i에 `(L-i)` 또는 `(L-i)²` weight |
| Critical | `crypticflow.py` | stop-gradient coord loss: `self.decoder(backbone_wrapped.detach(), ...)` |
| Critical | `crypticflow.py:291` | time-weighted coord loss: RMSD × t_i |
| Medium | `transformer.py:643-647` | hard clamp → `tanh` soft clamp |
| Medium | `transformer.py:871-901` | per-residue ESM/featurizer conditioning 추가 |
