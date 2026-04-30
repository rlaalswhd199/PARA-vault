# Paper — AlphaFold2: Highly accurate protein structure prediction with AlphaFold

## 메타

- **저자**: John Jumper, Richard Evans, Alexander Pritzel, et al. (DeepMind)
- **Venue / Year**: Nature, 2021
- **Link**: https://www.nature.com/articles/s41586-021-03819-2
- **Tier**: ⭐ Must-cite
- **원본 노트**: [[../../../../3_Resources/Papers/Paper_Jumper21_AlphaFold2]]

## TL;DR (3줄)

1. Evoformer + Structure Module 구조로 MSA와 templates를 활용해 원자 수준 단백질 구조 예측.
2. **FAPE loss** 제안: 각 residue local frame 기준 좌표 오차 → lever arm effect 없이 안정적 3D 학습.
3. 각 residue frame을 독립적으로 예측 (peptide bond geometry 의도적으로 무시) → loop closure 불필요.

## 핵심 아키텍처

```mermaid
%%{init: {'theme':'dark', 'flowchart': {'htmlLabels': true, 'curve': 'basis', 'nodeSpacing': 25, 'rankSpacing': 30, 'padding': 4, 'useMaxWidth': true}, 'themeVariables': {'fontSize': '12px', 'primaryColor': '#2d4a6e', 'primaryTextColor': '#e8eaf0', 'primaryBorderColor': '#5a8abf', 'lineColor': '#7ab3e0', 'secondaryColor': '#1e3a5a', 'tertiaryColor': '#162840', 'clusterBkg': '#1a2f45', 'clusterBorder': '#4a7aaa', 'titleColor': '#c8d8f0', 'edgeLabelBackground': '#1a2f45', 'nodeTextColor': '#e8eaf0'}}}%%
flowchart TB
    subgraph INPUT3["입력"]
        MSA["MSA<br/>(Multiple Sequence Alignment)"]
        TMPL["Templates<br/>(알려진 구조)"]
        SEQ3["Target 서열"]
    end

    subgraph EVOFORMER["Evoformer (×48 blocks)"]
        direction TB
        MSA_TRACK["MSA Representation<br/>(N_seq × L × c_m)"]
        PAIR_TRACK["Pair Representation<br/>(L × L × c_z)"]
        ROW_ATT["Row-wise Gated<br/>MSA Attention"]
        COL_ATT["Column-wise Gated<br/>MSA Attention"]
        TRI_UPD["Triangular<br/>Multiplicative Update"]
        MSA_TRACK <-->|"교차 업데이트"| PAIR_TRACK
        ROW_ATT & COL_ATT --> MSA_TRACK
        TRI_UPD --> PAIR_TRACK
    end

    subgraph STRUCT_MOD["Structure Module (×8 blocks)"]
        direction TB
        FRAMES["Residue Frames<br/>(Rᵢ, tᵢ) × L<br/>독립적으로 예측"]
        IPA4["IPA<br/>(Invariant Point Attention)<br/>3D 구조 인식 attention"]
        BB_UPD["Backbone Update<br/>(quaternion rotation)"]
        SC["Side Chain<br/>Torsion Angles"]
        FRAMES --> IPA4 --> BB_UPD --> FRAMES
        BB_UPD --> SC
    end

    subgraph FAPE_LOSS["FAPE Loss (핵심)"]
        direction LR
        FRAME_DEF["Local Frame Tᵢ<br/>= (Rᵢ, Cαᵢ)<br/>(N, Cα, C로 Gram-Schmidt)"]
        LOCAL_COORD["Local 좌표 변환<br/>Tᵢ⁻¹(xⱼ)"]
        DIST["dist(i,j) = ‖Tᵢ_pred⁻¹(xⱼ_pred)<br/>         - Tᵢ_true⁻¹(xⱼ_true)‖"]
        FAPE_FINAL["L_FAPE = mean_ij[<br/>min(dist(i,j), d_clamp)]"]
        FRAME_DEF --> LOCAL_COORD --> DIST --> FAPE_FINAL
    end

    MSA & TMPL & SEQ3 --> EVOFORMER
    EVOFORMER --> STRUCT_MOD
    STRUCT_MOD --> FAPE_LOSS
```


## 핵심 아이디어

- **FAPE**: 각 residue i의 local frame 기준으로 다른 residue j의 좌표 오차 측정 → global RMSD 대비 안정적
- **Independent frames**: Peptide bond constraint 의도적으로 위반 → 어떤 위치도 독립적으로 refinement 가능
- **d_clamp**: 이상치(outlier) gradient 제한 → 훈련 안정성 (OpenFold에서 sample 단위 clamping으로 개선)

## 우리 연구와의 연결 고리

- CrypticFlow의 FAPE 구현(`losses.py:291-333`)이 AlphaFold2 Eq. 4 참조
- CrypticFlow에서 FAPE + NERF backprop 조합이 weight=50에서 발산 → SE(3) 표현 없이는 FAPE gradient가 안정적이지 않음을 실험으로 확인
- **Must-cite**: FAPE loss 수식 인용

## 인용할 만한 문장

> "peptide bond geometry is completely unconstrained — breaking this constraint enables local refinement of all parts of the chain without solving complex loop closure problems"

## 추가로 읽을 참고문헌

- [ ] OpenFold — FAPE sample-level clamping 개선
- [ ] [[1_Projects/Crypticflow/Reading_Notes/Paper_Yim23_FrameDiff]] — FAPE를 생성 모델에 적용
