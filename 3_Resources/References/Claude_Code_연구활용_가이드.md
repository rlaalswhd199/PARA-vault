# Claude로 연구하기 — Cowork & Code 활용 가이드

> 대학원 연구자가 Claude Cowork + Code를 도입하여 연구 생산성을 극적으로 높인 실전 사례를 정리한 문서입니다. 연구 고유의 내용(프로젝트명, 모델 아키텍처 등)은 익명화되었으며, **Claude를 어떻게 활용했는지**에 초점을 맞추었습니다.

---

## 1. 도입 효과: 2주 만에 4개 프로젝트 동시 진행

Claude Cowork + Code 도입 후, 약 2주 만에 4개의 연구 프로젝트를 동시에 진행할 수 있었습니다.

| 프로젝트 | 진행 내용 | 기간 |
|---------|----------|------|
| Project A | Phase 1 학습 → 분석 | 3/4~3/9 |
| Project B | 구현 완료 → 학습 시작 | 3/10~3/11 |
| Project C | Phase 0 준비, 환경 셋업 | 3/12~3/13 |
| Project D | 모델 정의, 아키텍처 설계 | 3/13~3/14 |

핵심 메시지: **이 모든 것이 Claude 없이는 불가능했다.**

---

## 2. 인프라 설계: Obsidian을 중심으로 한 연구 노트 체계

### 왜 Obsidian인가?

Claude와의 연동을 극대화하기 위해 Obsidian을 연구 노트 플랫폼으로 선택했습니다.

- **Markdown Native**: Claude가 직접 읽고 수정 가능, 별도 변환 불필요
- **로컬 폴더 기반**: Claude Cowork이 폴더 마운트로 직접 접근
- **Wiki-link 연결**: `[[노트]]` 형식으로 연구 노트 간 자유로운 상호참조
- **Git 연동 가능**: 버전 관리 + Overleaf 연동으로 논문 작업 동기화

Notion/Google Docs는 클라우드 잠금, API 제한이 있지만, Obsidian은 로컬 파일이므로 Claude가 바로 접근할 수 있습니다.

### PARA 방법론으로 연구 노트 정리

| 구분 | 설명 | 예시 |
|------|------|------|
| **P**roject | 목표+데드라인 있는 진행 중 연구 | 현재 진행 중인 프로젝트들 |
| **A**rea | 꾸준히 관리하는 영역 | Daily Plan, Health, 행정 |
| **R**esource | 주제별 참고 자료 | Papers Index, 세미나 기록 |
| **A**rchive | 완료된 프로젝트 보관 | 과거 학회 출장 등 |

행동(Action) 기준 분류 → Claude가 맥락 파악 용이

### 분산 관리 → Obsidian 통합

**Before** (여러 도구에 분산):
- Zotero → 논문 PDF 관리
- Mendeley → 논문 메모
- Notion → 연구 노트
- Google Docs → 미팅 노트

**After** (Obsidian 하나로 통합):
- Papers Index.md → 논문 인덱스 (137편+)
- 프로젝트별 Paper Writing/ → .md + .tex 논문 원고
- Meeting Minutes/ → 교수님 미팅 기록
- Daily Plans/ → 600+ 일일 계획

**하나의 Vault에서 모든 연구 자료를 Claude가 직접 접근**

---

## 3. Claude Cowork — 연구 매니저 역할

Obsidian Vault를 마운트하면, Claude Cowork이 모든 연구 노트에 직접 접근하여 다음 역할을 수행합니다.

| 역할 | 구체적 활용 |
|------|----------|
| **연구 방향 탐색** | Gap analysis, 논문 서베이, 아이디어 검증 |
| **논문 읽기/쓰기** | Reading notes, 초안 작성, top-tier 문제 분석 |
| **결과 분석** | 실험 결과 해석, 시각화, 다음 실험 제안 |
| **문서 생성** | PPT, 주간 보고서, 미팅 자료 자동 생성 |

