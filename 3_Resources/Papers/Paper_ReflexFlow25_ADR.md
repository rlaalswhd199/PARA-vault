# Paper — ReflexFlow: Rethinking Learning Objective for Exposure Bias Alleviation in Flow Matching

## 메타

- **저자**: (저자 미확인 — arXiv 참조)
- **Venue / Year**: arXiv 2025 (arXiv:2512.04904)
- **Link**: https://arxiv.org/abs/2512.04904
- **Tier**: Should-cite
- **관련 프로젝트**: [[1_Projects/Crypticflow/README]]

## TL;DR (3줄)

1. Flow Matching에서 train-test mismatch(exposure bias)의 두 가지 근본 원인 규명: biased input에 대한 일반화 부재 + 초기 denoising에서 저주파 성분 부족.
2. **ADR (Anti-Drift Rectification)**: scheduled sampling으로 biased input을 시뮬레이션하고 corrective velocity를 추가 학습.
3. **FC (Frequency Compensation)**: exposure bias로 놓치는 저주파 성분을 loss reweighting으로 보상.

## 문제 정의 (Problem)

Flow Matching 모델은 학습 시 clean interpolant `xₜ`를 입력받지만, 추론 시에는 이전 step의 biased prediction `x̂ₜ`를 입력받는다. 이 train-test mismatch가 오차 누적을 야기한다.

## 핵심 아이디어 (Method)

### ADR (Anti-Drift Rectification)

```
1. v⁰θ = vθ(xₜ, t)                   ← clean input으로 첫 forward (detach)
2. x̂_{t+dt} = xₜ + dt · stop_grad(v⁰θ) ← biased state 시뮬레이션
3. v¹θ = vθ(x̂_{t+dt}, t+dt)          ← biased input으로 두 번째 forward
4. v_ADR = diff(x₁, x̂_{t+dt}) / (1-(t+dt)) ← corrective velocity
5. L_ADR = SmoothL1(v¹θ, v_ADR)
```

### FC (Frequency Compensation)

- Early timestep에서 저주파 성분 학습을 강화하도록 loss reweighting

## 실험 결과 (Results)

| 셋업 | 메트릭 | 값 |
|-----|--------|-----|
| ImageNet-256 (w/o cfg) | FID 감소 | 9.01% |
| ImageNet-256 (w cfg=1.5) | FID 감소 | 11.16% |
| CIFAR-10 | FID 감소 | 9.56% |

## 강점 / 약점

**Strengths**
- Exposure bias의 근본 원인을 명확히 규명
- 이미지 생성에서 일관된 성능 향상

**Weaknesses**
- 이미지 생성에서만 검증됨. 단백질 구조 생성에 직접 적용 가능성 미검증.

## 우리 연구와의 연결 고리

- **Project A**: CrypticFlow에서 ADR을 구현하여 실험함 (`crypticflow.py:373-436`). Xt input mode에서 val_loss는 개선(0.000771)되었으나 RMSD는 4.81 Å로 약간 악화. X0 mode에서는 exposure bias 자체가 없어 ADR이 불필요하다는 것을 확인. 결국 exposure bias 원천 제거(X0 mode)가 ADR 적용보다 효과적이었음.

## 인용할 만한 문장

> "ReflexFlow: reflexive refinement of the Flow Matching learning objective that dynamically corrects exposure bias"

## 추가로 읽을 참고문헌

- [ ] Riemannian Flow Matching (Chen & Lipman, 2024) — 토러스 geodesic velocity
