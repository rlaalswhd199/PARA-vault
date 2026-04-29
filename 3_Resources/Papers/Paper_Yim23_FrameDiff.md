# Paper — FrameDiff: SE(3) diffusion model with application to protein backbone generation

## 메타

- **저자**: Jason Yim, Brian L. Trippe, Valentin De Bortoli, Emile Mathieu, Arnaud Doucet, Regina Barzilay, Tommi Jaakkola
- **Venue / Year**: ICML 2023
- **Link**: https://arxiv.org/abs/2302.02277
- **GitHub**: https://github.com/jasonkyuyim/se3_diffusion
- **Tier**: ⭐ Must-cite
- **관련 프로젝트**: [[../../1_Projects/Project_A/README]]

## TL;DR (3줄)

1. 각 residue를 SE(3) rigid frame (rotation R ∈ SO(3) + translation t ∈ ℝ³)으로 표현하고, SE(3) 위에서 diffusion 수행.
2. Sequential chain reconstruction이 없으므로 **lever arm effect가 구조적으로 차단**됨.
3. Pretrained structure prediction network 없이도 500 residue까지 designable monomer 생성 가능.

## 문제 정의 (Problem)

SE(3) 공간에서 score matching을 수행하는 원칙적인 방법론이 부재. 기존 torsion angle 기반 방법들은 lever arm effect 문제를 가짐.

## 핵심 아이디어 (Method)

- **표현**: 각 residue → `(Rᵢ, tᵢ) ∈ SE(3)` (독립적인 rigid frame)
- **Diffusion**: SO(3) + ℝ³를 분리하여 각각 diffusion
  - Translation: Gaussian diffusion on ℝ³
  - Rotation: IGSO3 (Isotropic Gaussian on SO(3)) diffusion
- **Loss**: FAPE (Frame Aligned Point Error) — 각 residue local frame 기준으로 원자 위치 오차 측정
- **핵심**: Sequential chain reconstruction 없음 → N-terminal 오차가 C-terminal로 누적되지 않음

## 실험 결과 (Results)

| 셋업 | 메트릭 | 값 |
|-----|--------|-----|
| Designability (scTM≥0.5) | 성공률 | RFdiffusion 다음으로 높음 |
| 최대 생성 길이 | residues | 500 |

## 강점 / 약점

**Strengths**
- Lever arm effect 구조적 차단 (sequential NERF 없음)
- 긴 단백질(≤500 residues)에서도 안정적
- FAPE loss로 3D 공간 감독 학습 가능

**Weaknesses**
- SE(3) diffusion 구현 복잡도 높음
- Backbone-only (all-atom 생성 불가)

## 우리 연구와의 연결 고리

- **Project A**: CrypticFlow의 lever arm effect 근본 해결책이 SE(3) 표현으로의 전환. FrameDiff가 이 방향의 레퍼런스. Encoder/Decoder 전체 교체가 필요하지만 장기적으로 고려해야 할 방향. FAPE loss 수식 참조.

## 인용할 만한 문장

> "FrameDiff can generate designable monomers up to 500 amino acids without relying on a pretrained protein structure prediction network"

## 추가로 읽을 참고문헌

- [ ] [[Paper_Bose23_FoldFlow]] — SE(3) flow matching (diffusion 대신 flow)
- [ ] [[Paper_Jumper21_AlphaFold2]] — FAPE loss 원조
