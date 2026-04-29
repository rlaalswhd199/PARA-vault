# {{ProjectName}} — Code Repo

> 이 repo는 PARA vault의 [[1_Projects/{{ProjectName}}/README]]에 대응하는 **코드·실험** 저장소.
> vault 노트와 분리되어 있으며, vault에는 결과 요약과 reading note만 들어갑니다.

## 폴더 구조

```
proj-x/
├── README.md
├── pyproject.toml / requirements.txt
├── src/                  # 라이브러리 코드
├── configs/              # YAML/JSON 실험 설정
├── scripts/              # 실행 스크립트 (train, eval, ablate)
├── notebooks/            # 분석용 Jupyter
├── Experiments/          # 실험 결과 (logs, txt, csv) — 무거운 건 .gitignore
├── outputs/figures/      # 논문에 들어갈 figure
└── .gitignore
```

## 환경 셋업

```bash
python -m venv .venv && source .venv/bin/activate
pip install -e .
# 또는
pip install -r requirements.txt
```

## 실험 실행 (예시)

```bash
tmux new -s proj-x
python scripts/train.py --config configs/exp001.yaml
# wandb run URL: ...
```

## vault과의 연결

- 결과 요약은 vault의 `1_Projects/{{ProjectName}}/README.md` 로그 섹션에 한 줄
- figure는 `outputs/figures/` 에서 vault의 `Paper_Writing/{{ProjectName}}/figures/` 로 복사 또는 symlink
- 논문 .tex는 vault에서 작성 → 이 repo에는 figure/표 생성 코드만
