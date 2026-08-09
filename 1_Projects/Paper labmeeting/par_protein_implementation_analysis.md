# PAR Implementation Analysis from Code

## 한줄 요약

`/home/mjkim/apps/par-protein`의 PAR는 논문을 읽고 떠올리기 쉬운 "추상적 PAR"보다 훨씬 구체적으로는, `(1) interpolation 기반 multi-scale decomposition` + `(2) concatenated multiscale token stream 위의 autoregressive transformer encoder` + `(3) 각 scale마다 따로 도는 conditional CA flow decoder`의 조합으로 구현되어 있다.

특히 실제 코드에서는 다음이 중요하다.

1. coarse-to-fine 분해는 dyadic midpoint tree가 아니라 `F.interpolate` 기반 centroid/downsample-upsample 구조다.
2. 기본 설정에서는 residual structure가 아니라 absolute multiscale coordinates를 학습한다.
3. 학습의 기본 경로는 "all-scale 병렬 teacher forcing"가 아니라 `scheduled sampling`이 켜진 순차 scale-by-scale 학습이다.
4. 각 scale의 좌표 생성은 transformer가 직접 회귀하는 것이 아니라, `ProteinaWithPARCond`라는 conditional flow matcher가 맡는다.
5. 논문에서 크게 드러나지 않는 구현 디테일로 noisy context learning, KV cache, register token on/off, motif centroid replacement 같은 실용 장치가 많이 들어가 있다.

---

## 1. 전체 파이프라인

핵심 진입점은 `proteinfoundation/protein_autoregressive_modeling/par.py`의 `PAR` 클래스다.

- multi-scale decomposition: `PARProteinDecomposer`
- AR encoder: `ProteinTransformerAF3`
- scale-wise structure generator: `ProteinaWithPARCond`

즉, 구조적으로는 다음 순서다.

1. 원래 CA 좌표를 여러 scale의 centroid 좌표열로 분해한다.
2. 이전 scale까지의 structure input을 누적해서 AR encoder에 넣어 condition `z_cond`를 만든다.
3. 현재 scale의 좌표는 `z_cond + current structure input`을 조건으로 하는 flow model이 생성한다.
4. 생성된 현재 scale centroid를 다시 upsample/reconstruct해서 다음 scale input으로 넘긴다.

이 점에서 PAR는 "한 번의 transformer forward로 전체 좌표를 끝내는 모델"이 아니라, **AR encoder와 flow decoder를 scale마다 번갈아 호출하는 계층형 생성기**에 가깝다.

---

## 2. 실제 multiscale decomposition은 무엇을 하는가

### 2.1 midpoint tree가 아니라 interpolation-based centroids

가장 중요한 구현 디테일은 `protein_decomposer_by_length.py`이다.

- downsample: `F.interpolate(..., mode='linear')`
- upsample/reconstruct: `F.interpolate(..., mode='bicubic')`

즉 scale별 representation은 residue subset을 뽑는 방식이 아니라, **연속적인 1D 좌표열을 길이만 바꿔 보간한 centroid-like signal**이다.

기본 config는 `configs/model/ca_par_60m.yaml`:

- `num_local_centroids: [64, 128, 256]`
- `strategy: sample_by_length`
- `use_residual_structure: false`
- `align_corners: false`
- `zom_all_scale: true`

여기서 `sample_by_length`는 길이에 따라 실제 사용할 scale 수를 정한다. 예를 들어 길이 100이면 scale 길이는 대략 `[64, 100]`처럼 끝 scale이 raw length로 잘린다. 즉 config에 `[64, 128, 256]`가 있어도 모든 단백질이 3 scale을 다 쓰는 것은 아니다.

### 2.2 기본값은 residual decomposition이 아님

코드에는 residual decomposition 경로도 있지만, 기본 config는 `use_residual_structure: false`이다. 이 경우 각 scale이 residual을 맞추는 것이 아니라, 그 scale 길이에서의 **직접적인 좌표 표현**을 target으로 사용한다.

이 차이는 꽤 크다.

- `use_residual_structure: true`면 각 scale이 이전 scale reconstruction의 잔차를 담당한다.
- 현재 기본 경로는 그렇지 않고, 이전 scale reconstruction은 주로 **teacher forcing input / next-scale context**로 쓰인다.