### CLAUDE.md — 프로젝트 컨텍스트

매 세션마다 자동으로 로드되는 프로젝트 설명서를 작성합니다.

```
# CLAUDE.md

## Vault 소유자
- 이름: [연구자명] / 역할: 대학원생 (로보틱스)

## Project (현재 주력 연구)
- Project A: 학회 제출 완료
- Project B: 구현 완료, 학습 중
- Project C: Phase 0 준비 중

## 응답 스타일 – 연구 파트너 모드
- 꼬리를 무는 자기 질문
- 검증 먼저, 제안은 나중에
- 쉽게 꼬리 내리지 말 것
```

한 번 작성하면 모든 세션에서 맥락 유지 — **"매번 설명할 필요 없음"**

---

## 4. Claude Code — 구현 & 실험 Executor

터미널에서 직접 코딩하는 AI 에이전트로서 다음을 수행합니다.

- 코드베이스를 직접 읽고 이해
- 환경 셋업부터 구현까지 자율 수행
- 실험 실행, 에러 디버깅, 로그 분석
- Git commit, branch 관리
- tmux + wandb로 백그라운드 실험

### 실전 예시: 602줄 프롬프트 하나로 전체 구현 완성

```
$ claude
> Implementation Prompt를 읽고 [Project B] 구현해줘

✓ config.py 수정 (4ch input)
✓ depth_pipeline.py 생성
✓ MEM attention 구현
✓ train.py 수정 (LoRA)
⚠ RuntimeError 발견 → 패치
✓ 학습 파이프라인 완성
```

---

## 5. Cowork ↔ Code 생태계

두 도구가 공유 Git Codebase를 통해 유기적으로 연결됩니다.

**Cowork** (Desktop):
1. 연구 방향 설정
2. 프롬프트 작성
3. 결과 분석
4. 논문 작성 코칭

→ **프롬프트를 Git에 저장**

**Code** (Terminal):
1. 환경 셋업
2. 코드 구현
3. 실험 실행
4. 디버깅 & 로그

→ **결과를 Git에 저장**

Cowork이 설계한 프롬프트를 Git에 저장 → Code가 읽고 바로 실행

---

## 6. 자면서 실험하기 — tmux + wandb

| 시간 | 행동 |
|------|------|
| 23:00 | Claude Code에게 실험 명령 |
| 23:05 | tmux 세션에서 학습 시작 |
| Zzz... | wandb 로깅 자동 기록 중 |
| 08:00 | Cowork에게 결과 분석 요청 |

**연구자가 자는 동안에도 실험은 계속됩니다.**

---

## 7. Overleaf + Git 연동 (논문 작성)

Claude Code가 .tex를 직접 편집 → git push → Overleaf 반영

**워크플로우:**
1. Cowork이 초안 작성 (.md)
2. Code가 .tex로 변환/편집
3. git push → Overleaf 반영
4. Overleaf에서 공동 편집 가능

```
Paper Writing/ 구조
├── main.tex
├── Sections/
│   ├── abstract.tex
│   ├── introduction.tex
│   ├── method.tex
│   ├── experiments.tex
│   └── analysis.tex
└── math_commands.tex
```

현재 3개 논문을 동시 관리 중

---

## 8. 커넥터 (MCP) — 외부 서비스 연동

Model Context Protocol로 다양한 서비스를 Claude에 직접 연결합니다.

| 서비스 | 활용 |
|--------|------|
| **Slack** | 채널 메시지 읽기, 논문 링크 자동 수집 |
| **Google Drive** | 문서 검색/읽기, 자료 직접 접근 |
| **Google Docs** | 문서 읽기/수정, 미팅 노트 실시간 편집 |
| **Gmail** | 메일 검색/읽기, 초안 작성 |
| **Calendar** | 일정 확인/생성, 미팅 스케줄 관리 |
| **Notion** | 페이지 읽기/생성, 데이터베이스 접근 |

### Google Docs 연동 실전 예시

