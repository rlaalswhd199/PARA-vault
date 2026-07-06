# ICML 2026 Bio / Drug / GenAI Poster Reading List — 관련도 높은 항목만

**목적**: virtual pass로 talk를 듣는 것과 별개로, 시간 날 때 비동기로 읽을 poster/paper 목록입니다.  
**선정 기준**: AI 신약개발, molecule/protein generation, diffusion/flow matching, transformer/LLM, agentic biology, single-cell/omics perturbation과의 관련도가 높은 순서입니다.  
**Abstract 표기 방식**: 원문 abstract를 길게 그대로 옮기지 않고, 공개 abstract/프로젝트 설명을 바탕으로 한국어로 핵심을 요약했습니다. 일부 workshop paper는 공개 accepted list와 OpenReview 링크를 기준으로 확인했으며, 원문 PDF가 열리지 않는 경우 “제목/공개 목록 기준”이라고 명시했습니다.

---

## 온라인으로 확인하는 순서

1. **ICML virtual poster page**: poster PDF, slides, video, chat/discussion 링크가 붙어 있을 수 있습니다. 단, 모든 poster가 PDF/slide를 공개한 것은 아닙니다.
2. **OpenReview**: accepted paper 원고와 supplementary를 확인하기 가장 좋습니다.
3. **arXiv / project page / GitHub**: code, demo, figures, extra result를 확인하세요.

---

## P0-01. Towards Sub-Second Molecular Docking as a Structural Primitive: A Quantized Consistency Diffusion Framework
**표기 참고**: ICML virtual title: Towards Sub-second Biological Foundation Model Infrastructure: A Quantized Consistency Diffusion Framework for Molecular Docking

**Abstract 요약**  
Agent가 MCP 같은 프로토콜로 docking 도구를 호출하는 “interactive scientific workflow”를 전제로, diffusion 기반 docking을 sub-second 수준의 구조적 primitive로 만들려는 논문입니다. 핵심은 consistency diffusion과 quantization을 결합해 docking의 latency를 줄이고, 생물학 foundation model/agent workflow에서 즉시 호출 가능한 모듈로 만드는 것입니다.

**자세한 링크**
- ICML oral: https://icml.cc/virtual/2026/oral/71070
- ICML poster: https://icml.cc/virtual/2026/poster/64402
- OpenReview: https://openreview.net/forum?id=NyPHOtsJfE

**선정 이유**  
신약개발에서 docking은 가장 기본적인 downstream primitive 중 하나입니다. 여기에 diffusion, quantization, agentic workflow가 한 번에 들어가므로 네 관심사와 가장 직접적으로 겹칩니다.

**키워드**: drug discovery, docking, diffusion, quantization, agent tool

---

## P0-02. MuCO: Generative Peptide Cyclization Empowered by Multi-stage Conformation Optimization
**Abstract 요약**  
Linear peptide를 조건으로 cyclic peptide conformations의 분포를 생성하는 모델입니다. peptide cyclization을 topology-aware backbone design, generative side-chain packing, physics-aware all-atom optimization의 세 단계로 나누어 coarse-to-fine 방식으로 다양한 저에너지 cyclic peptide 구조를 탐색합니다.

**자세한 링크**
- ICML poster: https://icml.cc/virtual/2026/poster/66123
- OpenReview: https://openreview.net/forum?id=6l8bvRoJZN
- arXiv: https://arxiv.org/abs/2602.11189
- Slides PDF: https://icml.cc/media/icml-2026/Slides/66123.pdf
- GitHub: https://github.com/mianqiu00/MuCO
- Demo: https://muco.tylab.chat/

**선정 이유**  
cyclic peptide는 drug-like peptide design에서 중요하고, 이 논문은 flow matching/generative sampling과 physics-aware refinement를 결합합니다. 생성모델을 실제 therapeutic design에 어떻게 붙이는지 보기 좋습니다.

**키워드**: peptide design, generative model, flow matching, physics refinement

---

## P0-03. DeCoDe: Decoupling Binding Position and Molecular Conformation in 3D Ligand Diffusion for Structure-Based Drug Design
**Abstract 요약**  
Structure-based drug design에서 3D ligand diffusion이 binding position과 molecular conformation을 동시에 다루며 생기는 어려움을 분리하려는 논문입니다. ligand의 binding 위치와 conformation 생성을 명시적으로 disentangle하여 pose/conformation 품질을 개선하는 방향입니다.

