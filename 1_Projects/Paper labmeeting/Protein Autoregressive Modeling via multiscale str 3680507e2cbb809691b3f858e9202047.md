---
tags:
aliases:
cssclasses:
TQ_short_mode:
---
# Protein Autoregressive Modeling via multiscale structure generation

Type: Model
Published year: 2026
URL: https://par-protein.github.io/
Journal/Conference: ICML
Keyword: generative model
Status: 진행 중
Published Date: 2026년 5월 20일
Accept/Reject: accepted
Summary Writer: minjongkim

# Summary

기존의 단백질 생성 AI(예: 전 세계적으로 유명한 RFDiffusion 등)는 주로 **'디퓨전(Diffusion) 모델'**을 기반으로 했습니다. 하지만 이 논문은 ChatGPT 같은 생성형 AI의 핵심 기술인 '자기회귀(Autoregressive, AR) 모델' 방식을 단백질 구조 생성에 최초로 성공적으로 적용

first multi-scale autoregressive frameowrk. 조각을 coarse에서 fine한 구조로 다듬는 것과 유사하다. 이를 위해서 PAR은 3가지 부분으로 구성되어 있다. 

1. multi-scale downsampling operator
    
    학습도중에 단백질을 multi scale로 표현하는 모듈
    
2. autoregressive transformer
    
    multi scale 정보를 인코딩하고, 단백질 구조 생성을 가이드 하기 위해 conditional embedding을 생성함
    
3. flow-based backbone decoder
    
    앞서 만든 조건들에 맞추어 백본의 원자들을 생성하는 디코더
    

일반적으로 AR모델은 학습과 생성과정의 불일치에 의한 exposure bias에 시달려 단백질 구조 생성 퀄리티가 떨어진다. 우리는 이를 noise context learning과 scheduled sampling으로 이를 완화하여 강력한 백본 생성을 가능하게 하였다. PAR은 미세조정 없이 (zero shot) 생성가능하기에, 사람이 프롬프르토 넣은 조건부 생성과 motif sacffolding을 fine tunning 없이 가능하다. 비조건부 생성 벤치마크에서 PAR은 효율적으로 단백질 분포를 학습하고 높은 퀄리티로 단백질 백본을 생성하였고 유리한 스케일링 동작을 나타낸다. 이는 PAR을 단백질 구조 생성의 유망항 프레임 워크로 확립시킴. 

# Background

기존 단백질 생성 모델은 Ca 위주로 생성하고 diffusion과 flowmatching이 활용되었다. AR이 사용되기 어려웠던 이유는 1). 단백질은 시퀀스상 멀리 떨어진 residue 끼리 3D 공간에서는 매우 가까울 수 있는 강한 양방향성 의존성이 있기 때문이다. 따라서 왼쪽부터 오른쪽으로 순차적으로 하나씩 생성하는 AR 방식이 잘 맞지 않는다. 또한 2). 좌표가 이산화 되어 있지 않고 연속적인 데이터이기에 이를 이산화 해서 AR 하면 데이터의 미세한 세부사항 요소를 감소시켜 생산 성능이 떨어질 수 있다.

AR은 기본적으로 불연속 데이터에 성공을 거둔 모델이다. 왜냐면 과거의 토큰은 기반으로 다음 토큰을 예상하는데 사용했기 떄문이다. 연속인 데이터를 그대로 AR에 사용하면 문제가 있다.

억지로 데이터를 이산화 해서 AR에 넣으면 미세한 기하학적 세부 정보가 손실됨

또한 AR은 단방향성으로 예측한다. 하지만 단백질은 강력한 양방향성 상호작용을 한다. 

→토큰으로 쪼개지 말고, 연속적인 3D 공간을 통째로 유지하면서 AR을 적용하자!

**해결책 1: Next-Scale Prediction (스케일 단위 자기회귀)**

아미노산을 1번, 2번 순서대로 한 땀 한 땀 예측하는 방식을 버렸습니다. 대신 **"거친 해상도의 3D 점구름 $‭\rightarrow$‬ 정밀한 해상도의 3D 점구름"**이라는 **해상도 스케일 순서로 자기회귀**를 시켰습니다. 이 덕분에 3D 공간의 양방향 상호작용을 트랜스포머가 한눈에 바라보며 학습할 수 있게 되었습니다.

**해결책 2: AR 트랜스포머와 Flow 디코더의 이원화**트랜스포머

트랜스포머($‭\mathcal{T}_\theta$‬)에게 연속적인 좌표들의 맥락을 읽어 부드러운 '가이드라인 벡터(‭$z^i$‬)'만 만들게 유도하고, 실제 원자 좌표를 뿌리는 정밀한 작업은 **연속 공간 모델링의 최강자인 플로우 매칭 디코더($‭v_\theta$)**에게 전담시켰습니다.

# Method
![[Pasted image 20260528144716.png]]


조각가가 먼저 큰 형태를 만들고 나중에 디테일을 다듬는 방식

동그라미가 많을 수록 해상도가 높다.

- multi-scale downsample

구조적 맥락 및 타겟으로 사용도리 coarse-fine representation 생성. 학습시에만 필요하고, inference에는 입력 단백질이 없기에 downsampling 하지 않음. 

- AR transformer

non equivarient attention layer. 스케일별 조건부 임베딩을 생성하기 위해 모든 이전 스케일을 인코딩함.

다중 스케일 정보를 인코딩하고 구조 생성을 안내하기 위한 조건부 임베딩을 생성함.

각 스케일에 대한 조건 정보 $z^i$를 만듬

- flow based backbone decoder

