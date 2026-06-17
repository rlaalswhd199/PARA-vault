# PAR 발표 최종 스크립트

**논문**: Protein Autoregressive Modeling via Multiscale Structure Generation  
**발표자**: minjongkim (LCDD, SNU) | **발표일**: 2026-06-05  
**슬라이드**: 본편 1–33 | Appendix 34–43 (Q&A 백업)

---

## 도입

### Slide 1 — Title

안녕하세요. 오늘 제가 소개할 논문은 ByteDance Seed와 UIUC에서 나온 "Protein Autoregressive Modeling via Multiscale Structure Generation", 줄여서 PAR이라는 논문입니다. 올해 ICML 2026에서 spotlight, 상위 2.2%로 채택된 연구입니다. 오른쪽 그림은 PAR이 실제로 단백질을 만들어가는 과정인데, 거친 형태에서 시작해서 점점 디테일을 채워가는 게 보이실 겁니다. 이처럼 단백질을 스케일 단위로 나누고, 이전의 거친 스케일 정보를 맥락으로 flow matching 디코더를 활용해 autoregressive하게 단백질을 생성하는 모델입니다.

본격적으로 들어가기 전에, 이 논문이 무엇을 했는지 세 줄로 먼저 정리하고 시작하겠습니다.

---

### Slide 2 — 3줄 요약

본 논문을 세 가지로 요약하겠습니다.

**첫째**, 처음으로 ChatGPT 같은 자기회귀(AR) 모델 방식으로 단백질 Cα 백본을 생성하였습니다. 다만 단어를 하나씩 뽑듯이가 아니라, 해상도 스케일을 거친 것부터 세밀한 것 순서로 하나씩 채워가는 방식입니다.

**둘째**, PAR 모델은 FPSD 지표에서 161이라는 점수를 기록했고, 이는 지금까지 나온 생성 모델 중 가장 좋은 값입니다. 즉 PAR 모델이 만든 단백질 분포가 실제 자연계 단백질 분포에 가장 가깝다는 뜻입니다. 게다가 추가 학습 없이, zero-shot으로 모양 프롬프트나 motif scaffolding 같은 조건부 생성이 가능합니다.

**셋째**, AR, flow matching, multi-scale 이 세 가지를 한 모델에 결합하여 protein design, docking, 그리고 conformation change 연구에도 활용될 가능성이 있습니다.

---

## A. Background

### Slide 3 — 왜 단백질 백본 생성인가

그럼 먼저, "단백질 백본을 만든다"는 게 왜 중요한 문제인지부터 보겠습니다. 최근 몇 년 사이에 de novo로 단백질을 디자인하는 것이 신약 개발과 엔지니어링의 핵심으로 떠올랐습니다. binder, enzyme design, motif scaffolding과 같은 분야에서 de novo 단백질 디자인이 사용되고, 일반적인 파이프라인은 다음과 같습니다. 백본 골격을 만들고 MPNN 같은 도구로 골격에 맞는 아미노산 서열을 설계하고 ESMFold나 AlphaFold로 다시 접어서 검증합니다. 이때 첫 번째 단계가 전체 파이프라인의 병목이고 가장 중요합니다. 이것이 바로 PAR이 푸는 문제입니다.

---

### Slide 4 — Diffusion 천하, 그런데 AR은?

그럼 지금까지 백본 생성은 어떻게 해왔을까요? 한마디로 diffusion 위주였습니다. 표를 보시면 RFDiffusion, Genie2, Proteina 모두 diffusion 기반이고, PAR은 AR + Flow 조합으로 96.6%를 찍었습니다.

Diffusion의 한계는 세 가지입니다. 첫째 sampling step이 수백 개라 느립니다. 둘째 LLM 같은 일관된 scaling law가 잘 안 보입니다. 셋째 특정 task를 위해서는 fine-tune이 필요합니다.

AR이 해결책이 될 수 있습니다. 모델의 크기를 키우면 성능이 오르는 scaling law가 성립하고, zero-shot 프롬프트 제어, KV cache로 빠른 추론이 가능합니다.

---

### Slide 5 — 왜 단백질에선 AR이 안 됐나

그럼 왜 AR이 단백질 모델에서 사용되지 않았을까요? 단백질의 두 가지 본질과 충돌하기 때문입니다.

