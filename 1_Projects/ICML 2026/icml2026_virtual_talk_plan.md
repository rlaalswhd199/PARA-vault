# ICML 2026 Virtual Pass 청취 계획

**관심축:** AI 신약개발, 생성모델, diffusion/flow matching, transformer/LLM, 단백질·분자·생물학, agentic AI.  
**시간대:** 서울 현지 시간, KST/UTC+9.  
**우선순위:** P0 = 실시간으로 꼭 듣기, P1 = 가능하면 실시간/없으면 녹화, P2 = 녹화로 보충.

## 전체 전략

- **월요일:** 생성모델 기본기: diffusion/flow-matching tutorial을 먼저 듣고, 오후에는 LLM reasoning/agent 쪽을 잡는다.
- **화요일:** 단백질·유전체 oral block과 molecular docking oral, Poster Session 1–2를 집중한다.
- **수요일:** diffusion oral block, `Lab-in-the-Loop for Drug R&D with AI`, Poster Session 3을 핵심으로 본다.
- **목요일:** 세포/전사체/단백질 dynamics poster와 agent/transformer oral, Poster Session 8을 본다.
- **금요일:** GenBio workshop을 하루 중심으로 둔다.
- **토요일:** `AI x Drug/Chemistry`, `AI x Sampling & Computational Chemistry`, FM4LS poster를 번갈아 본다.

공식 일정과 virtual page는 직전에도 바뀔 수 있으니, 아래 동선을 기본으로 두고 ICML 앱/virtual page에서 최종 방·녹화·Q&A 링크를 확인하세요.

## 월요일 7/6 — Tutorial / Expo day

| 시간 | 우선순위 | 세션 | 왜 들어야 하는지 | 듣기 전 체크 |
|---|---:|---|---|---|
| 09:00–11:30 | P0 | **Tutorial: Diffusion and Flow-Matching: From Memorization to Generalization & Beyond** — Hall D1 | 분자 생성, peptide/protein design, docking diffusion, cell perturbation diffusion 논문을 이해하는 데 필요한 핵심 배경입니다. | posterior/score/flow matching, conditional generation 개념 복습 |
| 09:00–11:30 | P2 | Tutorial: Unifying Attention and Diffusion with Kan Extension Transformers — Hall C | attention/transformer와 diffusion을 하나의 구조 관점에서 보는 세션. P0 tutorial과 겹치므로 녹화로 보충 추천. | transformer attention, diagrammatic backprop은 키워드만 확인 |
| 13:30–16:00 | P0 | **Tutorial: Adaptive Reasoning in LLMs: From Post-Training to Test-Time Learning** — Hall C | AI scientist, bio-agent, LLM 기반 drug discovery workflow를 이해하는 배경입니다. | test-time scaling, tool use, verifier, agentic planning |
| 13:30–16:00 | P2 | Tutorial: New Techniques for Sequence Prediction: Spectral Filtering and Preconditioning — Hall D2 | protein/DNA/RNA sequence modeling에 관심이 크면 녹화로 보충할 만합니다. | sequence model, state-space/spectral filtering |

## 화요일 7/7 — Main Conference Day 1