$Z^i$를 조건으로 받아서 flow based decoder $v_\theta$ 가 해당 scale의 실제 백본 좌표 $x^i$를 생성하는 과정

이전 스케일을 다음 스케일에 맞게 길이를 upsampling 하여 transformer의 입력으로 사용함.

$z^i = T_\theta\bigl([bos,\ \mathrm{Up}(x^1, \mathrm{size}(2)),\ \dots,\ \mathrm{Up}(x^{i-1}, \mathrm{size}(i))]\bigr)$
[] → concatenate

$x_0^i \sim \mathcal{N}(0,I)$

생성된 이전 스케일들을 serial하게 transformer에 넣어 다음 스케일 조건을 만들고, 각 스케일의 decoder는 새 noise에서 시작해서 그 스케일 구조를 생성

upsampling 왜 필요? 이전 scale은 정보가 현재 scale보다 적기에, 현재 scale의 길이에 맞추어서 정렬

train 시 $x_t^1,x_t^2$는 “입력으로 주어지는 하나의 고정 noisy sample”이 아니라 sampling trajectory의 상태

$x_t^i = t_i x^i + (1-t_i)\epsilon^i$

깨끗한 구조 $x^i$와 노이즈를 선형보간해서 trajectory sample인 $x_t^i$를 만듬

근데 inference에서는 ground truth $x^i$  가 없음.

대신 샘플링 과정 자체가  $x_t^i$  를 만듬.

$x_{t=0}^i \sim \mathcal{N}(0,I)$

추론시에는 각 스케일마다 shape만 다른 독립 Gaussian noise에서 시작한다.

이후 ODE 혹은 SDE를 통해 점진적으로 xi 스케일 구조를 만듬

추론시 i번째 스케일을 만들때 이전 스케일들은 AR를 통과해 조건부 임베딩으로 사용되고, 입력은 독립된 가우시안 노이즈에서 출발. 즉 이전 스케일 구조는 가이드 역할만 수행함.현재 스케일 decoder는 그 가이드를 따라 자기 해상도에서 구조를 새로 생성

$z^n = T_\theta([\text{bos}, \text{Up}(x^1), \dots, \text{Up}(x^{n-1})]), \qquad x^n \sim p_\theta(\cdot \mid z^n)$

$p_\theta(x^i \mid z^i)$

 noise에서 시작하는 flow-matching sampler

ex) 10step ODE integration 과정

$x_{0.1}^2 = x_0^2 + 0.1 \cdot v_\theta(x_0^2, 0, z^2)$

$x_{0.2}^2 = x_{0.1}^2 + 0.1 \cdot v_\theta(x_{0.1}^2, 0.1, z^2)$

 스케일 2를 생성하는 동안 z2는 고정

SDE 과정

$dx_t = v_\theta(x_t,t)\,dt + g(t)s_\theta(x_t,t)\,dt + \sqrt{2g(t)\gamma}\,dW_t$

주소 표기는 노이즈에서 얻은 각 스케일의 노이즈 점들에 순서를 부여하는 것. 로 생성된 노이즈 점들이 3차원 공간에서 미아가 되지 않도록, 최종 단백질 길이(‭$L$‬)를 기준으로 균일하게 쪼갠 '서열상의 주소(Position ID)'를 세트로 묶어서 디코더에 함께 입력해 주줌

Q: un conditional generation은 이해가 되는데 conditional generation은 추론을 어떻게 하지?

- 프롬프트의 경우 사용자가 입력한 값을 첫번째 스케일인 X1으로 취급하고, AR과 decoder를 거쳐서 해상도를 높여나간다. 즉 프롬프트는 프롬프트는 "전체 생성의 출발점이 되는 coarse structure" 역할을 한다. → 엔지니어링에 사용할 수 있을지도?
- motif가 주어질 때, 모티프에 해당하는 좌표를 각 스케일에서 계속 유지함.원 단백질 구조를 여러 스케일로 downsample한 뒤, 각 스케일에서 ground-truth motif coordinates를 teacher-force하여 다음 스케일로 전달함.  입력으로 motif 원자의 좌표가 주어지면, 이 부분만 각 스케일에서 알려진 조건으로 사용함. 어떤 스케일 i 에서 전체 백본을 생성할떄 모티프 영역을 ground truth motif로 유지하거나 대체. 나머지 스캐폴딩은 모델이 생성.

teacher forcing:  일반 AR에서 teacher forcing은 이전 단계의 모델 예측 대신 ground truth를 다음 단계 입력으로 넣는 것. 하지만 PAR은 다르다! . motif scaffolding에서 원 구조를 여러 스케일로 downsample한 다음, 각 스케일에서 ground-truth motif coordinates를 teacher-force하여 다음 스케일로 전달. 즉 각 모티프 부분의 정답 좌표를 다음 단계 문맥으로 직접 넣음. 

$x_i^{\text{ctx}} = \text{Merge}(\tilde{x}_i,\; x_i^{\text{motif-gt}})$

모티프 구간만 ground truth로 강제 교체한 구조를 문맥으로 넘김.

하지만 decoder는 그 스케일의 전체 백본을 한 번에 생성하므로, 생성 후에는 모티프 구간을 다시 ground-truth motif로 덮어쓰는(replace) 과정이 필요함clash나 discontinuity를 피하기 위해, 교체 전에 ground-truth motif residues와 생성된 motif segments를 superimpose한다. 즉 전체를 생성한 다음 모티프 부분을 다시 정답으로 맞춰준다

