# Lever Arm Effect 해결 문헌 조사 보고서

**작성**: researcher agent (oh-my-claudecode:document-specialist)
**날짜**: 2026-02-23
**팀**: crypticflow-lever-arm

---

## 1. 문제 정의 및 문헌에서의 확인

**Lever arm effect는 공식적으로 인정된 문제임.** FoldingDiff (Wu et al., Nature Communications 2024) 논문이 이를 명시적으로 언급:

> "this framing allows for single-angle errors to significantly alter the overall generated structure — a sort of lever arm effect"

즉, torsion angle에서 작은 오차 하나가 체인 끝으로 갈수록 기하급수적으로 증폭되어 전체 구조를 왜곡하는 현상이며, 이는 NERF 기반 sequential reconstruction의 근본적 한계다. CrypticFlow의 Job 399에서 관찰된 현상 (angle loss 0.0004 → Cartesian RMSD 17.82Å) 이 바로 이 효과다.

---

## 2. 각 모델의 좌표 재구성 방식 비교

### 2.1 FoldingDiff (Torsion Angle Space)
- **방식**: 6개 backbone angle (3 bond + 3 dihedral) per residue를 sequential하게 NERF로 재구성
- **문제**: Lever arm effect 명시적 인정. 긴 단백질일수록 성능 저하 심각 (≤70 residues에서만 안정적)
- **해결 시도 없음**: "future work should explore geometrically-informed architectures"로만 언급
- **교훈**: CrypticFlow와 동일한 구조 → 동일한 문제 발생

### 2.2 FrameDiff / FoldFlow / Sesame (SE(3) Frame Space)
- **방식**: 각 residue를 SE(3) rigid frame (rotation R ∈ SO(3) + translation t ∈ ℝ³)으로 독립 표현
- **핵심**: Sequential chain reconstruction이 없음 → error accumulation 구조적 차단
- **Loss**: FAPE (Frame Aligned Point Error) = 각 residue의 local frame에서 측정된 거리 오차의 평균
- **Sesame (apo→holo 직접 관련)**: flow matching으로 apo→holo 변환 학습. SE(3) frame 사용 + FAPE + auxiliary pairwise distance loss 조합. CrypticFlow와 가장 유사한 task이나 표현 방식이 근본적으로 다름

### 2.3 AlphaFold2 Structure Module
- **방식**: 모든 residue frame을 global coordinate에서 독립적으로 예측 (chain constraint 의도적으로 위반 허용)
- **핵심 인사이트**: "peptide bond geometry is completely unconstrained — breaking this constraint enables local refinement of all parts of the chain without solving complex loop closure problems"
- **FAPE Loss**: 각 residue local frame 기준으로 원자 위치 오차를 측정 → global RMSD보다 stable
- **OpenFold 개선**: FAPE clamping을 batch 단위가 아닌 sample 단위로 적용 → 훈련 안정성 대폭 향상

### 2.4 RFdiffusion (SE(3) Diffusion)
- **방식**: C-alpha + N-C-alpha-C backbone frames를 직접 SE(3)에서 diffuse
- **Loss**: MSE on C-alpha atoms + backbone frames (FAPE가 아닌 MSE 사용 - unconditional generation에서 더 좋음)
- **Self-conditioning**: 이전 timestep 예측을 template으로 제공 → 훈련 안정성 향상

### 2.5 Torsion-Space Diffusion with Geometric Refinement (arxiv 2511.19184)
- **방식**: Torsion 공간에서 diffuse + 이후 post-processing refinement
- **Refinement 알고리즘 (200 iterations)**:
  1. Rg Scaling: `s = 1 + η_rg * (R_tgt/R_curr - 1)` 로 전체 구조 균일 스케일링
  2. Bond Restoration: 연속 residue 간 변위 벡터를 3.8Å로 정규화 (η_bond = 0.5)
- **결과**: Rg 오차 70% → 18.6% 감소, bond length 100% accuracy
- **한계**: Refinement이 training loop 외부의 post-processing → gradient 통한 학습 불가

---

## 3. 핵심 해결책 비교 분석

### Option A: SE(3) Frame 표현으로 전환 (근본적 해결)
- **방식**: NERF 재구성 제거. 각 residue를 (R, t) ∈ SE(3)으로 표현. Flow matching을 SE(3)^N에서 수행
- **장점**: Lever arm effect 구조적 차단. Error accumulation 없음. FAPE loss 사용 가능. 문헌에서 입증됨 (FrameDiff, FoldFlow, Sesame)
- **단점**: CrypticFlow 전체 아키텍처 재설계 필요. Encoder/Decoder 모두 교체. 구현 복잡도 높음
- **적합 시나리오**: 장기적 해결책. 현재 코드베이스의 주요 수정 필요

### Option B: FAPE Loss 추가 (현실적 단기 해결)
- **방식**: 현재 torsion angle loss 유지하면서 FAPE를 auxiliary loss로 추가
- **FAPE 공식**: 각 residue i에 대해 local frame T_i 기준으로 모든 원자 위치 오차 측정 후 평균
- **장점**: 기존 NERF reconstruction 유지하면서 Cartesian RMSD signal 주입 가능. AlphaFold2/OpenFold에서 안정성 입증됨. Job 401/403의 직접 coord RMSD loss보다 훨씬 안정적
- **핵심 차이**: FAPE는 local frame 기준이므로 lever arm effect에 덜 민감. 글로벌 RMSD처럼 체인 끝 오차가 폭발하지 않음
- **단점**: 여전히 NERF reconstruction 의존. 완전한 해결은 아님

