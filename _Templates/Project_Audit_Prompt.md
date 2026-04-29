# Project Audit & Vault Sync — Bootstrap Prompt (Template)

> 이미 서버에 존재하는 코드 repo를 읽어서 분석하고, vault와 동기화하기 위한 프롬프트.
> 새 프로젝트 audit이 필요할 때 이 파일을 복사해서 placeholder만 갈아끼우세요.

## 사용 방법

1. 이 파일을 복사: `cp _Templates/Project_Audit_Prompt.md 1_Projects/Project_X/_audit_prompt.md`
2. `<PROJECT_NAME>`, `<CODE_PATH>`, `<DATE>` 부분을 실제 값으로 교체
3. vault commit & push
4. 서버: `cd <VAULT_PATH> && git pull`
5. 서버: `cd <CODE_PATH> && claude` 실행 후, `1_Projects/Project_X/_audit_prompt.md` 내용을 그대로 붙여넣기
6. 보고서가 vault에 생성되면 로컬에서 pull 받아 검토 → cleanup 결정

---

# (이 아래부터가 Claude Code에게 주는 실제 프롬프트)

너는 지금 공용 GPU 서버에서 동작 중이고, 다음 두 디렉토리에 접근할 수 있다:

- **Vault**: `<VAULT_PATH>` (예: `~/research/PARA`) — 노트와 보고서를 쓸 곳
- **Code repo**: `<CODE_PATH>` (예: `~/code/proj-a`) — 분석 대상

이 프로젝트는 vault의 [[1_Projects/<PROJECT_NAME>/README]] 에 대응한다. CLAUDE.md (vault 루트)도 한 번 읽고 컨텍스트를 잡아라.

## 절대 규칙 (위반 금지)

1. **파일을 지우거나 이동하지 마라.** `rm`, `mv`로 코드 repo를 손대는 건 모두 금지. `git clean`, `git reset --hard` 도 금지.
2. **이름 변경 금지.** 단, vault 안에서 새 노트를 만드는 건 자유.
3. **`.gitignore`는 추가만**, 기존 줄 삭제 금지. 그것도 별도 커밋으로.
4. **시크릿이 commit되어 있다면 즉시 보고만 하고 손대지 마라.** key는 사람이 폐기·재발급해야 함.
5. 코드 repo에서 어떤 git 명령이든 실행 전에 `git status`로 작업 트리 깨끗한지 먼저 확인.
6. 보고서는 한국어로 작성, 단 코드·경로·로그 인용은 원문 그대로.

---

## Phase 1 — 읽기·분석 (read-only)

### 1.1 디렉토리 구조

```bash
cd <CODE_PATH>
tree -L 3 -I '__pycache__|*.egg-info|.venv|venv|node_modules|wandb|checkpoints|logs|data|.git'
# tree가 없으면: find . -maxdepth 3 -not -path '*/\.*' | sort
```

### 1.2 메타데이터 수집

- 언어·프레임워크 (`pyproject.toml`, `requirements.txt`, `environment.yml`, `setup.py` 확인)
- 진입점들: `**/train.py`, `**/main.py`, `**/run*.py`, `**/eval*.py`, `**/scripts/*.py`
- 설정 시스템: hydra? omegaconf? argparse? yaml? — `configs/`, `conf/` 폴더 있는지
- 로깅: wandb / tensorboard / plain text log
- 데이터 경로: 코드 안에 hardcoded path 또는 환경변수
- 체크포인트 경로: 어디에 저장되도록 되어 있나

### 1.3 git 상태

```bash
git log --oneline -20
git branch -a
git status
git remote -v
```

### 1.4 위험 파일 점검

```bash
# 잘못 tracked된 무거운 파일 또는 시크릿 후보
git ls-files | grep -E '\.(ckpt|pth|pt|bin|safetensors|h5|npy|npz|parquet|tfrecord|env)$' | head
git ls-files | grep -iE '(secret|api_?key|token|credential|\.env)' | head

# 큰 파일 (10MB 이상) tracked인지
git ls-files | xargs -I{} du -h {} 2>/dev/null | awk '$1 ~ /M$/ && $1+0 >= 10' | head
```