- 예시
    
    최종 단백질 길이: L = 128, 5-scale PAR 사용:
    
    $S = \{16, 32, 64, 96, 128\}$
    motif는 원 구조에서 residue 45 \sim 55 구간의 helix라고 해봅시다.
    
    먼저 원 구조에서 motif 구간을 포함한 backbone이 주어져 있습니다.
    이 전체 구조를 각 스케일로 downsample하면:
    $x_1^{\text{gt}}, x_2^{\text{gt}}, x_3^{\text{gt}}, x_4^{\text{gt}}, x_5^{\text{gt}}$
    가 생깁니다 .그리고 motif도 각 스케일에서 대응되는 위치로 downsample됩니다.
    예를 들어:스케일 16에서는 motif가 점 2개,스케일 32에서는 점 3개,스케일 64에서는 점 6개,스케일 128에서는 원래 $residue 45 \sim 55$ 전체처럼 나타날 수 있습니다.
    
    스케일 1
    
    보통 unconditional이면 x1 전체를 생성합니다.
    motif scaffolding에서는 스케일 1에서도 전체 $\tilde{x}_1$을 생성할 수 있지만,
    다음 단계로 넘기기 전에 motif 점들만 정답으로 바꿉니다.
    $\tilde{x}_1 \rightarrow \hat{x}_1$
    
    여기서 $\hat{x}_1$은 motif 영역만 ground truth를 가진 구조입니다.그 다음 transformer에는 $\hat{x}_1$이 들어갑니다.
    즉 다음 스케일의 문맥은 "이미 motif가 맞춰진 coarse structure"입니다.
    
    스케일 2
    
    transformer는 $\hat{x}_1$을 upsample한 구조를 보고 $z_2$를 만듭니다.
    decoder는 $z_2$조건에서 스케일 2 구조 전체 $\tilde{x}_2$를 생성합니다.하지만 $\tilde{x}_2$x의 motif 부분이 정답과 조금 다를 수 있습니다.
    
    그래서:생성된 motif segment와 ground-truth motif를 정렬한다.motif 부분만 교체한다.
    
    결과를 $\hat{x}_2$라고 둔다.다음 단계에는 $\hat{x}_2$를 넘긴다.
    
    마지막 스케일 5
    
    최종 full-resolution backbone $\tilde{x}_5$*를 생성한 뒤에도 motif 구간은 다시 교체합니다.그래서 최종 출력은:
    $x_{\text{final}} = \hat{x}_5$* 입니다.즉 최종 설계 결과는motif 좌표는 사실상 주어진 정답과 일치하고,나머지 scaffold만 모델이 생성한 구조가 됩니다.이게 바로 motif scaffolding입니다.
    

Point prompt: x1을 모델이 샘플링하지 않고 외부 prompt로 지정

Motif prompt: 각 스케일의 생성 결과 중 motif 부분을 외부 좌표로 계속 고정/교체

motif residue와 생성된 segment 사이의 clash나 discontinuity를 피하려고, replacement 전에 motif와 생성 segment를 superimpose한다.

Q). 그럼 조건부 생성 어디에다 써먹어?

효소의 활성부위 보존하고 나머지 구조는 재설계, 결합 인터페이스 이식, 금속 이온 결합이나 소분자 결합에 상호작용하는 단백질 residue 배치와 geometry를 유지 → 결과가 diverse 함

근데 motif를 고정하여 생성한다고 해도, 단백질이 안정한 상태에서 motif가 유지된다고 이야기 할수는 없지 않나? (한계점)

프롬프트는 shape first design, assembly-compatible shape design, t사람이 개입하는 interactive design→ 형상제어에는 좋지만 기능 제어에는 좋지 않음

Q). 무조건/조건부 생성에서 단백질 길이, 스케일 수는 지정해줘야하지 않을까?

길이와 스케일을 넣어줘야함으로 엄밀하게 말하면 무조건 생성도 길이 스케일 조건부 생성임.

스케일은 엄밀히 말하자면 scale by length로 넣어줌.

AR transformer의 첫 입력으로 learnable bos를 사용

단백질 전체 길이는 최종 출력의 형태를 결정하고, 각 스케일에서의 positional index를 결정하고

학습시 스케일과 추론시 스케일이 달라도 괜찮나?

Q). scale embedding?

scale embedding은 "지금 decoder가 몇 번째 스케일의 구조를 생성 중인지"를 알려주는 learnable ID 벡터

공유된 decoder가 여러 스케일을 처리하려면, 입력 길이만으로는 부족할 수 있기 때문입니다.
예를 들어 둘 다 길이 64로 보이더라도,어떤 경우는 중간 스케일의 거친 centroid 구조일 수 있고,어떤 경우는 다른 schedule에서 사실상 최종 출력에 가까운 구조일 수 있습니다.논문도 scale마다 통계적 특성이 다르기 때문에 이를 구분하기 위해 unique scale id를 모델에 넣는다고 설명함.

Q). 스케일 계획이 규칙적으로 증가해야할까?

굳이 글러필요는 없지만 너무 불규칙하면 학습 및 추론이 어려움

Q). 학습할때와 추론시의 스케일수가 달라도 괜찮나?

놉.  scale embedding 차원이 고정된 스케일 수에 묶여 있기 때문에, 학습 때와 다른 스케일 수로 바로 inference할 수 없다. 저자들은 이를 보완하기 위해 cale embedding을 제거한 모델을 따로 fine-tune함. 이경우에는 다른 scale configuration으로 inference가 가능. 하지만 성능이 유지되지 않음. 논문은 3-scale 모델을 5-scale inference로 돌렸을 때 FPSD는 비교적 안정적이지만 designability가 크게 떨어졌다고 보고됨.

