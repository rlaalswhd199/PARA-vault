# CrypticFlow 코드 리뷰 노트
작성일: 2026-05-06

---

## 1. 학습 설정 (train.py)

### CLI + YAML 우선순위
- `argparse` 기본값 → YAML → CLI 순서로 값이 결정됨
- CLI 입력값이 argparse 기본값과 같으면 YAML에 덮어씌워지는 한계 있음
- 모든 설정은 `args` 객체 하나에 통합됨

### DataLoader
- `num_workers=8` 설정이지만 dataset이 메모리에 preload되어 있어 실제 병목은 collate
- GPU util이 낮으면 workers 조정 또는 collate 최적화 필요

### NaN 처리
- step 레벨: 3회 연속 NaN → epoch 중단 (`nan_exploded=True`)
- epoch 레벨: `nan_exploded` 감지 → best checkpoint 복원 후 다음 epoch 계속
- `zero_grad()`로 오염된 gradient 초기화 (NaN은 누적되므로 반드시 필요)

### Gradient Clipping
- `clip_grad_norm_`의 반환값은 clipping 직전 norm → 학습 불안정성 모니터링 지표로 활용
- `total_grad_norm`에 누적 후 epoch 평균을 wandb에 기록

### Validation
- `@torch.no_grad()`: gradient 계산 끄기 → 메모리/속도 절약
- 1단계 loss는 `training_step` 재사용 → train/val loss 직접 비교 가능
- 학습 종료 후 `evaluate_full_rmsd`로 best model 기준 최종 RMSD 계산
  - interval 미스 보완 + best model 기준 재측정 두 가지 목적

---

## 2. 데이터셋 (dataset.py)

### 로딩 방식
- 초기화 시 전체 `.pt` 파일을 메모리에 preload → 학습 중 디스크 I/O 없음
- 유효성 검사: Apo/Holo 잔기 수 일치 필수 (Flow Matching의 1:1 대응 요건)

### PyG Data 객체
- 단백질 구조를 그래프로 표현하는 컨테이너
- 커스텀 필드 자유롭게 추가 가능 (`backbone`, `coord_CA`, `node_scalar` 등)
- `edge_index` 없이 backbone 내부 좌표를 직접 저장하는 방식 사용

### ESM embedding 처리
- shape이 `(N+2, 1536)` (BOS + 잔기 + EOS) — `num_nodes=N`과 불일치
- PyG Batch로 합칠 수 없어 collate에서 직접 `cat` → `(total_tokens, 1536)`
- 사용 시 `esm_batch` 인덱스로 단백질별 분리

---

## 3. 모델 아키텍처 (crypticflow.py, transformer.py)

### backbone 9-feature
- 컬럼: `[phi, psi, omega, tau, CA:C:1N, C:1N:1CA, 0C:1N, N:CA, CA:C]`
- 0~5: angular (circular, [-π, π])
- 6~8: distance (양수 실수, Å)
- `FEATURE_IS_ANGULAR` 상수로 구분

### register_buffer
- 학습되지 않는 상수 텐서를 모델에 등록
- `model.to(device)` 시 자동으로 device 이동
- `_is_angular` 마스크가 이 방식으로 등록됨

### t를 노드로 확장
- `t[apo_data.batch]`: 배치 인덱스로 각 잔기에 자기 단백질의 t값 복사
- PyG는 여러 단백질 노드를 하나의 긴 배열로 이어붙이기 때문에 필요

### Muon optimizer
- 2D 행렬 파라미터(Q/K/V/O)에만 적용, 나머지는 AdamW
- `torch.distributed` 초기화 필요 → 단일 GPU에서도 dummy 그룹 생성
- 파일 기반 초기화로 포트 충돌 방지

### Flash Attention
- `F.scaled_dot_product_attention`으로 자동 적용 (PyTorch 2.0+)
- 현재 masked 방식 사용 (padding 포함 후 attn_mask로 제외)
- varlen 방식 구현 시도 흔적 있었으나 제거됨 (데이터 길이 분포상 불필요)

### 가중치 초기화
- ReLU 전 레이어: Kaiming (He) init
- 나머지 Linear: Xavier init
- output_head 마지막: Small Normal (std=0.02) — 초기 velocity를 0 근처에서 시작

---

## 4. Loss (losses.py)

### Radian-aware Smooth L1
- angular 잔차: `atan2(sin(d), cos(d))`로 wrap (modulo 방식 대비 gradient 연속)
- distance 잔차: wrap 없이 그대로
- valid element 합계 / valid 개수 → 단백질 길이 무관 동일 스케일

### position-weighted loss
- `_radian_smooth_l1_per_residue`: 잔기별 `(L,)` loss 반환
- 앞쪽 잔기에 더 큰 가중치 (lever-arm 효과 반영)
- `weights[i] = (L-i) / sum(1..L)`

### Kabsch align (losses.py)
- 회전만 담당, 중심 이동 없음
- `batched_backbone_decode(center=True)`로 사전에 centroid가 원점 정렬된다고 가정

---

## 5. ODE Solver (ode_solver.py)

### Euler step
```
x_{n+1} = x_n + dt * v(x_n, t)
```
- 매 step 후 `_wrap_angular` 적용
  - angular(0~5): `atan2(sin, cos)` wrap
  - distance(6~8): `clamp(min=0)`
- wrap 없으면 각도 drift → NeRF 디코딩 NaN 발생

### velocity_field 클로저
- `featurizer`, `esm_embedding`을 클로저로 캡처
- ODE solver는 `velocity_field(backbone, t)`만 반복 호출
- `xt_input` 설정에 따라 xₜ 또는 x₀ 입력 선택

---

## 6. Encoder/Decoder (encoder.py)

### 두 가지 역할
1. **전처리**: PDB 3D 좌표 → 내부 좌표 (`.pt` 파일 생성 시)
2. **학습/추론**: 내부 좌표 → 3D 좌표 (RMSD, FAPE loss 계산 시)

### NeRF 디코딩
- 출력: `(B, 3*L, 3)` — N, CA, C 순서 (O 원자 없음)
- CA-only RMSD: 인덱스 `1, 4, 7, ...` (step=3)

---

## 7. 코드 정리 내역 (이번 세션)

| 파일 | 변경 내용 |
|---|---|
| `transformer.py` | Interleaved sequence 흔적 제거 (`* 2` 로직, 주석) |
| `transformer.py` | varlen Flash Attention 미사용 함수 3개 제거 |
| `losses.py` | `_modulo_with_wrapped_range` → `_wrap_angular` (atan2) 교체 |
| `losses.py`, `crypticflow.py` | Experiment A~F 레이블 제거 |
| `train.py` | `evaluate_full_rmsd`에 per_sample (pair_id, pdb_id, rmsd) 추가 |