### 1.5 README·문서 존재 여부

`README.md`, `docs/`, `notes/`, design doc, 설계 메모가 있는지 확인. 있다면 **핵심 내용만** 추려서 vault로 가져갈 후보로 표시 (옮기지 말고 표시만).

### 1.6 _Templates/Code_Repo_Template와 비교

vault의 `_Templates/Code_Repo_Template/` 구조와 현재 코드 repo를 비교해서 어떤 폴더·파일이 빠져 있는지 메모. 단, **이 단계에서는 추가하지 마라** — 보고서에만 적어라.

---

## Phase 2 — 보고서 작성 (write to vault)

다음 경로에 마크다운 파일을 만들어라:
`<VAULT_PATH>/1_Projects/<PROJECT_NAME>/Status_Snapshot_<DATE>.md`

구조:

```markdown
# <PROJECT_NAME> — Status Snapshot (<DATE>)

## 한 줄 요약
(이 프로젝트가 무엇을 푸는지, 코드와 README에서 추론. 추론은 추론이라고 명시)

## 현재 단계
(코드 완성도, 학습 진행 정도, 마지막 commit 메시지 기반)

## 디렉토리 구조 (주요)
\`\`\`
(Phase 1.1의 tree 출력 — 다듬어서)
\`\`\`

## 진입점·실행 명령
- 학습: `python ...`
- 평가: `python ...`
- 설정 시스템: ...

## 최근 커밋 흐름
(git log --oneline -10 결과)

## .gitignore 빠진 패턴
- (있다면)

## 보안·용량 사고 가능성
- 시크릿: (확인 결과 — 없음 / OOO 발견)
- 큰 tracked 파일: (없음 / 목록)

## vault로 이관 후보 노트
- 코드 repo의 OOO.md → 요약본을 1_Projects/<PROJECT_NAME>/Reading_Notes/ 로
- ...

## 미완·TODO로 보이는 곳
- (TODO 주석, 빈 함수, 의심스러운 부분)

## Code_Repo_Template 대비 차이
- 누락: ...
- 추가된 것: ...
```

---

## Phase 3 — Vault README 채우기

`<VAULT_PATH>/1_Projects/<PROJECT_NAME>/README.md` 의 placeholder들을 **확인된 사실로만** 채워라. 모르는 건 비워둬. 특히:

- 시작일 (git log의 first commit date)
- 현재 단계 (Status Snapshot의 요약)
- 한 줄 설명
- 핵심 가설 / 기여 (README 또는 paper draft에서 추출 가능하면)
- 코드 repo URL (`git remote get-url origin`)
- 로그 섹션에 `<DATE>` 항목 추가: "Status snapshot 작성, [[Status_Snapshot_<DATE>]]"

---

## Phase 4 — Cleanup 제안서

다음 경로에:
`<VAULT_PATH>/1_Projects/<PROJECT_NAME>/Cleanup_Proposal.md`

구조:

```markdown
# Cleanup Proposal (<DATE>)

## 즉시 해야 할 것 (보안)
- (시크릿 발견 시 — 사람이 처리)

## 권장 (사용자 승인 필요)
- [ ] .gitignore에 OOO 추가
- [ ] OOO 파일을 OOO로 이동 (이유: ...)
- [ ] README에 실행 예시 추가
- [ ] requirements.txt 또는 pyproject.toml 정리

## 선택적
- ...
```

---

## Phase 5 — Commit

### Vault

```bash
cd <VAULT_PATH>
git add 1_Projects/<PROJECT_NAME>/
git commit -m "<PROJECT_NAME>: status snapshot + README sync"
git push
```

### Code repo

이 라운드에서는 코드 repo에 어떤 변경도 만들지 않는다. push할 것 없음.

---

## 보고 형식

작업 끝나면 사람에게 다음을 한 메시지로 보고:

1. 보고서 경로 3개 (Status_Snapshot, README, Cleanup_Proposal)
2. 발견한 가장 중요한 3가지
3. 사람에게 결정이 필요한 항목 목록