즉 paper를 읽고 "각 scale이 residual만 생성하나?"라고 생각하면, 코드 기본 동작은 그쪽이 아니다.

### 2.3 teacher forcing input은 이전 scale GT reconstruction이다

분해기에서 각 scale용 `tf_input_sample`을 만들 때, 현재 scale GT를 바로 주는 것이 아니라, **이전 scale reconstruction을 다음 scale 길이로 다시 interpolate한 결과**를 넣는다.

이건 AR encoder가 현재 scale token을 볼 때 "이전까지 재구성된 구조 상태"를 입력으로 받도록 설계한 것이다.

---

## 3. attention mask와 token ordering

### 3.1 token은 scale별로 concat된다

AR encoder 입력은 scale별 token을 이어붙인 하나의 긴 sequence다.

예시:

- scale 0: 64 tokens
- scale 1: 128 tokens
- scale 2: 256 tokens
- 총 448 tokens

`protein_decomposer_by_length.py`에서 `attn_bias_for_masking`을 미리 만든다.

### 3.2 causal rule은 "현재 scale은 자기 scale과 이전 scale만 본다"

mask 생성 논리는:

- same scale: attend 가능
- previous scale: attend 가능
- future scale: attend 불가

즉 residue-level left-to-right causal mask가 아니라, **scale block 단위 causal mask**다.

이게 중요하다. PAR의 autoregressive성은 residue 순서 autoregressive가 아니라, **coarse-to-fine scale autoregressive**다.

### 3.3 variable length batch 처리

각 샘플마다 실제 사용 scale 길이가 다르기 때문에, 총 concat 길이 이후의 영역은 `-inf`로 막는다. 짧은 단백질 배치에서는 뒤 scale이 아예 비어 있을 수 있고, 그 경우 해당 scale loss를 skip한다.

---

## 4. position embedding과 scale embedding의 실제 의미

### 4.1 coarse token도 raw-sequence position을 대략 유지한다

`feature_utils.py`의 `get_int_pos_idx_from_lengths_all_scales()`는 각 scale token에 대해 `1..L` 사이를 `linspace`로 다시 매긴다.

예를 들어 길이 100을 64 token으로 줄이면 coarse token은 대략:

`[1.0, 2.57, 4.14, ..., 100.0]`

같은 interpolated residue index를 갖는다.

이 index는 `feature_factory.py`의 `InterpolatedPositionEmbedding`으로 embedding된다.

즉 coarse token은 단순히 "64개 토큰 중 몇 번째"가 아니라, **원래 residue 축에서 대략 어느 위치인지**를 같이 가진다.

### 4.2 level embedding은 encoder/decoder에서 역할이 다르다

`LevelEmbedding`은 두 가지 모드가 있다.

- encoder 쪽: concat된 긴 stream에서 `pos_offset`으로 현재 token이 어느 scale block에 속하는지 계산
- decoder 쪽: `cur_scale` 값을 그대로 받아 현재 scale index embedding을 사용

즉 `lvl_emb`는 "현재 residue 위치"가 아니라, **현재 token이 어느 resolution level에 있는지** 알려주는 feature다.

---

## 5. AR encoder는 실제로 무엇을 하는가

AR encoder는 `nn/protein_transformer.py`의 `ProteinTransformerAF3`다.

입력 구성:

- 좌표 input의 선형 embedding (`linear_3d_embed`)
- init sequence features (`int_pos_emb`, `chain_break_per_res` 등)
- conditioning features (`lvl_emb`)

출력:

- 좌표 자체가 아니라 `cond` token representation

즉 encoder는 직접 좌표를 맞추지 않고, **현재 scale flow decoder가 사용할 structural condition**을 만든다.

### 5.1 pair bias는 코드상 scaffold는 있지만 기본 경로는 아님

config 상으로 pair feature 관련 옵션이 꽤 많지만, 기본 AR encoder config는:

- `use_attn_pair_bias: false`
- `update_pair_repr: false`
- `num_registers: 0`

그리고 코드 안에도 `use_attn_pair_bias=True`일 때 `NotImplementedError('Pair representation is not tested yet.')`가 있다.

