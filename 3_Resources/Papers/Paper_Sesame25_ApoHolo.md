# Paper — Sesame: Opening the door to protein pockets

## 메타

- **저자**: (저자 미확인 — arXiv 참조)
- **Venue / Year**: GEM Workshop @ ICLR 2025 / arXiv 2025-09
- **Link**: https://arxiv.org/abs/2509.05302
- **Tier**: ⭐ Must-cite
- **관련 프로젝트**: [[../../1_Projects/Project_A/README]]

## TL;DR (3줄)

1. **CrypticFlow와 동일한 task**: Apo 구조에서 Holo 구조(ligand-bound conformation)를 생성하는 generative model.
2. SE(3) frame 기반 flow matching + FAPE loss를 사용하여 lever arm effect 없이 구조 생성.
3. 기존 MD simulation 대비 훨씬 빠른 속도로 docking에 적합한 pocket geometry 생성.

## 문제 정의 (Problem)

Molecular docking은 ligand-bound (holo) 구조가 필요하지만, 실험적으로 구하기 어려움. Apo 구조에서 holo conformation을 예측하는 것이 목표. 기존 MD simulation은 계산 비용이 너무 높음.

## 핵심 아이디어 (Method)

- **표현**: SE(3) rigid frame (CrypticFlow의 torsion angle 표현과 달리 NERF 없음)
- **조건**: Apo 구조 + (추정) binding site 정보
- **Flow matching**: SE(3)^N 위에서 apo→holo trajectory 학습
- **Loss**: FAPE + auxiliary pairwise distance loss

## 실험 결과 (Results)

| 셋업 | 메트릭 | 값 |
|-----|--------|-----|
| Docking performance | vs apo baseline | 개선됨 |
| Speed vs MD | 계산 시간 | 크게 단축 |

## 강점 / 약점

**Strengths**
- CrypticFlow와 **동일한 task** → 직접 비교 대상
- SE(3) 표현으로 lever arm effect 없음
- FAPE + pairwise distance loss 조합이 안정적임을 입증

**Weaknesses**
- GEM workshop 논문 (peer review 수준 미확인)
- 코드 공개 여부 미확인

## 우리 연구와의 연결 고리

- **Project A**: **가장 중요한 관련 논문**. CrypticFlow와 동일한 apo→holo task를 SE(3) frame으로 해결. Sesame의 아키텍처를 참조하여 CrypticFlow의 torsion angle 표현을 SE(3)로 전환하는 방향을 설계할 수 있음. 또한 Sesame 대비 CrypticFlow의 차별점을 논문에서 명시해야 함.

## 인용할 만한 문장

> (arXiv 원문 확인 필요)

## 추가로 읽을 참고문헌

- [ ] [[Paper_Bose23_FoldFlow]] — 동일한 SE(3) flow matching 방법론
- [ ] [[Paper_Yim23_FrameDiff]] — SE(3) diffusion
