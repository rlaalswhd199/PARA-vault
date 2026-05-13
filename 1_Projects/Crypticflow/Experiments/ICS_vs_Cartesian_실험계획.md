# ICS vs Cartesian Flow Matching 비교 실험 계획

작성일: 2026-05-09  
목적: ICS 공간에서의 flow matching이 Cartesian 공간보다 ODE inference 중 OOD에 더 민감하다는 것을 정량적으로 증명

---

## 배경

CrypticFlow (ICS 기반)는 loss는 잘 내려가는데 RMSD가 oscillate하는 현상이 있었다.
원인 분석:
1. `_wrap_angular` 버그 → CA-only 5-dim에 9-dim wrap 적용 → 수정 완료
2. ODE inference 중 ICS 공간의 미세한 오차가 NERF 역변환 시 ~100x 증폭됨 (Lever Arm Effect)
3. `xt_input=True` flow matching은 linear interpolation manifold를 학습하지만, ODE는 이 manifold에서 벗어남

**Cartesian 모델 구현 배경**: 동일 아키텍처에서 ICS 대신 Cartesian 좌표로 학습하면 위 문제가 얼마나 완화되는지 비교

---

## 실험 1: NERF Lever Arm Effect 정량화

### 목적
ICS 공간의 작은 노이즈 ε이 NERF 역변환 후 Cartesian RMSD를 ~100x 증폭하는 반면,
Cartesian 공간의 동일 크기 노이즈는 ~1.7x에 그침을 수치로 보임

### 방법
- 파일: `experiments/exp1_lever_arm.py` (구현 완료)
- ε = [0.001, 0.005, 0.01, 0.05, 0.1, 0.2, 0.5] 범위에서
- 각 ε마다 100회 시뮬레이션
- **ICS 노이즈**: apo CA 좌표 → CAOnlyEncoder → ICS 5-dim + ε → NERF → Cartesian RMSD
- **Cartesian 노이즈**: apo CA 좌표 + ε → Kabsch align 후 RMSD
- 출력: ε vs RMSD 그래프 (linear + log-log), 증폭 비율 그래프

### 기대 결과
| ε | ICS RMSD | Cartesian RMSD | 증폭비 |
|---|----------|----------------|--------|
| 0.001 | ~0.10Å | ~0.0017Å | ~60x |
| 0.01  | ~1.0Å  | ~0.017Å  | ~60x |
| 0.1   | ~8Å    | ~0.17Å   | ~47x |

### 실행 방법
```bash
cd /home/mjkim/project/crypticflow
crypticflow_env/.venv/bin/python experiments/exp1_lever_arm.py
# 결과: experiments/results/exp1_lever_arm.json
# 그림: experiments/results/exp1_lever_arm_*.png
```

---

## 실험 2: ICS vs Cartesian Flow Matching 학습 비교

### 목적
동일 아키텍처, 동일 데이터에서 ICS(CrypticFlow)와 Cartesian 모델을 비교하여
ODE inference 중 RMSD 개선 정도와 step 수에 따른 안정성 차이를 측정

### 비교 모델
| 항목 | CrypticFlow (ICS) | Cartesian 모델 |
|------|-------------------|----------------|
| 입력 | (L,5) ICS: [d_CA, sinθ, cosθ, sinφ, cosφ] | (L,3) Cartesian: [X,Y,Z] |
| 출력 | ICS velocity → NERF 복원 | Cartesian velocity → centroid 정규화 |
| wrap | `_wrap_ca_only` | `_wrap_identity` (없음) |
| 아키텍처 | 동일 (DiT, hidden=256, layers=32) | 동일 |
| 데이터 | 3개 단백질 (small/mid/large) | 동일 |

### 현재 진행 중인 학습 실험 (2026-05-09 제출, uniform time sampling)

