# ICML 2026 Virtual-only Single-stream 청취 계획 — Poster session 제외 버전

**목적**: 현장 참석 없이 virtual pass 1장으로, 동시에 두 세션을 켜지 않고 들을 수 있는 “한 줄짜리 live 청취 계획”입니다.  
**관심사 기준**: AI 신약개발, 생성모델, diffusion/flow matching, protein/molecule design, transformer/LLM, agentic biology.  
**시간대**: KST / 서울 현지 시간.  
**중요한 변경**: poster session은 이 파일의 live agenda에서 제거했습니다. Poster는 별도 `icml2026_bio_drug_genai_poster_reading_list.md`에서 시간 날 때 비동기로 확인하세요.

---

## 우선순위 기준

- **P0**: 네 관심사와 직접 연결됩니다. 가능하면 live로 듣기.
- **P1**: 매우 관련 있지만 P0와 겹치면 녹화/후속 시청.
- **P2**: 배경지식·확장용. 체력과 시간이 남으면 시청.

---

## 7/6 월 — Tutorials / Expo day

| 시간 | 우선순위 | 선택할 live 세션 | 왜 듣는지 | Virtual / 세부 링크 |
|---|---:|---|---|---|
| 09:00–11:30 | **P0** | **Tutorial: Diffusion and Flow-Matching: From Memorization to Generalization & Beyond** | 분자 생성, 단백질/펩타이드 생성, single-cell perturbation, docking diffusion 논문을 읽기 위한 핵심 배경입니다. 이번 poster list의 MuCO, DeCoDe, VecMol, CURE, PerturbDiff, Atlas-CFM 같은 논문을 이해하는 데 바로 연결됩니다. | https://icml.cc/virtual/2026/75374 |
| 13:30–16:00 | **P0** | **Tutorial: Adaptive Reasoning in LLMs: From Post-Training to Test-Time Learning** | 신약개발 workflow가 점점 “모델이 도구를 호출하고, 실험을 계획하고, 결과를 반영하는 agent” 구조로 가고 있습니다. GenBio workshop과 DrugAgent/PDAgent류 poster를 이해하는 데 좋습니다. | https://icml.cc/virtual/2026/75366 |

**녹화로 보면 좋은 대안**

- **Unifying Attention and Diffusion with Kan Extension Transformers**: attention/diffusion/transformer를 이론적으로 연결하는 내용. 생성모델 architecture에 관심이 크면 나중에 보세요.  
  https://icml.cc/virtual/2026/75371
- **New Techniques for Sequence Prediction: Spectral Filtering and Preconditioning**: biological sequence model, DNA/RNA/protein foundation model 쪽 배경으로 좋습니다.  
  https://icml.cc/virtual/2026/75370

---

## 7/7 화 — Main Conference Day 1

| 시간 | 우선순위 | 선택할 live 세션 | 왜 듣는지 | Virtual / 세부 링크 |
|---|---:|---|---|---|
| 08:30–09:30 | **P1** | **Invited Talk: Towards AI Agents In the Real World** | 금요일 GenBio와 토요일 AI4Science의 agentic biology / AI scientist 흐름을 이해하기 위한 배경 talk입니다. | https://icml.cc/virtual/2026/invited-talk/67258 |
| 10:00–11:00 | **P0** | **Oral block: AI for Science — Proteins and Genomic Sequences** | protein backbone generation, genomic foundation model, protein fitness benchmark를 한 번에 볼 수 있는 block입니다. 특히 **Protein Autoregressive Modeling via Multiscale Structure Generation**은 poster list의 P0 항목으로 따로 공부할 가치가 큽니다. | key oral: https://icml.cc/virtual/2026/oral/71037 |
| 13:30–14:30 | **P0** | **Oral block: AI for Science / Molecular Modeling** | 신약개발과 molecular modeling에 가장 직접적인 main-conference oral block입니다. 특히 **Towards Sub-second Biological Foundation Model Infrastructure / Quantized Consistency Diffusion for Molecular Docking**는 docking + diffusion + agentic workflow가 만나는 발표라 live로 추천합니다. | key oral: https://icml.cc/virtual/2026/oral/71070 |
| 16:00–17:00 | **P2** | **Invited Talk: Causal Inference with Transformer Models** | transcriptomics-conditioned drug design, perturbation modeling, causal reasoning에 관심이 있으면 배경으로 좋습니다. P0 세션보다 우선순위는 낮으니 피곤하면 녹화로 돌려도 됩니다. | https://icml.cc/virtual/2026/invited-talk/67261 |

---

## 7/8 수 — Main Conference Day 2

