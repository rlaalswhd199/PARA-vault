# Papers Index

읽은 논문들의 마스터 인덱스. Claude `paper-reading-note` 스킬로 자동 갱신 가능.

## 사용 방법

1. arXiv 링크 또는 PDF를 Claude에게 전달하며 "논문 정리해줘" 요청
2. Claude가 `Papers/` 안에 구조화된 노트(`Paper_저자YY_제목.md`) 생성
3. 본 인덱스에 한 줄 추가

## 상태 표

- ✅ Read & noted
- 🟡 Skimmed
- 🔴 Queue (읽을 예정)

---

## By Project

### Project A 관련 — Lever Arm Effect & Protein Conformation Flow Matching

#### Torsion Angle 기반 (CrypticFlow 현재 방식)
- ✅ [[3_Resources/Papers/Paper_Wu24_FoldingDiff]] — Nature Commun. 2024, torsion angle diffusion, **lever arm effect 최초 명시**, Must-cite
- 🟡 [[3_Resources/Papers/Paper_Int2Cart22]] — JCTC 2022, internal→Cartesian 오차 누적 정량 분석, Should-cite

#### SE(3) Frame 기반 (향후 방향)
- ✅ [[3_Resources/Papers/Paper_Yim23_FrameDiff]] — ICML 2023, SE(3) diffusion, lever arm effect 구조적 차단, Must-cite
- ✅ [[3_Resources/Papers/Paper_Bose23_FoldFlow]] — ICLR 2024 Spotlight, SE(3) stochastic flow matching, Must-cite
- ✅ [[3_Resources/Papers/Paper_Sesame25_ApoHolo]] — GEM@ICLR 2025, **apo→holo CrypticFlow와 동일 task**, SE(3) flow matching, Must-cite
- ✅ [[1_Projects/Crypticflow/Reading_Notes/Paper_Yim23_FrameFlow]] — ICLR 2024 Workshop, SE(3) flow matching (FrameDiff→FrameFlow), 5× 적은 step, Must-cite
- ✅ [[1_Projects/Crypticflow/Reading_Notes/Paper_Zhou25_DynamicFlow]] — ICLR 2025, **apo→holo full-atom SE(3) flow** (포켓 중심), Must-cite
- ✅ [[3_Resources/Papers/Paper_Jin24_P2DFlow]] — JCTC 2025, 단백질 앙상블 SE(3) flow, approximate energy prior, Should-cite
- ✅ [[1_Projects/Crypticflow/Reading_Notes/Paper_Huguet24_FoldFlow2]] — NeurIPS 2024, 서열 조건부 SE(3) flow (FoldFlow-2), Should-cite
- ✅ [[3_Resources/Papers/Paper_Wagner24_GAFL]] — NeurIPS 2024, Geometric Algebra + Clifford Frame Attention, Should-cite
- ✅ [[1_Projects/Crypticflow/Reading_Notes/Paper_Yue25_ReQFlow]] — ICML 2025, quaternion SLERP + rectified flow, 37×↑속도, Must-cite

#### Loss 설계
- ✅ [[3_Resources/Papers/Paper_Jumper21_AlphaFold2]] — Nature 2021, **FAPE loss 원조**, Must-cite
- ✅ [[3_Resources/Papers/Paper_Bose24_AlphaFlow]] — arXiv 2402.04845, AlphaFold + flow matching, squared FAPE loss, Should-cite

#### Exposure Bias / Flow Matching 이론
- ✅ [[3_Resources/Papers/Paper_ReflexFlow25_ADR]] — arXiv 2512.04904, ADR(Anti-Drift Rectification), CrypticFlow에 직접 구현·실험됨, Should-cite

#### DiT 후속 아키텍처 (문제 3: DiT 확장성)
- ✅ [[1_Projects/Crypticflow/Reading_Notes/Paper_Mo26_SaDiT]] — preprint 2026, DiT+IPA Token Cache, 230× 가속, 99.5% designability, Must-cite
- ✅ [[1_Projects/Crypticflow/Reading_Notes/Paper_NVIDIA25_Proteina]] — ICLR 2025 oral, 비등변 400M flow transformer, 800 residue, Should-cite
- ✅ [[3_Resources/Papers/Paper_Ma24_SiT]] — ECCV 2024, DiT 기반 interpolant framework (flow+diffusion 통합), Skim
- ✅ [[3_Resources/Papers/Paper_Zhao25_DyDiT]] — TPAMI 2026, 동적 width/token 선택, DiT 51% FLOPs 절감, Skim

#### Chain Break / 비연속 서열 처리 (문제 2)
- ✅ [[1_Projects/Crypticflow/Reading_Notes/Paper_Zhang23_FrameDiPT]] — bioRxiv 2023, SE(3) diffusion + inpainting, 이진 마스크로 chain gap 처리, Must-cite
- ✅ [[3_Resources/Papers/Paper_Ingraham23_Chroma]] — Nature 2023, 비연속 crop 조건부 학습, Should-cite
- ✅ [[3_Resources/Papers/Paper_Watson23_RFdiffusion]] — Nature 2023, `/0` chain break token + 200aa 인덱스 점프, Should-cite

#### Cryptic Pocket Detection (Baseline / Pre-filter)
- ✅ [[1_Projects/Crypticflow/Reading_Notes/Paper_Meller23_PocketMiner]] — Nat. Commun. 2023, GVP-GNN cryptic pocket location 예측 (단일 apo 구조 → residue 확률), ROC-AUC 0.87, >1000× faster than CryptoSite, **CrypticFlow의 conditioning / validation baseline**, Must-cite

### Project B 관련

