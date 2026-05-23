# 바이브 코딩(Vibe Coding) for 약학 연구자 — 원데이 워크샵 강의 계획서

> *"가설은 내가, 코드는 AI가, 검증은 함께"* — 실험 과학자를 위한 AI 협업 코딩 부트캠프

## 사전 준비 사항
* 개인 노트북 (macOS / Linux / Windows + WSL2 권장)
* **GitHub 계정** 및 Git 설치 (또는 GitHub Desktop)
* **Anthropic 계정** (Claude Pro 권장, Claude Code 사용을 위함)
* **Cursor IDE** 설치 — <https://cursor.com>
* **Obsidian** 설치 — <https://obsidian.md>
* **공용 GPU 서버 SSH 접속 정보** (조교가 사전 배포)
* 셋업이 어려운 분을 위한 **Google Colab + Claude API 폴백 트랙** 별도 제공

---

## 강의 일정 (09:00 - 18:00)

| 시간                | 세션명                                              | 세부 내용 및 활동                                                                                                                                                                                                                                                                                                                                                                 |
| :---------------- | :----------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **09:00 - 09:30** | **Session 1: Why Vibe Coding?**                  | • Andrej Karpathy의 정의(2025.2)와 *"Syntax는 AI가, Intent는 내가"*<br>• 실험 과학자에게 바이브 코딩이 주는 가치: **가설 → 코드 → 검증** 사이클 단축<br>• 약학 연구에서의 활용 사례: ADMET 예측, 분자 도킹 자동화, 임상 데이터 정리                                                                                                                                                                                                        |
| **09:30 - 10:30** | **Session 2: 개발 환경 셋업**                          | • **Cursor + Claude Code** 설치·인증·VS Code 확장 점검<br>• `uv`로 1분 안에 파이썬 환경 구축 (RDKit, scikit-learn 등)<br>• **공용 GPU 서버 SSH 접속** — `Cursor: Connect to Host` / `~/.ssh/config` 설정<br>• 원격 서버에서 첫 코드 실행: *"안녕, 분자!"* (SMILES → mol 객체)                                                                                                                                           |
| **10:30 - 11:30** | **Session 3: AI 하네싱(Harnessing)**                | • **Prompt + Context + Harness** 3종 엔지니어링 개념<br>• `CLAUDE.md` 작성 — AI에게 내 연구 컨텍스트(데이터 위치, 코딩 스타일, 도메인 용어) 가르치기<br>• **MCP 서버 & Skills** 맛보기 — RDKit·PubMed·PDB MCP<br>• 환각(Hallucination)과 엣지 케이스 점검: *비전공자를 위한 코드 리뷰 체크리스트*                                                                                                                                               |
| **11:30 - 12:30** | **Session 4: GitHub & 공개 모델 활용**                 | • Git/GitHub 기초 — clone, commit, push, branch, PR 5분 요약<br>• **공개 BBB 예측 모델 레포 클론 → 재현 실습** (예: `theochem/B3DB`, `samoturk/admet`)<br>• 공개 데이터셋 둘러보기 — MoleculeNet, PubChem, ChEMBL, DrugBank<br>• 보안: **API 키 관리, `.gitignore`, secret scanning** — *Rule of Two*: 같은 지시 두 번 하면 파일로                                                                                       |
| **12:30 - 13:30** | 🍱 **점심 시간**                                     | 식사 및 휴식                                                                                                                                                                                                                                                                                                                                                                    |
| **13:30 - 14:30** | **Session 5: 엑셀 탈출 — 깨끗한 연구 데이터**                | • 노가다 전처리 자동화 (merge, pivot, melt, fuzzy match)<br>• **SMILES 정규화 & RDKit 디스크립터** 계산 (MW, LogP, TPSA, HBA/HBD 등)<br>• B3DB BBB 데이터셋(7,807 분자) 다운로드 → train/valid/test 분할<br>• 1초 만에 EDA 리포트 생성 (`ydata-profiling` + Claude Code)                                                                                                                                           |
| **14:30 - 16:30** | **Session 6: BBB 투과율 예측 모델 구축 & 평가** *(메인 프로젝트)* | • 분자 구조로부터 **혈뇌장벽(BBB) 투과 여부** 분류 모델 학습<br>• Baseline: scikit-learn Random Forest / XGBoost — Cursor와 Claude Code로 페어 코딩<br>• **모델 평가**: AUROC, PR Curve, Confusion Matrix, Calibration plot<br>• **성능 시각화**: matplotlib/plotly로 논문 그림 퀄리티 만들기<br>• **해석 가능성**: SHAP value로 어떤 디스크립터가 BBB 통과를 결정하는지 시각화<br>• (선택) Morgan fingerprint + Graph Neural Network 비교 — GPU 서버 활용 |
| **16:30 - 17:15** | **Session 7: 모델 배포 — 30분 안에 웹앱**                 | • **Streamlit**으로 "BBB Predictor" 웹앱 제작<br>• SMILES 드래그&드롭 → 실시간 예측 + 분자 구조 렌더링<br>• **Hugging Face Spaces** 또는 Streamlit Community Cloud로 1-click 무료 배포<br>• 공유 가능한 URL 받기 → 연구실/지도교수에게 바로 공유                                                                                                                                                                             |
| **17:15 - 17:45** | **Session 8: Second Brain 연구노트**                 | • **Obsidian + Claude Code + GitHub** PKM 셋업<br>• Vault 구조 제안: `Inbox / Project / Literature / Daily / Permanent` or PARA<br>• Claude가 PDF 논문 요약 → Permanent Note 생성 → 기존 노트와 연결<br>• 매일 세션 로그 자동 작성 + GitHub로 백업·버전 관리<br>• *세컨드 브레인이 시간이 지날수록 가치가 누적되는 이유*                                                                                                               |
| **17:45 - 18:00** | **Session 9: 결과 공유 & Wrap-up**                   | • 개인/팀별 **BBB 모델 결과 발표** (각 3분, 어떤 디스크립터가 중요했는지 + 배포 URL 시연)<br>• **AI4Science 시대의 연구자 태도** 정리 — 비판적 검증, 재현 가능성, 도메인 지식의 가치<br>• Q&A 및 후속 학습 로드맵 공유                                                                                                                                                                                                                        |