즉 논문에서 pair 정보가 중요해 보이더라도, **이 repo의 실제 검증된 기본 경로는 pair-biased AR가 아니다**.

### 5.2 register token은 encoder inference 최적화용에 가깝다

decoder가 아니라 AR encoder에 register 관련 구현이 있다.

- 학습 기본 config에서는 `num_registers: 0`
- 그러나 일반 구현은 register insertion을 지원
- inference에서는 첫 scale만 register를 켜고, 이후 scale에서는 `set_register_usage(False)`로 꺼버린다

주석에도 적혀 있듯 이유는 register가 scale 사이에 끼어드는 것을 피하기 위해서다.

즉 register는 "모든 scale에 항상 쓰는 core design"이라기보다, **일부 설정에서 쓸 수 있는 inference-time special handling**이다.

### 5.3 KV cache를 켜서 AR encoder를 scale-wise generation에 맞춘다

`generate()`와 `generate_motif_scaffold()`에서는 AR encoder의 각 layer에 대해 `b.mhba.mha.kv_caching(True)`를 켠다.

이건 coarse-to-fine generation 중 repeated forward cost를 줄이기 위한 구현으로 보인다. 논문에는 잘 안 드러날 수 있지만, 실제 inference 최적화의 핵심이다.

---

## 6. 각 scale의 좌표는 transformer가 아니라 conditional flow가 만든다

### 6.1 실제 생성기는 `ProteinaWithPARCond`

`PAR.forward_1_scale()`에서 현재 scale batch를 만들고 `self.atom_diffusion.training_step(...)`를 호출한다. 여기서 `self.atom_diffusion`이 `ProteinaWithPARCond`다.

즉 현재 scale의 CA 좌표는 AR encoder가 직접 출력하지 않는다. 대신:

- `z_cond`: AR encoder 출력
- `s_cond`: 현재 scale structure input
- `int_pos_idx`, `lvl_emb`, `time_emb`, `x_sc`

를 조건으로 하는 flow model이 좌표를 맞춘다.

### 6.2 decoder 내부에서는 `coors_embed + init_feat + structure_feat`를 합친다

`proteinflow/nn/proteina_transformer.py`를 보면 decoder input token은 다음 세 부분의 합이다.

- `x_t`의 좌표 embedding
- `feats_init_seq`에서 온 init representation
- `feats_structure_seq`에서 온 structure representation

기본 config에서는:

- `feats_structure_seq: ["z_cond"]`
- `feats_init_seq: ["int_pos_emb", "x_sc", "chain_break_per_res"]`
- `feats_cond_seq: ["time_emb", "lvl_emb"]`

즉 decoder는 "현재 noisy 좌표 `x_t`" 위에, PAR condition과 self-conditioning을 얹어서 denoising/flow prediction을 한다.

### 6.3 diffusion_batch_mul은 꽤 중요한 학습 디테일

`configs/model/atom_diff/caflow_60m.yaml`에서:

- `diffusion_batch_mul: 5`

`PAR.forward_1_scale()`에서는 같은 scale target 하나를 5번 repeat해서 서로 다른 noise/time 샘플로 학습시킨다. 즉 한 번의 scale 학습 step이 실제로는 **같은 structural target에 대해 여러 개의 flow-matching sample**을 만든다.

이건 논문 요약만 보면 놓치기 쉬운 구현 detail이다.

---

## 7. flow matching objective의 실제 형태

### 7.1 reference distribution은 Cartesian Gaussian

`R3NFlowMatcher`는 reference를 centered Gaussian in Cartesian CA space로 둔다.

- `x_0 ~ N(0, I)`
- 필요하면 zero-center

그리고 interpolation은:

`x_t = (1 - t) x_0 + t x_1`

즉 torsion-space나 rigid-frame flow가 아니라, **현재 repo의 PAR-CA 경로는 Cartesian CA flow**다.

### 7.2 target_pred는 velocity parameterization

기본 config는 `target_pred: v`.

`ProteinaTrainerBase._nn_out_to_x_clean()`에 따라:

