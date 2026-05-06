# Project A — CrypticFlow

## 메타

- **시작일**: 2025-12-11
- **데드라인**: YYYY-MM-DD (학회/저널)
- **타겟 venue**: ICLR
- **현재 단계**: 오버핏 실험 완료 → 풀 데이터셋(1587 curated pair) 학습 실험 진행 중
- **공동 연구자**: 김민종

## 한 줄 설명

Flow Matching + Transformer 기반으로 단백질의 Apo → Holo 구조 변화(conformation change)를 예측하는 모델. ESM-3 임베딩과 물리화학적 특성으로 conditioning하여 backbone 원자(N, CA, C, O) 9차원 표현의 velocity를 예측.

## 핵심 가설 / 기여

1. 단백질의 백본 원자들을 internal coordinate space로 옮긴 후 flowmatching 학습시키면, conformation change를 배워서 apo를 입력으로 holo를 생성하는 모델을 만들 수 있을 것이다.
2. overfit test를 통과하였음으로, 모델이 이면각과 각도 정보를 정확히 맞출 수 있다면 생성된 Holo와 정답 holo의 RMSD는 낮을 것이다.
3. SEASAMINE, SBAlign, FDBM 등의 모델 보다 성능이 뛰어나고, equivariance 를 만족시킬 수 있을 것이다.

## 마일스톤

- [ ] 관련 연구 서베이 — `Reading_Notes/` 채우기
- [ ] 베이스라인 재현
- [x] 메소드 구현 — Flow Matching + Transformer
- [x] Overfit test 통과 (seed 문제 해결 후)
- [ ] 실험 결과 정리
- [ ] 논문 초안 — `Paper_Writing/`
- [ ] 제출

## 코드 / 논문

- **코드 repo**: `git@github.com:rlaalswhd199/crypticflow.git` (서버 path: `/home/mjkim/project/crypticflow/`)
- **논문 원고**: [[../../Paper_Writing/Project_A/main]] (vault 내 `Paper_Writing/Project_A/`)

## 관련 노트

- [[../1_Projects/README]]
- [[../../3_Resources/Papers/Papers_Index]]

## 현재 상태 (2026-05-06)

- **Branch**: `main`
- **진행도**: 오버핏 실험 완료 → 풀 데이터셋(1587 curated pair) 학습 실험 진행 중
- **주요 이슈**: loss 설계 미확정 (FAPE → ADR → 바닐라 순으로 실험 중)

### 미완·TODO
1. loss 설계 미확정 — 최적 loss 아직 결론 없음
2. Untracked 파일 정리 미완: `configs/overfit/`, `s_code/overfit/`, `scripts/`
3. `data/dataset.py`, `data/preprocess_pdb.py`, `train.py` 수정됐으나 unstaged
4. 평가(eval) 스크립트 없음 — 정량 평가 미구현 가능성

---

## 디렉토리 구조

```
Crypticflow/
├── Reading_Notes/   # 논문 요약
├── Code_Notes/      # 코드 리뷰, 디버그 기록
├── Analysis/        # 분석 보고서
├── Experiments/     # 실험 설정/결과
└── README.md        # 이 파일
```

---

## 로그

### 2026-05-06
- 코드 전체 리뷰 진행 (train.py, dataset.py, model/*.py)
- 코드 정리: Interleaved sequence 흔적 제거, varlen 미사용 함수 제거, modulo → atan2 교체, Experiment A~F 레이블 제거
- `evaluate_full_rmsd`에 per_sample (pair_id, pdb_id) 정보 추가
- [[Code_Notes/Code_Review_2026-05-06]] 작성

### 2026-04-29
- Overfit test 실패 원인 확인: seed 문제 (seed 다양화 / dataset 확장으로 해결)
- 전체 데이터셋(1587 curated pair)으로 full training 시작
- Lever arm effect 분석 및 해결 시도 4가지 정리 → [[Analysis/Lever_Arm_Effect_Analysis]]
- 관련 논문 8편 Reading Notes 작성