Q). up sampling 해서 해상도를 맞춘다고 해도, 직전 스케일의 해상도만 맞지, 더 이전 스케일의 해상도는 현재 스케일의 해상도보다 떨어지는거 아닌가?

transformer에 넣을 때는 모든 이전 스케일을 현재 스케일 길이로 각각 upsample해서 shape를 맞춤, 스케일 i의 조건 임베딩을 만들 때, 이전 스케일들을 모두 현재 스케일 크기로 upsample해서 transformer에 넣는다. 즉 즉 coarse scale과 fine scale이 모두 같은 전체 길이 L 위의 상대적 위치를 공유하도록 만드

L=128이 최종 출력 크기와 positional index 범위를 정하고, $S=\{16,32,64,128\}$같은 4단계 스케일 계획이 autoregressive 생성 루프를 정합니다. 추론은 첫 스케일에서 bos로 시작해 x_1x1x_1x1을 생성하고, 이를 upsample하여 다음 스케일 문맥으로 넣는 과정을 반복해 최종 1$28 \times 3$1 backbone을 생성합니다.

# Result

단일 샘플링에 비해 2.5배 빠른 속도를 달성함.

Q). self conditioning 이란?

```jsx
[현재 노이즈 상태의 좌표 x_t] 
       │
       ▼ (1) 1차 통과 (Pass 1) : "대충 완성본 상상해보기"
[Flow Decoder v_θ] ──> [최종 완제품에 대한 대략적인 예측치 x̂]
       │                                       │
       └───────────────────┬───────────────────┘
                           ▼ (2) 2차 통과 (Pass 2) : "상상도를 힌트로 받아 진짜 예측하기"
                     [Flow Decoder v_θ (Conditioned on x̂)]
                           │
                           ▼ (3) 최종 출력
                     [훨씬 정밀하고 안정한 다음 단계 좌표 x_t+1]
```

AR 모듈이 주는 가이드는 **"스케일 간의 거친 위상학적 문맥(Global Layout)"**인 반면, Self-conditioning이 주는 가이드는 **"현재 스케일 내부에서 디코더가 노이즈를 걷어낼 때 쓰는 국소적 나침반"** 역할을 하기 때문에, 두 기법이 서로 완벽하게 보완(Complementary)되며 단백질의 구조적 품질을 극대화하게 됩니다.

1 step euler 결과를 condition으로 넣는다.

Q). VQVAE?

일반적인 오토인코더(Autoencoder)나 VAE는 데이터를 입력받아 연속적인 숫자(Continuous Vector) 형태의 잠재 공간(Latent Space)으로 압축합니다.

반면, VQ-VAE는 이 잠재 공간을 무한한 연속적 숫자가 아니라, 딱 정해진 개수의 '대표 벡터'들이 모여 있는 '코드북(Codebook)'이라는 불연속적인(Discrete) 공간으로 바꿉니다.

단백질 구조를 VQ-VAE처럼 딱딱 끊어지는 정해진 코드북 대표값(Structure Token)으로 강제 변환하면 **태생적으로 정밀한 물리적 세부 정보(Discretization Loss)가 다 날아가 버립니다**. 그래서 PAR는 VQ-VAE 방식을 버리고, **좌표를 연속적인 숫자(Continuous) 상태 그대로 유지하되 스케일만 조절하며 예측하는 독창적인 아키텍처를 깎아 만든 것. 구조의 연속적 특성을 온전히 보존하면서도 멀티스케일 방식을 도입해 트랜스포머의 자기회귀적 이점을 누리도록 설계함.**

