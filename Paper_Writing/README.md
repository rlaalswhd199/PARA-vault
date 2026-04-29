# Paper_Writing

여러 프로젝트의 논문 원고(.tex / .md)를 한 곳에서 관리합니다.

## 폴더 구조

```
Paper_Writing/
├── Project_A/
│   ├── main.tex
│   ├── math_commands.tex
│   └── Sections/
│       ├── abstract.tex
│       ├── introduction.tex
│       ├── method.tex
│       ├── experiments.tex
│       └── analysis.tex
├── Project_B/
├── Project_C/
└── Project_D/
```

## 코드 repo와의 관계

- **원고(.tex / .md)** 는 vault에서 관리 — Obsidian으로 .md 초안 작성, Cowork이 직접 편집
- **figure 생성 스크립트, 실험 결과 표, bib 자동 생성** 은 각 프로젝트 코드 repo (`~/code/proj-x/`)에 두기
- 결과 figure는 코드 repo의 `outputs/figures/` 에서 생성 → `Paper_Writing/Project_X/figures/` 로 복사하거나 git에서 cherry-pick

## Overleaf 연동

`Paper_Writing/Project_X/` 단위로 Overleaf의 "Git" 탭에서 sub-path로 묶을 수는 없기 때문에, Overleaf 연동이 필요한 프로젝트는 둘 중 하나:

1. **이 vault repo를 그대로 Overleaf git remote로 연결** — 단순. 단, Overleaf 빌드 root을 `Paper_Writing/Project_X/main.tex`로 명시 필요.
2. **별도 paper repo 분리** — 한 논문이 학회 + 저널 양쪽에 갈 때만 권장.

## 빌드

```
cd Paper_Writing/Project_A
latexmk -pdf main.tex
```

`.aux`, `.log`, `.bbl`, `.fdb_latexmk` 등은 `.gitignore`로 무시 처리됨.