| 시간 | 우선순위 | 세션 / talk | 왜 들어야 하는지 | 실전 동선 |
|---|---:|---|---|---|
| 08:30–09:30 | P1 | **Invited Talk: Towards AI Agents In the Real World** — Hall C | 토·금 workshop의 agentic biology/AI scientist 흐름을 이해하는 데 좋습니다. | 실시간으로 듣고, poster question 아이디어 적기 |
| 10:00–11:00 | P0 | **Oral 1C: AI for Science: Proteins and Genomic Sequences** — Hall D2 | 단백질·유전체 foundation model, protein fitness, protein structure generation이 한 블록에 모입니다. | 아래 4개 oral을 연속 시청 |
| 10:00–10:15 | P0 | dnaHNet: A Scalable and Hierarchical Foundation Model for Genomic Sequence Learning | genomic sequence foundation model 배경. | genomics 모델링 관심이면 질문 준비 |
| 10:15–10:30 | P0 | FLIP2: Expanding Protein Fitness Landscape Benchmarks for Real-World ML Applications | protein fitness landscape benchmark는 protein design evaluation에 중요합니다. | benchmark split, real-world task 확인 |
| 10:30–10:45 | P0 | Protein Autoregressive Modeling via Multiscale Structure Generation | 단백질 구조 생성모델 핵심 후보입니다. | Poster Session 2에서도 확인 |
| 10:45–11:00 | P1 | Protein Fold Classification at Scale: Benchmarking and Pretraining | protein representation/pretraining 이해에 도움. | 관련 poster로 이어보기 |
| 11:00–12:15 | P0 | **Poster Session 1** | Oral 1C와 30분 겹치므로, 11시 이후 BioAgent/CoarseBind/protein design 포스터를 우선 확인. | poster file의 Session 1 P0/P1부터 클릭 |
| 13:30–14:30 | P0 | **Oral 2D: AI for Science: Differential Equations & Molecular Modeling** — Hall D1 | molecular modeling, synthesis planning, docking infrastructure가 포함됩니다. | 특히 14:15–14:30 docking talk 놓치지 않기 |
| 13:30–13:45 | P1 | From Feasible to Practical: Pareto-Optimal Synthesis Planning | 생성한 분자가 실제 합성 가능한지 연결하는 주제입니다. | retrosynthesis/synthesis planning 관점으로 듣기 |
| 14:15–14:30 | P0 | **Towards Sub-second Biological Foundation Model Infrastructure: A Quantized Consistency Diffusion Framework for Molecular Docking** | 신약개발 + diffusion + docking + agentic workflow latency가 직접 만납니다. | 다음 날 Poster Session 3에서 포스터 확인 |
| 14:30–15:45 | P0 | **Poster Session 2** | MuCO, Agent Rosetta, protein autoregressive, SynLaD, TSMGen 등 관련 포스터가 많습니다. | `MuCO`와 `Protein Design with Agent Rosetta` 우선 |
| 16:00–17:00 | P2 | Invited Talk: Causal Inference with Transformer Models — Hall C | perturbation biology, causal drug response modeling에 관심 있으면 도움됩니다. | 피곤하면 녹화로 보충 |

## 수요일 7/8 — Main Conference Day 2

| 시간 | 우선순위 | 세션 / talk | 왜 들어야 하는지 | 실전 동선 |
|---|---:|---|---|---|
| 08:30–09:30 | P2 | Invited Talk: How Far Can Quadratics Take Us? Lessons for LLM Pretraining — Hall C | biological foundation model을 직접 만들 생각이면 LLM pretraining 관점에서 유용합니다. | 녹화도 충분 |
| 10:00–11:00 | P1 | **Oral 3A: Diffusion Models** — Hall C | 생성모델 기본기 보강. molecule/protein diffusion 논문을 읽는 데 도움이 됩니다. | 11시 이후 Poster Session 3로 이동 |
| 10:00–10:15 | P1 | Any-Order GPT as Masked Diffusion Model | autoregressive와 masked diffusion 연결. biological sequence generation에 참고 가능. | architecture 관점으로 듣기 |
| 10:30–10:45 | P1 | High-accuracy and dimension-free sampling with diffusions | diffusion sampling 이론/정확도 관점. | 생성모델 논문 평가에 도움 |
| 11:00–12:15 | P0 | **Poster Session 3** | Sub-second docking, BioDynaSpec, ConGLUDe, FIDIA, ScDiVa, DPLM-Evo 등 핵심 포스터가 많습니다. | 이 날 가장 중요한 poster block 중 하나 |
| 13:30–14:30 | P0 | **Invited Talk: Lab-in-the-Loop for Drug R&D with AI** — Hall C | 이번 관심사에 가장 직접적인 invited talk. AI와 실험실·drug R&D를 closed loop로 연결하는 관점입니다. | 반드시 실시간 추천 |
| 14:30–16:15 | P1 | Poster Session 4 | molecule editing/interpretability 등 보강 포스터를 볼 시간. | Poster list의 Session 4 확인 |
| 16:00–17:00 | P1 | Oral 4E: AI for Science: Dynamical Systems and Processes | molecular dynamics, biological dynamics, generative emulator와 연결됩니다. | MD/Amber와 연결해서 듣기 |
| 17:00–18:45 | P2 | Poster Session 5 | peptide design, LLM/agent 보강 포스터를 훑습니다. | 시간이 부족하면 P0/P1만 |

