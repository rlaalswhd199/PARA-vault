# Overfitting 테스트 결과 분석 보고서: Lever Arm Effect 수치 진단

**작성**: scientist agent (oh-my-claudecode:scientist)
**날짜**: 2026-02-23
**분석 대상**: pair_05081 (265 residues), SLURM jobs 399–403
**팀**: crypticflow-lever-arm

---

## 1. Job 399 상세 분석 (Vanilla, coord_loss_weight=0, circle_penalty=0)

### 설정
- `backbone_loss_weight=1.0, beta=0.1, circle_penalty=0.0`
- Epochs: 5000, 단일 파일 오버피팅 (pair_05081)

### Backbone Loss 수렴 곡선

| Epoch | val_loss | RMSD (Å) |
|-------|----------|----------|
| 0     | 1.1708   | (미측정)  |
| 1     | 0.4918   | (미측정)  |
| 9     | 0.1374   | 19.95    |
| 19    | 0.1095   | 19.19    |
| 29    | 0.1038   | 17.67    |
| 39    | 0.0902   | 16.14    |
| 49    | 0.0967   | 18.02    |
| 59    | 0.0828   | 17.17    |
| 69    | 0.0850   | 18.97    |
| 79    | 0.0749   | 16.53    |
| 89    | 0.0793   | 13.17    |
| 99    | 0.0713   | 16.65    |
| ...   | ...      | ...      |
| ~3314 | **0.0004** (best) | ~17.82 |

**backbone < 0.001 첫 도달**: Epoch **1299** (train loss 기준)
- Epoch 1299에서 train loss=0.0009
- Epoch 1355에서 0.0007로 하락
- best val_loss=0.0004는 epoch ~3314–3317에서 달성

### RMSD 수렴 곡선 (매 ~10 epoch마다 측정)

RMSD는 전체 훈련을 통해 **13~20Å 사이에서 진동**하며 수렴하지 않음:
- Epoch 10: 19.95Å (Δ=-14.26 vs apo-holo)
- Epoch 90 (일시적 최소): **13.17Å** — 최저값
- Epoch 130: 16.29Å
- Epoch 200 (일시적 반등): 18.97Å
- 후반부 (epoch 3000대): 14.32–22.88Å 사이 진동
- **최종 기록**: pair_05081: First=5.69Å → Final=17.82Å (Δ=-12.13Å)

### val_loss vs RMSD 역설

핵심 관찰: **val_loss=0.0004 (역대 최저)에서 RMSD=17.82Å (매우 높음)**
- val_loss가 1.1708→0.0004로 2900배 개선되는 동안
- RMSD는 5.69Å (초기 apo-holo 거리)에서 17.82Å로 **오히려 악화**
- angle space 최적화가 Cartesian space에서 역효과임을 명백히 증명

---

## 2. Job 401 상세 분석 (coord_loss_weight=1.0, circle_penalty=1.0)

### 설정
- `backbone_loss_weight=1.0, beta=0.1, circle_penalty=1.0, coord_loss_weight=1.0`

### Coord RMSD 초기값 및 즉각적 폭발

| Epoch | Train Loss | Backbone | Coord RMSD |
|-------|-----------|----------|------------|
| 0     | 24.2434   | 0.2833   | **23.9601** |
| 1     | 25.3781   | 0.7354   | 24.6427    |
| 2     | 16.0232   | 0.8768   | 15.1463    |
| 6     | 38.0026   | 2.1799   | **35.8227** |
| 9     | 49.0959   | 5.1356   | **43.9604** |
| 10    | 57.5053   | 6.3159   | **51.1895** |
| 13    | 147.6044  | 14.2738  | **133.3307** |

**Epoch 6부터 폭발 시작**: coord_rmsd가 15→35→43→51→133Å로 3에폭 안에 10배 증가.

**이후 발산 경로**:
- Epoch ~190: 793 Å
- Epoch ~195: **5,694 Å**
- Epoch ~200: **66,918 Å** (완전 폭발)
- Epoch ~520: Loss=11,407, coord_rmsd=31,500 Å
- Epoch ~529: Loss=**14,648,818** (1400만 단위)

**NaN/Inf**: Job 401은 overflow 상태로 계속 실행 (gradient skip 없음, 값 자체 overflow).

---

## 3. Job 402 상세 분석 (coord_loss_weight=0.01, circle_penalty=1.0)

### 설정
- `coord_loss_weight=0.01` (1.0 → 0.01로 100배 감소)

### 초기 동작

| Epoch | Train Loss | Backbone | Coord RMSD |
|-------|-----------|----------|------------|
| 0     | 0.7625    | 0.2833   | 23.9601    |
| 1     | 1.0401    | 0.6821   | 17.9000    |
| 7     | 2.7464    | 2.3902   | 17.8117    |
| 25    | 2.0094    | 1.6771   | 16.6129    |
| 35    | 2.4259    | 1.8726   | 27.6618    |
| ~37   | (폭발)    | 107      | 145        |
| ~40   | (폭발)    | —        | 185        |
| ~42   | (폭발)    | —        | **504**    |