**첫째** discretization loss입니다. 단백질 좌표는 연속적인 실수값입니다. 억지로 VQ-VAE로 토큰화하면 옹스트롬 단위의 미세한 기하 정보가 다 날아가 버립니다.

**둘째** bidirectional dependency입니다. 서열상 멀리 떨어진 잔기가 3D 공간에서는 수소결합으로 붙어 있을 수 있습니다. 단방향 AR은 왼쪽부터 순서대로 만들기 때문에, 48번을 만들 때는 아직 없는 92번(미래)을 참조할 수 없습니다.

---

### Slide 6 — 이미지의 next-scale 전환 (VAR)

이 문제, 이미지 분야에서 이미 먼저 겪었고 해결하기 위한 연구가 있었습니다. 이미지도 양방향성 문제 때문에 GPT처럼 토큰을 하나씩 생성하기 어려웠습니다. 좌→우, 위→아래 같은 1차원 순서로 한 칸씩 생성을 시도했으나 양방향성 문제도 해결이 안되고 attention 비용이 폭발합니다.

그래서 생각해낸 것이 NeurIPS 2024의 VAR이 제안한 next-scale입니다. 1×1 해상도에서 시작해서 2×2, 4×4, 8×8로 스케일을 키워 나가면서 이미지를 생성합니다. 이러면 같은 스케일 안의 모든 점을 한꺼번에 보니 양방향성도 살고 빠릅니다. ImageNet에서 FID 1.73으로 DiT를 AR로 처음 넘었고, 20배 빠르고, scaling law도 관찰됐습니다.

---



---

### Slide 8 — PAR 핵심 아이디어: next-scale prediction

비유하자면 조각가의 작업 방식입니다. 조각가는 처음에는 큰 덩어리부터 형태를 잡고 점점 다듬습니다. PAR도 마찬가지입니다. Scale 1에서 전체 윤곽을 몇 개 점으로 잡고, Scale 2, 3으로 가면서 점 개수를 늘려 구조를 세밀하게 만들고, 마지막에 전체 백본을 완성합니다.

AR Transformer가 이전 스케일들을 보고 조건 벡터를 만들고, Flow Decoder가 그 조건으로 실제 Cα 좌표를 연속값 그대로 생성합니다. 이렇게 함으로써 양방향성 문제와 이산화 문제를 해결합니다.

---

## B. Method

### Slide 9 — 전체 아키텍처: 세 모듈

전체적인 구조는 LLM이 이전 단어 보고 다음 단어 예측하듯, 전체 확률 분포를 이전 스케일들이 주어졌을 때 다음 스케일의 확률의 곱으로 분해했다고 생각하시면 됩니다. PAR은 세 모듈로 구성됩니다. 첫 번째로 multi-scale downsampling 모듈은 학습할 때 정답 단백질을 여러 해상도로 쪼개서 각 스케일의 학습 타깃과 컨텍스트를 만듭니다. 두 번째로 AR Transformer는 이전 스케일들을 입력받아 다음 스케일을 위한 조건 임베딩을 만듭니다. 세 번째로 Flow Decoder는 노이즈와 조건을 받아서 실제 좌표를 생성합니다. 이 디코더를 모든 스케일이 공유합니다.

---

### Slide 10 — Multi-scale Downsampling

이제 구체적인 예로 길이 128인 단백질 하나를 3-scale로 나누어 학습 및 추론하는 과정을 살펴보겠습니다. 서열을 균등하게 나누고 centroid를 뽑는 방식으로 길이 128인 단백질을 {32, 64, 128} 세 단계로 쪼갭니다. 이러한 과정을 다운샘플링이라고 하며 학습 시에만 진행합니다.

---

### Slide 11 — 학습 Scale i=1

가장 거친 스케일 x¹이 준비됐습니다. 스케일 1은 맥락으로 줄 이전 스케일이 없으므로 BOS 토큰 하나만 트랜스포머에 넣어줍니다. 이렇게 해서 z1을 만듭니다. 그 다음 flow matching입니다. 우선 정답 구조 x1에 노이즈 ε1을 섞어서 시간 t의 보간 상태 x1_t를 만듭니다. 디코더에 이를 입력으로 하고, 앞서 생성한 z1을 조건으로 하여 x1 − ε1을 예측하도록 디코더를 학습시킵니다.

