# Paper — FoldingDiff: Protein structure generation via folding diffusion

## 메타

- **저자**: Kevin E. Wu, Kevin K. Yang, Rianne van den Berg, Sarah Alamdari, James Y. Zou, Alex X. Lu, Ava P. Bhatt
- **Venue / Year**: Nature Communications, 2024
- **Link**: https://www.nature.com/articles/s41467-024-45051-2 | PMC: https://pmc.ncbi.nlm.nih.gov/articles/PMC10844308/
- **Tier**: ⭐ Must-cite
- **관련 프로젝트**: [[1_Projects/Crypticflow/README]]

## TL;DR (3줄)

1. Protein backbone을 6개 backbone angle (3 bond + 3 dihedral) per residue의 시퀀스로 표현하고, DDPM으로 denoising하여 단백질 구조를 생성.
2. Torsion angle 공간에서의 diffusion이 equivariant network 없이도 shift/rotation invariance를 자연스럽게 달성함.
3. **Lever arm effect를 명시적으로 인정**: 단일 각도 오차가 체인 끝으로 갈수록 기하급수적으로 증폭되어 전체 구조를 왜곡하는 현상. L≤70 residues에서만 안정적.

## 문제 정의 (Problem)

단백질 backbone 구조 생성에서 기존의 Cartesian coordinate 기반 방법들은 SE(3) equivariant network가 필요하여 복잡함. 각도 공간 표현은 이를 회피할 수 있으나 lever arm effect 문제가 있음.

## 핵심 아이디어 (Method)

- **표현**: 각 잔기의 6개 backbone angle `[φ, ψ, ω, τ, ∠CA:C:N, ∠C:N:CA]` 시퀀스
- **Diffusion**: DDPM을 각도 공간 (wrapped normal distribution)에서 수행
- **Reconstruction**: NERF(Natural Extension Reference Frame)로 3D 좌표 변환
- **Loss**: Radian-aware smooth L1 (wrapping 처리)

## 실험 결과 (Results)

| 셋업 | 메트릭 | 값 |
|-----|--------|-----|
| L≤70 residues | Designability | 안정적 |
| L>70 residues | RMSD | 급격히 악화 |

## 강점 / 약점

**Strengths**
- Equivariant network 불필요 → 구현 단순
- Angular representation의 shift/rotation invariance 자연 달성
- Lever arm effect를 문헌에서 최초로 명시적으로 정의

**Weaknesses**
- Lever arm effect로 인해 긴 단백질(L>70)에서 성능 저하 심각
- "future work should explore geometrically-informed architectures"로만 언급하고 해결책 제시 없음

## 우리 연구와의 연결 고리

- **Project A**: CrypticFlow가 FoldingDiff와 동일한 torsion angle 표현 사용 → 동일한 lever arm effect 발생. Job 399 (angle loss=0.0004 → RMSD=17.82 Å)가 이 논문에서 예측한 현상과 정확히 일치. **Must-cite for motivation**.
- Radian-aware smooth L1 loss도 FoldingDiff에서 먼저 제안됨 → cite 필요.

## 인용할 만한 문장

> "this framing allows for single-angle errors to significantly alter the overall generated structure — a sort of lever arm effect"

## 추가로 읽을 참고문헌

- [ ] [[3_Resources/Papers/Paper_Yim23_FrameDiff]] — Lever arm effect 없는 SE(3) 접근법
- [ ] [[3_Resources/Papers/Paper_Bose23_FoldFlow]] — SE(3) flow matching