| Job | 모델 | 단백질 | L | RMSD(apo,holo) | Config |
|-----|------|--------|---|----------------|--------|
| 34345 | ICS (CA-only v5) | 1SL7_A_1SL9_A | 166 | 2.98Å | overfit_ca_small_v5.yaml |
| 34346 | ICS (CA-only v5) | 3OIC_D_3OID_B | 248 | 4.64Å | overfit_ca_mid_v5.yaml |
| 34347 | ICS (CA-only v5) | 4JNF_A_4JN4_B | 212 | 27.62Å | overfit_ca_large_v5.yaml |
| 34348 | Cartesian v2 | 1SL7_A_1SL9_A | 166 | 2.98Å | overfit_cart_small_v2.yaml |
| 34349 | Cartesian v2 | 3OIC_D_3OID_B | 248 | 4.64Å | overfit_cart_mid_v2.yaml |
| 34350 | Cartesian v2 | 4JNF_A_4JN4_B | 212 | 27.62Å | overfit_cart_large_v2.yaml |

> 이전 grid 버전(34342~34344)은 ODE steps 비교 실험 시 편향이 생길 수 있어 취소하고 uniform으로 재제출

### 비교 지표
1. **최종 RMSD**: 수렴 후 holo_true와 pred 간 Kabsch RMSD
2. **RMSD vs ODE steps**: steps=[1,2,5,10,20,50] 별 RMSD (ICS는 step 증가할수록 악화될 것)
3. **학습 안정성**: loss vs epoch 곡선, RMSD oscillation 여부

### 분석 스크립트 계획
파일: `experiments/exp2_ics_vs_cart.py` (미구현)

```python
# 해야 할 것:
# 1. ICS checkpoint (ca_small_v4, ca_mid_v4, ca_large_v4) 로드
# 2. Cartesian checkpoint (cart_small, cart_mid, cart_large) 로드
# 3. 각 모델에 대해 ode_steps=[1,2,5,10,20,50]로 inference
# 4. RMSD 계산 및 비교 그래프 생성
```

---

## 내일 해야 할 작업

### 1. Cartesian 학습 결과 확인 (job 34342~34344)
```bash
tail -f ~/s_outs/cf_cart_overfit-34342.out  # small
tail -f ~/s_outs/cf_cart_overfit-34344.out  # large
```
- epoch 1000 시점 RMSD 확인 (visualizations 폴더)
- loss 수렴 여부 확인

### 2. exp1_lever_arm.py 실행
```bash
cd /home/mjkim/project/crypticflow
crypticflow_env/.venv/bin/python experiments/exp1_lever_arm.py
```

### 3. exp2_ics_vs_cart.py 작성 및 실행
- ICS checkpoint 경로:
  - small: `checkpoints_overfit_test/ca_small_v4/_job3433*/`
  - mid: `checkpoints_overfit_test/ca_mid_v4/_job3433*/`
  - large: `checkpoints_overfit_test/ca_large_v4/_job3433*/`
- Cartesian checkpoint 경로:
  - small: `checkpoints_overfit_test/cart_small_v1/_job34342/`
  - mid: `checkpoints_overfit_test/cart_mid_v1/_job34343/`
  - large: `checkpoints_overfit_test/cart_large_v1/_job34344/`

### 4. 수정된 버그 확인
- `ode_solver.py`: `_wrap_identity` 추가 완료
- `model/crypticflow.py`: cartesian 모드에서 `_wrap_identity` 사용으로 수정 완료
- `train.py`: cartesian 모드 RMSD 계산 경로 추가 완료

---

## 발견된 버그 기록

### 버그 1: `_wrap_angular` cartesian 좌표 압축 (2026-05-09 수정)
- **현상**: cartesian 모델 inference 시 pred 좌표가 origin 근처로 붕괴 (std ~1.8Å)
- **원인**: `ode_solver.py`에서 `wrap_fn=None`이면 `_wrap_angular` 기본 적용 → (L,3) X,Y,Z를 `atan2`로 [-π,π] 압축
- **수정**: `_wrap_identity` 추가, cartesian 모드에서 명시적으로 전달

### 버그 2: `_wrap_angular` CA-only 5-dim 적용 (이전 세션 수정)
- **현상**: CA-only inference RMSD oscillation
- **원인**: `_wrap_angular`가 9-dim 기준으로 구현 → 5-dim에 잘못 적용
- **수정**: `_wrap_ca_only` 추가, CA-only 모드에서 명시적으로 전달