## 목요일 7/9 — Main Conference Day 3

| 시간 | 우선순위 | 세션 / talk | 왜 들어야 하는지 | 실전 동선 |
|---|---:|---|---|---|
| 10:00–11:00 | P2 | Oral 5A: LLM Training & Inference Efficiency 또는 Oral 5F: Graph & Federated Learning | transformer/LLM 효율, GNN 기반 molecular/protein modeling을 보강할 수 있습니다. | poster를 우선하고 oral은 녹화도 가능 |
| 10:30–12:15 | P0 | **Poster Session 6** | PerturbDiff, RNA-FM, GenUnfold, SPATIA 등 single-cell/omics/protein dynamics 포스터를 집중. | Poster file의 Session 6부터 |
| 16:00–17:00 | P1 | **Oral 6B: Agentic Systems** — Hall B2 | bio-agent/AI scientist 구현 관점에서 도움이 됩니다. | agent 쪽 관심이면 실시간 |
| 16:00–17:00 | P1 | **Oral 6G: Theory: Transformers & GNNs** — ASEM 201–203 | protein graph, molecular graph, transformer 구조에 관심 있으면 중요합니다. | 6B와 겹치므로 하나는 녹화로 |
| 17:00–18:45 | P0 | **Poster Session 8** | VecMol, DeCoDe, TD3B, PDAgent, Proteo-R1, ProtDBench, DMTA-cycle drug design 등 가장 풍부한 포스터 block. | 목요일 최우선 poster block |

## 금요일 7/10 — Workshop: Generative and Agentic AI for Biology

이 날은 가능하면 **하루 전체를 GenBio workshop**에 쓰는 것을 추천합니다. 생성모델, agentic biology, closed-loop wet-lab, therapeutic design이 모두 겹칩니다.

| 시간 | 우선순위 | 세션 | 왜 들어야 하는지 |
|---|---:|---|---|
| 08:35–08:45 | P1 | Opening remarks | 워크숍 문제의식과 accepted/poster 운영 확인 |
| 08:45–09:30 | P0 | Invited: James Zou | biomedical AI, agent/science workflow 관점에서 중요 |
| 09:30–10:00 | P0 | Invited: Samuel Stanton | generative biology / protein·molecule design 흐름 확인 |
| 10:30–11:00 | P0 | Invited: Joy Jiao | biology foundation/generative model 관점 보강 |
| 11:00–11:30 | P0 | Invited: Jeremy Wohlwend | protein/structure/biodesign 관련 가능성이 높아 우선 추천 |
| 11:30–12:15 | P0 | Poster Session 1 | workshop poster는 질의응답 가치가 큼 |
| 13:00–13:30 | P0 | Invited: Martin Steinegger | protein sequence/structure/database·evolution 관련 맥락에 강함 |
| 13:30–14:00 | P0 | Invited: Yunha Hwang | generative/biology 응용 관점 |
| 14:00–14:45 | P0 | Contributed talks | spotlight성 발표. 관련 논문 빠르게 파악 |
| 14:45–15:30 | P0 | Poster Session 2 | agentic biology / generative bio 포스터 확인 |
| 15:30–16:00 | P0 | Invited: Yusuf Roohani | perturbation/biology AI 흐름과 연결 가능 |
| 16:00–17:00 | P0 | Panel | 연구 방향을 잡는 데 가장 유용할 수 있음 |