| 시간 | 우선순위 | 선택할 live 세션 | 왜 듣는지 | Virtual / 세부 링크 |
|---|---:|---|---|---|
| 08:30–09:30 | **P1** | **Invited Talk: How Far Can Quadratics Take Us? Lessons for LLM Pretraining** | biological foundation model이나 LLM/transformer scaling을 직접 다룰 때 도움 되는 pretraining 관점입니다. | https://icml.cc/virtual/2026/invited-talk/67264 |
| 10:00–11:00 | **P1** | **Oral block: Diffusion Models** | molecule/protein generation에 바로 쓰이는 diffusion sampling, masked diffusion, generative modeling 이론 배경을 보강하는 시간입니다. | official schedule / virtual에서 Oral 3A 확인 |
| 13:30–14:30 | **P0** | **Invited Talk: Lab-in-the-Loop for Drug R&D with AI** | 이번 ICML에서 네 관심사와 가장 직접적으로 맞는 invited talk입니다. AI가 wet-lab, drug discovery/development, 실험 설계·해석 loop에 어떻게 들어가는지 큰 그림을 잡기 좋습니다. | https://icml.cc/virtual/2026/invited-talk/67266 |
| 16:00–17:00 | **P1** | **Oral block: AI for Science — Dynamical Systems and Processes** | protein dynamics, molecular dynamics surrogate, scientific generative model 쪽과 이어지는 배경입니다. Amber/MD도 같이 공부하려는 흐름이면 추천합니다. | official schedule / virtual에서 Oral 4E 확인 |

---

## 7/9 목 — Main Conference Day 3

| 시간 | 우선순위 | 선택할 live 세션 | 왜 듣는지 | Virtual / 세부 링크 |
|---|---:|---|---|---|
| 08:30–09:30 | **P2** | **Invited Talk: From Behavioural Guardrails to Principled Agency** | agentic AI 안전성·원칙에 관한 talk로 보입니다. 신약개발 직접성은 낮지만 autonomous scientific agent를 생각하면 배경으로 좋습니다. | https://icml.cc/virtual/2026/invited-talk/67270 |
| 13:30–14:30 | **P2** | **Invited Talk: What will be left for us to work on?** | 큰 그림/전망형 invited talk로 보고, 필수보다는 확장용으로 두세요. | https://icml.cc/virtual/2026/invited-talk/67274 |
| 16:00–17:00 | **P1** | **Oral block: Theory — Transformers & GNNs** | molecular graph, protein graph, transformer/GNN architecture의 기반 이해를 보강하기 좋습니다. 같은 시간 agentic systems가 겹친다면, agent는 금·토 workshop에서 많이 다루므로 이 block을 live로 추천합니다. | official schedule / virtual에서 Oral 6G 확인 |

**녹화로 보면 좋은 대안**

- **Oral block: Agentic Systems**: agent 쪽을 더 깊게 보고 싶으면 녹화로 보세요. 다만 금요일 GenBio와 토요일 AI4Science가 agentic science를 더 직접적으로 다룹니다.

---

## 7/10 금 — Workshop Day 1

### P0 고정 추천: Generative and Agentic AI for Biology

이날은 **하루 전체를 GenBio workshop에 두는 것**을 추천합니다. 주제가 네 관심사와 가장 정확히 겹칩니다: generative models for proteins/RNAs/cells, therapeutic design, agentic experimental planning, closed-loop wet-lab integration.

| 시간 | 우선순위 | live로 들을 부분 | 왜 듣는지 | 링크 |
|---|---:|---|---|---|
| 08:35–08:45 | P1 | Opening Remarks | 워크숍 framing 확인. | https://genbio-workshop.github.io/2026/ |
| 08:45–09:30 | **P0** | Invited Talk — James Zou | AI for biology와 biomedical discovery 큰 그림을 잡기 좋습니다. | https://genbio-workshop.github.io/2026/ |
| 09:30–10:00 | **P0** | Invited Talk — Samuel Stanton | agentic/scientific AI 관점 보강. | https://genbio-workshop.github.io/2026/ |
| 10:30–11:00 | **P0** | Invited Talk — Joy Jiao | AI agent / tool-use / scientific workflow 관점에서 기대값이 큽니다. | https://genbio-workshop.github.io/2026/ |
| 11:00–11:30 | **P0** | Invited Talk — Jeremy Wohlwend | Boltz 계열 구조·생물학 모델링과 연결 가능성이 큽니다. | https://genbio-workshop.github.io/2026/ |
| 13:00–13:30 | **P0** | Invited Talk — Martin Steinegger | protein sequence/structure database, foundation model 생태계와 연결됩니다. | https://genbio-workshop.github.io/2026/ |
| 13:30–14:00 | **P0** | Invited Talk — Yunha Hwang | biological discovery / lab-in-the-loop 쪽 관점 보강. | https://genbio-workshop.github.io/2026/ |
| 14:00–14:45 | P1 | Contributed Talks | spotlight 성격의 짧은 발표를 빠르게 훑기 좋습니다. | https://genbio-workshop.github.io/2026/ |
| 15:30–16:00 | **P0** | Invited Talk — Yusuf Roohani | virtual cell, perturbation biology, generative cell models와 연결될 가능성이 큽니다. | https://genbio-workshop.github.io/2026/ |
| 16:00–17:00 | **P0** | Panel Discussion | “generative model vs agentic AI for biology”의 방향성을 잡기 좋습니다. | https://genbio-workshop.github.io/2026/ |