**자세한 링크**
- ICML poster: https://icml.cc/virtual/2026/poster/61882
- OpenReview: https://openreview.net/forum?id=lywUbYpYfG
- PDF attachment: https://openreview.net/attachment?id=lywUbYpYfG&name=pdf

**선정 이유**  
3D ligand diffusion은 신약개발 생성모델의 핵심 축입니다. docking pose와 conformer generation의 결합/분리를 어떻게 모델링하는지 보면 SBDD generative model의 병목을 이해하기 좋습니다.

**키워드**: SBDD, 3D ligand diffusion, binding pose, conformation

---

## P0-04. Reading the Cell, Designing the Cure: Perturbation-Conditioned Molecular Diffusion for Function-Oriented Drug Design
**Abstract 요약**  
Transcriptome-based drug design을 “원하는 세포 상태 전이를 만들 분자를 생성하는 inverse problem”으로 공식화합니다. target protein structure가 없거나 phenotype/pathway 기반 drug action을 보고 싶을 때, transcriptomic perturbation signal을 조건으로 molecule diffusion을 수행하는 CURE framework입니다.

**자세한 링크**
- ICML poster: https://icml.cc/virtual/2026/poster/66023
- OpenReview: https://openreview.net/forum?id=7pinsbGVLt
- arXiv: https://arxiv.org/abs/2605.15243
- PDF: https://arxiv.org/pdf/2605.15243

**선정 이유**  
전통적인 target-centric drug design을 넘어, phenotype/transcriptome-conditioned generation으로 가는 흐름입니다. single-cell/omics와 molecule generation을 연결하고 싶다면 매우 중요합니다.

**키워드**: drug design, transcriptomics, diffusion, perturbation, phenotype-driven discovery

---

## P0-05. Contrastive Geometric Learning Unlocks Unified Structure- and Ligand-Based Drug Design
**Abstract 요약**  
ConGLUDe는 structure-based와 ligand-based drug design을 하나의 contrastive geometric model로 통합합니다. whole-protein representation과 implicit binding-site embedding을 만드는 protein encoder, 빠른 ligand encoder를 결합해 pre-defined pocket 없이 virtual screening, target fishing, ligand-conditioned pocket prediction을 지원합니다.

**자세한 링크**
- ICML poster: https://icml.cc/virtual/2026/poster/63420
- OpenReview: https://openreview.net/forum?id=XJaXdi5R21
- arXiv: https://arxiv.org/abs/2601.09693
- PDF: https://arxiv.org/pdf/2601.09693

**선정 이유**  
실제 drug discovery에서는 구조 데이터와 bioactivity 데이터가 따로 놀기 쉽습니다. 이 논문은 두 축을 하나의 모델로 통합하려는 시도라 foundation model for drug discovery 관점에서 좋습니다.

**키워드**: drug discovery, contrastive learning, protein-ligand, virtual screening, target fishing

---

## P0-06. VecMol: Vector-Field Representations for 3D Molecule Generation
**Abstract 요약**  
3D molecule을 graph와 coordinate를 함께 생성하는 기존 방식 대신, Euclidean space 위의 continuous vector field로 표현합니다. vector field는 주변 atom을 가리키며 molecular structure를 암묵적으로 담고, latent diffusion으로 생성한 뒤 decoding합니다. QM9와 GEOM-Drugs benchmark에서 가능성을 보입니다.

**자세한 링크**
- ICML poster: https://icml.cc/virtual/2026/poster/66367
- OpenReview: https://openreview.net/forum?id=4K87H0eSqu
- arXiv: https://arxiv.org/abs/2603.12734
- PDF attachment: https://openreview.net/attachment?id=4K87H0eSqu&name=pdf

**선정 이유**  
3D molecule generation의 representation 자체를 바꾸는 논문입니다. graph+coordinate co-generation의 어려움을 vector field로 우회한다는 점이 새로운 generative modeling 아이디어로 볼 만합니다.

**키워드**: 3D molecule generation, latent diffusion, vector field, neural field

---