- **교수님 미팅 노트**: Google Docs 미팅 문서 공유 → Claude가 직접 읽기 → 핵심 피드백 추출 + Vault 반영 → 다음 TODO 자동 생성
- **공동 연구 문서 편집**: 공유 문서 내용 읽기 → 수정사항 직접 반영 → 댓글로 설명 추가 → 동기들과 실시간 협업
- **자료 취합 & 정리**: Drive에서 관련 문서 검색 → 여러 문서 내용 통합 → 요약 보고서 생성 → Obsidian에 정리 노트 저장

별도의 복붙 없이 Claude가 Google Docs를 직접 읽고 수정

---

## 9. Skills — 반복 워크플로우 자동화

SKILL.md에 best practice를 한 번 작성 → 이후 매번 자동 적용

| 스킬 이름 | 트리거 | 기능 |
|----------|--------|------|
| paper-reading-note | "논문 정리해줘" | arXiv → 구조화된 노트 + Index 업데이트 |
| paper-writing-coach | "논문 작성" | top-tier 문제 분석 → 작성 코칭 |
| related-work-surveyor | "related work" | 9개 학회 최신 논문 종합 서베이 |
| weekly-research-digest | "주간 정리" | Daily notes → 주간 연구 요약 |
| research-seminar-ppt | "세미나PPT" | Vault 노트 → 발표 자료 자동 생성 |
| slack-paper-collector | "슬랙 논문 정리" | Slack 링크 → Papers Index 자동 추가 |
| research-direction-explorer | "연구 방향" | Gap analysis + Tier 랭킹 |

---

## 10. 데모 사례

### 데모 1: 논문 읽기 → 구조화된 노트
paper-reading-note 스킬을 사용하여 arXiv 논문을 구조화된 연구 노트로 자동 변환

### 데모 2: Related Work 조사
한 번의 요청으로 46편 논문, 8개 카테고리의 comprehensive한 서베이를 자동 생성. 각 논문에 Venue, Tier(Must-cite/Should-cite) 분류 포함.

### 데모 3: 주간 연구 정리
weekly-research-digest 스킬로 Daily notes를 주간 연구 요약으로 자동 변환

### 데모 4: 세미나 PPT 자동 생성
research-seminar-ppt 스킬로 Vault 노트에서 발표 자료를 자동 생성 (이 발표 자료 자체도 Claude가 만듦!)

---

## 11. 실전: Claude Code 버그 발견 & 해결

구현 과정에서 사람이 놓치기 쉬운 config 불일치를 Claude가 즉시 감지하고 수정한 사례입니다.

**발견된 버그:**
- RuntimeError: size mismatch — config의 num_channels=3이 실제 4ch input과 충돌
- Trainable params 불일치 — 예상 4M → 실제 19.8M (LoRA 18.9M + patch embed 904K)

**자동 해결:**
- Dynamic patching 적용 — runtime에서 config 동적 수정, pretrained weight 유지
- Param 분석 & 문서화 — LoRA rank=16 → 18.9M, 정확한 breakdown 기록

---

## 핵심 요약

1. **Obsidian + PARA**: 모든 연구 자료를 로컬 Markdown으로 통합 → Claude가 직접 접근 가능
2. **CLAUDE.md**: 프로젝트 컨텍스트를 한 번 작성하면 매 세션 자동 로드
3. **Cowork ↔ Code 생태계**: Cowork은 연구 매니저, Code는 구현/실험 실행자로 역할 분담
4. **Git 공유**: 두 도구가 동일한 Git Repository를 바라보며 프롬프트와 결과를 주고받음
5. **MCP 커넥터**: Slack, Google Docs, Drive 등 외부 서비스와 직접 연동
6. **Skills 자동화**: 반복되는 연구 워크플로우를 스킬로 정의하여 키워드 한 마디로 실행
7. **tmux + wandb**: 자는 동안에도 실험이 계속되고, 아침에 결과 분석 요청
