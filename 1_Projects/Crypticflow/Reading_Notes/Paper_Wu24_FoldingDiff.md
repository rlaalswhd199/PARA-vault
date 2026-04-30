# Paper — FoldingDiff: Protein structure generation via folding diffusion

## 메타

- **저자**: Kevin E. Wu, Kevin K. Yang, Rianne van den Berg, Sarah Alamdari, James Y. Zou, Alex X. Lu, Ava P. Bhatt
- **Venue / Year**: Nature Communications, 2024
- **Link**: https://www.nature.com/articles/s41467-024-45051-2
- **Tier**: ⭐ Must-cite
- **원본 노트**: [[../../../../3_Resources/Papers/Paper_Wu24_FoldingDiff]]

## TL;DR (3줄)

1. Protein backbone을 6개 backbone angle per residue로 표현하고 DDPM으로 denoising하여 구조 생성.
2. Torsion angle 공간에서의 diffusion이 equivariant network 없이 shift/rotation invariance 달성.
3. **Lever arm effect 명시**: 단일 각도 오차가 체인 끝으로 갈수록 기하급수적으로 증폭. L≤70에서만 안정.

## 핵심 아키텍처

```mermaid
%%{init: {'theme':'dark', 'flowchart': {'htmlLabels': true, 'curve': 'basis', 'nodeSpacing': 25, 'rankSpacing': 30, 'padding': 4, 'useMaxWidth': true}, 'themeVariables': {'fontSize': '12px', 'primaryColor': '#2d4a6e', 'primaryTextColor': '#e8eaf0', 'primaryBorderColor': '#5a8abf', 'lineColor': '#7ab3e0', 'secondaryColor': '#1e3a5a', 'tertiaryColor': '#162840', 'clusterBkg': '#1a2f45', 'clusterBorder': '#4a7aaa', 'titleColor': '#c8d8f0', 'edgeLabelBackground': '#1a2f45', 'nodeTextColor': '#e8eaf0'}}}%%
flowchart TB
    subgraph INPUT["입력"]
        SEQ["아미노산 서열<br/>(L residues)"]
        NOISE["Random Angles<br/>(L, 6) — unfolded state"]
    end

    subgraph REPR["각도 표현 (L, 6)"]
        ANG["φ, ψ, ω<br/>(dihedral angles)<br/>τ, ∠CA:C:N, ∠C:N:CA<br/>(bond angles)"]
    end

    subgraph DIFFUSION["DDPM Denoising (T steps)"]
        T["Timestep t"]
        BERT["BERT-style<br/>Transformer<br/>(1D sequence model)"]
        PRED["예측 노이즈<br/>ε̂_θ(xₜ, t)"]
    end

    subgraph DECODE["NERF 재구성"]
        NERF["Sequential NERF<br/>N₀→Cα₀→C₀→N₁→..."]
        COORD["3D Backbone<br/>Coordinates"]
    end

    subgraph PROBLEM["⚠️ Lever Arm Effect"]
        ERR["N-terminal 각도 오차<br/>δθ ≈ 0.02 rad"]
        AMP["C-terminal RMSD<br/>247× 증폭 → ~5 Å"]
        ERR --> AMP
    end

    SEQ --> BERT
    NOISE --> DIFFUSION
    T --> BERT
    BERT --> PRED
    PRED -->|"x₀ 복원"| ANG
    ANG --> NERF
    NERF --> COORD
    NERF -.->|"순차 누적"| PROBLEM
```


## 핵심 아이디어

- **표현**: `[φ, ψ, ω, τ, ∠CA:C:N, ∠C:N:CA]` × L residues → (L, 6) 각도 시퀀스
- **Diffusion**: DDPM on wrapped normal distribution (각도 공간)
- **Loss**: Radian-aware smooth L1 (wrapping 처리) ← CrypticFlow가 그대로 채택
- **Architecture**: BERT-style Transformer (1D, equivariant network 불필요)

## 우리 연구와의 연결 고리

- CrypticFlow가 동일한 torsion angle 표현 + NERF 사용 → 동일한 lever arm effect 발생
- Job 399: angle loss=0.0004 수렴 → RMSD=17.82 Å (891× 증폭) — 이 논문이 예측한 현상과 일치
- Radian-aware smooth L1 loss 인용 필요

## 인용할 만한 문장

> "this framing allows for single-angle errors to significantly alter the overall generated structure — a sort of lever arm effect"

## 추가로 읽을 참고문헌

- [ ] [[1_Projects/Crypticflow/Reading_Notes/Paper_Yim23_FrameDiff]] — lever arm effect 없는 SE(3) 접근
- [ ] [[1_Projects/Crypticflow/Reading_Notes/Paper_Int2Cart22]] — NERF 오차 누적 정량 분석