- network output = `v` (정확히는 clean reconstruction에 필요한 velocity-like quantity)
- clean prediction은 `x_1_pred = x_t + (1 - t) * nn_pred`

즉 decoder는 직접 clean coordinates를 찍는 게 아니라, velocity parameterization을 통해 clean sample을 복원한다.

### 7.3 FM loss는 `(1-t)^{-2}` weight가 들어간다

`ProteinaWithPARCond.compute_fm_loss()`를 보면 residue mask를 적용한 MSE에:

`1 / ((1 - t)^2 + 1e-5)`

가 곱해진다.

즉 late-time region이 더 세게 weighted된다. 단순한 unweighted Cartesian MSE가 아니다.

### 7.4 self-conditioning은 decoder에도 들어간다

`ProteinaWithPARCond.training_step()`에서는 0.5 확률로 self-conditioning을 켠다.

- 먼저 한 번 clean prediction
- 그 출력을 detach해서 `x_sc`로 다시 batch에 넣음
- 본 forward에서 conditioning feature로 사용

따라서 PAR 전체로 보면 0.5 확률 scheduled sampling뿐 아니라, decoder 자체에도 별도의 0.5 확률 self-conditioning이 있다.

---

## 8. 학습 경로에서 중요한 실전 디테일

### 8.1 기본 학습 경로는 scheduled sampling ON

`configs/experiment_config/training_ca_par_60m.yaml`:

- `schedule_sampling: true`
- `noisy_context_learning: true`
- `self_cond: true`

즉 default 학습은 단순 teacher forcing이 아니다.

### 8.2 scheduled sampling 방식은 hard-coded 0.5 Bernoulli

`par.py`의 scale loop에서, `scale_idx > 0`이면:

- `random.random() > 0.5`일 때
- 이전 scale의 predicted centroid를 `get_next_autoregressive_input()`으로 propagate해서 현재 scale input을 대체

즉 학습 중 현재 scale input은 절반 확률로 GT-based input, 절반 확률로 predicted previous-scale input이 된다. 별도 annealing schedule은 없다.

### 8.3 noisy context learning은 flow time과 별개다

`apply_noisy_context_learning_1_scale()`는:

- `t ~ Uniform(0,1)` sample
- `cur_input_noisy = t * input + (1 - t) * noise`

를 적용한다.

이 `t`는 flow matcher의 `t`와는 별개다. 즉 decoder가 보는 noisy `x_t` 외에도, **AR encoder/structure context input 쪽에도 추가적인 노이즈 주입**이 있다.

이 역시 paper에서 간단히 지나갈 수 있지만, 실제 안정성에는 큰 영향을 줄 가능성이 있다.

### 8.4 `forward_all_scales()`는 현재 비주류 경로거나 버그 가능성이 있다

코드상 `schedule_sampling=False`일 때는 `forward_all_scales()`를 타게 되어 있는데, 이 함수는 내부에서 `total_loss`를 누적해 놓고 마지막에 `train_loss`를 나누어 반환한다.

하지만 함수 내부에 `train_loss` 초기화/누적이 없어서, 현재 코드만 보면 **non-scheduled path는 broken일 가능성**이 높다.

즉 실제로 잘 쓰이고 검증된 경로는 `schedule_sampling=True`인 순차 scale-by-scale 학습으로 보는 것이 안전하다.

---

## 9. inference에서 paper보다 중요한 구현 포인트

### 9.1 unconditional generation은 scale-by-scale recursive generation

`generate()`는 다음 식으로 동작한다.

1. first-scale BOS latent 준비
2. 현재 scale input으로 AR encoder 실행
3. flow decoder로 centroid 생성
4. `get_next_autoregressive_input()`으로 raw-length reconstruction을 update
5. 그 reconstruction을 다음 scale 길이로 다시 줄여 다음 input으로 사용

즉 generation의 핵심 state는 단순 token hidden state가 아니라, **누적 재구성된 Cartesian structure**다.

### 9.2 마지막 몇 step은 강제로 deterministic VF mode

`R3NFlowMatcher.full_simulation()`에서 sampling mode가 기본적으로 `sc`여도:

- `t > 0.99`면 무조건 `vf`
- `schedule_mode in ["cos_sch_v_snr", "edm"]`이면 `t > 0.985`부터 `vf`

