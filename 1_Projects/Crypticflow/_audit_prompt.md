# Project A — Audit Prompt (Claude Code on server)

> 서버에서 Claude Code 실행 후 이 파일 내용을 그대로 붙여넣으세요.
> 실행 전 아래 placeholder 4개만 본인 환경에 맞게 교체하세요.

## 실행 전 교체할 placeholder

| Placeholder | 의미 | 예시 |
|------------|------|------|
| `<VAULT_PATH>` | 서버에서 vault clone한 경로 | `~/research/PARA` |
| `<CODE_PATH>` | Project A 코드 repo의 절대 경로 | `~/code/proj-a` 또는 실제 위치 |
| `<DATE>` | 오늘 날짜 (YYYY-MM-DD) | `2026-04-29` |

---

## (이 아래를 Claude Code에 붙여넣기)

너는 지금 공용 GPU 서버에서 동작 중이고, 다음 두 디렉토리에 접근할 수 있다:

- **Vault**: `<VAULT_PATH>` — 보고서를 쓸 곳
- **Code repo**: `<CODE_PATH>` — 분석 대상 (Project A)

먼저 `<VAULT_PATH>/CLAUDE.md` 와 `<VAULT_PATH>/1_Projects/Project_A/README.md` 를 읽고 vault 쪽 컨텍스트를 잡아라. 그 다음 아래 5단계를 순서대로 진행하라.

### 절대 규칙

1. **코드 repo의 파일을 지우거나 이동·이름변경 하지 마라**. `rm`, `mv`, `git clean`, `git reset --hard` 모두 금지.
2. `.gitignore`는 추가만 가능, 기존 줄 삭제 금지.
3. **시크릿이 발견되면 보고만 하고 만지지 마라.** key는 사람이 폐기·재발급해야 함.
4. 코드 repo에는 이 라운드에서 어떤 변경도 만들지 마라. vault에만 쓴다.
5. 보고서는 **한국어**로 작성, 코드·경로·git 출력은 원문 그대로.

### Phase 1 — 분석 (read-only)

```bash
cd <CODE_PATH>

# 구조
tree -L 3 -I '__pycache__|*.egg-info|.venv|venv|node_modules|wandb|checkpoints|logs|data|.git' 2>/dev/null \
  || find . -maxdepth 3 -not -path '*/\.*' | sort

# 의존성·진입점
ls pyproject.toml requirements*.txt environment*.yml setup.py 2>/dev/null
find . -maxdepth 4 \( -name 'train*.py' -o -name 'main.py' -o -name 'run*.py' -o -name 'eval*.py' \) -not -path '*/\.*' 2>/dev/null

# git 상태
git log --oneline -20
git branch -a
git status
git remote -v

# 위험 파일
git ls-files | grep -E '\.(ckpt|pth|pt|bin|safetensors|h5|npy|npz|parquet|tfrecord|env)$' | head
git ls-files | grep -iE '(secret|api_?key|token|credential|\.env)' | head
```

수집한 정보를 정리해서 다음 단계로 진행.

### Phase 2 — 보고서 작성

`<VAULT_PATH>/1_Projects/Project_A/Status_Snapshot_<DATE>.md` 에 다음 항목을 한국어로:

- **한 줄 요약**: 코드와 README에서 추론한 것
- **현재 단계**: 마지막 commit·branch·진행도
- **디렉토리 구조** (주요 폴더)
- **진입점·실행 명령**
- **최근 커밋 흐름** (git log --oneline -10)
- **.gitignore 빠진 패턴** (Code_Repo_Template의 .gitignore와 비교)
- **보안·용량 사고 가능성**
- **vault로 이관 후보 노트** (코드 repo 안 README/docs/notes 중)
- **미완·TODO로 보이는 곳**

### Phase 3 — Vault README 채우기

`<VAULT_PATH>/1_Projects/Project_A/README.md` 의 placeholder를 **확인된 사실로만** 채워라:

- 시작일 (`git log --reverse --format=%ai | head -1`)
- 현재 단계 (Status Snapshot 요약)
- 한 줄 설명
- 코드 repo URL (`git -C <CODE_PATH> remote get-url origin`)
- 로그 섹션에 `<DATE>` 항목으로 "Status snapshot 작성, [[Status_Snapshot_<DATE>]]" 추가

모르는 항목은 비워둬라. 추측으로 채우지 마라.

### Phase 4 — Cleanup 제안서

`<VAULT_PATH>/1_Projects/Project_A/Cleanup_Proposal.md` 에:

- **즉시 (보안)**: 시크릿이 commit돼 있으면 여기
- **권장 (승인 필요)**: .gitignore 추가, 파일 이동, README 보강 등
- **선택적**: 코드 정리, requirements 정렬 등

각 항목에 "이유"와 "예상 영향" 한 줄씩.

### Phase 5 — Commit

```bash
cd <VAULT_PATH>
git status
git add 1_Projects/Project_A/
git commit -m "Project_A: status snapshot + README sync (<DATE>)"
git push
```

코드 repo에는 push 하지 않는다.

### 마무리 보고

작업 끝나면 한 메시지로:

1. 생성된 3개 파일 경로
2. 발견한 가장 중요한 3가지
3. 사람의 결정이 필요한 항목 목록
