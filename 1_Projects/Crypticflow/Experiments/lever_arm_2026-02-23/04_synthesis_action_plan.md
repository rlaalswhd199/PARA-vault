# CrypticFlow Lever Arm Effect — 종합 분석 및 실행 계획

**작성**: team-lead (Claude Sonnet 4.6)
**날짜**: 2026-02-23
**팀**: crypticflow-lever-arm
**근거**: 문헌 조사(researcher) + 로그 분석(scientist) + 코드 리뷰(code-reviewer/Opus) 종합

---

## 진단 요약

3개 에이전트의 결론이 완전히 일치한다.

| 관찰 | 원인 (확인됨) |
|------|--------------|
| Job 399: angle loss=0.0004 → RMSD=17.82Å (초기 5.69Å에서 악화) | NERF sequential chain lever arm 증폭 |
| Job 401: epoch 6부터 RMSD 35→133Å 폭발 | Kabsch RMSD gradient가 795-atom NERF 역전파 시 기하급수 증폭 |
| Job 402/403: 가중치 0.01–0.02로 줄여도 동일 폭발 | 메커니즘(gradient path) unchanged → 가중치 조정 무의미 |
| Job 403: epoch 3699 CUDA illegal memory access | NaN/Inf gradient → GPU 메모리 오염 → wandb hook 접근 시 crash |

**이론적 검증**: δθ=0.02 rad (val_loss=0.0004에서), N=265 → RMSD_expected ≈ **11.7 Å**
관찰값 17.82 Å와 order-of-magnitude 일치 — lever arm이 수치적으로 설명됨

**문헌 확인**: FoldingDiff (Nature Commun. 2024)이 동일 현상을 "lever arm effect"로 명시적 기재.
≤70 residues에서만 안정적이라 보고 → CrypticFlow의 265-residue 단백질에서 더 심각함.

---

## 근본 원인

```
Path A (vanilla, Job 399):  angle loss 수렴 → RMSD 발산  ← NERF lever arm
Path B (coord loss, Jobs 401/403): gradient 폭발 → NaN/CUDA crash  ← NERF Jacobian
```

**내부좌표 표현 + sequential NERF + global Kabsch RMSD loss의 조합이 근본적으로 incompatible.**

NERF map의 Jacobian condition number가 chain 길이에 따라 성장하므로, 265-residue chain에서 이 map을 통한 gradient 기반 최적화는 수치적으로 불안정하다.

---

## 즉시 실행 (1–2일) — 안전한 버그 픽스

### Fix 1: Bond length clamp (`crypticflow.py`)

```python
# compute_velocity_loss 내부, decoder 호출 직전
backbone_1_pred_wrapped[:, 6:] = backbone_1_pred_wrapped[:, 6:].clamp(min=0.1)
```

음수 bond length → degenerate geometry → gradient spike를 차단.
ODE solver는 이미 적용하지만 훈련 경로에 빠져있음.

### Fix 2: RMSD sqrt epsilon (`losses.py:217`)

```python
rmsd = torch.sqrt((diff ** 2).sum(dim=-1).mean() + 1e-8)
```

RMSD≈0일 때 gradient→∞ 방지.

### Fix 3: adaLN clamp → tanh softclamp (`transformer.py:643-647`)

```python
gamma1 = 2.0 * torch.tanh(gamma1 / 2.0)
gamma2 = 2.0 * torch.tanh(gamma2 / 2.0)
alpha1 = torch.tanh(alpha1)
alpha2 = torch.tanh(alpha2)
```

Hard clamp의 zero-gradient dead zone 제거. 모델 표현력 회복.

---

## 단기 실험 (3–7일) — Lever Arm 핵심 해결

### 실험 A: Position-weighted angle loss

**원리**: NERF decoder를 건드리지 않고, 체인 앞쪽 잔기의 angle 오차가 더 큰 Cartesian 오차를 유발한다는 사실을 loss에 반영.

```python
# crypticflow.py — compute_velocity_loss 내부
L = backbone_t_i.shape[1]
leverage = torch.arange(L, 0, -1, device=device, dtype=torch.float)
leverage = leverage / leverage.sum()  # normalize

# radian_smooth_l1_loss를 per-residue로 계산 후 weighted sum
loss_per_residue = radian_smooth_l1_loss(v_pred_i, v_target_i)  # (B, L, 9)
loss_backbone = (loss_per_residue.mean(-1) * leverage).sum()
```

**기대 효과**: RMSD Cartesian loss와 동등한 효과, NERF 역전파 없음 → gradient explosion 없음.
**리스크**: 낮음. 기존 코드 최소 수정.

### 실험 B: Stop-gradient coord loss

**원리**: coord loss는 RMSD signal을 제공하되, NERF Jacobian을 완전히 차단.