즉 sampling 끝부분은 noise를 꺼서 안정화한다.

### 9.3 self-conditioning은 inference에서도 계속 사용

flow simulation loop에서 `step > 0 and self_cond`이면 이전 step clean prediction `x_1_pred`를 `x_sc`로 다시 넣는다.

즉 decoder는 time integration 전체 동안 자기 예측을 다음 step condition으로 재사용한다.

---

## 10. force decoding은 "마지막 몇 scale만 생성"하는 방식

`force_decode()` 구현은 일반적인 residue-wise prompting과 다르다.

동작은:

1. input structure를 먼저 multiscale로 decomposition
2. 앞쪽 scale은 GT centroid를 그대로 사용
3. `generate_last_n_scales`부터만 모델이 생성
4. 나머지는 recursive하게 이어감

즉 prompt generation은 arbitrary residue mask completion이 아니라, **coarse scales teacher forcing + final scales generation**에 가깝다.

이건 crypticflow 쪽에서 apo 정보를 prompt처럼 활용할 때도 아이디어적으로 참고할 만하다.

---

## 11. motif scaffold 구현 디테일

`generate_motif_scaffold()`도 논문 수준 설명보다 구현이 꽤 구체적이다.

### 11.1 motif 빈칸은 먼저 interpolation으로 채운다

`fill_linear_interp_nearest_neighbor()`로 motif가 아닌 위치를 먼저 채운 뒤 decomposer에 넣는다.

즉 motif structure conditioning은 sparse point set 그대로 쓰는 것이 아니라, **일단 전체 CA path를 임시 복원한 뒤 multiscale decomposition**한다.

### 11.2 motif replacement는 scale마다 한다

생성 후 마지막에 한 번 motif를 overwrite하는 것이 아니라, 각 scale에서:

- motif mask를 현재 scale 길이로 downsample
- generated centroid와 GT motif centroid를 alignment
- motif 위치 centroid를 치환

즉 motif conditioning은 iterative multiscale inpainting에 가깝다.

---

## 12. config를 보면 실제 default path가 더 명확해진다

### 12.1 AR encoder default

`configs/model/nn/ca_af3_60M_notri_par.yaml`

- token dim 512
- 12 layers
- `use_attn_pair_bias: false`
- `feats_init_seq: ["int_pos_emb","chain_break_per_res"]`
- `feats_cond_seq: ["lvl_emb"]`
- `num_registers: 0`

즉 AR encoder는 생각보다 단순하다. 시간 embedding도 없고, 현재 scale noisy 좌표도 보지 않는다. **이전 scale structure input + 위치/level 정보로 condition latent를 만든다.**

### 12.2 flow decoder default

`configs/model/atom_diff/nn/ca_af3_60M_notri.yaml`

- `feats_structure_seq: ["z_cond"]`
- `feats_init_seq: ["int_pos_emb","x_sc","chain_break_per_res"]`
- `feats_cond_seq: ["time_emb","lvl_emb"]`
- `num_registers: 10`

즉 register는 AR encoder보다 오히려 decoder 쪽 default에 더 강하게 들어가 있다.

### 12.3 요약하면 encoder와 decoder 역할 분리가 선명하다

- encoder: multiscale context aggregation
- decoder: current-scale denoising/generation

이 구조는 crypticflow에서 recursive anchor idea를 구현할 때도 꽤 참고할 만하다. coarse global dependency와 local geometric generation을 한 네트워크에 억지로 합치지 않고 분리할 수 있기 때문이다.

---

## 13. train/inference script 수준의 구현 포인트

### 13.1 checkpoint loading은 꽤 느슨하다

`train_par.py`, `inference_par.py`, `motif_inference_par.py` 모두 `strict=False` 로딩 경로가 있다.

이 말은:

- architecture 변경을 어느 정도 허용
- scale config 변경이나 long_protein variant에서 일부 buffer mismatch를 허용

하는 쪽으로 구현이 기울어 있다는 뜻이다.

### 13.2 long protein 설정 시 일부 decomposer buffer를 버린다

`train_par.py`에서 `long_protein`이면 checkpoint load 전에 다음 key를 제거한다.