## 토요일 7/11 — FM4LS + AI for Science 병행 전략

토요일은 겹치는 세션이 많습니다. virtual pass라면 실시간 Q&A/포스터를 우선하고, invited talk는 녹화로 보충하세요.

| 시간 | 우선순위 | 추천 | 이유 |
|---|---:|---|---|
| 08:30–09:20 | P1 | FM4LS opening + early invited talks | life sciences foundation model 큰 그림을 잡기 좋음 |
| 09:20–09:50 | P0 | **AI for Science: AI x Drug/Chemistry — Wengong Jin** | 토요일의 drug/chemistry 최우선 talk |
| 10:20–11:05 | P1 | FM4LS Panel Discussion | life sciences LLM/Foundation Model 연구 방향 파악 |
| 11:05–12:15 | P0 | **FM4LS Poster Session I** | drug-target, molecular reasoning, protein model poster 확인 |
| 12:50–13:20 | P0 | **AI for Science: AI x Sampling & Computational Chemistry — Jonas Köhler** | molecular simulation/sampling/chemistry generation과 직접 연결 |
| 13:35–14:25 | P1 | FM4LS invited talks | biomedical/foundation model 보강 |
| 14:25–15:35 | P0 | **FM4LS Poster Session II** | DrugAgent, DTA, diffusion transformer, perturbation poster 등 관련성이 큼 |
| 15:35–16:50 | P1 | FM4LS late invited talks: Jinbo Xu, Mohammed AlQuraishi, Žiga Avsec | protein/structure/genomics foundation model 관심이면 녹화 포함 강추 |
| 15:55–16:55 | P2 | AI4Science Poster Session II | FM4LS와 겹치므로 poster list 기준으로 필요한 것만 확인 |

## 하루 전 준비 체크리스트

1. ICML virtual page에서 위 P0 세션을 calendar/bookmark에 넣기.
2. Poster file의 P0 poster를 먼저 OpenReview로 열어 abstract, method figure, code/project link 여부 확인.
3. 질문 템플릿을 미리 준비: “이 모델은 wet-lab/MD/docking loop에 어떻게 들어가는가?”, “evaluation split이 real-world design을 반영하는가?”, “latency와 uncertainty는 어떻게 처리하는가?”
4. 겹치는 세션은 실시간 포스터 Q&A를 우선하고, tutorial/invited talk는 녹화로 보충.


---

## 참고한 공개 일정/자료

- ICML 2026 official conference page: https://icml.cc/Conferences/2026
- ICML 2026 tutorials announcement: https://blog.icml.cc/2026/04/02/announcing-the-icml-2026-tutorials/
- ICML 2026 presenter/oral instructions: https://icml.cc/Conferences/2026/PresenterInstructions
- ICML 2026 invited talks announcement: https://blog.icml.cc/2026/05/18/announcing-the-icml-2026-invited-talks/
- ICML 2026 workshops announcement: https://blog.icml.cc/2026/04/06/announcing-the-icml-2026-workshops-and-affinity-workshops/
- GenBio workshop schedule: https://genbio-workshop.github.io/2026/
- FM4LS schedule and accepted papers: https://icml2026fm4ls.github.io/pages/schedule.html , https://icml2026fm4ls.github.io/pages/accepted-paper.html
- AI for Science workshop schedule: https://ai4sciencecommunity.github.io/icml26/schedule
- ICML 2026 public schedule data snapshot used for poster/session times: https://raw.githubusercontent.com/psmiz/icml2026-schedule/main/data.js
- ICML 2026 poster materials browser / public material availability note: https://github.com/psmiz/ICML_2026_Browser/tree/main/posters