---

### Slide 12 — 학습 Scale i=2

스케일 1에 대해서 학습을 진행했으니, 다음은 스케일 2입니다. 정답 스케일 1에 대해서 인접한 점 사이를 선형 보간하는 방식으로 업샘플링합니다. Transformer 입력은 [BOS, Up(x¹)]가 되고, 여기서 z²가 나옵니다. 나머지는 스케일 1과 똑같습니다. 하나 짚을 점은 학습 때는 x1hat이 아닌 정답 x1을 그대로 사용한다는 점입니다.

---

### Slide 13 — 학습 Scale i=3 + 전체 loss

마지막은 스케일 3입니다. BOS 토큰과 이전 정답 스케일 두 개를 모두 128개의 점으로 업샘플링해서 트랜스포머에 넣습니다. 이렇게 생성된 z3는 거친 정보와 중간 정보를 모두 갖고 있습니다. 전체 학습 loss는 세 스케일의 flow matching loss를 다 더한 겁니다. 여기서 중요한 것은 디코더와 AR 모두 loss를 공유한다는 점입니다.

---

### Slide 14 — AR Transformer 입력 해부

그럼 각 모듈이 데이터의 디테일한 차이를 어떻게 구분할까요? 우선 AR 모듈입니다. 토큰의 입력은 세 임베딩의 합입니다. 좌표 임베딩은 3D 좌표를 linear layer로 256차원으로 변환합니다. scale embedding은 몇 번째 스케일인지 학습한 lookup table에서 가져옵니다. position embedding은 스케일에서 토큰의 위치를 상대 위치를 기준으로 보간합니다.

---

### Slide 15 — Flow Decoder 조건 구성 + Self-conditioning

다음은 flow decoder입니다. 디코더의 입력은 AR Transformer 출력, 스케일 임베딩, 그리고 self-conditioning입니다. self-conditioning에 대해서 자세히 설명드리겠습니다. 50%의 확률로 2-step forward를 진행하고 예측한 1-step Euler 결과를 조건에 넣습니다. 나머지 50%의 확률로는 self-conditioning 없이 1-step forward를 진행하여 디코더가 작동하도록 합니다. 오른쪽 그래프는 self-conditioning 유무에 따라 모든 단백질 길이에서의 sc-RMSD를 비교한 값인데, self-conditioning을 하였을 때 일관된 개선이 있었음을 확인할 수 있었습니다.

---

### Slide 16 — Exposure bias + NCL + SS

다음은 모델이 깨끗한 정답 데이터를 teacher forcing 함으로 발생하는 훈련과 추론의 데이터 분포의 차이인 exposure bias를 어떻게 해결했는지입니다. 저자들은 두 가지 방법을 채택했습니다.

우선 **SS(Scheduled Sampling)**입니다. 0.5 확률로 GT 대신 모델 자신의 1-step Euler 예측값을 컨텍스트로 사용하는 것입니다. 그 다음은 **Noisy Context Learning**으로 SS 결과에 추가로 가우시안 노이즈를 섞는 것입니다. w를 0~1 사이에서 매번 랜덤하게 뽑아서 정답과 노이즈를 섞습니다. 두 가지 방법을 모두 사용했을 때 모델의 성능이 32%가량 증가했음을 확인했습니다.

---

### Slide 17 — 추론 Walkthrough

이제 추론 과정은 어떻게 흘러가는지 살펴보겠습니다. "노이즈에서 시작해서 스케일별로 디코딩하고, 그 결과를 다음 스케일 조건으로 넘긴다"입니다.

- 스케일 1: BOS로 z¹ 만들고, 노이즈 ε¹에서 시작해 32점 x¹ 샘플링
- 스케일 2: Up(x¹)로 z² 만들고, 노이즈 ε²에서 64점 x² 샘플링
- 스케일 3: Up(x¹), Up(x²)로 z³ 만들고, 노이즈 ε³에서 128점 x³ 샘플링

KV cache를 활용해서 추론의 속도를 높였고, 항상 이전 예측값이 다음 예측의 context로 활용됩니다.

---

### Slide 18 — SDE + ODE 샘플링 전략

