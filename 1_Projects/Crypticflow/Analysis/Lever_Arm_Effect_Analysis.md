# Lever Arm Effect — 문제 분석 및 해결 시도 정리

> CrypticFlow에서 발생한 lever arm effect의 원인, 실험적 증명, 해결 시도 4가지를 정리한 문서.
> 코드 repo 분석 결과를 vault로 이관 (2026-04-29).

---

## 1. 문제 정의

### 현상

Flow Matching으로 학습한 CrypticFlow 모델에서 **각도 loss는 수렴(≈0.0004)했는데 Cartesian RMSD는 오히려 악화(5.69→17.82 Å)** 되는 현상 발생.

### 근본 원인: Sequential NERF의 오차 누적

단백질 backbone을 내부 좌표 `(L, 9)` — phi, psi, omega, tau, bond angle 2개, bond length 3개 — 로 표현한 뒤, NERF(Natural Extension Reference Frame)으로 3D 좌표로 변환할 때 오차가 순차적으로 누적된다.

```
N₀ → Cα₀ → C₀ → N₁ → Cα₁ → C₁ → ··· → Nₗ → Cαₗ → Cₗ
     ↑ 각 원자 위치는 이전 3개 원자에 의존 (O(L) 누적)
```

**FoldingDiff (Wu et al., 2024)** 에서 명시적으로 언급:
> "this framing allows for single-angle errors to significantly alter the overall generated structure — a sort of lever arm effect"

---

## 2. 실험적 증명 (pair_05081, L=265 residues)

### Exp1: NERF Round-trip 정확도

| 측정값 | 값 |
|--------|-----|
| Round-trip RMSD (CA) | **0.14 mÅ** |
| Apo–Holo true RMSD | 5.71 Å |

→ NERF 구현 자체는 정확. 문제는 모델이 예측하는 **각도 오차**에 있음.

### Exp3: Jacobian Norm — 수학적 증명

| 각도 유형 | 최대 (N-term) | 최소 (C-term) | N/C 비율 |
|-----------|--------------|--------------|----------|
| **phi** | 455.9 (j=24) | 1.39 (j=264) | **328.8×** |
| psi | 502.5 (j=80) | 29.4 (j=256) | 17.1× |
| omega | 475.3 (j=24) | 36.3 (j=256) | 13.1× |

→ N-terminal phi 각도 하나의 오차가 C-terminal보다 **329배** 크게 전파됨.

### Exp5: Noise Amplification Curve

| ε (rad) | ε (°) | Mean RMSD | Amplification |
|---------|-------|-----------|---------------|
| 0.001 | 0.057° | 0.242 Å | **242×** |
| 0.010 | 0.573° | 2.284 Å | 228× |
| **0.020** | **1.15°** | **4.946 Å** | **247×** |
| 0.050 | 2.86° | 11.409 Å | 228× |

→ Job 399에서 관찰된 17.82 Å = **891× 증폭** (σ ≈ 0.02 rad)

---

## 3. 해결 시도 4가지 및 결과

### 비교 요약

| 전략 | 아이디어 | best_val_loss | RMSD | 효과 |
|------|----------|--------------|------|------|
| **X0 (apo 고정 입력)** | Exposure bias 원천 제거 | 0.00163 | **2.38 Å** ⭐ | 최고 |
| Vanilla (Xt input) | baseline | 0.00107 | 4.37 Å | 기준 |
| ADR | Exposure bias 보정 학습 | 0.000771 | 4.81 Å | 미미 |
| Position-Weight | 앞 잔기에 더 큰 penalty | 0.0000653* | 5.33 Å | 역효과 |
| Riemannian FM | 토러스 geodesic velocity | 0.00105 | 6.76 Å | 역효과 |
| FAPE | 3D 공간 직접 학습 | 0.3225 (발산) | 6.03 Å | 발산 |

### 3.1 Position-Weighted Loss

- **아이디어**: NERF chain에서 앞쪽 잔기의 오차가 이후 모든 잔기에 누적되므로, `wᵢ = (L-i) / Σⱼ(L-j)` 가중치로 앞쪽 잔기 penalty 강화.
- **실패 원인**: 가중치 합 < 1 → loss 스케일 자체가 줄어드는 부작용. RMSD 오히려 악화.

