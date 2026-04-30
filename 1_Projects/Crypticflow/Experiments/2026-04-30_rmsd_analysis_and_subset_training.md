# 실험 로그: RMSD 분석 및 데이터 서브셋 학습 (2026-04-30)

## 배경

기존 full 데이터 학습 (job 32408, `full_curated_6000ada`) 결과에서 val RMSD가 6.7 Å 수준에서 plateau. 원인 분석 및 개선 실험 진행.

---

## 1. RMSD 계산 버그 발견 및 수정

### 문제
- 기존 분석 스크립트(`val_rmsd_analysis.py`, `dataset_rmsd_stats.py`)가 **centroid 정렬만 하고 Kabsch rotation 없이** RMSD를 계산하고 있었음
- 동일 파일에서 centroid-only: **38.95 Å** vs Kabsch: **0.34 Å** → 완전히 다른 값

### 수정
- `ca_rmsd()` 함수에 Kabsch alignment (SVD 기반 최적 회전행렬) 추가
- `torch.linalg.svd` → reflection 보정 (det < 0 시 flip) → 회전 후 RMSD 계산

### 모델 val RMSD 계산 (`compute_pairwise_rmsd`)
- `utils/visualization.py`의 `compute_pairwise_rmsd`는 이미 Kabsch alignment 적용 중 (`align=True` default)
- 모델이 보고하는 val RMSD는 정확한 Kabsch-aligned RMSD임

---

## 2. 전체 데이터셋 GT RMSD 분포 분석

**스크립트**: `analysis/dataset_rmsd_stats.py`
**결과 그래프**: `checkpoints/full_curated_6000ada_job32408/analysis/dataset_rmsd_distribution.png`

| Split | N | Mean | Median |
|-------|---|------|--------|
| Train | 6,742 | 1.42 Å | 0.69 Å |
| Val | 842 | 1.24 Å | 0.68 Å |
| Test | 844 | 1.58 Å | 0.68 Å |
| **전체** | **8,428** | **1.42 Å** | **0.69 Å** |

**구간 분포 (전체)**:
- 0~3 Å: **94.2%** (7,943개) — 대부분 rigid 케이스
- 3~7 Å: 3.3% (282개)
- 7~15 Å: 0.7% (58개)
- 15~30 Å: 1.3% (107개)
- 30+ Å: 0.5% (38개)

**핵심**: 데이터의 94%가 apo ≈ holo (거의 변화 없음). flexible 케이스는 소수.

---

## 3. Val GT vs Pred 교차 분석

**스크립트**: `analysis/val_rmsd_analysis.py`, `analysis/val_rmsd_cross_analysis.py`
**결과 그래프**: `checkpoints/full_curated_6000ada_job32408/analysis/val_rmsd_cross_analysis.png`

### GT 구간별 성능 (Kabsch 기준)

| GT 구간 | N | GT avg | Pred avg | Err abs |
|---------|---|--------|----------|---------|
| 0~1 Å | 571 (67.8%) | 0.51 Å | 5.49 Å | 4.98 Å |
| 1~2 Å | 172 (20.4%) | 1.33 Å | 8.31 Å | 6.98 Å |
| 2~3 Å | 50 | 2.38 Å | 9.76 Å | 7.37 Å |
| 3~7 Å | 33 | 4.12 Å | 10.99 Å | 6.87 Å |
| 7~15 Å | 7 | 10.11 Å | 10.32 Å | 3.81 Å ← 가장 잘 맞춤 |
| 15+ Å | 9 | 22.55 Å | 16.37 Å | 7.25 Å |

### 핵심 발견
- 모델이 **"아무것도 안 변한다"를 학습하지 못함** — GT 0~1 Å 케이스 571개 중 29개(5%)만 pred 0~2 Å로 올바르게 예측
- 잘 맞춘 케이스(abs err < 1 Å): **17개 (2%)** 뿐
- 모든 오차 방향이 양수 (+) — 항상 실제보다 더 크게 움직임
- Rigid 과대예측: GT <3 Å 케이스 793개 중 114개(14.4%)가 pred >10 Å

---

## 4. 데이터 서브셋 학습 실험

### 실험 설계
GT apo-holo RMSD 기준으로 데이터를 두 그룹으로 분리:

| 그룹 | 기준 | 파일 수 | 디렉토리 |
|------|------|---------|---------|
| Flexible | ≥ 3 Å | 485개 (5.8%) | `cryptic_pocket_DB_v2_flexible_3A` |
| Rigid | < 3 Å | 7,943개 (94.2%) | `cryptic_pocket_DB_v2_rigid_3A` |

### Flexible 학습 결과 (job 32502, 완료)

- **Config**: `configs/transformer_flexible_3A.yaml` (batch=16, epochs=1000, xt_input=true)
- **데이터 GT RMSD**: mean 10.97 Å, median 5.38 Å, max 50.23 Å

| Epoch | Val RMSD |
|-------|---------|
| 0 | 37.1 Å |
| 50 | 13.7 Å |
| **140 (최저)** | **12.7 Å** |
| 200~ | 15~17 Å (oscillation, overfitting) |
| 990 (최종) | 15.6 Å |

**결론**: epoch 140 이후 overfitting. 485개 데이터로는 일반화 한계. 그러나 RMSD 자체가 높은 건 데이터 부족보다 **loss 구조적 한계** 가능성이 큼.

### Rigid + Flexible 학습 (진행 중)
- Rigid job 32556 (heavy 파티션, 실행 중)
- Flexible job 32555 (heavy 파티션, 실행 중)

---

## 5. Job 32557 실패 원인 분석

**원인**: `crypticflow_train_full.sh`의 CONFIG 기본값이 존재하지 않는 파일을 참조
```
CONFIG="${CONFIG:-$PROJECT_DIR/configs/transformer_full_curated_6000ada.yaml}"
```
→ 파일 없음 → `os.path.exists()` False → YAML 미로드 → argparse default 경로(`/home/mjkim/Project/apoholo_IITP/...`) 사용 → FileNotFoundError

**수정**: CONFIG를 `transformer_full_curated.yaml`로 변경

---

## 6. 현재 가설 및 다음 실험 방향

### 근본 원인 가설
- **backbone velocity loss**가 velocity field(= holo - apo 방향)를 학습하는데, "no movement" 케이스(apo ≈ holo)에서 velocity target ≈ 0이지만 모델이 이를 표현하지 못함
- Flow matching이 임의 초기 분포에서 시작하므로, ODE가 10 step 동안 불필요하게 구조를 이동시킴

### 다음 실험 후보
1. `rmsd_loss_weight > 0` — pred-holo RMSD를 직접 loss에 추가
2. `xt_input: true` (이미 현재 config에 적용됨) — noisy intermediate 입력으로 flow 방향 개선
3. `ode_steps` 축소 (10 → 5 또는 3)
4. 더 많은 flexible 데이터 확보 (현재 485개가 너무 적음)

---

## 관련 파일

| 파일 | 설명 |
|------|------|
| `analysis/dataset_rmsd_stats.py` | 전체 데이터셋 GT RMSD 분포 (Kabsch) |
| `analysis/val_rmsd_analysis.py` | Val GT vs Pred RMSD 구간별 분석 |
| `analysis/val_rmsd_cross_analysis.py` | GT × Pred 교차 분석 + confusion matrix |
| `scripts/filter_flexible_db.py` | 3Å 이상 파일 필터링 및 복사 |
| `configs/transformer_flexible_3A.yaml` | Flexible 서브셋 학습 config |
| `configs/transformer_rigid_3A.yaml` | Rigid 서브셋 학습 config |