추론 과정에서 샘플링을 어떻게 하면 성능의 손실 없이 빠르게 할 수 있을까요? 거친 스케일은 SDE로, fine한 스케일은 ODE로 디코딩하는 방법입니다. 거친 스케일은 점이 적어서 SDE 비용도 싸지만 fine scale은 점이 많기에 비용이 비쌉니다. 따라서 단백질의 다양성을 결정하는 초기 스케일은 SDE로, 미세 구조를 결정하는 후기 스케일은 ODE로 빠르게 샘플링하여 다양성과 속도 두 마리 토끼를 모두 잡았습니다. Table 2를 보면 길이 200의 단백질 기준으로 Proteina에 비해 2.5배나 빠르지만 designability는 증가했습니다.

---

### Slide 19 — Method 정리

지금까지 method를 한 장으로 정리하겠습니다. 한 줄로 요약하면, **"coarse-to-fine으로 한 스케일씩, 각 스케일은 flow로 채운다"**입니다. 학습과 추론 과정의 차이, 모델의 특징과 수식을 다시 확인하실 수 있습니다.

---

## C. Results

### Slide 20 — Unconditional 생성 결과

그럼 이제부터 PAR의 결과를 확인해보겠습니다. PDB 데이터 기준으로 학습된 PAR의 경우 FPSD 161로 역대 최저, Designability 96.6%, sc-RMSD 1.04, Novelty 0.85로 계산되었습니다. 비교가 되는 단백질 생성 모델인 FrameDiff, RFDiffusion, ESM3, Genie2, Proteina에 비해 품질, 자연스러움, 새로움을 다 잡았다고 저자들은 주장합니다.

---

### Slide 21 — FPSD가 왜 필요한가

이미 FPSD라는 지표가 생소하실 텐데요. FPSD라는 지표가 무엇이고 왜 필요한지 잠깐 설명하겠습니다. 익숙하실 sc-RMSD나 TM-score는 단백질 하나하나의 품질만 봐서 다양성을 판단하기 어렵습니다. FPSD는 이미지 FID를 단백질에 가져온 개념으로, Fold Class Predictor로 3D 좌표를 특징 벡터로 바꾸고, 실제 분포와 생성 분포를 가우시안으로 근사한 뒤 Wasserstein-2 거리를 잽니다. 따라서 품질뿐만 아니라 다양성도 반영되는 지표입니다. RFDiffusion 254, Proteina 282인데 PAR_pdb 161으로 압도적으로 다양하고 품질 좋은 단백질을 모델이 생성하고 있음을 보여줍니다.

---

### Slide 22 — Zero-shot point prompt

지금까지 unconditional protein generation을 살펴봤습니다. 이제부터 zero-shot 조건부 생성 파트로 넘어가겠습니다. 우선 사용자의 프롬프트에 따라서 지정된 모양의 단백질을 만드는 point prompt에 대해서 말씀드리겠습니다. 여기 그림에 있는 것과 같이 글씨 쓰듯이 생성할 단백질의 모양을 그려주면, 이에 맞추어서 단백질을 생성합니다. 놀라운 점은 PAR을 따로 fine-tuning 할 필요 없는 zero-shot 모델이라는 점입니다. 원리는 입력받은 16개의 3D 좌표 점들을 첫 번째 스케일의 입력으로 강제로 지정하는 것입니다. 이를 context로 AR이 상위 스케일을 생성합니다.

---

### Slide 23 — Zero-shot motif scaffolding

두 번째 zero-shot 조건부 생성은 motif 좌표를 고정하고 나머지 scaffold를 만드는 것입니다. Figure 4에서 보면 알 수 있듯이, 노란색 motif 부분을 고정하면 PAR이 motif는 고정된 채로 scaffold를 생성합니다. 이것의 원리는 지정한 모티프 부분을 각 스케일에서 Ground Truth로 교체하여 context로 전달하기 때문입니다. 이러한 생성 방법은 효소의 활성부위, 단백질의 결합 residue를 유지한 채로 새로운 단백질을 설계하는 데 활용될 수 있겠습니다.

기존의 다른 diffusion 모델들과 어떤 점이 다른가 하면, PAR은 fine-tuning 없이도 motif scaffolding이 가능한 zero-shot 모델이라는 점입니다. Table 11에서 비교를 진행했는데 PAR이 잘한 케이스도 있고, 못한 케이스도 있어서 엄청나게 성능이 좋다고 이야기하기는 어렵습니다. 이 부분은 한계점 파트에서 다시 말씀드리겠습니다.