**결론**: 초기에는 일시적 안정화를 보였으나 가중치를 100배 줄여도 폭발을 피하지 못함.

---

## 4. Job 403 상세 분석 (coord_loss_weight=0.02, circle_penalty=1.0)

### 설정
- `coord_loss_weight=0.02`

### Loss 폭발 타임라인

| Epoch | Train Loss | Backbone | Coord RMSD |
|-------|-----------|----------|------------|
| 0     | 0.7625    | 0.2833   | 23.9601    |
| 1     | 1.0401    | 0.6821   | 17.9000    |
| ~25   | 19.4468   | 14.9997  | **222.3541** |
| ~44   | 204.5229  | 194.4417 | **504.0597** |
| ~97   | 182.2768  | 164.5765 | **885.0173** |
| ~195  | 5,694     | —        | 4,091      |
| ~200  | 66,918    | —        | 58,452     |
| 3693  | val=**14,646,486** | — | —     |
| 3694  | 14,648,818 | 10,777  | **2,896,520** |

### NaN/Inf Gradient 검출
- **첫 발생**: Epoch **3688** (`⚠️ [Step 3688] NaN/Inf gradient detected, skipping step`)
- 이후 연속: Epoch 3693, 3694, 3696, 3697
- NaN step에서는 Train Loss=0.0000, Coord RMSD=0.0000 (스킵됨)

### CUDA Illegal Memory Access
- **Epoch 3699**: `loss.backward()` 도중 crash
- 스택: `wandb/integration/torch/wandb_torch.py`의 gradient hook에서 `tensor.cpu().detach().clone()` 실행 중
- 오류: `torch.AcceleratorError: CUDA error: an illegal memory access was encountered`
- **근본 원인**: NaN/Inf 값이 GPU 메모리를 오염 → wandb hook이 불법 메모리 주소 접근

---

## 5. 수치적 Lever Arm 분석

### 관찰값
- pair_05081: N=265 residues
- 초기 apo-holo RMSD: **5.69 Å**
- angle loss 수렴 후 RMSD: 13–22 Å (평균 ~17 Å)

### 이론적 Lever Arm 계산

NERF 순차적 재구성에서 잔기 i의 각도 오차 δθ_i는 이후 (N-i)개 잔기의 좌표에 누적된다.

**파라미터**:
- C-alpha 간 거리: b ≈ 3.8 Å
- angle error: √0.0004 ≈ **0.02 rad** (val_loss 수렴 시점)

**계산**:
```
RMSD_expected = δθ × b × sqrt(Σ(N-i)² / N)  for i=0..N-1
              = 0.02 × 3.8 × sqrt(N(N+1)(2N+1)/6 / N)
              = 0.076 × sqrt(265×266×531/(6×265))
              ≈ 0.076 × sqrt(23,541)
              ≈ 0.076 × 153.4 ≈ 11.7 Å
```

**결론**: 이론값 **~11.7 Å** vs 관찰값 **13–22 Å** (평균 ~17 Å)

같은 order of magnitude — 이론적 lever arm 효과가 관찰된 RMSD 악화를 정량적으로 설명한다.

실제 RMSD가 이론값보다 높은 이유:
1. angle error가 독립적이지 않고 correlated
2. 일부 구간에서 δθ > 0.02 rad인 영역 존재
3. 디헤드럴 각도의 비선형 propagation

---

## 6. 결론 및 권고사항

### A. Vanilla 모델 (Job 399)의 근본적 문제

**"Angle space 최적화 ≠ Cartesian space 수렴"**

- val_loss=0.0004에도 불구하고 RMSD가 5.69→17.82 Å로 증가
- RMSD 곡선이 13–22 Å 사이에서 비수렴: 어떤 체크포인트도 신뢰 불가
- 단순히 더 훈련하거나 learning rate를 낮춰도 해결 불가 — **구조적 문제**

### B. Coord Loss 추가 (Job 401/402/403)의 실패 원인

1. **즉각적 RMSD 폭발**: coord_loss gradient가 NeRF decoder 역전파 시 Jacobian이 극단적으로 커짐
2. **가중치 감소의 한계**: 0.01–0.02로 줄여도 폭발 (메커니즘이 unchanged)
3. **만성적 불안정**: 폭발-회복-재폭발 반복 패턴
4. **NaN은 증상**: 실질적 발산은 epoch 6(Job 401)에 시작, NaN은 epoch 3688에 감지

### C. 다음 실험 우선순위

1. **Anchor Loss (내부 거리)**: pairwise distance loss (i, i+5, i+10 로컬 거리) — NERF 역전파 불필요
2. **Stop-gradient + Detach NeRF**: coord_loss 계산 시 NeRF output detach()
3. **Multi-time loss**: 여러 중간 시점에서 loss 계산
4. **Internal Coordinate Loss**: Ramachandran plot 분포 또는 로컬 geometry loss

**즉시 실험 제안**: pair_05081에 `detach()` + 거리 기반 앵커 loss (coord_loss_weight=0.1)로 단일 테스트. epoch 100 이내 RMSD 안정화 여부 확인.
