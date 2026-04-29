# Git Workflow — Vault ↔ 코드 repo ↔ 머신 간 동기화

> 공용 서버 + 로컬 데스크탑 + 노트북 사이에서 vault와 코드 repo를
> 어떻게 일관되게 유지할지 정리한 문서.

---

## 1. 두 종류의 repo

| 종류 | 위치 (예시) | 들어가는 것 | 들어가지 않는 것 |
|------|------------|------------|----------------|
| **PARA vault** (`para-vault`) | 모든 머신의 `~/Documents/PARA/` | .md 노트, .tex 원고, CLAUDE.md, 템플릿 | 코드, 체크포인트, wandb 로그, 데이터셋 |
| **프로젝트 코드 repo** (`proj-a`, `proj-b`, …) | `~/code/proj-x/` | `src/`, `configs/`, `scripts/`, 실험 결과(텍스트), figures 생성 코드 | 체크포인트(.ckpt), wandb 캐시, 데이터셋 |

vault repo는 **하나**, 코드 repo는 **프로젝트 수만큼**.

---

## 2. 머신별 무엇을 clone하는가

| 머신 | vault | 코드 repo |
|------|-------|----------|
| 로컬 데스크탑 (Obsidian) | ✅ 항상 | 작업 중인 프로젝트만 |
| 노트북 (이동 중 노트) | ✅ 항상 | 보통 ❌ |
| 공용 GPU 서버 | ✅ (단, `chmod 700` 디렉토리 안) | 실험 중인 프로젝트만 |

---

## 3. 공용 서버 보안 — `chmod 700` 필수

공용 서버에서는 본인 외에 다른 사용자가 home 또는 작업 디렉토리를 들여다볼 수 있는 경우가 흔합니다. clone 직전에 권한을 잠그세요.

```bash
# 한 번만 (서버 첫 셋업 시)
mkdir -p ~/research
chmod 700 ~/research        # owner만 r/w/x
chmod 700 ~                  # home 자체도 700이면 더 안전 (관리자 정책 확인)

# clone은 여기 안에서
cd ~/research
git clone git@github.com:<user>/para-vault.git PARA
git clone git@github.com:<user>/proj-a.git    code/proj-a
chmod -R go-rwx PARA code/proj-a   # 혹시 모를 부모 권한 누수 차단
```

`umask 077`을 `~/.bashrc`에 추가하면 이후 새로 만드는 파일들이 자동으로 owner-only가 됩니다.

---

## 4. 일상 동기화 리듬

### 작업 시작 시 (어느 머신이든)

```bash
cd ~/Documents/PARA && git pull --rebase
cd ~/code/proj-a    && git pull --rebase
```

`pull --rebase`는 머지 커밋이 안 쌓이고 히스토리가 깔끔합니다.

### 작업 중

- 의미 있는 단위마다 commit (실험 1 run 종료, 미팅 노트 정리, 섹션 한 챕터 등)
- 다른 머신으로 옮기기 전 반드시 `git push`

### 자리 뜨기 전

```bash
git status          # untracked 없는지 확인
git add -A
git commit -m "<짧은 메시지>"
git push
```

---

## 5. 충돌 회피 — "쓰기 zone" 분리 규칙

같은 파일을 여러 머신에서 동시에 편집하지 않는 게 가장 큰 원칙입니다. PARA 구조 안에서 권장되는 zone:

| 영역 | 주로 편집하는 머신 |
|------|-------------------|
| `2_Areas/Daily_Plans/`, `Meeting_Minutes/` | 로컬 데스크탑 / 노트북 |
| `3_Resources/Papers/` (Reading Notes) | 로컬 (Obsidian으로 작성) |
| `Paper_Writing/Project_X/` | 로컬 (초안), 서버 (figure 경로 참조 시 가끔) |
| `1_Projects/Project_X/README.md` 로그 | 로컬 + 서버 — 단, 같은 줄 동시 편집 X |
| 코드 repo `src/`, `Experiments/` | 서버 |

서버에서 vault를 **읽기 위주**로 쓰고 (CLAUDE.md, README, Reading_Notes 참고), 쓰기는 코드 repo 위주로 하면 충돌이 거의 안 생깁니다.

---

## 6. 자주 쓰는 시나리오

### A. 로컬에서 새 프로젝트 코드 repo 만들기

```bash
cd ~/code
mkdir proj-e && cd proj-e
git init
cp ~/Documents/PARA/_Templates/Code_Repo_Template/.gitignore .
cp -r ~/Documents/PARA/_Templates/Code_Repo_Template/* .
git add -A && git commit -m "init proj-e"

gh repo create proj-e --private --source=. --remote=origin --push
# (gh CLI 없으면 GitHub 웹에서 만들고 git remote add origin <url>; git push -u origin main)
```

### B. 서버에서 처음 클론

```bash
mkdir -p ~/research && chmod 700 ~/research && cd ~/research
git clone git@github.com:<user>/para-vault.git PARA
git clone git@github.com:<user>/proj-a.git    code/proj-a

# 작업
tmux new -s proj-a
cd ~/research/code/proj-a
python scripts/train.py --config configs/exp001.yaml
```

### C. 서버에서 실험 끝난 후

```bash
cd ~/research/code/proj-a
git add -A
git commit -m "exp001: baseline 64ch, val acc 0.812"
git push

# 핵심 결과를 vault에도 반영하고 싶으면
cd ~/research/PARA
$EDITOR 1_Projects/Project_A/README.md   # 로그 한 줄 추가
git add -A && git commit -m "log: Project_A exp001 result" && git push
```

### D. 다음 날 로컬에서 이어 받기

```bash
cd ~/Documents/PARA && git pull
cd ~/code/proj-a    && git pull
# Obsidian 열고 Project_A/README.md에서 어제 서버에서 추가한 로그 확인
```

---

## 7. 충돌 났을 때 (그래도 가끔 남)

```bash
git pull --rebase
# CONFLICT 표시된 파일 열어서 <<<<<<< ======= >>>>>>> 마커 정리
git add <conflicted-file>
git rebase --continue
git push
```

`Daily_Plans/`처럼 그날 만든 파일은 충돌이 거의 없고, README 로그처럼 양쪽에서 줄을 추가하는 경우 충돌 → 두 줄 다 살리면 끝.

---

## 8. Overleaf 연동 (선택)

vault repo를 그대로 Overleaf의 Git remote로 연결할 수 있습니다.

1. Overleaf 프로젝트 생성 → "Git" 메뉴에서 `https://git.overleaf.com/<id>` 확보
2. 로컬에서:
   ```bash
   cd ~/Documents/PARA
   git remote add overleaf https://git.overleaf.com/<id>
   git push overleaf main
   ```
3. Overleaf에서 빌드 root을 `Paper_Writing/Project_A/main.tex` 로 설정
4. 양방향: Overleaf 수정 → `git pull overleaf main`, 로컬 수정 → `git push overleaf main`

여러 논문을 한 vault repo에 두면 push할 때마다 모든 논문이 다 동기화됩니다 — 보통 문제 없지만 의도적으로 분리하고 싶으면 별도 paper repo로 빼야 합니다.

---

## 9. 절대 git에 올리면 안 되는 것

- 학교/연구실 비공개 데이터셋
- API 키, wandb token, SSH key
- 학생 등록번호·여권 번호 같은 PII
- `.env` 파일

`.gitignore`에 미리 넣어두는 것이 안전. 사고로 push했다면 `git filter-repo`로 히스토리에서 제거하고 키는 즉시 폐기·재발급.