---

### Slide 24 — 왜 zero-shot이 가능한가

다음 슬라이드는 zero-shot 조건부 생성의 두 가지 방법을 정리한 슬라이드입니다. AR의 순차적 조건부 구조가 "거친 조건을 미세 스케일로 자동 전파하는" 메커니즘 그 자체이기 때문에 fine-tuning 없이 zero-shot으로 조건부 생성이 가능합니다.

---

### Slide 25 — 해석: Attention map

다음은 모델이 정말 coarse-to-fine을 학습했는지, 내부를 들여다보겠습니다. 5×5 attention map입니다. 세로축이 현재 생성 중인 스케일, 가로축은 참고하는 이전 스케일인데 x=k 위치가 실제로는 scale (k-1)의 업샘플이라고 생각해주시면 됩니다. attention map을 통해 3가지 사항을 관찰할 수 있습니다. PAR 모델이 BOS 토큰은 거의 무시하고, 각 스케일은 직전 스케일을 가장 강하게 attend한다는 점입니다. 또한 직전이 아닌 스케일도 완전히 버리지 않고 참고하고 있다는 점입니다. 그리고 AR 모듈의 트랜스포머 레이어가 깊어질수록 직전 스케일에 더 집중하는 경향이 있다는 것도 확인할 수 있었습니다. 이를 통해 모델이 스스로 coarse-to-fine 구조를 학습했다고 할 수 있습니다.

---

### Slide 26 — Scaling behavior

다음으로 AR 모델의 장점인 scaling law가 PAR 모델에서도 성립하는지 확인해보겠습니다. 모델의 크기가 커지면 FPSD, fS, RMSD metric 모두 좋아지는 것을 확인할 수 있었습니다. 또한 training step을 증가시키면 모든 모델 크기에서 지속적으로 개선되는 것을 통해서 아직 모델이 수렴하지 않았고, 더 학습하면 좋아질 가능성이 있음을 뜻합니다. 흥미로운 점은 Table 12를 보면 AR 모듈보다 디코더를 키우는 게 훨씬 효과적이었습니다. AR의 크기만 키우면 오히려 성능은 떨어지는 것을 확인할 수 있었습니다. 즉 구조 생성 품질은 디코더의 크기에 비례합니다.

---

### Slide 27 — Quality-diversity trade-off (γ)

다음은 샘플링 단계에서 품질과 다양성을 조절하는 방법입니다. 샘플링 할 때 SDE와 ODE를 섞어서 사용하는데, 이때 SDE의 감마 값을 통해 재학습 없이 designability와 다양성을 조절할 수 있습니다. 감마 값을 낮추면 경로가 더 결정론적으로 변하여 생성된 구조의 품질이 높아집니다. 반면 감마 값을 높이면 모델이 더 넓은 구조 공간을 탐색해서 다양성이 증가합니다. Table 10은 designability와 다양성의 합이 최대가 되는 sweet spot을 찾은 것인데, 그 값은 0.6이라고 합니다.

---

### Slide 28 — Limitations

지금까지 장점 위주로 소개했는데, 이제부터는 한계점에 대해서 말씀드리겠습니다.

- **첫 번째**: PAR 모델이 생성하는 단백질은 Cα만 있다는 점입니다.
- **두 번째**: 생성할 단백질의 길이와 학습과 추론에 쓰일 스케일의 수를 미리 정해야 한다는 점입니다.
- **세 번째**: motif scaffolding이 zero-shot이라 fine-tune baseline보다 성능이 낮은 편이며, 이렇게 모티프를 고정해서 생성한 단백질이 실제 실험 환경에서 안정하게 유지된다는 보장이 없습니다.
- **네 번째**: point prompt는 전체 단백질 형태를 제어할 뿐이고, 타겟에 결합하는 binder 설계 같은 기능 조건을 받아서 구조를 생성하는 기능이 없다는 점입니다.

저자들도 이를 인지하고 future direction으로 all-atom 생성, conformational dynamics로 확장, 다중 체인과 이종 분자에 대한 확장을 제시합니다.

---

## D. Wrap-up

### Slide 29 — Take-home message