- `protein_decomposer.attn_bias_for_masking`
- `protein_decomposer.attn_bias_for_decoding`
- `protein_decomposer.length_indices`
- `nn.class_cond_factory.feat_creators.0.lvl_1L`

즉 scale 재설정은 단순 inference arg가 아니라, **decomposer와 level-embedding buffer까지 다시 맞춰야 하는 구현 이슈**가 있다.

---

## 14. paper만 보면 놓치기 쉬운 핵심 caveat

### 14.1 이것은 residue autoregressive가 아니다

PAR의 autoregressive성은 residue-by-residue가 아니라 scale-by-scale이다. 따라서 wall-clock step 수는 scale 수에 비례하고, 각 step 내부 cost는 현재 scale 길이에 따라 달라진다.

### 14.2 구조 생성은 ICS가 아니라 Cartesian CA flow다

현재 repo 기준으로는 coarse-to-fine PAR 위에서 도는 생성기가 ICS가 아니라 Cartesian CA flow matcher다. 따라서 우리 recursive-anchor-ICS 아이디어와 비교할 때는, "PAR의 recursive skeleton"은 가져오되 **geometry representation은 완전히 바뀔 수 있다**고 보는 게 맞다.

### 14.3 decomposition 자체가 물리 prior를 주는 것은 아니다

현재 decomposition은 interpolation 기반이므로, bond length/bond angle 같은 강한 local geometry prior를 직접 보장하지 않는다. PAR의 장점은 geometric validity 자체보다 **error accumulation을 coarse-to-fine context로 분산하는 데** 더 가깝다.

### 14.4 구현상 실전 안정화 장치가 많다

실제 학습/샘플링 품질은 아래 요소들의 영향을 크게 받을 가능성이 있다.

- scheduled sampling
- noisy context learning
- decoder self-conditioning
- late-step deterministic VF switch
- zero-center at all scales (`zom_all_scale`)

즉 논문 본문보다, **이 repo에서는 training trick과 sampling heuristic이 모델 성격을 크게 좌우한다.**

---

## 15. crypticflow 관점에서 바로 참고할 만한 점

### 15.1 가져갈 만한 것

1. 전체 구조를 coarse-to-fine recursion으로 분해하고, 각 level 예측을 다음 level condition으로 쓰는 방식
2. encoder와 generator를 분리해서 global context와 local generation을 역할 분담시키는 방식
3. teacher forcing만 쓰지 않고 predicted previous-level context를 학습 때부터 섞는 방식
4. position embedding을 raw residue axis 기준으로 interpolation해서 coarse token에도 위치 의미를 남기는 방식

### 15.2 그대로 가져오면 안 되는 것

1. interpolation-based Cartesian centroids 자체
2. local geometry를 거의 보장하지 않는 decomposition
3. pair bias가 실제 기본 경로가 아니라는 점을 무시한 해석

우리 쪽 recursive-anchor-ICS는 오히려 여기서 **PAR의 recursion/conditioning skeleton만 가져오고, scale state representation과 decoder를 ICS-aware하게 다시 설계하는 방향**이 더 자연스럽다.

---

## 16. 최종 요약

이 코드베이스의 PAR를 한 문장으로 정리하면:

**"이전 scale reconstruction을 조건으로 삼아 multiscale latent를 AR encoder로 만들고, 각 scale 좌표는 별도의 conditional CA flow model이 생성하는 coarse-to-fine recursive Cartesian generator"** 이다.

논문만 보고 떠올릴 수 있는 추상적 그림과 비교했을 때, 코드 레벨에서 특히 중요한 차이는 다음 세 가지다.

1. decomposition이 midpoint tree가 아니라 interpolation-based multiscale centroid decomposition이라는 점
2. 기본 학습이 scheduled sampling + noisy context learning + self-conditioning 위에서 돌아간다는 점
3. 실제 좌표 생성기가 AR transformer가 아니라 scale-wise conditional flow decoder라는 점

이 세 가지를 이해해야 `par-protein`의 실험을 제대로 재현하거나, 이를 `crypticflow_par`로 옮기면서 어떤 부분을 유지하고 어떤 부분을 갈아엎을지 정확히 판단할 수 있다.
