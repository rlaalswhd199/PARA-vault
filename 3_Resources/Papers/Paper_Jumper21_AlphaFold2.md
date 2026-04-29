# Paper — AlphaFold2: Highly accurate protein structure prediction with AlphaFold

## 메타

- **저자**: John Jumper, Richard Evans, Alexander Pritzel, et al. (DeepMind)
- **Venue / Year**: Nature, 2021
- **Link**: https://www.nature.com/articles/s41586-021-03819-2
- **Tier**: ⭐ Must-cite
- **관련 프로젝트**: [[../../1_Projects/Project_A/README]]

## TL;DR (3줄)

1. Evoformer + Structure Module 구조로 단백질 구조를 원자 수준으로 예측하는 AlphaFold2.
2. **FAPE (Frame Aligned Point Error) loss** 제안: 각 residue local frame 기준으로 원자 위치 오차 측정 → lever arm effect 없이 안정적인 3D 학습 가능.
3. 각 residue frame을 **독립적으로** 예측 (peptide bond geometry 의도적으로 무시) → loop closure 문제 없이 local refinement 가능.

## 문제 정의 (Problem)

단백질 구조 예측에서 3D 좌표를 직접 예측하면 global RMSD loss가 lever arm effect에 취약하고 gradient가 불안정함.

## 핵심 아이디어 (Method)

### FAPE Loss (Eq. 4)

각 residue i의 local frame `Tᵢ = (Rᵢ, tᵢ)` (N, Cα, C로 Gram-Schmidt):

```
dist(i,j) = || Tᵢ_pred⁻¹(xⱼ_pred) - Tᵢ_true⁻¹(xⱼ_true) ||

L_FAPE = (1/N_frames · 1/N_atoms) Σᵢ Σⱼ min(dist(i,j), d_clamp)
```

**핵심**: 각 frame 기준의 상대 좌표를 비교 → global alignment 불필요, lever arm 없음.

### Independent Frame Prediction

> "peptide bond geometry is completely unconstrained — breaking this constraint enables local refinement of all parts of the chain without solving complex loop closure problems"

## 실험 결과 (Results)

| 셋업 | 메트릭 | 값 |
|-----|--------|-----|
| CASP14 | GDT_TS | ~92.4 |
| TM-score | — | >0.9 대부분 |

## 강점 / 약점

**Strengths**
- FAPE loss가 3D 공간 감독을 안정적으로 수행
- Independent frame prediction으로 어떤 길이에서도 안정적

**Weaknesses**
- MSA 의존성 (AlphaFold2의 한계, ESMFold에서 해소됨)

## 우리 연구와의 연결 고리

- **Project A**: CrypticFlow의 FAPE loss 구현 (`losses.py:291-333`)이 AlphaFold2 Eq. 4를 참조. 단, NERF backprop과 함께 사용 시 gradient 폭발 (weight=50에서 발산). SE(3) 표현으로 전환하면 FAPE loss가 제대로 작동할 것으로 예상. **Must-cite for FAPE loss**.

## 인용할 만한 문장

> "peptide bond geometry is completely unconstrained — breaking this constraint enables local refinement of all parts of the chain without solving complex loop closure problems"

## 추가로 읽을 참고문헌

- [ ] OpenFold — FAPE clamping 개선 (sample 단위 clamping)
- [ ] [[Paper_Wu24_FoldingDiff]] — torsion angle 기반 대안