### Project C 관련

### Project D 관련

---

## By Topic

### Protein Structure Generation (Backbone)
- ✅ [[3_Resources/Papers/Paper_Wu24_FoldingDiff]] — Torsion angle diffusion, Nature Commun. 2024
- ✅ [[3_Resources/Papers/Paper_Yim23_FrameDiff]] — SE(3) diffusion, ICML 2023
- ✅ [[3_Resources/Papers/Paper_Bose23_FoldFlow]] — SE(3) flow matching, ICLR 2024
- ✅ [[1_Projects/Crypticflow/Reading_Notes/Paper_Yim23_FrameFlow]] — SE(3) flow matching (FrameFlow), ICLR 2024 Workshop
- ✅ [[1_Projects/Crypticflow/Reading_Notes/Paper_Huguet24_FoldFlow2]] — 서열 조건부 SE(3) flow, NeurIPS 2024
- ✅ [[3_Resources/Papers/Paper_Wagner24_GAFL]] — Geometric Algebra Flow, NeurIPS 2024
- ✅ [[1_Projects/Crypticflow/Reading_Notes/Paper_Yue25_ReQFlow]] — Quaternion rectified flow, ICML 2025
- ✅ [[1_Projects/Crypticflow/Reading_Notes/Paper_NVIDIA25_Proteina]] — 비등변 대형 flow transformer, ICLR 2025

### Protein Conformation Change (Apo → Holo)
- ✅ [[3_Resources/Papers/Paper_Sesame25_ApoHolo]] — Flow matching for apo→holo, GEM@ICLR 2025
- ✅ [[3_Resources/Papers/Paper_Bose24_AlphaFlow]] — Protein ensemble flow matching
- ✅ [[1_Projects/Crypticflow/Reading_Notes/Paper_Zhou25_DynamicFlow]] — Full-atom apo→holo SE(3) flow (포켓), ICLR 2025
- ✅ [[3_Resources/Papers/Paper_Jin24_P2DFlow]] — 단백질 앙상블 SE(3) flow, JCTC 2025

### Chain Break / 비연속 서열 처리
- ✅ [[1_Projects/Crypticflow/Reading_Notes/Paper_Zhang23_FrameDiPT]] — SE(3) inpainting + 이진 마스크, bioRxiv 2023
- ✅ [[3_Resources/Papers/Paper_Ingraham23_Chroma]] — 비연속 crop 학습, Nature 2023
- ✅ [[3_Resources/Papers/Paper_Watson23_RFdiffusion]] — `/0` chain break token, Nature 2023

### DiT 아키텍처 (후속 / 효율화)
- ✅ [[3_Resources/Papers/Paper_Ma24_SiT]] — Interpolant transformer, ECCV 2024
- ✅ [[3_Resources/Papers/Paper_Zhao25_DyDiT]] — 동적 width/token, TPAMI 2026
- ✅ [[1_Projects/Crypticflow/Reading_Notes/Paper_Mo26_SaDiT]] — DiT+IPA Token Cache, preprint 2026

### FAPE Loss & 3D Coordinate Supervision
- ✅ [[3_Resources/Papers/Paper_Jumper21_AlphaFold2]] — FAPE loss 원조, Nature 2021
- ✅ [[3_Resources/Papers/Paper_Bose24_AlphaFlow]] — Squared FAPE

### NERF & Internal Coordinates
- ✅ [[3_Resources/Papers/Paper_Wu24_FoldingDiff]] — Lever arm effect 명시
- 🟡 [[3_Resources/Papers/Paper_Int2Cart22]] — NERF 오차 누적 정량화

### Flow Matching Theory
- ✅ [[3_Resources/Papers/Paper_Bose23_FoldFlow]] — Riemannian OT flow matching
- ✅ [[3_Resources/Papers/Paper_ReflexFlow25_ADR]] — Exposure bias 해결 (ADR + FC)
- ✅ [[3_Resources/Papers/Paper_Ma24_SiT]] — Interpolant framework (flow+diffusion 통합)
- ✅ [[1_Projects/Crypticflow/Reading_Notes/Paper_Yue25_ReQFlow]] — Rectified quaternion flow

### Cryptic Pocket Detection / Druggability
- ✅ [[1_Projects/Crypticflow/Reading_Notes/Paper_Meller23_PocketMiner]] — GVP-GNN 단일 구조 cryptic pocket 예측, Nat. Commun. 2023

---

## Reading Queue (🔴)

- [ ] OpenFold (PMC 2024) — FAPE clamping 개선 (sample 단위), 훈련 안정성
- [x] RFdiffusion (Nature 2023) — `/0` chain break token → 노트 완료 ([[3_Resources/Papers/Paper_Watson23_RFdiffusion]])
- [ ] MP-NeRF (PubMed 2022) — NERF 병렬화 및 수치 안정성 한계
- [ ] Riemannian Flow Matching (Chen & Lipman, 2024) — 토러스 geodesic velocity
- [ ] Torsion-Space Diffusion with Geometric Refinement (arXiv 2511.19184) — Rg correction + bond restoration
- [ ] Cimermancic et al. 2016 — CryptoSite 원조 (J. Mol. Biol.) ← PocketMiner의 비교 대상
- [ ] Zimmerman et al. 2021 — SARS-CoV-2 exascale MD (Nat. Chem.) ← PocketMiner training data 출처
- [ ] Cruz et al. 2022 — Ebola VP35 cryptic pocket (Nat. Commun.) ← 동일
- [ ] Jing et al. 2020 — Geometric Vector Perceptrons (arXiv 2009.01411) ← GVP-GNN 원조