- metrics
    - sc-RMSD
        
        self-consistency RMSD로, 설계한 서열을 다시 fold했을 때 생성 구조와의 차이
        
        $\text{RMSD} = \sqrt{\frac{1}{N}\sum_{i=1}^{N}\|\mathbf{x}_i - \hat{\mathbf{x}}i\|^2}$
        
    - Designability (%)
        
        생성 구조에 대해 ProteinMPNN으로 서열을 설계하고, ESMFold로 다시 접었을 때 원래 구조와 잘 맞는 경우의 비율
        
    - fs (C/A/T) Class/Architecture/topology (점점 세밀해짐 scale 1,2,3)
        
        AI가 생성한 단백질 구조가 얼마나 생물학적으로 '그럴듯한 품질(Quality)'을 가졌는지, 그리고 얼마나 '다양한 형태(Diversity)'로 디자인되었는지를 동시에 측정
        
        `fS`는 **점수가 높을수록 개별 단백질의 완성도(품질)가 높고 생성된 종류(다양성)가 풍부하다는 뜻**
        
        CATH는 단백질을 **C**(Class, 이차구조 함량), **A**(Architecture, 대략적인 형태), **T**(Topology, 세부 연결성)라는 계층 구조로 분류
        
        분포 수준 평가를 위해 길이 60부터 255까지, 간격 5로 각 길이마다 125개씩 총 5000개 구조를 샘플링하고, designability filtering 없이 전부 사용 →그 다음 각 생성 구조를 fold class predictor에 넣어, 해당 구조가 어떤 fold class에 속할 확률분포를 얻는다. 이를 기반으로 생성된 모든 단백질에 대한 조건부 확률 분포를 전부 더해서 평균을 낸다. (다양한 단백질을 만들 수록 이 그래프는 퍼진다.) 개별 단백질의 분포와 집단 전체의 분포간의 KL divergence를 계산한다 
        
        (어떤 샘플이 아주 그럴듯하면 predictor가 한두 개 class에 높은 확신을 보일 것이고, 품질이 낮거나 애매하면 분포가 퍼질 가능성이)
        
          계산 방법은 사전 학습된 구조 분류 신경망을 통해 개별 생성물의 **조건부 확률 분포**를 구하고, 이들의 평균인 **한계 확률 분포**를 도출한 뒤, 두 분포 간의 **KL-Divergence**를 연산하여 최종 점수를 산출
        
        $fS \propto \exp\left( \mathbb{E}{x} \left[ D{\mathrm{KL}} \big( p(y \mid x) \,\|\, p(y) \big) \right] \right)$
        
        - FPSD: "실제 데이터 분포와 얼마나 비슷한가?"
        - fS: "생성 샘플이 fold 관점에서 얼마나 또렷하고 다양한가?”
    - Diversity TM-Sc
        
        생성 샘플들끼리 서로 얼마나 비슷한지 보는 지표. 평균 pairwise TM-score가 낮을수록 더 diverse
        
    - Novelty TM-Sc
        
        생성 구조가 학습 데이터의 기존 구조와 얼마나 다른지 보는 지표. 일반적으로는 훈련 셋 복사 여부를 보는데 사용된다.
        
    - Sec. Struct. % (α/β)
        
        생성된 구조에 포함된 alpha helix / beta sheet 비율
        
    - FPSD (Fréchet Protein Structure Distance)
        
        생성된 구조 분포와 실제 데이터 분포가 얼마나 가까운지 측정
        
        FID의 단백질 버젼. 기존에 AI가 만든 단백질이 우수한지 평가할떄, sc-RMSD 나 TM-score 같은 지표를 사용했다. 하지만 이 지표는 단백질 하나하나가 자연계의 정답 단백질과 얼마나 똑같이 생겼는지만 검사함. 즉 다양성이 반영되지 않는다. FPSD는 AI가 생성한 단백질의 분포와 실제 단백질의 분포를 통제로 비교하여 구조적 품질과 다양성을 동시에 스캔할 수 있는 지표이다. 점수가 낮으면 낮을수록 AI가 실제 자연계의 단백질 분포를 완벽하게 모사했다는 뜻. 
        
        - 계산법
            
            실제 단백질 집단과 AI가 생산한 단백질 집단에서 3D 구조 특징을 추출하도록 훈련도니 신경망을 이용해서 좌표를 벡터로 변환한다. 변환한 분포간의 평균과 분산을 계산하고, 가우시안 분포사이의 최단 거리를 구하는 수학 공식 (Wasserstein-2 Distance)을 이용해서 최종 거리 점수를 도출함.
            
        - 결과
            
            AFDB 대비 FPSD가 PAR(400M)모델은 211.8을 기록하며 대조군 중 최상위권. PDB subset으로 fintunning을 진행한 PAR_PDB 모델은 FPSD가 161.0까지 떨어진다.
            
        - 의미
            
            단일 스케일 디퓨전 모델의 강자인 RFDiffusion(253.7)이나 Genie2(350.0)보다 **압도적으로 낮은(우수한) 수치**입니다. 즉, PAR가 기존 디퓨전 모델들보다 **"자연계에 존재하는 실제 단백질 고유의 복잡한 3D 구조적 분포와 다양성을 훨씬 더 사실적으로 정밀하게 학습해 낸다
            
        - 질문들
            - 특징 추출 신경망의 표준이 존재하나?
                
                이미지 분야의 FID처럼 전 세계 연구자가 무조건 똑같이 쓰는 '완전한 범용 표준 신경망'은 단백질 분야에 아직 존재하지 않음. 하지만 준 표준으로 사용되는 Protenia의 프로토콜을 사용함. 단백질의 3D 좌표 데이터를 입력받아 고유의 접힘(Fold) 모양을 분류하도록 사전 학습된 **Fold Class Predictor** 신경망을 사용함.
                
    - **Wasserstein-2 Distance (와서스테인 거리)**
        
        
        $d^2 = \|\mu_A - \mu_B\|^2 + \text{Tr}(\Sigma_A + \Sigma_B - 2(\Sigma_A\Sigma_B)^{1/2})‬‭‬‭‬‭‬‭‬‭‬‭‬‭‬‭‬‭‬$ (프레셰 거리)
        
         흔히 '최적 운송 거리(Optimal Transport Distance)' 또는 **'Earth Mover's Distance (포크레인 거리)'**라는 직관적인 별명으로 불립니다. KL Divergence의 경우 두 분포가 겹치는 영역이 없으면 거기를 측정하지 못하는 단점을 상쇄한 개념.
        
           AI 단백질 분포와 실제 단백질 분포를 수백 차원의 기하학적 흙더미로 가정하고, 하나의 분포를 다른 분포로 변형하기 위한 **최적의 구조적 운송 비용**을 계산하는 지표
         PAR 모델은 이 최적 운송 거리(FPSD)를 기존 모델 대비 수십 점 이상 단축함으로써 자연계의 실제 단백질 분포와 가장 통계적으로 유사한 구조를 생성해 냈음을 입증함.
        

Q). zero shot generation ?

A). AI가 한 번도 특별히 연습(추가 학습)해본 적 없는 새로운 지시나 조건에 대해, 그동안 쌓아온 기본기만으로 즉석에서 정답을 만들어내는 능력. 기존 모델들처럼 특정 도메인이나 타겟 기능(스캐폴딩, 가이드 생성 등)을 위해 수천 개의 커스텀 데이터를 모아 **모델을 재학습(Fine-tuning)할 필요가 없다.**

Q). Self conditioning 

[주된 기여]

