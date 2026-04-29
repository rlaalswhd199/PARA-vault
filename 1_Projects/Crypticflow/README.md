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

## 로그

### 2026-04-29
- Status snapshot 작성, [[Status_Snapshot_2026-04-29]]
- Lever arm effect 분석 및 해결 시도 4가지 정리, [[Lever_Arm_Effect_Analysis]]
- 관련 논문 8편 Reading Notes 작성 및 Reading_Notes/ 이관

### 2026-04-29 (실험 업데이트)
- Overfit test 실패 원인 확인: seed 문제 (seed 다양화 / dataset 확장으로 해결)
- 현재 전체 데이터셋(1587 curated pair)으로 full training 진행 중