핵심을 한 장으로 정리하겠습니다.

1. PAR은 Multi-scale AR + Flow, 새로운 패러다임을 제시하였다.
2. FPSD 161로 베이스라인 모델들과 비교했을 때 자연 단백질 분포에 가장 가까운 단백질 구조를 생성하는 모델이다.
3. AR 기반이기에 fine-tune 없이 zero-shot으로 point prompt, motif scaffolding과 같은 조건부 생성이 가능하다.

즉 PAR은 **"coarse-to-fine으로 한 스케일씩, 각 스케일은 flow로 채운다"는 단순한 아이디어가 단백질 백본 생성의 새 기준을 만들었습니다.**

---

### Slide 30 — Implications: CrypticFlow 관점

여기서 끝나면 아쉽겠죠? 그럼 PAR 연구를 저희 연구에 어떻게 적용할 수 있을까요? PAR 논문 Discussion에 "같은 coarse-to-fine 매핑으로 protein conformation 예측 확장 가능"이라고 적혀 있습니다. 이는 torsional 공간에서 apo를 입력으로 holo 구조를 생성하는 제 과제인 CrypticFlow와 관련이 있습니다. 이미지 분야 VAREdit, ControlVAR 같은 VAR 기반 조건부 생성 논문들이 "source→target" 변환을 next-scale AR로 구현했는데, 이걸 apo→holo에 적용하는 아이디어를 현재 탐색 중입니다. 그리고 현재 제 모델이 ODE를 활용해서 학습 및 추론을 하기에 추론 과정에서 exposure bias를 크게 겪고 있습니다. 이에 PAR에서 사용된 self-conditioning, NCL, SS 같은 방법을 적용해 볼 수 있을 것 같습니다.

---

### Slide 31 — Implications: Drug discovery

그리고 저희 연구실의 주제인 신약개발과 연관을 지어 생각해봤습니다. motif scaffolding과 point prompt를 docking·design 파이프라인에 바로 응용 가능해 보입니다. 효소 활성부위 보존, binding pocket을 공유하는 단백질의 다양화, binder 후보 탐색에 활용 가능하며 fine-tune 없이 zero-shot으로 사용 가능합니다. 추가적인 장점은 triangle module이 없어서 속도가 빠르고 메모리를 적게 소모합니다. 그리고 앞에서 이야기했던 것처럼 감마 값을 조절해서 모델의 다양성과 품질을 원하는 대로 조절할 수 있습니다.

---

### Slide 32 — OpenReview 리뷰

마지막으로 PAR 논문은 ICLR에서는 리젝당했는데, 오픈 리뷰에 리뷰어들이 지적한 내용들이 있어서 가지고 왔습니다.

- **칭찬**: 최초 multi-scale AR, NCL+SS, 우아한 접근
- **지적**: Proteina 대비 우위 불명확, AR 기여도 모호, 긴 단백질 성능 저하

저자는 추가 실험으로 대응했지만 리젝당하고 ICML에 제출해서 accept된 것으로 생각됩니다. 올해 ICML은 7월에 서울 코엑스에서 열리니 관심 있으신 분들은 가셔서 내용을 확인해보셔도 좋을 것 같습니다.

---

### Slide 33 — Thank you & Q&A

들어주셔서 감사합니다.

---

## Appendix (Q&A 백업, Slide 34–43)

| 슬라이드 | 내용 |
|---------|------|
| 34 (A) | PAR vs Proteina inference 설정 + Self-conditioning (Fig 8) |
| 35 (B) | AR Transformer 역할 검증 (Table 5) |
| 36 (C) | 긴 단백질 생성 & Scale-Agnostic Inference |
| 37 (D) | SDE/ODE 오케스트레이션 designability 분석 (Fig 7) |
| 38 (E) | Table 1 Metric 의미 & 계산 방법 |
| 39 (F) | KL vs Wasserstein-2 비교 |
| 40 (G) | Unique Solutions & Novelty 계산 방법 |
| 41 (H) | Attention Score Matrix 계산 과정 |
| 42 (I) | fS 계산 방법 & γ sweet spot |
| 43 (J) | sc-RMSD & TM-score 계산 방법 |

---

*발표 자료: `par_presentation.html` | 서버: `http://147.46.139.205:8765/par_presentation.html`*
