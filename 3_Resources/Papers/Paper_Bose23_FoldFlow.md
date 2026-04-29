# Paper — FoldFlow: SE(3)-Stochastic Flow Matching for Protein Backbone Generation

## 메타

- **저자**: Avishek Joey Bose, Tara Akhound-Sadegh, Kilian Fatras, Guillaume Huguet, Jarrid Rector-Brooks, Cheng-Hao Liu, Andrei Cristian Nica, Maksym Korablyov, Michael Bronstein, Alexander Tong
- **Venue / Year**: ICLR 2024 Spotlight
- **Link**: https://arxiv.org/abs/2310.02391
- **GitHub**: https://github.com/DreamFold/FoldFlow
- **Tier**: ⭐ Must-cite
- **관련 프로젝트**: [[1_Projects/Crypticflow/README]]

## TL;DR (3줄)

1. SE(3) 위에서 flow matching을 수행하는 FoldFlow 시리즈 제안 (FoldFlow-Base, FoldFlow-OT, FoldFlow-SFM).
2. Riemannian Optimal Transport를 통해 더 단순하고 안정적인 flow 학습.
3. Diffusion 기반 방법보다 훈련 안정성↑, 속도↑ — 최대 300 residues 생성.

## 문제 정의 (Problem)

기존 protein backbone generation이 diffusion 기반에 집중되어 있고, SE(3) 위의 flow matching 방법론이 부재.

## 핵심 아이디어 (Method)

### FoldFlow 3가지 변형

| 모델 | 특징 |
|------|------|
| FoldFlow-Base | Deterministic continuous-time dynamics, simulation-free |
| FoldFlow-OT | Riemannian OT로 더 단순한 flow 학습 |
| FoldFlow-SFM | OT + stochastic continuous-time dynamics 조합 |

- **표현**: 각 residue → SE(3) frame (FrameDiff와 동일)
- **Flow**: SE(3) geodesic interpolation (SO(3) + ℝ³ 분리)
- **장점**: Diffusion 대비 훈련 안정성↑, ODE solver로 빠른 샘플링

## 실험 결과 (Results)

| 셋업 | 메트릭 | 값 |
|-----|--------|-----|
| Designability | scTM≥0.5 비율 | 높음 |
| Diversity & Novelty | — | 개선됨 |
| Max length | residues | 300 |

## 강점 / 약점

**Strengths**
- Flow matching이 diffusion보다 훈련 안정적
- Riemannian OT로 flow 경로 단순화
- CrypticFlow와 같은 flow matching 패러다임 → 직접 참조 가능

**Weaknesses**
- Unconditional generation (서열 conditioning 없음)
- SE(3) 구현 복잡도

## 우리 연구와의 연결 고리

- **Project A**: CrypticFlow도 flow matching 기반 → FoldFlow의 SE(3) 구현을 참조하여 torsion angle 공간에서 SE(3) 공간으로 전환하는 방향을 검토할 수 있음. 특히 FoldFlow-OT의 Riemannian OT 개념이 흥미로움.

## 인용할 만한 문장

> "FoldFlow generative models are more stable and faster to train than diffusion-based approaches"

## 추가로 읽을 참고문헌

- [ ] [[3_Resources/Papers/Paper_Yim23_FrameDiff]] — SE(3) diffusion (FoldFlow의 비교 대상)
- [ ] [[3_Resources/Papers/Paper_Sesame25_ApoHolo]] — SE(3) flow matching for apo→holo
