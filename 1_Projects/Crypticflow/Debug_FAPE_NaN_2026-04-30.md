# Debug Note — FAPE Loss NaN Gradient 원인 분석 및 수정

**날짜**: 2026-04-30  
**Job**: cf_full-32561 → cf_full_curated-32646 → cf_full_curated-32651  
**관련 파일**: `model/crypticflow.py`, `model/encoder.py`, `model/losses.py`

---

## 현상

학습 초기부터 **매 epoch 첫 2-3 step에서 연속 NaN gradient** 발생.

```
⚠️ [Step 1] NaN/Inf gradient detected, skipping step (연속 1회)
⚠️ [Step 2] NaN/Inf gradient detected, skipping step (연속 2회)
⚠️ [Step 3] NaN/Inf gradient detected, skipping step (연속 3회)
🚨 연속 NaN 3회 — best checkpoint 복원 필요
⚠️ best checkpoint 없음 — 현재 weight로 계속
```

`fape_loss_weight=0.1`이 켜진 상태에서만 발생. FAPE를 끄면 정상 학습.

---

## 원인 추적 과정

### 1차 가설 (틀림): bond angle clamp 부재

`batched_backbone_decode` 호출 전 `pred_feat`의 bond angle cols(4,5: `CA:C:1N`, `C:1N:1CA`)이 `atan2` wrap 후에도 음수일 수 있고, `mp_nerf_torch`가 `theta ∈ [-π, π]`를 요구하므로 문제가 될 것이라 판단.

→ bond angle cols(4,5)를 `[0.1, π-0.1]`로 clamp 추가 (`crypticflow.py`).  
→ **NaN 여전히 발생. forward는 문제 없음.**

### 2차 진단: `torch.autograd.set_detect_anomaly(True)`

```
Error detected in MulBackward0.
  File "crypticflow.py", line 386, compute_velocity_loss
    pred_coords_all = batched_backbone_decode(pred_feat, lengths_t, center=True)
RuntimeError: Function 'MulBackward0' returned nan values in its 0th output.
```

**발생 위치가 정확히 FAPE 경로의 `batched_backbone_decode` backward.**

### 3차 분석: mp_nerf_torch backward NaN 메커니즘

`mp_nerf_torch` 내부:

```python
rotate = torch.stack([cb, n_plane_, n_plane], dim=-1)
rotate = rotate / torch.norm(rotate, dim=-2, keepdim=True)  # ← 문제
```

- **forward**: `norm`이 0에 가까워도 작은 값으로 나눠서 큰 수가 나올 뿐, NaN은 아님
- **backward**: `d/dx (x / ||x||)` = `(I - x̂x̂ᵀ) / ||x||` → `||x|| → 0`이면 **gradient NaN**

학습 초기에 모델이 큰 velocity를 예측 → 1-step Euler 후 `backbone_1_pred`가 폭발 → NeRF 재귀에서 연속된 좌표들이 거의 평행 또는 degenerate → `torch.cross` 결과가 0에 가까운 벡터 → backward에서 NaN.

---

## 최종 수정

**`crypticflow.py:386`** — FAPE decode 경로의 `pred_feat`를 `detach()`

```python
# 수정 전
pred_coords_all = batched_backbone_decode(pred_feat, lengths_t, center=True)

# 수정 후
pred_coords_all = batched_backbone_decode(pred_feat.detach(), lengths_t, center=True)
true_coords_all = batched_backbone_decode(true_feat.detach(), lengths_t, center=True)
```

**검증**: 배치 16개, 5 step 반복 → `grad_nan=False` 확인.

---

## 설계 함의: FAPE gradient 흐름

`detach()` 적용 후 FAPE loss는 **모델 파라미터에 gradient를 전혀 기여하지 않는다.**  
loss 값은 wandb에 찍히지만 학습에 영향 없는 dead loss.

### 다른 모델들은 어떻게 했나?

| 모델 | FAPE 사용? | NeRF detach? | 이유 |
|------|-----------|-------------|------|
| **FoldingDiff** | ❌ | — | NeRF를 loss에 넣지 않음. Angle space loss만 사용, NeRF는 evaluation 전용 |
| **FrameDiff** | ❌ | — | `bb_atom_loss`는 frame→coords 변환 (NeRF 아님), gradient 흐름 |
| **AlphaFold2** | ✅ (주 loss) | `stop_rot_gradient()` | NeRF NaN 때문이 아니라 iterative refinement 안정화 목적. AF2는 dihedral→coords NeRF를 쓰지 않음 |

**핵심**: NeRF(dihedral → Cartesian) backward NaN을 겪은 사례가 없는 이유는, 주요 모델들이 애초에 NeRF를 differentiable loss 경로에 넣지 않기 때문.

### 선택지 비교

| 방법 | 효과 | 트레이드오프 |
|------|------|-------------|
| `pred_feat.detach()` (현재) | NaN 해결 | FAPE gradient 없음 — dead loss |
| `mp_nerf_torch`에 epsilon 추가 | FAPE gradient 살아남 | NeRF 수치 안정성 보장 필요 |
| `fape_loss_weight: 0.0`으로 끄기 | 가장 깔끔 | FAPE supervision 포기 |
| Angle space auxiliary loss만 사용 | FoldingDiff 방식 | 좌표 감독 없음 |

---

## 현재 상태 및 미결 과제

- **Job 32651** 실행 중 (`cf_full_curated-32651.out`)
- config: `fape_loss_weight: 0.1` (wandb 수치는 찍히나 gradient 기여 없음)
- 실질적으로 backbone velocity loss만으로 학습 중인 상태

### TODO

- [ ] FAPE를 실제 gradient 기여하게 하려면: `mp_nerf_torch` 수정 또는 대체 좌표 loss 설계
- [ ] 또는 `fape_loss_weight: 0.0`으로 명시적으로 끄고 config 정리
- [ ] NeRF backward 안정화: `norm.clamp(min=1e-8)` 패치 후 재실험

---

## 관련 노트

- [[Status_Snapshot_2026-04-29]]
- [[Paper_Wu24_FoldingDiff]]
- [[Paper_Yim23_FrameDiff]]
- [[Paper_Jumper21_AlphaFold2]]