### Option C: Truncated/Stop-Gradient Cartesian Loss (단기 안정화)
- **방식**: coord RMSD loss 계산 시 gradient를 중간 지점에서 차단 (detach)
- **Job 401/403 실패 원인**: 전체 NERF chain을 통과하는 gradient가 lever arm effect를 역전파하면서 폭발
- **해결**: `loss = RMSD(nerf_coords.detach(), target_coords)` 또는 일정 residue 수마다 gradient 차단
- **장점**: 구현이 간단함. 기존 코드에 최소한의 변경
- **단점**: Gradient 정보 손실. 학습 효율 저하 가능

### Option D: 체인 분할 재구성 (중기 해결)
- **방식**: 긴 단백질 체인을 K개 세그먼트로 나누고 각 세그먼트 중간점을 anchor로 사용. 각 세그먼트를 독립적으로 NERF 재구성 후 Kabsch alignment로 연결
- **장점**: Error accumulation을 세그먼트 길이로 제한. 구현 가능한 수준의 수정
- **단점**: 세그먼트 경계에서의 continuity 보장 어려움. Anchor point 결정 방법 문헌에 없음

### Option E: Post-processing Geometric Refinement (최소 수정)
- **방식**: Training loop 밖에서 생성된 구조에 Rg correction + bond restoration 반복 적용
- **장점**: 기존 학습 코드 무수정. 즉시 적용 가능
- **단점**: Training signal에 영향 없음. 근본 문제 해결 안 됨. Inference 시 추가 연산

---

## 4. CrypticFlow에 대한 구체적 권고사항

### 우선순위 1 (즉시, Job 401/403 재현 방지): Gradient Clipping + Loss Weight 극소화
- coord RMSD loss weight를 매우 작게 시작 (λ=1e-6부터) 점진적 증가
- gradient norm clipping 강화 (max_norm=0.1 수준)
- NERF forward pass를 `torch.no_grad()` 블록으로 감싸고 별도 branch로 loss 계산

### 우선순위 2 (단기, 1-2주): FAPE-style Local Frame Loss 구현
- 각 residue의 local backbone frame (N, Ca, C로 정의) 구성
- 이 frame 기준으로 인접 residue 위치 오차 측정
- 전체 NERF chain RMSD 대신 이 local frame RMSD를 auxiliary loss로 사용
- Weight: `L_total = L_torsion + λ_fape * L_fape` (λ_fape ≈ 0.01~0.1)

### 우선순위 3 (중기, 1개월): SE(3) 표현 전환 검토
- TorsionalEncoder를 SE(3) frame encoder로 교체
- Flow matching vector field를 SO(3) + ℝ³ 분리 학습
- Sesame 코드 참조: apo→holo flow matching with SE(3) frames

---

## 5. Job 399/401/403 실패 원인 요약

| Job | 설정 | 실패 원인 | 문헌 대응 |
|-----|------|-----------|-----------|
| 399 | torsion loss only | Lever arm effect: angle loss 수렴해도 RMSD 악화 | FoldingDiff에서 동일 현상 보고 |
| 401/403 | + coord RMSD loss | NERF gradient 역전파 시 lever arm effect가 gradient를 기하급수적으로 증폭 → NaN/CUDA OOM | FAPE loss가 이를 해결하는 이유 |

---

## 6. 참고 문헌

- [FoldingDiff - Nature Communications 2024](https://www.nature.com/articles/s41467-024-45051-2) — Lever arm effect 명시적 언급
- [Torsion-Space Diffusion with Geometric Refinement (arXiv 2511.19184)](https://arxiv.org/abs/2511.19184) — Rg correction + bond restoration
- [FoldFlow - SE(3) Flow Matching (arXiv 2310.02391)](https://arxiv.org/abs/2310.02391) — SE(3) frame 기반 backbone generation
- [FrameDiff - SE(3) Diffusion (arXiv 2302.02277)](https://arxiv.org/abs/2302.02277) — SE(3) rigid body diffusion
- [Sesame - Apo→Holo Flow Matching (arXiv 2509.05302)](https://arxiv.org/html/2509.05302) — CrypticFlow와 가장 유사한 task
- [AlphaFold2 - Nature 2021](https://www.nature.com/articles/s41586-021-03819-2) — FAPE loss, independent frame prediction
- [OpenFold - PMC 2024](https://pmc.ncbi.nlm.nih.gov/articles/PMC11645889/) — FAPE clamping 개선으로 훈련 안정성 향상
- [RFdiffusion - PubMed 2023](https://pubmed.ncbi.nlm.nih.gov/37433327/) — MSE on backbone frames, self-conditioning
- [MP-NeRF - PubMed 2022](https://pubmed.ncbi.nlm.nih.gov/34709663/) — NERF 병렬화 (수치 안정성 한계 설명)
- [AlphaFlow - arXiv 2402.04845](https://arxiv.org/abs/2402.04845) — Flow matching for protein ensembles with FAPE loss