---

## 7/11 토 — Workshop Day 2

토요일은 **AI4Science workshop**과 **FM4LS workshop**이 겹칩니다. 동시에 두 개를 켜지 않는 기준으로 아래처럼 추천합니다. 핵심은 **AI4Science에서 drug/chemistry talk 2개를 live로 듣고, 나머지는 FM4LS invited talks를 듣는 것**입니다. Poster session은 agenda에서 제외했습니다.

| 시간 | 우선순위 | 선택할 live 세션 | 왜 듣는지 | 링크 |
|---|---:|---|---|---|
| 08:40–09:05 | P1 | FM4LS — Invited Talk by Emily Fox | life-science foundation model / multimodal modeling 배경. | https://icml2026fm4ls.github.io/pages/schedule.html |
| 09:20–09:50 | **P0** | AI4Science — **Invited Talk: AI x Drug/Chemistry** — Wengong Jin | 토요일 전체에서 신약개발/화학에 가장 직접적인 invited talk입니다. | https://ai4sciencecommunity.github.io/icml26/schedule |
| 10:20–11:05 | P1 | FM4LS — Panel Discussion | 생명과학 foundation model 커뮤니티의 관점 정리. | https://icml2026fm4ls.github.io/pages/schedule.html |
| 12:50–13:20 | **P0** | AI4Science — **Invited Talk: AI x Sampling & Computational Chemistry** — Jonas Köhler | molecular sampling, computational chemistry, generative modeling과 직접 연결됩니다. | https://ai4sciencecommunity.github.io/icml26/schedule |
| 13:35–14:25 | P1 | FM4LS — Invited Talks by Ruijiang Li / Haider Warraich | multimodal/life-science model 응용 관점 보강. | https://icml2026fm4ls.github.io/pages/schedule.html |
| 15:05–15:55 | P1 | AI4Science — Panel: Benchmarking “Breakthroughs” in AI Scientist | autonomous AI scientist의 평가·신뢰성 문제를 보는 시간입니다. | https://ai4sciencecommunity.github.io/icml26/schedule |
| 15:35–16:50 | **P0** | FM4LS — Invited Talks by Jinbo Xu / Mohammed AlQuraishi / Žiga Avsec | protein structure/foundation model/sequence biology 쪽으로 가장 강한 late block입니다. 단, 15:35–15:55가 AI4Science panel과 겹치므로 하나만 고르려면 FM4LS late invited talks를 우선하세요. | https://icml2026fm4ls.github.io/pages/schedule.html |

### 토요일 single-stream 권장 선택

- **09:20–09:50** AI4Science Wengong Jin은 반드시 live.
- **12:50–13:20** AI4Science Jonas Köhler도 live.
- **15:35–16:50**은 FM4LS late invited talks를 live로 추천. AI4Science panel은 녹화로 보면 됩니다.

---

## 녹화/후속 시청 우선순위

1. **Tutorial: Unifying Attention and Diffusion with Kan Extension Transformers**  
   생성모델/transformer architecture 이론 보강.
2. **Tutorial: New Techniques for Sequence Prediction**  
   DNA/RNA/protein sequence model 쪽 배경.
3. **Main conference Agentic Systems oral blocks**  
   금·토 workshop으로 agentic science를 먼저 본 뒤, 더 알고 싶으면 후속 시청.
4. **Causal Inference with Transformer Models**  
   perturbation, transcriptomics, causal drug response modeling에 관심이 커질 때 후속 시청.

---

## 이 계획에서 poster session을 뺀 이유

Virtual pass로 talk를 들을 때 poster session까지 live agenda에 넣으면, main talk와 workshop talk를 놓치기 쉽습니다. Poster는 논문 PDF, OpenReview, project/code page, ICML virtual poster page로 시간 날 때 따로 볼 수 있으므로, live 시간에는 tutorial/oral/invited/workshop talk에 집중하는 편이 효율적입니다.

---

## 주요 공식 출처

- ICML 2026 Dates: https://icml.cc/Conferences/2026/Dates
- ICML 2026 virtual schedule data mirror: https://raw.githubusercontent.com/psmiz/icml2026-schedule/main/data.js
- GenBio workshop: https://genbio-workshop.github.io/2026/
- AI4Science workshop schedule: https://ai4sciencecommunity.github.io/icml26/schedule
- FM4LS workshop schedule: https://icml2026fm4ls.github.io/pages/schedule.html