```python
# crypticflow.py:288 전후
with torch.no_grad():
    pred_coords_sg = self.decoder(backbone_1_pred_wrapped, center=True)

# target coords도 동일하게
coord_rmsd = kabsch_rmsd_loss_batched(pred_coords_sg, target_coords_i)

# time-weighting: t≈0이면 1-step Euler 부정확 → 그 구간 coord loss 억제
coord_rmsd_weighted = t_i.mean() * coord_rmsd * self.coord_loss_weight
```

**추가**: `coord_loss_weight=1e-4`부터 시작 (Job 401의 1.0 대비 10,000배 작음).
**기대 효과**: gradient explosion 차단 + 약한 Cartesian signal 제공.

**두 실험을 동시에 sbatch 제출하여 병렬 비교 권장.**

---

## 중기 실험 (2–4주) — 구조적 해결

### 실험 C: FAPE-style Local Frame Loss

AlphaFold2/Sesame가 global RMSD 대신 사용하는 방식. 각 잔기의 local backbone frame (N, Cα, C로 정의) 기준으로 인접 원자 위치 오차를 측정한다.

```python
def fape_loss(pred_coords, true_coords, backbone_frames, clamp_dist=10.0):
    """
    pred_coords: (B, N, 3) - predicted Cα positions
    backbone_frames: list of (R, t) tuples per residue
    """
    losses = []
    for i, (R, t) in enumerate(backbone_frames):
        # transform all coords to residue i's local frame
        local_pred = (pred_coords - t) @ R
        local_true = (true_coords - t) @ R
        dist = torch.norm(local_pred - local_true, dim=-1)
        dist = torch.clamp(dist, max=clamp_dist)  # OpenFold improvement
        losses.append(dist.mean())
    return torch.stack(losses).mean()

# L_total = L_torsion + λ_fape * L_fape
# λ_fape ≈ 0.01~0.1
```

**핵심 차이**: local frame 기준이므로 lever arm에 덜 민감. 체인 끝 오차가 글로벌 RMSD처럼 폭발하지 않음.

### 실험 D: Residue-level Conditioning

```python
# transformer.py — 현재 mean pooling 대신
esm_per_residue = esm_embeddings  # (L, 1536)
feat_per_residue = featurizer_features  # (L, 76)

# token embedding에 직접 더하기
token_emb = self.input_proj(x) + self.esm_proj(esm_per_residue) + self.feat_proj(feat_per_residue)
```

265개 잔기 중 국소 구조 변화를 예측하는 데 필수적인 per-residue 정보 제공.

---

## 장기 (1개월+) — 근본적 아키텍처 전환

### 실험 E: SE(3) Frame 표현 전환

FoldingDiff → FrameDiff → Sesame의 진화가 보여주듯, torsion + NERF 조합은 긴 chain에서 근본적 한계를 가진다.

**핵심**: 각 잔기를 `(R, t) ∈ SE(3)`으로 표현 → NERF 완전 제거 → lever arm effect 자체 소멸

**참고 구현**:
- Sesame (arXiv 2509.05302): CrypticFlow와 동일한 apo→holo flow matching task를 SE(3) frame으로 구현
- FoldFlow (arXiv 2310.02391): SE(3)^N 위에서의 flow matching

---

## 실험 계획 (권장 순서)

```
1주차: Fix 1+2+3 적용 후 Job 399 설정 재실행 → vanilla baseline 확인
       실험 A (position-weighted) + 실험 B (stop-gradient) 병렬 sbatch

2주차: 실험 A/B 결과 비교
       → 더 좋은 쪽 + 실험 C (FAPE) 조합 테스트

3주차: 실험 D (residue-level conditioning) 추가

4주차+: 결과에 따라 실험 E (SE(3) 전환) 여부 결정
```

**목표 기준**: pair_05081 단백질에서 epoch 200 이내에 RMSD < 5.69Å (초기 apo-holo 거리) 달성.

---

## 파일별 수정 요약

| 파일 | 수정 내용 | 우선순위 |
|------|-----------|---------|
| `crypticflow.py:287` | bond length clamp `clamp(min=0.1)` | 즉시 |
| `losses.py:217` | `sqrt(x + 1e-8)` | 즉시 |
| `transformer.py:643-647` | hard clamp → `tanh` softclamp | 즉시 |
| `crypticflow.py` (compute_velocity_loss) | position-weighted angle loss | 실험 A |
| `crypticflow.py` (compute_velocity_loss) | stop-gradient + time-weighted coord loss | 실험 B |
| `losses.py` | FAPE loss 함수 추가 | 실험 C |
| `transformer.py` | per-residue ESM/featurizer conditioning | 실험 D |

---

## 참고 문헌 (Literature Review에서)

- FoldingDiff (Nature Commun. 2024): lever arm effect 명시적 기재
- Sesame (arXiv 2509.05302): apo→holo SE(3) flow matching — 가장 직접적 참고
- AlphaFold2 (Nature 2021): FAPE loss 원조
- OpenFold (PMC 2024): FAPE clamping 개선
- FrameDiff (arXiv 2302.02277): SE(3) rigid body diffusion
- FoldFlow (arXiv 2310.02391): SE(3) flow matching