## P0-07. BioDynaSpec: Harmonic-Guided Spatio-Spectral Autoregressive Diffusion for Protein Dynamics Generation
**Abstract 요약**  
Long-horizon all-atom protein MD trajectory generation에서 autoregressive error accumulation과 temporal-resolution 제약을 다룹니다. frequency decomposition, autoregressive-diffusion generation, inter-residue frequency coupling structural prior를 결합해 protein dynamics trajectory를 더 안정적으로 생성하려는 framework입니다.

**자세한 링크**
- ICML poster: https://icml.cc/virtual/2026/poster/63769
- OpenReview: https://openreview.net/forum?id=TwMRZPkn4e
- Project page: https://linmj-judy.github.io/publication/2026-icml-biodynaspec
- GitHub: https://github.com/Linmj-Judy/BioDynaSpec

**선정 이유**  
네가 Amber/MD도 공부하려는 흐름과 직접 연결됩니다. AI가 protein dynamics를 생성하거나 surrogate로 대체하는 방향을 이해하는 데 핵심 poster입니다.

**키워드**: protein dynamics, molecular dynamics, diffusion, spatio-spectral model

---

## P0-08. Protein Autoregressive Modeling via Multiscale Structure Generation
**Abstract 요약**  
PAR는 protein backbone generation을 coarse-to-fine next-scale prediction으로 다루는 multi-scale autoregressive framework입니다. multi-scale downsampling, autoregressive transformer, flow-based decoder를 결합해 Cα atom을 직접 모델링하고, noisy context learning과 scheduled sampling으로 exposure bias를 줄입니다.

**자세한 링크**
- ICML oral: https://icml.cc/virtual/2026/oral/71037
- ICML poster: https://icml.cc/virtual/2026/poster/66808
- OpenReview: https://openreview.net/forum?id=08tW615mgI
- arXiv: https://arxiv.org/abs/2602.04883
- Project page: https://par-protein.github.io/

**선정 이유**  
protein generation을 diffusion만이 아니라 autoregressive+flow 구조로 보는 논문입니다. transformer 기반 생성모델과 단백질 구조 설계의 연결을 공부하기 좋습니다.

**키워드**: protein backbone generation, autoregressive model, transformer, flow decoder

---

## P0-09. FIDIA: Function-Informed Sequence Design via Inference-Aligned Policy Optimization
**Abstract 요약**  
Function-conditioned biological sequence design을 policy optimization 관점에서 다루는 논문입니다. 공개 코드 기준으로 motif scaffolding, ligand-related design, reward alignment, diversity/structure constraints 등 function-informed design 요소를 다루는 것으로 보입니다.

**자세한 링크**
- ICML poster: https://icml.cc/virtual/2026/poster/61459
- OpenReview: https://openreview.net/forum?id=pvbJsa0ia0
- GitHub: https://github.com/deng-ai-lab/FIDIA-code

**선정 이유**  
단순히 “그럴듯한 sequence”가 아니라 function objective에 맞는 sequence를 어떻게 설계할지 보는 논문입니다. protein/peptide engineering 관심이면 우선순위가 높습니다.

**키워드**: sequence design, protein design, policy optimization, function-informed generation

---

## P0-10. From Holo Pockets to Electron Density: GPT-style Drug Design with Density
**Abstract 요약**  
Rigid empty pocket만 조건으로 쓰는 기존 structure-based generation 대신, ligand/solvent/유연성 정보를 포함할 수 있는 low-resolution electron density를 조건으로 molecule을 생성합니다. decoder-only autoregressive EDMolGPT가 electron density point cloud를 조건으로 de novo molecule을 생성하는 방향입니다.

**자세한 링크**
- ICML poster: https://icml.cc/virtual/2026/poster/61593
- OpenReview: https://openreview.net/forum?id=oaMuJPfDUS
- arXiv: https://arxiv.org/abs/2605.08767
- Project page: https://jiahaochen1.github.io/EDMolGPT_Page/
- GitHub: https://github.com/JiahaoChen1/EDMolGPT

**선정 이유**  
GPT-style autoregressive generation을 3D structural biology signal과 결합합니다. transformer/generative model 관점과 신약개발 응용이 잘 만나는 poster입니다.

**키워드**: drug design, electron density, autoregressive model, transformer, SBDD

---

