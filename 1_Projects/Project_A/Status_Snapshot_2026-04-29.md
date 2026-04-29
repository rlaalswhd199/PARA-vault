# Status Snapshot — 2026-04-29

## 한 줄 요약

Apo → Holo 단백질 구조 변화 예측 모델(CrypticFlow)로, Flow Matching + Transformer 기반 backbone velocity 예측을 구현하고 현재 오버핏 실험을 통해 모델 학습 가능성을 검증 중인 단계.

---

## 현재 단계

- **Branch**: `main` (origin/main과 동기화됨)
- **마지막 커밋**: `66484ac Clean vanilla training path and add overfit configs`
- **진행도**: 오버핏 실험 단계 완료 → 풀 데이터셋(1587 curated pair) 학습 실험 진행 중
- **주요 이슈**: `git status`상 configs/overfit/*.yaml, s_code/overfit/*.sh 등 다수 파일이 untracked 또는 deleted 상태 (로컬 정리 작업 진행 중)

---

## 디렉토리 구조 (주요 폴더)

```
crypticflow/
├── model/              # 핵심 모델 코드
│   ├── crypticflow.py  # 최상위 Flow Network
│   ├── transformer.py  # TransformerFlowNetwork
│   ├── encoder.py      # PLFeature + ESM-3 conditioning
│   └── ode_solver.py   # ODE 샘플링 (Euler 등)
├── data/
│   ├── dataset.py      # 데이터셋 (modified, unstaged)
│   ├── preprocess_pdb.py (modified, unstaged)
│   ├── curate_d3pm.py  (untracked)
│   └── ...             # 여러 전처리 스크립트 (untracked)
├── configs/
│   ├── d3pm_train.yaml
│   ├── transformer_full_vanila_2.yaml
│   ├── transformer_full_curated_6000ada.yaml (untracked)
│   └── overfit/        (untracked 폴더)
├── s_code/             # SLURM 제출 스크립트
│   └── overfit/        (untracked 폴더)
├── scripts/            # 분석 스크립트 (untracked)
├── docs/               # 아키텍처 문서
│   ├── crypticflow_architecture.md
│   ├── lever_arm_solutions.md
│   └── architecture.md (untracked)
├── reports/            # lever-arm 실험 리포트 (2026-02-23)
├── checkpoints/        # 학습된 모델 (gitignore됨, 31 GB)
├── train.py            # 진입점 (modified, unstaged)
├── requirements.txt
└── environment.yml
```

---

## 진입점·실행 명령

```bash
# 로컬 학습
python train.py --config configs/d3pm_train.yaml

# SLURM 제출 (GPU: 6000ada)
sbatch s_code/crypticflow_train_curated_6000ada.sh

# 오버핏 테스트
sbatch s_code/overfit/  # 각종 실험별 스크립트
```

---

## 최근 커밋 흐름 (git log --oneline -10)

```
66484ac Clean vanilla training path and add overfit configs
6a2f88b feat: add overfit experiments, analysis scripts, and architecture docs
0185e1e fix: replace ADR direction loss with radian-aware smooth L1
e846bcf feat: implement ADR (Anti-Drift Rectification) loss for Xt mode
094f591 feat: add beta clamping in adaLN, NaN checkpoint reload, and overfit experiments
9d9c6e7 fix: backbone 기준 num_nodes/validation 통일 및 학습 스크립트 수정
e5f15e5 exp: apo-only conditioning to eliminate train-test distribution mismatch
af3c068 feat: implement FAPE loss (Experiment B) for Cartesian coordinate supervision
b4356e4 perf: Reduce WandB logging overhead for faster training
a3a0731 fix: Lever-arm fixes and remove Kabsch RMSD coord loss
```

흐름 해석:
- FAPE loss 실험 → ADR loss 실험 → 바닐라 path 정리 순서로 진행
- loss 설계가 반복적으로 변경되고 있음 → 아직 최적 loss 미확정

---

## .gitignore 빠진 패턴 (템플릿 대비)

| 패턴 | 템플릿에 있음 | 현재 repo | 비고 |
|---|---|---|---|
| `*.onnx` | ✅ | ❌ | 모델 export시 필요 |
| `*.bin` | ✅ | ❌ | HuggingFace 모델 등 |
| `*.safetensors` | ✅ | ❌ | 최신 모델 포맷 |
| `weights/` | ✅ | ❌ | 별도 weight 폴더 |
| `data/` (디렉토리) | ✅ | ❌ | 주의: 현재 data/에 코드 있음, 전체 제외 불가 |
| `*.err` | ✅ | ❌ | SLURM 에러 로그 |
| `*.out` | ✅ | ❌ | SLURM 출력 로그 |
| `outputs/cache/` | ✅ | ❌ | 캐시 디렉토리 |
| `reports/` | ❌ | ❌ | 실험 리포트 — 추가 고려 필요 |
| `results/` | ✅ | ✅ | 현재 있음 |

---

## 보안·용량 사고 가능성

- **시크릿**: `git ls-files`로 검색한 결과 커밋된 API key·credential 없음. `.env`도 gitignore됨. **위험 없음**.
- **대용량 바이너리**: `checkpoints/` 디렉토리가 **31 GB**. gitignore에 포함되어 있어 추적되지 않음. 단, 로컬 디스크 공간 주의.
- **Untracked 파일 누적**: configs/overfit/, s_code/overfit/, scripts/ 등 다수 untracked 파일이 있고, configs/overfit/*.yaml이 동시에 `deleted` 상태(로컬에서 삭제됨)로 표시됨. 이는 git 이력과 로컬 상태의 불일치를 의미하며, 실수로 `git checkout .`을 실행하면 작업 중인 파일이 사라질 수 있음.
- **공용 서버**: CLAUDE.md에 `chmod 700` 권고가 있으나 실제 권한 설정 여부 미확인.

---

## Vault 이관 후보 노트

코드 repo 내에 설계 문서·실험 리포트가 있어 vault로 옮기기 좋은 후보들:

| 파일 | 내용 | 이관 적합성 |
|---|---|---|
| `docs/crypticflow_architecture.md` | 전체 아키텍처 설명 (Mermaid 포함) | ✅ 높음 |
| `docs/lever_arm_solutions.md` | lever-arm 문제 해결 방안 | ✅ 높음 |
| `docs/architecture.md` | 바닐라 모델 아키텍처 (untracked) | ✅ 높음 |
| `reports/lever_arm_2026-02-23/` | lever-arm 실험 전체 리포트 5개 파일 | ✅ 높음 |
| `README.md` | 짧은 한 줄 설명 | 보완 후 이관 가능 |

---

## 미완·TODO로 보이는 곳

1. **loss 설계 미확정**: FAPE → ADR → 바닐라 순으로 실험 중, 최적 loss 아직 결론 없음
2. **Untracked 파일 정리 미완**: configs/overfit/, s_code/overfit/, scripts/ 가 commit되지 않음
3. **data/dataset.py, data/preprocess_pdb.py**: 수정됐으나 unstaged 상태 — 변경 내용 커밋 필요
4. **train.py**: 수정됐으나 unstaged 상태
5. **평가(eval) 스크립트 없음**: eval*.py가 find 결과에 없음 — 정량 평가 미구현 가능성
6. **configs/overfit/*.yaml**: git에는 있으나 로컬에서 deleted 상태 — 정리 필요
7. **docs/architecture.md**: untracked 상태 — commit 필요