1. 기존 AR의 한계를 해결하는 단백질 백본 생성을 위한 최초의 단중 스케일 AR 모델
2. Ca 원자를 직접 모델링 하여 이산화 손실을 피함
3. 노이즈 컨텍스트 학습과 스케쥴링 샘플링으로 노출 편향 완화
4. 해석 가능한 생성
5. FPSE  161점
6. 효율적인 샘플링과 제로샷 일반화 잠재력

$$

\begin{align*}
p_{\theta}(\mathbf{x}) &= \mathbb{E}{X \sim q{\text{decompose}}(\cdot|\mathbf{x})} \left[ p_{\theta}(X = \{\mathbf{x}^1, \dots, \mathbf{x}^n\}) \right] \\
&= \mathbb{E}{X \sim q{\text{decompose}}(\cdot|\mathbf{x})} \prod_{i=1}^{n} p_{\theta}(\mathbf{x}^i | X^{<i})
\end{align*}

$$

PAR가 단백질 구조 x를
여러 해상도의 구조 $\{x^1,\ldots,x^n\}$ 로 분해한 뒤,
이전의 coarse한 스케일을 조건으로 다음 finer scale을 생성하는 autoregressive 모델

down sampling 전략이 pairwise spatial relationship을 보존한다.

스케일링: 경험적으로, 길이로 스케일을 정의하는 것이 데이터 분포 모델링에서 약간 더 나은 결과를 산출함.

PAR는 단백질을 residue 순서로 생성하지 않고, 멀티스케일 구조를 coarse-to-fine으로 autoregressive하게 생성하며, Transformer는 조건 임베딩을 만들고 flow decoder는 실제 좌표를 continuous space에서 복원한다

flowmatching loss

$$

\mathcal{L}(\theta) = \mathbb{E}_{x \sim p_D} \left[ \frac{1}{n} \sum_{i=1}^n \frac{1}{\text{size}(i)} \mathbb{E}_{t^i \sim p(t^i), \epsilon^i \sim \mathcal{N}(0, I)} \left\| \mathbf{v}\theta(\mathbf{x}_{t^i}^i, t^i, \mathbf{z}^i) - (x^i - \epsilon^i) \right\|^2 \right].

$$

decoder $v_\theta$는 noise  $\epsilon_i$에서 실제 구조 xi로 가는 vector field를 예측하도록 학습

그리고 이 예측은 현재 scale의 조건 정보 zi에 의해 guided 된다.

$x^i_{t_i} = t_i x_i + (1-t_i)\epsilon_i$

$(x_i - \epsilon_i)$ : 이상적인 target vector field

time sampling은 protenia에서 가지고 옴. (log-logit)

roteina는 학습 시 시간 ‭$t$‬를 균등하게 뽑지 않고, 특정 시간대에 더 자주, 혹은 더 정밀하게 샘플링되도록 가중치를 주는 변형된 확률 분포(Non-uniform Distribution) 방식을 도입.

디코더가 스케일을 식별하고 self conditioning input을 추가 조건으로 통합하기 위해서 Zi와 함께 스케일 임베딩을 추가로 연결함. (수식에서는 생략됨)

각 스케일에서 위치 인코딩은 [1, L]에서 size(i)개의 숫자를 균일하게 샘플링하여 결정한다. 거친 스케일에서는 인접한 인덱스 간의 넓은 간격이 모델이 전역 구조 레이아웃을 포착하도록 장려하는 반면, 더 미세한 스케일에서는 조밀한 인덱스가 모델이 지역적 세부 사항에 집중할 수 있도록 한다.

 $dx_t = vθ(x_t, t)dt$

- SDE 공식 및 배경지식

SDE 샘플링은 모델이 고정된 경로로만 단백질을 생성하지 않고, 확률적인 탐색을 통해 구조적 다양성을 확보할 수 있게 돕는 수학적 장치

$$
dx_t = v_\theta(\mathbf{x}t, t) dt + g(t) s\theta(\mathbf{x}_t, t) dt + \sqrt{2g(t)\gamma} dW_t,

$$

- 수식 설명
    
    **①** $‭v_\theta(x_t, t)dt‭$**: 결정론적 흐름 (Drift / Flow matching)**
    
    - 플로우 매칭 모델이 본래 가지고 있는 **"가장 매끄럽고 일직선에 가까운 정답으로의 이동 방향"**입니다. 노이즈 상태에서 시작해 단백질 구조로 나아가는 메인 추진력입니다.
    
    **②** $‭\sqrt{2g(t)\gamma}d\mathcal{W}_t$**: 무작위 확산 (Stochastic Diffusion / Noise)**
    
    - 위너 프로세스에 기반하여 원자 좌표를 사방으로 불규칙하게 흔들어 깨뜨리는 **'확률적 흔들림(Noise)'** 항입니다. 생성물의 다양성을 확보하기 위해 인위적으로 무작위성을 주입하는 것입니다.
    
    **③** ‭$g(t)s_\theta(x_t, t)dt$**: 밀도 중심 복원력 (Score Guidance)**
    
    - ②번 항 때문에 원자들이 무작위로 튕겨 나갈 때, **확률 밀도가 높은 단백질 구조의 중심축으로 원자들을 다시 강하게 수렴시키는 복원 정화 장치**입니다

wt: standard wiener process = 브라운 운동

평균이 ‭0이고 분산이 시간에 비례하는 **가우시안(정규) 노이**즈의 성질

γ is a noise scaling parameter

g(t) **(시간 의존 스케일링 함수): 간 단계(‭$t$‬)에 따라 노이즈를 흔드는 세기와 스코어로 잡아당기는 세기의 '밸런스'를 조절하는 조절 노브(Control Knob)**

score function 은 ‬‭‬‭현재 데이터 분포의 로그 확률밀도에 대한 기울기

