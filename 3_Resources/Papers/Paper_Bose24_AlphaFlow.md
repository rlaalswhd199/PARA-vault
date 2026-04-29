# Paper — AlphaFlow: AlphaFold Meets Flow Matching for Generating Protein Ensembles

## 메타

- **저자**: Matthew Jude Bose, et al.
- **Venue / Year**: arXiv 2024 (arXiv:2402.04845)
- **Link**: https://arxiv.org/abs/2402.04845
- **Tier**: Should-cite
- **관련 프로젝트**: [[../../1_Projects/Project_A/README]]

## TL;DR (3줄)

1. AlphaFold/ESMFold를 flow matching 프레임워크로 fine-tune하여 단백질 구조 **앙상블**을 생성하는 AlphaFlow/ESMFlow 제안.
2. Squared FAPE loss를 사용한 새로운 훈련 전략으로 all-atom 예측 가능.
3. PDB 훈련 시 AlphaFold+MSA subsampling보다 precision-diversity tradeoff에서 우월.

## 문제 정의 (Problem)

단백질의 생물학적 기능은 동적 구조 앙상블에 의존하지만, AlphaFold 등은 단일 구조만 예측함. MD simulation은 비용이 너무 높음.

## 핵심 아이디어 (Method)

- **기반**: AlphaFold2/ESMFold를 백본으로 사용
- **Flow Matching**: 구조 → 구조 간 flow 학습 (PDB 구조들 사이)
- **Loss**: Squared FAPE loss (standard FAPE보다 안정적)
- **Prior**: Harmonic diffusion 기반 polymer-structured prior (scale-invariant noising)
- **Training**: Fine-tuning 방식 → 기존 pretrained weight 활용

## 실험 결과 (Results)

| 셋업 | 메트릭 | 값 |
|-----|--------|-----|
| PDB 앙상블 | Precision↑ Diversity↑ | AlphaFold+MSA 대비 우월 |
| MD 앙상블 | 구조 flexibility 재현 | 정확 |
| MD 앙상블 | positional distributions | 정확 |

## 강점 / 약점

**Strengths**
- Pretrained AlphaFold 활용으로 구현 용이
- Squared FAPE loss로 all-atom 예측
- 단백질 앙상블 생성의 실용적 대안

**Weaknesses**
- AlphaFold 라이선스 의존
- Apo→Holo 직접 예측이 아닌 앙상블 샘플링

## 우리 연구와의 연결 고리

- **Project A**: AlphaFlow는 protein ensemble을 생성하는 반면, CrypticFlow는 apo→holo 특정 전환을 예측. 목표가 다르지만 flow matching + FAPE loss 조합의 레퍼런스로 유용. Squared FAPE loss가 standard FAPE보다 안정적이라는 점 참고.

## 인용할 만한 문장

> "AlphaFold Meets Flow Matching for Generating Protein Ensembles"

## 추가로 읽을 참고문헌

- [ ] [[Paper_Sesame25_ApoHolo]] — Apo→holo 직접 예측 (더 관련성 높음)
- [ ] [[Paper_Jumper21_AlphaFold2]] — FAPE loss 원조