### 3.2 FAPE Loss (Frame-Aligned Point Error)

- **아이디어**: 각 잔기의 local backbone frame (N, Cα, C 기준 Gram-Schmidt) 기준으로 인접 잔기 위치 오차 측정. Global RMSD보다 안정적.
- **실패 원인**: NERF O(L) gradient chain + weight=50 → exploding gradient. FAPE는 SE(3) 표현에서 안정적이지만 NERF backprop이 chain이 길수록 불안정.

### 3.3 Riemannian Flow Matching

- **아이디어**: 각도 공간은 토러스 (S¹)ⁿ이므로, 표준 FM의 유클리드 velocity 대신 geodesic velocity `uₜ = log_{xₜ}(x₁) / (1-t)` 사용.
- **결과**: 학습 중 최저 RMSD 3.57 Å 달성했으나, best_val_loss 시점과 불일치. t→1에서 1/(1-t) 발산 문제.
- **발견**: **loss 기준 best ≠ RMSD 기준 best** 문제 드러냄.

### 3.4 ADR (Anti-Drift Rectification)

- **아이디어**: ReflexFlow (arXiv:2512.04904)에서 제안. 학습 시 clean interpolant 입력 vs 추론 시 biased state 입력의 **exposure bias**를 해결하기 위해, biased state를 시뮬레이션하고 corrective velocity를 추가 학습.
- **결과**: Xt input mode에서 val_loss 개선(0.000771)이나 RMSD는 약간 악화(4.81 Å). X0 mode에서는 exposure bias 자체가 없어 불필요.

---

## 4. 핵심 통찰: 진짜 원인은 Exposure Bias

> **Lever arm effect는 증상, Exposure Bias가 근본 원인이었다.**

- **Train**: clean interpolant `xₜ = x₀ + t·Δ`를 입력받아 velocity 예측
- **Inference**: 이전 step의 biased prediction을 입력받아 velocity 예측

이 train-test mismatch(exposure bias)가 오차를 축적시켜 RMSD를 폭발시킴.

**X0 mode** (추론 시 항상 apo backbone을 입력)로 mismatch를 원천 차단 → RMSD 4.37 → **2.38 Å** (45% 개선).

잔여 오차(2.38 Å)는 σ≈0.013 rad의 각도 오차 → RMSD≈3 Å 증폭인 NERF lever arm effect가 원인.

---

## 5. 향후 방향

### 단기
- FAPE loss를 SE(3) frame 기반으로 (NERF backprop 없이) 적용
- Gradient norm clipping 강화 (max_norm=0.1 수준)

### 중기
- SE(3) frame 표현으로 전환 (FrameDiff, FoldFlow, Sesame 참조)
- 각 residue를 (R, t) ∈ SE(3)으로 표현 → lever arm effect 구조적 차단

### 장기
- Sesame (arXiv:2509.05302) 코드 참조: apo→holo flow matching with SE(3) frames

---

## 관련 파일

- 코드 repo 실험 스크립트: `scripts/lever_arm/exp1_oracle.py` ~ `exp7_kabsch_center_bias.py`
- 코드 repo 리포트: `reports/lever_arm_2026-02-23/`
- Vault 이관 리포트: [[../Experiments/lever_arm_2026-02-23/01_literature_review]]
- 관련 논문: [[../../3_Resources/Papers/Paper_Wu24_FoldingDiff]], [[../../3_Resources/Papers/Paper_Yim23_FrameDiff]], [[../../3_Resources/Papers/Paper_Bose23_FoldFlow]], [[../../3_Resources/Papers/Paper_Sesame25_ApoHolo]]

---

## 참고 문헌

- [FoldingDiff — Nature Communications 2024](https://www.nature.com/articles/s41467-024-45051-2)
- [ReflexFlow — arXiv 2512.04904](https://arxiv.org/abs/2512.04904)
- [Sesame — arXiv 2509.05302](https://arxiv.org/abs/2509.05302)
- [FrameDiff — arXiv 2302.02277](https://arxiv.org/abs/2302.02277)
- [FoldFlow — arXiv 2310.02391](https://arxiv.org/abs/2310.02391)
- [AlphaFlow — arXiv 2402.04845](https://arxiv.org/abs/2402.04845)