$s_\theta(x_t,{s})={\frac{t v_{\theta}(x_{t},t)-x_{t}}{1-t}}$

- 공식 유도
    
    $‭x_t = t \cdot x + (1 - t) \cdot \epsilon$
    
    $‭\frac{dx_t}{dt} = v_{\text{target}} = x - \epsilon‬‭‬‬$
    
    1,2 식 연립하여 정리하면 ‬‭‬‭‬‬‭‬‭‬
    
    $‭\therefore \epsilon = x_t - t \cdot v_\theta‬‭‬‭‬‭‬$
      $‭s_\theta(x_t, t) = -\frac{\epsilon}{1 - t} ‭‬‭‬‭‬‭‬$ 에 대입하여 정리하면
    
    $s_{\theta}(x_{t},\,\,\,t)=\,-\,\frac{x_{t}-t\cdot v_{\theta}}{1-t}=\frac{t\cdot v_{\theta}(x_{t},t)-x_{t}}{1-t}$
    

SDE와 ODE를 섞어서 사용함!

400 step SDE sampling → 2 step ODE 샘플링

5개 스케일이 있다면 **앞선 coarse한 스케일들에서는 SDE(확률미분방정식)**를 돌려서 거친 뼈대 좌표들을 무작위 노이즈를 섞어가며 유연하게 생성하고, **뒷단의 fine한 스케일들에서는 속도가 빠른 ODE(상미분방정식)**로 전환하여 뼈대를 촘촘하게 메우고 미세 조정하는 방식 400/400/2/2/2

연산량이 가장 가볍고 아톰 수가 적은 **초기 coarse 스케일에서만 SDE 400 step을 돌려 연산 효율을 챙기고**, 정작 연산량이 폭발하는 **최종 fine 스케일에서는 단 2 step(ODE)만 쓴다. (fine으로 갈수록 아톰이 많아져서 제곱에 비례해서 트랜스포머 연산량이 증가하기 떄문이다)**

**초기 Coarse 스케일에는 SDE 샘플링으로 대세를 잡고, 구조적 대세가 잡힌 Fine 스케일에는 초고속 ODE 샘플링으로 전환하는 멀티스케일 오케스트레이션**을 구현함으로써 고품질과 초고속 생성 효율을 동시에 달성

**결과:** 단백질의 품질(Designability)은 97%로 완벽하게 유지하면서, **생성 속도를 기존 단일 스케일 모델 대비 2.5배나 끌어올리는 대성공**

## exposure bias 완화하기

 autoregressive (AR) 모델이 학습 때와 추론 때 다른 입력을 본다. PAR에서는 구조를 한 번에 생성하지 않고 coarse-to-fine으로 여러 scale에 걸쳐 순차적으로 생성하므로, 앞 scale의 작은 오차가 뒤 scale로 전달되면서 점점 커질 수 있다. 이를 줄이기 위해 noisy context learning과 Scheduled sampling 방법을 도입하였다. 

Q). AR 모델에서 왜 exposure bias가 생기나?

훈련할떄는 정답을 기준으로 AR 입력과 조건을 만들어줌. 하지만 추론할 떄는 이전 스케일에 대해 모델 자신이 생성한 결과를 다시 입력으로 사용함. 따라서 학습과 추론의 입력 분포가 달라짐.

teacher forcing으로만 학습하면 모델이 너무 깨끗한 문맥에만 익숙해져서, 실제 생성 상황의 noisy context에 약해진다. 

- noisy context learning

학습할 때 이전 scale의 정답 contexst를 일부러 망가트려 넣는다. 

근데 훈련할때는 원래 ground truth에 noise를 linear interpolate 해서 넣지 않나?

$x_i^{\text{ncl}} = w_i^{\text{ncl}} \cdot x_i + \left(1 - w_i^{\text{ncl}}\right)\cdot \epsilon_i^{\text{ncl}}$

- 노테이션
    
    xi: i번째 scale의 ground-truth 구조
    $\epsilon_i^{\text{ncl}} \sim \mathcal{N}(0, I)$
    $w_i^{\text{ncl}} \in [0,1]$ : 원래 구조를 얼마나 유지할지 정하는 가중치
    $x_i^{\text{ncl}}$: 노이즈가 섞인 context
    
- Scheduled sampling
    
    이건 autoregressive랑 같은거 아닌아?
    
    1 step euler prediction 후에 예측값을 조건으로 넣기
    
    $$
    x_i^{\text{pred}} = x_t^i + (1 - t_i)\, v_\theta(x_t^i, t_i, z_i)
    $$
    
    Scheduled Sampling은 한 걸음 더 나아가 모델 자신의 예측을 context로 직접 써보게 하는 방법.
    
    확률 0.5로 ground truth $x_i$ 대신에 모델의 예측 결과인 $x_i^{pred}$
    
    정답만 있을 때 잘하는 모델이 아니라, 내가 조금 틀린 출력을 냈을 때도 다음 단계에서 복구할 수 있는 모델을 학습함
    
    ## 결과
    
    성능 검증 + 설계 선택의 타당성 검증
    
    주장 1: AR도 protein structure generation에 쓸 수 있다
    
    - 기존에는 diffusion이 주류였음 AR는 단백질의 bidirectional dependency 때문에 어렵다고 여겨졌음
    
    주장 2: next-token이 아니라 next-scale AR가 단백질에 더 적합하다
    
    - 단백질은 residue 순서보다 3D 상호작용이 중요해서 단방향 residue-by-residue 생성은 부적절할 수 있음
    
    주장 3: coarse-to-fine 생성은 zero-shot 제어와 sampling 효율 면에서 이점이 있다
    
    - global topology를 먼저 만들고 finer detail을 나중에 보정
    
    주장 4: exposure bias가 성능 저하의 큰 원인이며, NCL과 SS가 이를 완화한다
    
    - teacher forcing만 쓰면 inference 때 자기 예측을 컨텍스트로 써야 해서 오차 누적