## P0-11. PerturbDiff: Functional Diffusion for Single-Cell Perturbation Modeling
**Abstract 요약**  
Unpaired control/perturbed single-cell population에서 perturbation response를 예측하는 generative framework입니다. Hilbert space의 distributional representation 위에서 conditional velocity field를 학습해 hidden cellular variability와 unseen perturbation generalization을 다룹니다.

**자세한 링크**
- ICML poster: https://icml.cc/virtual/2026/poster/60643
- OpenReview: https://openreview.net/forum?id=yBAqonxCdp
- arXiv: https://arxiv.org/abs/2602.19685
- Project page: https://katarinayuan.github.io/PerturbDiff-ProjectPage/
- GitHub: https://github.com/DeepGraphLearning/PerturbDiff

**선정 이유**  
drug response와 perturbation biology를 generative diffusion 관점에서 연결합니다. transcriptomics-conditioned molecule generation을 이해하기 전후로 같이 보면 좋습니다.

**키워드**: single-cell, perturbation, diffusion, virtual cell, drug response

---

## P0-12. PDAgent: An LLM-Driven Autonomous Agent Framework Towards In Silico Protein Design via Directed Mutation
**Abstract 요약**  
Natural-language-guided protein design을 위해 LLM-driven autonomous agent가 directed mutation을 반복 수행하는 framework입니다. 공개 slide/GitHub 기준으로 ReAct-style loop를 통해 sequence optimization, structure prediction, property analysis를 닫힌 루프로 수행합니다.

**자세한 링크**
- ICML poster: https://icml.cc/virtual/2026/poster/63768
- OpenReview: https://openreview.net/forum?id=TwTvDVj6cH
- Slides PDF: https://icml.cc/media/icml-2026/Slides/63768.pdf
- GitHub: https://github.com/Gift-OYS/PDAgent

**선정 이유**  
agent가 실제 protein design workflow에 어떻게 들어가는지 볼 수 있습니다. GenBio workshop의 “agentic biology”를 구체적인 시스템으로 이해하는 데 좋습니다.

**키워드**: agent, protein design, LLM, directed mutation, closed-loop optimization

---

## P0-13. DrugAgent: Reliable Multi-Agent Aggregation under Conflicting Biomedical Evidence
**Abstract 요약**  
Drug–target interaction prediction에서 ML model, knowledge graph, literature/RAG처럼 서로 다른 evidence source를 specialized agent들이 수집하고, multi-agent reasoning으로 conflict를 조정해 더 설명 가능한 예측을 만드는 framework입니다.

**자세한 링크**
- FM4LS accepted list: https://icml2026fm4ls.github.io/pages/accepted-paper.html
- OpenReview: https://openreview.net/forum?id=nSDxbVaJpQ
- PDF: https://openreview.net/pdf?id=nSDxbVaJpQ

**선정 이유**  
신약개발 agent는 단순히 분자를 생성하는 것뿐 아니라, 상충하는 biomedical evidence를 통합해야 합니다. agentic drug discovery의 현실적인 문제를 다룹니다.

**키워드**: drug-target interaction, multi-agent, biomedical evidence, RAG, knowledge graph

---

## P0-14. PROTEUS: Predicting How Post-Translational Modifications Alter Drug Binding Affinity
**Abstract 요약**  
PTM이 protein drug target의 binding landscape를 바꾸지만, 특정 PTM이 drug binding affinity를 어떻게 바꾸는지 예측하는 computational method가 부족하다는 문제를 다룹니다. protein LM embedding, 3D contact graph, PTM-site annotation, drug molecular graph를 결합해 PTM으로 인한 ΔΔG 변화를 예측합니다.

**자세한 링크**
- FM4LS accepted list: https://icml2026fm4ls.github.io/pages/accepted-paper.html
- OpenReview: https://openreview.net/forum?id=wZVHPYvc65

**선정 이유**  
실제 drug target은 PTM 상태에 따라 ligandability/binding이 달라질 수 있습니다. protein biology와 drug binding prediction을 잇는 좋은 poster입니다.

**키워드**: drug binding affinity, PTM, protein LM, molecular graph, ΔΔG

---

## P0-15. Local-Atlas Control-Anchored Flow Matching for Unpaired Single-Cell Perturbation Prediction
**Abstract 요약**  
Destructive single-cell perturbation assay에서는 같은 cell의 before/after pair가 없기 때문에 perturbation prediction이 paired regression이 아니라 unpaired conditional distribution problem이 됩니다. Atlas-CFM은 control-derived anchor, transport-aware pseudo-pairing, tangent/normal vector-field regularization으로 flow matching을 안정화합니다.

