# Paper — FrameDiff: SE(3) diffusion model with application to protein backbone generation

## 메타

- **저자**: Jason Yim, Brian L. Trippe, Valentin De Bortoli, Emile Mathieu, Arnaud Doucet, Regina Barzilay, Tommi Jaakkola
- **Venue / Year**: ICML 2023
- **Link**: https://arxiv.org/abs/2302.02277
- **GitHub**: https://github.com/jasonkyuyim/se3_diffusion
- **Tier**: ⭐ Must-cite
- **원본 노트**: [[../../../../3_Resources/Papers/Paper_Yim23_FrameDiff]]

## TL;DR (3줄)

1. 각 residue를 SE(3) rigid frame으로 독립 표현하고 SE(3) 위에서 diffusion 수행.
2. Sequential chain reconstruction이 없으므로 **lever arm effect 구조적 차단**.
3. Pretrained structure prediction 없이 최대 500 residue까지 designable monomer 생성.

## 핵심 아키텍처

![[3_Resources/Papers/Paper_Yim23_FrameDiff_arch.png]]

<details>
<summary>Mermaid source</summary>

```mermaid
%%{init: {'theme':'base', 'flowchart': {'htmlLabels': false, 'curve': 'basis', 'nodeSpacing': 25, 'rankSpacing': 30, 'padding': 4, 'useMaxWidth': true}, 'themeVariables': {'fontSize': '12px'}}}%%
flowchart TB
    subgraph INPUT["입력"]
        SEQ["서열 (L residues)"]
        NOISE["Random SE(3) Frames\n(Rᵢ, tᵢ) × L"]
    end

    subgraph REPR["SE(3) Frame 표현"]
        FRAME["각 residue i →\n(Rᵢ ∈ SO(3), tᵢ ∈ ℝ³)\nN, Cα, C로 frame 정의"]
    end

    subgraph DIFFUSION["SE(3) Score Matching"]
        direction TB
        ROT["SO(3) Diffusion\nIGSO3 (Isotropic Gaussian)"]
        TRANS["ℝ³ Diffusion\nGaussian"]
        SCORE_R["Rotation Score\n∇_{Rᵢ} log p(Rₜ)"]
        SCORE_T["Translation Score\n∇_{tᵢ} log p(tₜ)"]
        ROT --> SCORE_R
        TRANS --> SCORE_T
    end

    subgraph MODEL["IPA Transformer"]
        IPA["Invariant Point\nAttention (IPA)\n(AlphaFold2 구조 모듈)"]
        PAIR["Pair Representation\n(L×L)"]
        SINGLE["Single Representation\n(L)"]
        IPA --> PAIR & SINGLE
    end

    subgraph LOSS["FAPE Loss"]
        LOCAL["Local Frame 기준\n상대 좌표 비교\ndist(i,j) = ‖Tᵢ⁻¹(xⱼ_pred) - Tᵢ⁻¹(xⱼ_true)‖"]
        CLAMP["d_clamp 적용\n(gradient 안정화)"]
        LOCAL --> CLAMP
    end

    SEQ --> MODEL
    NOISE --> DIFFUSION
    DIFFUSION --> MODEL
    MODEL --> SCORE_R & SCORE_T
    MODEL --> LOSS

    note1["⭐ Sequential NERF 없음\n→ Lever arm effect 차단"]
```

</details>

## 핵심 아이디어

- **표현**: `(Rᵢ, tᵢ) ∈ SE(3)` × L (각 residue 독립)
- **Diffusion**: SO(3) + ℝ³ 분리, IGSO3 noise schedule
- **Architecture**: IPA (Invariant Point Attention) Transformer — AlphaFold2 구조 모듈 차용
- **Loss**: FAPE (Frame Aligned Point Error)
- **핵심**: 체인 순서에 의존하지 않으므로 N-terminal 오차가 C-terminal로 전파되지 않음

## 우리 연구와의 연결 고리

- CrypticFlow의 장기 방향: torsion angle → SE(3) frame 전환 시 FrameDiff가 레퍼런스
- FAPE loss 수식 참조 (`losses.py`의 FAPE 구현이 이 논문 기반)
- CrypticFlow에서 FAPE + NERF backprop 조합이 폭발하는 이유: FrameDiff는 NERF 없이 바로 SE(3)에서 작동하기 때문

## 인용할 만한 문장

> "FrameDiff can generate designable monomers up to 500 amino acids without relying on a pretrained protein structure prediction network"

## 추가로 읽을 참고문헌

- [ ] [[1_Projects/Crypticflow/Reading_Notes/Paper_Bose23_FoldFlow]] — SE(3) flow matching 버전
- [ ] [[1_Projects/Crypticflow/Reading_Notes/Paper_Jumper21_AlphaFold2]] — IPA, FAPE loss 원조
