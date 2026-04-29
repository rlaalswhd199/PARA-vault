# Paper — Int2Cart: Learning Correlations between Internal Coordinates to improve 3D Cartesian Coordinates for Proteins

## 메타

- **저자**: (저자 미확인 — arXiv 참조)
- **Venue / Year**: Journal of Chemical Theory and Computation (JCTC), 2022
- **Link**: https://arxiv.org/abs/2205.04676 | https://pubs.acs.org/doi/10.1021/acs.jctc.2c01270 | PMC: https://pmc.ncbi.nlm.nih.gov/articles/PMC10404647/
- **Tier**: Should-cite
- **관련 프로젝트**: [[../../1_Projects/Project_A/README]]

## TL;DR (3줄)

1. Backbone torsion angle → 3D Cartesian 좌표 변환 시 발생하는 NERF 오차 누적 문제를 정량 분석.
2. Torsion angle만으로는 재구성이 부정확하며, bond length/angle들 사이의 상관관계를 ML로 학습하면 정확도 향상.
3. 100-residue 기준 RMSD ~2.07 Å, 전체 test set 평균 ~3.74 Å — lever arm effect의 정량적 근거 제공.

## 문제 정의 (Problem)

Internal coordinate(torsion angle) → Cartesian coordinate 변환(NERF)에서 오차가 순차적으로 누적됨. 고정된 bond length/angle 사용 시 실제 구조와 괴리 발생.

## 핵심 아이디어 (Method)

- **ML 모델**: Backbone torsion angle + residue type → bond length, bond angle 예측
- **근거**: Bond length/angle들은 torsion angle 및 residue type과 상관관계가 있음
- **Pipeline**: Torsion → (ML로) bond geometry → NERF → 3D coordinates
- 고정값 또는 static library 대비 Cartesian 재구성 정확도 향상

## 실험 결과 (Results)

| 셋업 | 메트릭 | 값 |
|-----|--------|-----|
| 100-residue 기준 | Reconstruction RMSD | ~2.07 Å |
| 전체 test set (globular) | Mean RMSD | ~3.74 Å |

## 강점 / 약점

**Strengths**
- NERF 오차 누적(lever arm effect)을 정량적으로 측정한 중요한 선행 연구
- Bond geometry 학습으로 재구성 정확도 개선

**Weaknesses**
- 여전히 NERF sequential reconstruction 의존 → 근본 해결 아님
- 단백질 생성이 아닌 재구성 정확도 향상에 초점

## 우리 연구와의 연결 고리

- **Project A**: CrypticFlow의 Exp5 실험에서 ε=0.02 rad → RMSD 4.95 Å (247× 증폭)를 실험적으로 확인. Int2Cart의 정량 분석이 이 현상의 이론적 배경을 제공. **Lever arm effect 수치 인용 시 참조**.

## 인용할 만한 문장

> "adopting a sequential reconstruction method such as NeRF accumulates small errors that result in inadequate ring closure"

## 추가로 읽을 참고문헌

- [ ] MP-NeRF (PubMed 2022) — NERF 병렬화 및 수치 안정성 분석
- [ ] [[Paper_Wu24_FoldingDiff]] — Lever arm effect 명시