**자세한 링크**
- FM4LS accepted list: https://icml2026fm4ls.github.io/pages/accepted-paper.html
- OpenReview: https://openreview.net/forum?id=4Kj8btmGbK

**선정 이유**  
flow matching이 단백질/분자뿐 아니라 single-cell perturbation에도 어떻게 쓰이는지 보여줍니다. drug perturbation response modeling과 직접 연결됩니다.

**키워드**: single-cell, perturbation, flow matching, unpaired distribution, virtual cell

---

## P0-16. WACA-DTA: Water-Aware Geometric Biases for Structure-Conditioned Drug-Target Affinity Prediction
**Abstract 요약**  
Structure-conditioned drug–target affinity prediction에서 distance/angular geometric bias와 hydration/water prior를 cross-attention에 주입하는 방식입니다. rule-based masks, latent water edges, predicted hydration-site tokens 같은 plug-in water priors를 활용합니다.

**자세한 링크**
- FM4LS accepted list: https://icml2026fm4ls.github.io/pages/accepted-paper.html
- OpenReview: https://openreview.net/forum?id=HbSthyi1GG
- GitHub: https://github.com/khan114514/WACA-DTA

**선정 이유**  
protein-ligand binding에서 물/수화는 자주 무시되지만 실제 affinity에 중요합니다. 구조 기반 DTA 모델이 물리적 prior를 어떻게 넣는지 보기 좋습니다.

**키워드**: DTA, hydration, structure-conditioned affinity, geometric bias, cross-attention

---

## P1-17. MolEmb: Multimodal Large Language Models Can Be Strong Molecular Embedding Models
**Abstract 요약**  
Multimodal LLM을 molecule embedding model로 활용할 수 있는지 보는 workshop paper입니다. molecule representation과 text/biomedical context를 정렬해 retrieval, property prediction, molecular understanding에 쓰려는 방향으로 해석할 수 있습니다.

**자세한 링크**
- FM4LS accepted list: https://icml2026fm4ls.github.io/pages/accepted-paper.html
- OpenReview: https://openreview.net/forum?id=dD95A7ATXn

**선정 이유**  
분자 자체를 “LLM이 이해하는 embedding space”에 올리는 연구 흐름입니다. generative drug design과 agentic evidence retrieval 사이의 표현학습 기반을 보기 좋습니다.

**키워드**: molecular embedding, multimodal LLM, representation learning, drug discovery

---

## P1-18. Transcriptomics-Conditioned Virtual Tissue Synthesis via Diffusion Transformers
**Abstract 요약**  
Spatial transcriptomics는 H&E morphology와 spatially resolved gene expression을 연결합니다. STMDiT는 morphology embedding과 transcriptomic profile을 함께 조건으로 H&E histopathology patch를 합성하는 diffusion transformer입니다.

**자세한 링크**
- FM4LS accepted list: https://icml2026fm4ls.github.io/pages/accepted-paper.html
- bioRxiv: https://www.biorxiv.org/content/10.64898/2026.05.26.727902v1
- PDF: https://www.biorxiv.org/content/10.64898/2026.05.26.727902v1.full.pdf

**선정 이유**  
생성모델이 molecule/protein을 넘어 tissue/omics로 확장되는 예입니다. diffusion transformer와 transcriptomics conditioning을 같이 볼 수 있습니다.

**키워드**: diffusion transformer, transcriptomics, virtual tissue, histopathology, multimodal biology

---

## P1-19. Geometric Pocket-Centric Protein Encoding for Polypharmacology-Guided Multi-Target Drug Design
**Abstract 요약**  
Polypharmacology와 multi-target drug design을 위해 protein structure/sequence와 pharmacological constraints를 통합하는 pocket-centric encoding framework입니다. 여러 target에 동시에 작용하는 inhibitor/agonist 설계를 지향합니다.

**자세한 링크**
- ICML poster: https://icml.cc/virtual/2026/poster/65413
- OpenReview: https://openreview.net/forum?id=DuaA7vJGF6
- GitHub: https://github.com/HaoranLiu1998/MM-MT

