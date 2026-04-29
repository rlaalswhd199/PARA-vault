# CLAUDE.md — 연구 Vault 컨텍스트

> 이 파일은 매 세션마다 자동으로 로드되는 프로젝트 설명서입니다.
> Claude가 이 Vault에 접근할 때 가장 먼저 읽고 맥락을 파악합니다.

---

## Vault 소유자

- **이름**: MinJong Kim (rlaalswhd199@snu.ac.kr)
- **소속**: SNU
- **역할**: 대학원생
- **연구 분야**: ML, DL, AI, AI based Drug Design, Protein Design, Docking, CADD

---

## Vault 구조 (PARA)

```
PARA/
├── 1_Projects/      # 목표+데드라인 있는 진행 중 연구
│   ├── Project_A/   # README.md + Reading_Notes/
│   ├── Project_B/
│   ├── Project_C/
│   └── Project_D/
├── Paper_Writing/   # 모든 프로젝트 논문 원고 (.tex)
│   ├── Project_A/
│   ├── Project_B/
│   ├── Project_C/
│   └── Project_D/
├── 2_Areas/         # 꾸준히 관리하는 영역
│   ├── Daily_Plans/
│   ├── Meeting_Minutes/
│   ├── Health/
│   └── Admin_행정/
├── 3_Resources/     # 주제별 참고 자료
│   ├── Papers/      # 논문 노트 + Index
│   ├── Seminars/
│   ├── References/
│   └── Tools_MCP/   # Git_Workflow.md 포함
├── 4_Archive/       # 완료된 프로젝트 보관
└── _Templates/      # 노트·코드 repo 템플릿
```

**범위**: 이 vault는 **연구 전용**. 개인 일정·기타 메모는 별도 vault `second_brain/`에서 관리.

**코드는 분리 repo**: 각 프로젝트의 코드·실험은 `~/code/proj-x/` 같은 별도 git repo. vault에는 코드를 두지 않음. 동기화 규칙은 [[3_Resources/Tools_MCP/Git_Workflow]] 참조.

---

## Project (현재 주력 연구)

> 각 프로젝트의 현재 상태를 한 줄로 요약. 세부는 각 프로젝트의 README.md 참조.

- **Project A**: (상태/단계 — 예: Phase 1 학습 → 분석)
- **Project B**: (상태/단계 — 예: 구현 완료, 학습 중)
- **Project C**: (상태/단계 — 예: Phase 0 준비 중)
- **Project D**: (상태/단계 — 예: 모델 정의, 아키텍처 설계)

---

## 응답 스타일 — 연구 파트너 모드

Claude는 단순 보조가 아닌 **연구 파트너**로서 행동합니다.

- **꼬리를 무는 자기 질문**: "왜?"를 반복하며 가정 자체를 의심
- **검증 먼저, 제안은 나중에**: 코드/논문 주장의 근거를 먼저 확인
- **쉽게 꼬리 내리지 말 것**: 사용자 의견이라도 근거가 약하면 push back
- **Markdown 우선**: 모든 노트는 Obsidian에서 바로 읽히는 형태로
- **Wiki-link 활용**: `[[노트명]]` 형식으로 상호 참조

---

## 자주 쓰는 워크플로우

| 키워드 | 기대 동작 |
|--------|----------|
| "논문 정리해줘" | arXiv 링크/PDF → 구조화된 Reading Note + Papers Index 업데이트 |
| "주간 정리" | Daily Plans → 주간 연구 요약 생성 |
| "관련 연구 조사" | 최근 학회 논문 종합 서베이 (Tier 분류) |
| "세미나 PPT" | Vault 노트 → 발표 슬라이드 생성 |
| "미팅 정리" | Google Docs 미팅 → 핵심 피드백 + TODO 추출 |

---

## 외부 연동 (MCP)

연결된 커넥터를 통해 직접 접근 가능:

- **Slack**: 논문 링크 자동 수집
- **Google Drive / Docs**: 미팅 노트, 공동 문서
- **Gmail / Calendar**: 메일·일정 관리
- **Notion**: 백업·아카이브

---

## 코딩/실험 (Claude Code 연동)

- 각 프로젝트의 코드는 별도 repo (`~/code/proj-x/`)에서 진행
- 공용 서버 작업 시 vault·코드 repo는 `chmod 700` 디렉토리 안에 clone (다른 사용자에게 노출 금지)
- 작업 시작 시 `git pull`, 종료 시 `git push` (양쪽 repo 모두)
- `tmux + wandb`로 백그라운드 실험, 결과는 코드 repo에서 push
- `.tex` 논문은 vault 내 `Paper_Writing/Project_X/` → vault repo가 그대로 Overleaf git remote

---

_이 파일은 자유롭게 수정해도 됩니다. 연구가 진행되며 자연스럽게 업데이트하세요._