---

## 참고 사항

> * 본 과정은 코딩 실력보다 **연구 아이디어를 빠르게 결과물로 만드는 능력**과 **AI의 답을 검증하는 능력**을 키우는 데 초점을 둡니다.
> * 메인 실습 주제는 **혈뇌장벽(BBB) 투과율 예측 모델**입니다. BBB 통과 가능성은 신경계 약물 개발에서 가장 먼저 평가되는 ADMET 성질 중 하나로, 약학 연구자에게 즉시 와닿는 문제입니다.
> * 모든 세션은 **AI 협업 워크플로우 시연 → 따라하기 → 자기 데이터로 확장** 순서로 진행됩니다.
> * Session 6의 BBB 데이터셋은 [B3DB](https://github.com/theochem/B3DB)를 기본으로 사용하며, 본인 실험실 화합물 데이터로 fine-tune해도 좋습니다.
> * 결과 공유 후 1주일간 **#vibe-coding-pharm** Slack 채널에서 후속 1:1 멘토링이 제공됩니다.

---

## 핵심 학습 결과 (Learning Outcomes)

워크샵 종료 시점에 수강생은 다음을 할 수 있게 됩니다.

1. **Cursor와 Claude Code**를 자유롭게 오가며 코드를 작성·실행·디버깅한다.
2. `CLAUDE.md`와 MCP를 통해 **AI에게 연구 컨텍스트를 전달**한다.
3. GitHub에서 **공개 예측 모델을 클론·재현**하고, 자신의 데이터로 fine-tune한다.
4. **SMILES → 분자 디스크립터 → ML 모델 → 평가 → 시각화 → 웹 배포**의 전 과정을 혼자 끝낸다.
5. **Obsidian 기반 Second Brain**으로 연구 노트와 코드를 함께 버전 관리한다.
6. AI가 만든 결과물에서 **환각과 엣지 케이스를 식별**하고 비판적으로 검증한다.

---

## 참고한 워크샵 및 자료

- **Argonne National Laboratory** — Vibe Coding Hackathon for Researchers (2025.6)
- **Aalto University** — *"Vibe Coding for Researchers"*
- **Stanford Continuing Studies** — TECH-42 *"Vibe Coding: Building Software in Conversation with AI"*
- **Berkeley ALS Photon Science Computing** — Vibe Coding Workshop (Rule of Two, 보안 best practice)
- **GitHub** — `letitbk/claude-academic-setup`, `pedrohcgs/claude-code-my-workflow`
- **paulgp.substack** — *"Getting Started with Claude Code: A Researcher's Setup Guide"*
- **국내 바이브 코딩 강의** — 패스트캠퍼스, 코드트리(서경대 특강), 당근(개발자가 말아주는 바이브코딩), Selfish Club
- **Karpathy 영감 기반 Obsidian + Claude Code Second Brain 워크플로우** (JP Narowski, MindStudio, noahvnct 등)
