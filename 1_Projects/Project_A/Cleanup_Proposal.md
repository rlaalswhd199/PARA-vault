# Cleanup Proposal — 2026-04-29

## 즉시 (보안)

없음. `git ls-files`로 API key·credential·`.env` 등을 검색한 결과 커밋된 시크릿 없음. `.env`는 gitignore에 포함돼 있음.

---

## 권장 (승인 필요)

### 1. `.gitignore`에 패턴 추가

현재 gitignore와 Code_Repo_Template 비교 결과 누락된 패턴:

```gitignore
# 추가 권장
*.onnx
*.bin
*.safetensors
weights/
*.err
*.out
outputs/cache/
```

- **이유**: 템플릿 기준 표준 패턴 누락. 특히 `*.out`/`*.err`는 SLURM 로그가 s_outs/가 아닌 repo 내에 생길 경우 추적될 위험.
- **예상 영향**: 기존 tracked 파일 없으므로 추가만 하면 됨. 기존 줄 삭제 없이 append 가능.

### 2. Untracked 파일 일괄 commit

현재 untracked 상태인 파일들을 commit해야 로컬-원격 상태가 동기화됨:

- `configs/overfit/` (overfit 실험 설정)
- `configs/transformer_full_curated_6000ada.yaml`
- `s_code/overfit/`, `s_code/crypticflow_train_curated_6000ada.sh`, `s_code/crypticflow_preprocess_curated_pt.sh`
- `data/curate_d3pm.py`, `data/curate_pair_pdb_db.py`, `data/d3pm_patchr_collect.py`, `data/d3pm_patchr_prep.py`, `data/make_features_d3pm.py`, `data/preprocess_d3pm.py`, `data/analyze_d3pm_gaps.py`
- `scripts/analyze_16pair_overfit.py`, `scripts/compare_pair_pdbs.py`
- `docs/architecture.md`

- **이유**: git status가 매우 지저분한 상태. 분실 위험 및 협업 시 혼란.
- **예상 영향**: 원격 repo에 실험 내역이 보존됨. 이후 추적 가능.

### 3. Unstaged 변경 파일 commit 또는 stash

- `data/dataset.py`, `data/preprocess_pdb.py`, `train.py` — 수정됐으나 unstaged

- **이유**: 로컬에만 존재하는 변경사항. 서버 재시작이나 실수로 `git restore`하면 손실 가능.
- **예상 영향**: 원격 백업 확보. 실험 재현성 향상.

### 4. `configs/overfit/*.yaml` deleted 상태 정리

git에는 tracked돼 있으나 로컬에서 삭제된 파일들:
- `configs/overfit_fape.yaml`, `overfit_position_weight.yaml`, `overfit_remannian.yaml` 등 12개

선택지:
- (A) `git rm configs/overfit_*.yaml` 으로 삭제를 commit에 반영
- (B) `git restore configs/overfit_*.yaml` 으로 파일 복원

- **이유**: 현재 상태는 git이 "삭제됐다"고 인식하지만 commit되지 않은 상태. 혼란 야기.
- **예상 영향**: git status 깔끔해짐. 단, (A) 선택 시 해당 config 영구 삭제.

### 5. Vault로 실험 리포트 이관

`reports/lever_arm_2026-02-23/` 5개 파일을 vault `1_Projects/Project_A/Reading_Notes/` 또는 별도 `Experiments/` 폴더로 이관 검토.

- **이유**: 설계 결정·실험 분석 문서는 vault에 두는 게 PARA 원칙에 맞음.
- **예상 영향**: 코드 repo가 가벼워짐. 코드 repo에는 코드만 남음.

---

## 선택적

### 6. `docs/` 내 아키텍처 문서 vault 동기화

`docs/crypticflow_architecture.md`, `docs/lever_arm_solutions.md`를 vault `1_Projects/Project_A/`에 복사 or 링크.

- **이유**: 아키텍처 이해를 위해 vault에서도 접근 가능하면 편리.
- **예상 영향**: 코드 repo 원본은 그대로 유지, vault에 사본 추가.

### 7. README.md 보강

현재 README.md가 한 줄(`IITP apo to holo conformation change model`)만 있음.

- **이유**: 협업자나 미래의 자신을 위한 최소한의 실행 방법·의존성 설명 필요.
- **예상 영향**: 온보딩 시간 단축.

### 8. eval 스크립트 작성

현재 평가용 진입점(`eval*.py`)이 없음.

- **이유**: 학습된 모델의 정량 평가(RMSD, TM-score 등)를 위한 스크립트 필요.
- **예상 영향**: 실험 결과를 수치로 비교 가능해짐.