sampling 설정에 따라 quality-diversity trade-off를 조절할 수 있다.

γ를 조절하면:
낮은 noise → 더 높은 designability
높은 stochasticity → 더 좋은 FPSD / diversity

PDB fine-tuning 후에는 매우 낮은 FPSD와 높은 designability를 동시에 달성

기존 diffusion/flow baseline과 경쟁력 있거나 일부 측면에서 더 우수한 성능

Q). PAR_pdb

 같은 PAR를 AFDB로 먼저 학습한 뒤 PDB의 designable subset으로 추가 fine-tuning한 버전. 보통의 PAR은 주로 AFDB representative dataset에서 학습된 모델이고, PAR_\text{pdb}pdb_\text{pdb}pdb는 여기에 더해 PDB의 21K designable samples로 짧게 추가 학습한 모델

Q). protenia pair representation, **Triangle-based Module** 

- pair representation
    
    "모든 아미노산들 간의 1:1 상대적 관계"를 나타내는 거대한 2차원 행렬$(‭L \times L‬)$정보
    
    i번째 아미노산과 j번째 아미노산의 거리는 대충 얼마이고, 서로 어떤 각도로 마주 보고 있다"와 같은 3차원 공간상의 pairwise 상대적 기하학 정보를 인공신경망이 끊임없이 기억하고 업데이트할 수 있도록 돕는 지도 역할
    
- **Triangle-based Module**
    
    Pair representation 행렬 안의 데이터들이 **실제 3차원 물리 공간의 유클리드 기하학 법칙을 위배하지 않도록 강력하게 규제하고 다듬어주는 필터**
    
    삼각형의 두 변의 길이의 합은 나머지 한 변의 길이보다 항상 커야 한다"*는 규칙이 있습니다. 단백질 구조를 예측하거나 만들 때, AI가 수학적으로 픽셀 단위 연산을 하다 보면 이 물리적 삼각형 법칙이 깨지는 엉터리 거리를 상상해 내기 쉽습니다. 삼각형 모듈(Triangle Multiplicative Update 등)은 **아미노산 세 개(**‭i, j, k$‬‭ ****‭‬‭‬ ****‭‬**)를 묶어 삼각형 관계를 계속 체크하며 거리를 교정하는 극도로 정교한 연산**
    
- 왜 두 모듈을 껐을?
    - Pair representation(‭L \times L)과 삼각형 모듈은 3개의 아미노산 관계를 묶어 연산하기 때문에, 메모리 사용량과 계산 복잡도가 서열 길이의 **세제곱(**‭L^3**) 혹은 4제곱(**‭L^4**) 단위로 무지막지하게 폭발**
    - 복잡한 물리적 제약 조건을 수식으로 묶어두는 대신, 최대 18 레이어에 달하는 두터운 일반 트랜스포머의 어텐션(Self-Attention) 레이어를 사용하여 원자들 간의 멀고 가까운 글로벌 상호작용과 관계성을 딥러닝 데이터 그 자체의 힘으로 녹여내어 학습하도록 유도

Q). model이 equivariance를 만족하는가? non equivarient transformer를 사용했는데?

# Personal Opinion

# Reference

프롬프트

지금부터 연구실 랩미팅 발표를 위한 준비를 같이 할거야.
우선 우리 연구실이 어떤 일을 하는지 설명해줄게. 우리연구시는 AI 기반 신약개발을 하는 연구실이야. 그래서 Protein design, Protein Ligand docking, drug screening, AI agent engineering, 약학 분야에 AI 접목하여 약물 설계하기, chemical reaction space 탐구, 약학 분야 AI 생성 모델 만들기 등의 분야를 다루고 있어. 자세한 내용은 링크를 첨부해줄게. [https://sites.google.com/view/lcbc](https://sites.google.com/view/lcbc)

우리는 매주 1명이 연구 진척상황을 보고하고, 1명은 연구실 사람들에게 도움이 될 paper를 소개해. 내가 2주 뒤에 paper 발표를 해야해서 너랑 같이 괜찮은 논문을 서치하고, 정리 및 이해하며 그 결과 html로 발표자료도 만들려고자해. 작업을 도와줘.

내가 관련 프로젝트를 진행할 디렉토리를 여기에 만들었어. 앞으로 정리, 공부, 작업는 여기서 하자. 그리고 context 유지를 위한 작업 md 파일도 여기에 만들어두자. 그리고 관련해서 우리 연구실 대학원생이 codex로 기획하고 claude로 html 발표 자료 만든 것을 pdf로 변환한 파일도 첨부해두었어.

우선 처음으로 할 것은 우리 연구실 사람들이 관심있어하거나 내 연구인 Crypticflow (/home/mjkim/project/crypticflow)와 관련이 있을 법한 최신 연구들을 Nature, Science, Cell, JCIM 등의 유명한 저널에서 리서치 하는 거야. 일단 넓게 잡아서 20편 이상을 찾아보고 정리할 것인데, 3줄 요약, novelty, 선정이유 등의 항목으로 정리하면서 리서치해서 md 파일로 정리 할거야. 그다음에 하나를 선정해서 같이 공부하고 발표자료를 만들자. 필요한 MCP나 허가 사항이 있으면 알려줘.