**선정 이유**  
현실의 약물은 single target보다 multi-target effect가 중요할 때가 많습니다. 구조 기반 design을 polypharmacology 관점으로 확장하는 poster라 볼 만합니다.

**키워드**: polypharmacology, multi-target drug design, protein encoding, pocket-centric model

---

## P1-20. Search, Edit, and Fold: LLM-Guided MSA Optimization for Protein Conformation Prediction
**Abstract 요약**  
LLM을 이용해 MSA를 검색·수정하고, 그 결과를 protein conformation prediction에 활용하는 framework입니다. protein structure prediction에서 입력 MSA 품질과 모델 reasoning/optimization을 연결합니다.

**자세한 링크**
- FM4LS accepted list: https://icml2026fm4ls.github.io/pages/accepted-paper.html
- OpenReview: https://openreview.net/forum?id=L8TR5pzlF2

**선정 이유**  
protein foundation model을 쓸 때 MSA와 sequence context를 어떻게 개선할지가 중요합니다. LLM-guided protein workflow의 좋은 예입니다.

**키워드**: protein conformation, LLM, MSA optimization, folding

---

## P1-21. Steering Large Language Models through the DMTA Cycle: Structure-Based Drug Design via Knowledge-Driven Bi-Level Thompson Sampling
**Abstract 요약**  
Design–Make–Test–Analyze cycle에서 LLM을 steering하고, structure-based drug design을 knowledge-driven bi-level Thompson sampling으로 수행하려는 논문입니다. 생성/선택/평가 loop를 active learning·Bayesian optimization 관점으로 연결합니다.

**자세한 링크**
- ICML poster: https://icml.cc/virtual/2026/poster/60577
- OpenReview: https://openreview.net/forum?id=yqF2ubqiCn

**선정 이유**  
실제 drug discovery는 한 번 생성하고 끝나는 것이 아니라 DMTA loop입니다. LLM과 sequential decision making을 drug design loop에 넣는 관점이 중요합니다.

**키워드**: LLM, DMTA cycle, structure-based drug design, Thompson sampling, active learning

---

## P1-22. Causal-IQD-DTA: Counterfactual Interaction-Quality Disentanglement for Robust Drug–Target Affinity Prediction
**Abstract 요약**  
Drug–target affinity prediction에서 interaction quality를 counterfactual/disentanglement 관점으로 분리해 robust DTA를 만들려는 workshop paper입니다. 제목과 accepted-list 기준으로 causal/disentangled representation을 DTA robustness에 연결하는 방향입니다.

**자세한 링크**
- FM4LS accepted list: https://icml2026fm4ls.github.io/pages/accepted-paper.html
- OpenReview: https://openreview.net/forum?id=2EhO9Exmhi

**선정 이유**  
DTA는 dataset shortcut과 spurious correlation에 취약합니다. causal/counterfactual 관점으로 DTA를 보려는 시도라 후속 공부 가치가 있습니다.

**키워드**: DTA, causal representation, counterfactual, robustness

---

## 우선 읽기 순서 추천

시간이 적으면 아래 8개만 먼저 보세요.

1. **Towards Sub-Second Molecular Docking as a Structural Primitive**
2. **MuCO**
3. **DeCoDe**
4. **Reading the Cell, Designing the Cure / CURE**
5. **ConGLUDe**
6. **VecMol**
7. **BioDynaSpec**
8. **Protein Autoregressive Modeling via Multiscale Structure Generation**

그 다음 agent와 biology workflow 쪽으로 **PDAgent**, **DrugAgent**, **PROTEUS**, **Atlas-CFM**, **WACA-DTA**를 이어서 보면 좋습니다.

---

## 참고 출처

- ICML 2026 virtual schedule mirror: https://raw.githubusercontent.com/psmiz/icml2026-schedule/main/data.js
- ICML 2026 author instructions / OpenReview 공개 안내: https://icml.cc/Conferences/2026/AuthorInstructions
- ICML 2026 poster material availability snapshot: https://github.com/KimYeongHyeon/ICML_2026_Browser/blob/main/icml_2026_materials/posters/README.md
- FM4LS accepted papers: https://icml2026fm4ls.github.io/pages/accepted-paper.html
- GenBio workshop: https://genbio-workshop.github.io/2026/
