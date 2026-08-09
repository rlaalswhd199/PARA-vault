# Recursive Anchor-ICS + PAR 구현 구상

## 한 줄 요약

사용자 아이디어의 핵심은 맞다. 다만 이 문서의 권장 해석은
**"coarse scale은 ICS가 아니라 Cartesian C-alpha anchor로 생성하고, fine/final scale에서만 local ICS refinement를 사용한다"**는 것이다.
즉 **"downsample한 anchor chain 전체를 다시 긴 NERF로 순차 복원"** 하면 lever arm이 줄기만 할 뿐 남는다.  
권장안은:

1. **coarse scale의 sparse anchor chain은 Cartesian C-alpha 좌표로 생성**하고
2. 그 다음 스케일들은 **anchor pair 사이 midpoint를 local geometry 규칙으로 refinement**하고
3. 모델은 **C-alpha only output**만 만들고, 마지막에 **deterministic atomization**으로 전체 backbone을 복원하는 것이다.

이렇게 하면 coarse에서는 Cartesian의 단순함과 안정성을 쓰고,
fine/final 단계에서만 geometry-aware refinement를 넣어
physical validity와 lever arm 완화를 동시에 노릴 수 있다.

---

## 왜 이 아이디어가 이전 결론과 완전히 충돌하지 않는가

기존 worklog의 결론은:

- `avg_pool`로 만든 coarse bead에는 ICS를 정의하기 어렵다.
- centroid bead는 실제 사슬 위 점이 아니므로 3.8A 결합 해석이 깨진다.

그런데 지금 아이디어는 다르다.

- bead를 평균으로 만들지 않고
- **실제 residue의 C-alpha를 stride로 선택한 anchor**를 쓰자는 것이다.

이 경우 local refinement 관점에서는 다음이 가능해진다.

1. **pair-anchored local geometry / ICS**  
   anchor A, B가 주어졌을 때 그 사이 midpoint residue를
   `A/B에 대한 내부좌표`로 표현할 수 있다.

2. **마지막 deterministic atomization**  
   마지막에 얻어진 C-alpha trace를 기반으로
   backbone atom(N, CA, C, O)을 표준 기하로 복원할 수 있다.

즉, "ICS 아이디어가 전혀 불가능"한 것은 아니고,
정확히는 **avg_pool coarse bead에는 불가능하고,
stride-selected real anchor를 쓸 때 local refinement나 atomization 단계에서 의미가 있다**고 보는 편이 맞다.

다만 중요한 조건이 있다:

- coarse anchor 사이에는 더 이상 3.8A 고정 결합 같은 강한 화학 제약이 없다.
- 따라서 coarse scale을 굳이 ICS로 생성해도
  우리가 기대하는 physical validity 이득이 크지 않다.

그래서 **coarse scale은 Cartesian이 기본값이고,
geometry-aware 처리는 local refinement와 atomization에 집중하는 것이 더 자연스럽다.**

---

## 핵심 주의점

이 아이디어에서 가장 중요한 함정은 하나다.

> **coarse anchor chain을 만들었다고 해서, 그 chain을 다시 한쪽 끝부터 NERF로 길게 풀면 lever arm이 다시 생긴다.**

길이가 `L`에서 `L/4`로 줄면 증폭은 완화되지만, 구조적으로는 여전히 같은 문제다.

따라서 진짜 이득은 다음에서 나온다.

- coarsest chain은 짧아서 lever arm이 작음
- finer scale에서는 더 이상 전역 chain decode를 하지 않고
- **고정된 두 anchor 사이의 작은 local subproblem**만 푼다

즉 이 아이디어의 본질은:

`global ICS chain generation`이 아니라  
`coarse Cartesian anchor generation + local recursive interval refinement + deterministic atomization`

으로 보는 게 맞다.

---

## 권장 아키텍처

이 문서에서는 이 설계를 **Recursive Anchor-ICS (RAICS)** 라고 부르겠다.
다만 이름과 달리, **coarse scale 자체를 ICS로 생성하는 것은 권장하지 않는다.**
ICS는 주로 **anchor-conditioned local refinement** 단계에서 사용한다.

### 전체 구조

1. **Coarse anchor generation**
   실제 residue를 stride로 뽑은 sparse anchor chain을 **Cartesian C-alpha 좌표로 생성**
2. **Recursive midpoint refinement**
   각 anchor interval 안의 midpoint residue를, 양쪽 anchor에 조건부인 local geometry 규칙으로 refinement
3. **PAR-style autoregressive context**
   이전 scale의 예측을 다음 scale context로 넘김
4. **최종 deterministic backbone atomization**
   full C-alpha가 나온 뒤 backbone atom(N, CA, C, O)을 표준 기하로 복원

---

## 1. Scale 구성

### 추천: 단순 global stride보다 "dyadic midpoint tree"

사용자 아이디어는 stride 기반인데, 구현은 다음처럼 하는 게 더 안정적이다.

- coarsest anchor set: `I^S`
- finer scale: 각 인접 anchor pair 사이에 **중간 residue 하나**를 추가
- 이를 full resolution까지 반복

예를 들어 `L=219`라면:

```text
level 0 (full):      all residues
level 1:             every 2 residues + interval midpoint rule
level 2:             every 4 residues
level 3:             every 8 residues
...
level S:             very sparse anchors
```

하지만 실제 구현은 `linspace(...).round()`보다,
각 interval의 midpoint를 재귀적으로 쪼개는 binary tree가 더 좋다.

**여기서 `dyadic`은 "2로 계속 반씩 쪼갠다"는 뜻이다.**
즉 interval `[left, right]`가 있으면:

1. 그 사이의 midpoint residue 하나를 먼저 고른다.
2. 그러면 interval이 `[left, mid]`, `[mid, right]` 두 개로 나뉜다.
3. 각 interval에 대해 같은 작업을 반복한다.

작은 예를 들면 residue index가 `0..8`일 때:

```text
처음 anchor: 0 ---------------- 8
1차 분할:    0 ------- 4 ------- 8
2차 분할:    0 --- 2 --- 4 --- 6 --- 8
3차 분할:    0 - 1 - 2 - 3 - 4 - 5 - 6 - 7 - 8
```

즉 "dyadic midpoint tree"는
`긴 구간을 midpoint로 반씩 나누는 이진 트리(binary tree)`라고 이해하면 된다.

장점:

- 모든 refinement step이 "anchor pair -> midpoint 1개 생성" 문제로 통일된다.
- 길이가 2의 배수가 아니어도 자연스럽다.
- PAR의 coarse-to-fine 구조와도 잘 맞는다.

### 1.1 edge case: anchor 사이 residue 수가 짝수일 때는 어떻게 하나

중요한 점은, 실제 구현에서 기대해야 하는 것은
**perfect binary tree**가 아니라 **ragged binary tree**라는 것이다.

즉 모든 interval이 항상 "유일한 midpoint residue"를 갖는 것은 아니다.
예를 들어 anchor가 `CA_i`와 `CA_{i+3}`이면
그 사이 내부 residue는 `CA_{i+1}`, `CA_{i+2}` 두 개라서
sequence 기준 중앙 residue가 하나로 정해지지 않는다.

하지만 이것은 recursion이 불가능하다는 뜻이 아니다.
단지 **split residue를 deterministic rule로 하나 선택해야 한다**는 뜻이다.

### 추천 split rule

interval endpoint를 `(l, r)`라고 하고
`Δ = r - l`을 해당 interval의 residue span이라고 하자.

추천 규칙은 다음과 같다.

- `Δ = 1`:
  인접 residue이므로 생성할 내부 residue가 없다. 종료한다.
- `Δ = 2`:
  내부 residue가 정확히 1개다. 마지막 스케일용 local decoder를 적용할 수 있다.
- `Δ >= 3`:
  `m = floor((l + r) / 2)` 같은 deterministic rule로 split residue를 고른다.
  그 다음 `[l, m]`, `[m, r]` 두 child interval로 재귀한다.

예를 들어 `[i, i+3]` interval이면:

```text
m = floor((i + i+3)/2) = i+1
```

이므로 먼저 `CA_{i+1}`를 생성하고,
남은 `[i+1, i+3]`은 `Δ = 2`인 leaf interval로 처리하면 된다.

즉 "anchor 사이에 CA가 2개 있으면 midpoint가 없다"기보다,
정확히는 **유일한 중앙 residue는 없지만 split rule로 하나를 먼저 고르면 된다**고 보는 편이 맞다.

### 중요한 구현 철학

처음부터 stride를 완벽히 잡아 edge case를 없애는 방향보다는,
**tree builder가 ragged interval을 안정적으로 처리하도록 설계하는 것**이 더 중요하다.

즉 목표는:

- 단백질 길이 `L`이 2의 거듭제곱이 아니어도 동작
- coarse interval 길이가 전부 같지 않아도 동작
- `Δ = 1 / 2 / 3 / ...` interval이 섞여도 동작

하는 것이다.

### 추천 edge-case 처리 정책

MVP 기준으로는 아래 정책이 가장 단순하고 안정적이다.

- 첫 residue와 마지막 residue는 항상 anchor로 둔다
- missing residue나 chain break가 있으면 해당 구간을 별도 segment로 분리한다
- split rule은 전역적으로 하나만 고정한다:
  `m = floor((l + r) / 2)` 권장
- `Δ = 2` interval만 마지막 scale 전용 decoder를 사용한다
- `Δ = 3`은 별도 특수 케이스로 만들지 말고,
  `floor midpoint -> one child with Δ = 2` 규칙으로 흘려보낸다
- dataset metadata에 최소한 아래를 넣는다:
  `span = r-l`, `n_left`, `n_right`, `is_leaf`, `is_final_leaf`

이렇게 하면 모델은
좌우 길이가 비대칭인 interval과 final leaf interval을 구분해 학습할 수 있다.

### 나중에 고려할 수 있는 확장

필요하면 `Δ = 3` interval에 대해
`CA_{i+1}`, `CA_{i+2}`를 한 번에 생성하는 2-residue micro-decoder를 둘 수도 있다.

하지만 초기 버전에서는 권장하지 않는다.
그렇게 하면:

- local output space가 커지고
- "anchor pair -> midpoint 1개 생성"이라는 문제 정식화가 깨지고
- 디버깅이 더 어려워진다

따라서 첫 구현은
**ragged binary tree + deterministic split rule**
조합으로 가는 것이 가장 현실적이다.

---

## 2. Coarse scale 표현: Cartesian anchor coordinates (권장)

coarse anchor index set `I^s = [i_1, i_2, ..., i_n]`가 있으면,
권장 기본안은 해당 anchor의 **Cartesian C-alpha 좌표를 그대로 상태변수로 두는 것**이다.

```text
X_anchor^s = [CA_{i_1}, CA_{i_2}, ..., CA_{i_n}]    shape (n, 3)
```

즉 coarse scale state는 단순히:

- anchor residue들의 C-alpha 좌표
- apo 상태와 holo 상태 사이의 coarse displacement

로 생각하면 된다.

### 장점

- representation이 가장 단순하다
- coarse anchor 사이에는 강한 화학 제약이 없기 때문에 Cartesian이 더 자연스럽다
- lever arm을 일으키는 전역 NERF decode를 피할 수 있다
- apo->holo task에서 coarse global displacement를 바로 학습하기 쉽다

### 한계

- physical validity를 representation 자체로 보장하진 않는다
- coarse 단계에서는 local bond geometry 정보를 직접 쓰지 않는다

하지만 이 한계는 괜찮다.
왜냐하면 coarse 단계의 역할은 **정확한 backbone chemistry**가 아니라
**전역 shape와 큰 conformational displacement를 잡는 것**이기 때문이다.

### optional ablation: virtual C-alpha ICS

stride-selected real anchor에 대해 virtual C-alpha ICS를 정의하는 것은 여전히 가능하다.
다만 현재 문서의 추천 baseline은 아니다.

이유:

- coarse anchor 사이에는 3.8A 같은 강한 화학 제약이 없음
- virtual chain을 굳이 ICS로 바꿔도 physical validity 이득이 작음
- 반면 decode/representation 복잡도는 커진다

따라서 **처음 구현은 Cartesian coarse anchor만 쓰고,
virtual CA-ICS는 나중 ablation으로 보는 게 맞다.**

---

## 3. Fine scale 표현: pair-anchored local ICS

여기가 이번 아이디어의 핵심이다.

인접 coarse anchor `A = x_a`, `B = x_b`가 있고,
그 사이에 넣을 midpoint residue를 `M = x_m`이라고 하자.

이 residue는 전역 chain에서 순차 배치하지 않고,
**A와 B 두 anchor에 대한 local 내부좌표**로 표현한다.

### 3.1 상태 변수

`M`의 3D 자유도는 3개이므로 다음 3개로 표현할 수 있다.

1. `r_L = ||M - A||`
2. `r_R = ||B - M||`
3. `omega = azimuth around AB`

여기서 `r_L`, `r_R`는 양수 거리이고,
`omega`는 `AB` 축 둘레의 각도다.

**`omega`를 직관적으로 이해하는 방법**

- 먼저 `A`와 `B`를 잇는 선 `AB`를 하나의 "축(axis)"이라고 본다.
- `r_L`, `r_R`가 정해지면, `M`이 있을 수 있는 위치는 보통 원(circle) 하나가 된다.
- 그 원은 `AB`에 수직인 평면 위에 있다.
- `omega`는 그 원 위에서 **어느 방향에 놓일지**를 정하는 각도다.

즉 `omega`는
`A-M-B` 평면의 bond angle이 아니라,
**`AB`라는 축을 기준으로 원 둘레를 몇 도 돌아갔는가**를 나타내는 각도다.

그림으로 보면:

```text
AB 축을 정면에서 바라본 단면

          M(omega = 90 deg)
                o
                |
M(180 deg)  o --+-- o  M(0 deg)
                |
                o
         M(omega = 270 deg)
```

위 그림에서 가운데 `+`는 `AB` 축을 정면에서 본 점이고,
`M`은 그 둘레 원 위를 돈다.
그래서 `omega`는 "축 둘레의 각도"라고 부른다.

이 표현을 쓰는 이유는,
`M`의 위치를 3D Cartesian `(x,y,z)`로 직접 예측하는 대신
`양쪽 anchor로부터의 거리 + 원 위 각도`
형태로 표현하면 local geometry를 더 잘 다룰 수 있기 때문이다.

### 3.2 contour-length upper bound

`A -> M` 사이에 실제 backbone bond가 `n_L`개,
`M -> B` 사이에 bond가 `n_R`개 있으면,

```text
r_L <= 3.8 * n_L
r_R <= 3.8 * n_R
```

이 상한은 물리적으로 자연스럽다.

따라서 네트워크는 정규화된 변수로 예측하는 편이 좋다.

```text
u_L, u_R, sin(omega), cos(omega)
r_L = (3.8 * n_L) * sigmoid(u_L)
r_R = (3.8 * n_R) * sigmoid(u_R)
```

여기서 `u_L`, `u_R`는 **모델이 직접 출력하는 unconstrained raw value**다.
즉 아직 거리 단위(Å)도 아니고, 범위 제한도 없는 그냥 실수다.

예를 들면 모델이:

```text
u_L = -2.0
u_R =  1.5
```

를 출력할 수 있다. 그러면:

```text
sigmoid(-2.0) ~= 0.119
sigmoid( 1.5) ~= 0.818
```

가 되고, 만약 `n_L = 2`, `n_R = 3`이라면:

```text
r_L = 3.8 * 2 * 0.119 ~= 0.90 A
r_R = 3.8 * 3 * 0.818 ~= 9.33 A
```

가 된다.

왜 이렇게 하냐면, `r_L`, `r_R`를 모델이 직접 예측하게 하면:

- 음수 거리가 나올 수 있고
- 너무 큰 거리도 나올 수 있다

그래서 먼저 모델은 자유로운 실수 `u_L`, `u_R`를 내고,
우리가 `sigmoid()`를 통과시켜 항상 `(0, 1)` 범위로 만든 다음,
물리적으로 가능한 최대 contour length인 `3.8 * n_L`, `3.8 * n_R`를 곱해
**항상 유효한 거리 범위 안으로 강제**하는 것이다.

한마디로:

- `u_L` = 모델의 raw logit
- `sigmoid(u_L)` = "최대 가능 거리 대비 몇 퍼센트인가"
- `r_L` = 실제 거리(Å)

### 3.2b 두 구가 실제로 만나도록 하는 feasibility 제약

사용자가 짚은 것처럼, `r_L`, `r_R`에 상한만 걸어서는 부족하다.

왜냐하면:

- `r_L + r_R < d` 이면 두 구가 너무 멀어서 아예 만나지 않고
- `|r_L - r_R| > d` 이면 한 구가 다른 구 안에 너무 깊게 들어가서 역시 원 교집합이 없다

여기서 `d = ||B - A||` 이다.

즉 두 구가 실제로 만나서 원(circle)을 만들려면 반드시:

```text
|r_L - r_R| <= d <= r_L + r_R
```

가 성립해야 한다.

이건 삼각형 부등식과 같은 조건이라고 보면 된다.
즉 `A`, `M`, `B` 세 점이 실제 삼각형을 만들 수 있어야 한다는 뜻이다.

그래서 맞다. **이 feasibility에 대해서도 별도 constraint / penalty를 거는 게 필요하다.**

권장 방법은 두 가지다.

#### 방법 A: hinge penalty

```text
L_feas
= relu(d - (r_L + r_R))^2
+ relu(|r_L - r_R| - d)^2
```

의 형태로, 불가능한 쪽으로 벗어난 만큼만 벌점을 주는 방식이다.

#### 방법 B: decode 전에 projection

예측된 `(r_L, r_R)`를 그대로 쓰지 말고,
decode 직전에 feasible set으로 약하게 끌어당기는 방법도 있다.

예를 들어:

- `r_L + r_R < d` 이면 둘을 조금 키우고
- `|r_L - r_R| > d` 이면 차이를 조금 줄이는

식의 differentiable projection을 둘 수 있다.

실전에서는:

- 학습 중엔 `L_feas`를 두고
- decode 시에도 작은 projection/fallback을 두는

이중 안전장치가 가장 현실적이다.

### 3.3 decode

두 구의 교집합을 이용해 midpoint를 복원한다.

```text
d = ||B - A||
e1 = (B - A) / d

x_axis = (r_L^2 - r_R^2 + d^2) / (2d)
rho^2  = r_L^2 - x_axis^2

C = A + x_axis * e1
M = C + rho * (cos(omega) * e2 + sin(omega) * e3)
```

여기서 `e2, e3`는 `AB`에 수직인 local frame이다.

### 3.3b 마지막 스케일은 어디까지 deterministic하게 만들 수 있는가

사용자 아이디어처럼, **온전한 backbone을 만들기 직전의 마지막 스케일**에서는
physical validity를 훨씬 강하게 밀어붙일 수 있다.

특히 stride=2 마지막 삽입이라면:

- left anchor `A = CA_i`
- right anchor `B = CA_{i+2}`
- 새로 넣을 residue `M = CA_{i+1}`

이고, 이때는 실제로

```text
|A - M| = 3.8 A
|M - B| = 3.8 A
```

를 **정확히 강제**하는 것이 자연스럽다.

여기까지는 맞다. 마지막 스케일은 중간 스케일보다
훨씬 더 **geometry-heavy** 하게 설계할 수 있다.

다만 중요한 점이 하나 있다.

> **거리 2개를 정확히 고정해도 `M`은 아직 하나로 안 정해지고, 원(circle) 하나 위에 남는다.**

즉 마지막 단계에도 여전히 **1 자유도**가 남고,
그게 바로 `omega`다.

즉 마지막 스케일에서 truly deterministic하게 만들 수 있는 부분은:

- `|A-M| = 3.8 A`
- `|M-B| = 3.8 A`
- 필요하면 feasibility / local frame 안정화 규칙

까지이고,
**유일한 3D placement를 위해서는 결국 `omega` 또는 그와 동등한 정보가 하나 더 필요하다.**

#### 왜 결합각이 "거의 고정"이어도 아직 부족한가

직관적으로는 `A-M-B` 결합각도 거의 일정하니
그것까지 쓰면 `M`이 하나로 정해질 것처럼 느껴질 수 있다.

그런데 실제로는:

- `|A-M|`
- `|M-B|`
- `|A-B|`

가 정해지면 `angle(A,M,B)`는 코사인 법칙으로 이미 정해진다.

```text
cos angle(A,M,B) = (|A-M|^2 + |M-B|^2 - |A-B|^2) / (2 |A-M| |M-B|)
```

즉 `Ca-Ca-Ca` 결합각이 거의 고정이라는 사실은
새로운 자유도를 더 줄여주지 않는다.

즉 마지막 스케일에서 "결합각이 거의 고정"이라는 사실은
새로운 자유도를 더 줄인다기보다,
**coarse anchor 사이 거리 `|A-B|`가 물리적으로 너무 이상하면 안 된다**는 뜻에 더 가깝다.

남아 있는 진짜 마지막 자유도는
`AB` 축 둘레 회전인 `omega`다.

따라서 이 문서의 현재 해석은 다음과 같다.

- 마지막 스케일을 **완전 무모델 deterministic** 하게 만들 수 있는 것은 아니다
- 다만 `r_L, r_R` 같은 길이 자유도는 사실상 없애고
- **마지막 1 자유도인 `omega`만 예측하거나 외부 규칙으로 정하는 것**이 가능하다

즉 마지막 스케일의 핵심은
**"full coordinate generation"이 아니라 "omega resolution"**이라고 보는 편이 정확하다.

### 3.3c 그래서 마지막 스케일을 어떻게 설계할 수 있나

실제로는 **final C-alpha placement** 관점에서 아래 3가지 설계가 가능하다.

#### 옵션 1. 고정 규칙 기반 `omega` insertion

모델은 마지막 스케일에서 아무것도 예측하지 않고,

- `|A-M| = |M-B| = 3.8 A`
- `omega = omega_apo`

또는

- `omega = frame interpolation rule`

같은 **고정 규칙**으로 `M`을 배치한다.

장점:

- physical validity가 가장 강하다
- 마지막 단계에서 model error가 geometry를 깨뜨릴 여지가 거의 없다

단점:

- apo->holo 과정에서 local rearrangement가 필요한 경우
  마지막 residue 위치를 너무 보수적으로 고정할 수 있다
- final accuracy ceiling이 생길 수 있다

즉 이것은 "완전한 무자유도 삽입"이 아니라,
**`omega`를 모델 대신 외부 규칙이 정하는 경우**라고 이해하는 편이 정확하다.

#### 옵션 2. `omega-only` final insertion

마지막 스케일에서는

- 거리 2개는 완전히 고정
- 모델은 `omega`만 예측

하는 방식이다.

즉 마지막 단계의 learned output을 3D 좌표 전체가 아니라
**딱 1 자유도만** 맡게 한다.

장점:

- physical validity와 flexibility 사이 균형이 좋다
- geometry는 거의 규칙이 담당하고,
  모델은 local orientation만 조절하면 된다

이 문서 전체의 현재 기본안은 사실상 여기에 가장 가깝다.

#### 옵션 3. full learned local final step

필요하다면 마지막 스케일에서도 다시

- `r_L, r_R, omega`
- 또는 local Cartesian residual

을 더 유연하게 학습시키는 선택지도 있다.

장점:

- apo->holo에서 마지막 local twist / flip이 큰 경우 더 유연할 수 있다
- hard geometry가 너무 보수적인지 직접 비교할 수 있다

단점:

- 마지막 스케일의 output space가 다시 커진다
- physical validity를 모델 loss에 더 많이 의존하게 된다
- 지금 문제의식인 "geometry를 최대한 규칙으로 처리하자"와는 거리가 멀어진다

중요한 점은,
**위 3개는 어디까지나 final C-alpha를 어떻게 놓을 것인가에 대한 선택지**라는 것이다.
그 다음의 backbone atomization은 이들과 별개의 downstream 단계다.

즉 어느 옵션을 쓰더라도,
final C-alpha가 정해진 뒤에는 `N, CA, C, O`를
deterministic backbone atomization으로 복원할 수 있다.

### 3.3d 현재 관점에서 가장 추천하는 절충안

내 생각에는 처음부터 `omega`까지 외부 규칙으로 완전히 고정하기보다,

1. **마지막 스케일은 거리 제약을 hard constraint로 두고**
2. **모델은 `omega`만 예측하게 축소한 뒤**
3. 필요하면 그 다음 ablation으로 `omega`를 apo/rule 기반으로 고정하거나,
   반대로 full learned local step과 비교

하는 순서가 가장 안전하다.

즉:

- 중간 스케일: local ICS generation
- 마지막 스케일: almost deterministic geometry + tiny learned residual

이 현실적이다.

그 이유는,
마지막 단계에서 local conformational adjustment가 정말 필요한지 아직 모르기 때문이다.
처음부터 완전 deterministic으로 잠가버리면
"모델이 필요 없어서"가 아니라
"모델이 필요한 미세 자유도까지 같이 죽여서"
성능이 막히는지 분리하기 어려워진다.

### 3.3e 마지막 스케일 전용 decoder / atomization 설계

여기서는 위 아이디어를 실제 구현 형태로 더 구체화한다.

목표는:

> **마지막 스케일에서는 모델이 기하 전체를 생성하지 않고,**
> **가능한 한 많은 부분을 deterministic geometry decoder가 담당하게 만드는 것**

이다.

#### Case A. 고정 규칙 기반 `omega` final C-alpha insertion

가정:

- final scale은 stride=2 insertion
- parent anchor는 `A = CA_i`, `B = CA_{i+2}`
- 새 residue는 `M = CA_{i+1}`
- `|A-M| = |M-B| = 3.8 A`를 hard constraint로 둔다

이때 `M`은 교집합 원 위에 있으므로
남은 1 자유도 `omega`만 정하면 된다.

가장 단순한 규칙은:

```text
omega = omega_apo
```

즉 apo 구조에서 같은 interval의 midpoint가 놓여 있던 원 위 각도를
그대로 복사하는 방식이다.

구현 스케치:

```python
def deterministic_insert_ca(A, B, omega_ref, bond_len=3.8):
    d = torch.norm(B - A)

    # final scale에서는 |A-M| = |M-B| = 3.8 A
    rL = bond_len
    rR = bond_len

    # circle center
    e1 = (B - A) / d
    C = 0.5 * (A + B)
    rho_sq = bond_len**2 - (d / 2)**2
    if rho_sq <= 0:
        return C  # fallback

    rho = torch.sqrt(rho_sq)

    e2, e3 = build_local_frame(A, B)  # apo reference 기반
    M = C + rho * (torch.cos(omega_ref) * e2 + torch.sin(omega_ref) * e3)
    return M
```

장점:

- 가장 강한 physical validity
- final scale이 geometry engine처럼 동작

단점:

- holo에서 local flip / twist가 필요한 경우 못 따라간다

#### Case B. `omega`만 모델이 예측하는 decoder

이게 가장 추천되는 실전형이다.

여기서는 마지막 스케일에서 모델이 내는 출력은 오직:

```text
sin(omega), cos(omega)
```

뿐이다.

즉 거리 관련 자유도는 전부 deterministic하게 처리한다.

구현 스케치:

```python
def final_scale_decoder(A, B, omega_head, bond_len=3.8):
    d = torch.norm(B - A)
    e1 = (B - A) / d

    # hard geometry
    C = 0.5 * (A + B)
    rho_sq = bond_len**2 - (d / 2)**2
    if rho_sq <= 0:
        return C

    rho = torch.sqrt(rho_sq)
    e2, e3 = build_local_frame(A, B)

    omega = torch.atan2(omega_head[0], omega_head[1])
    M = C + rho * (torch.cos(omega) * e2 + torch.sin(omega) * e3)
    return M
```

이 경우 마지막 스케일 loss도 매우 단순해진다.

```text
L_final = MSE(sin(omega_pred), sin(omega_gt))
        + MSE(cos(omega_pred), cos(omega_gt))
```

즉 model이 직접 `(x, y, z)`를 생성하지 않으므로
geometry violation의 여지가 크게 줄어든다.

#### Case C. downstream deterministic backbone atomization

이 단계는 Case A/B 중 무엇을 쓰든 그 뒤에 붙는 공통 후처리다.
즉 `omega`를 어떻게 정했는지와는 별개의 단계다.

마지막 C-alpha가 정해지면, backbone atom도 거의 결정론적으로 복원할 수 있다.

예를 들면:

- `CA_i, CA_{i+1}, CA_{i+2}` local frame 구성
- 표준 peptide bond geometry 사용
- `N, C, O`를 canonical template로 배치

즉 마지막 단계는:

```text
anchor -> final C-alpha insertion (A or B) -> deterministic backbone atomization
```

의 2단계 geometry pipeline으로 만들 수 있다.

이 경우 모델이 직접 예측하는 것은 사실상

- coarse anchor
- 필요하다면 final `omega`

정도만 남는다.

### 3.3f 마지막 스케일 전용 decoder의 장점

이 설계의 좋은 점은 세 가지다.

1. **physical validity를 hard constraint로 넣을 수 있다**
   final neighbor CA distance를 정확히 3.8 A로 고정 가능
2. **lever arm 문제와 무관한 local geometry engine이 된다**
   마지막 단계는 더 이상 global chain decode가 아니다
3. **학습 난이도가 크게 줄어든다**
   final scale output dimension이 `(x,y,z)` 또는 `(r_L,r_R,omega)`보다 훨씬 작아질 수 있다

### 3.3g 마지막 스케일 decoder의 한계

반대로 한계도 분명하다.

1. parent anchor가 이미 틀리면 final deterministic step이 그것을 고칠 수는 없다
2. `omega_apo` 고정은 너무 보수적일 수 있다
3. beta-sheet / loop처럼 마지막 local orientation이 apo와 크게 달라지는 경우
   no-model final step은 성능 ceiling을 만들 수 있다

즉 deterministic final decoder는
**mid/final local geometry 보장용**으로는 훌륭하지만,
global error correction까지 기대하면 안 된다.

### 3.3h 추천 실험 순서

최종적으로는 아래 3개를 꼭 ablation하는 게 좋다.

#### Ablation 1. `omega`도 없는 완전 deterministic final step

```text
final rule: r_L = r_R = 3.8 A, omega = omega_apo
```

이 실험은:

- "정말 마지막 스케일에 모델이 전혀 필요 없는가?"

를 직접 보여준다.

#### Ablation 2. `omega-only` final step

```text
final rule: r_L = r_R = 3.8 A, model predicts omega only
```

이 실험은:

- "마지막 자유도 하나만 학습하면 충분한가?"

를 보여준다.

#### Ablation 3. full learned final step

```text
final rule: model predicts full local state
```

이 실험은:

- hard geometry를 많이 넣는 것이 실제로 도움이 되는지
- 아니면 마지막 유연성을 너무 많이 죽이는지

를 비교하게 해 준다.

현재 직관상 가장 가능성이 높은 건 **Ablation 2 (`omega-only`)**다.

### 3.4 local frame 정의

`omega`의 기준축이 매번 뒤집히면 학습이 망가지므로,
`e2, e3`는 deterministic하게 잡아야 한다.

직관적으로는 이렇게 보면 된다.

- `AB`를 하나의 **막대/축**이라고 생각한다.
- 그 축에 수직인 평면은 **시계판(clock face)**처럼 생긴다.
- `e2`는 그 시계판에서 "3시 방향"처럼 우리가 임의로 정한 **0도 기준 화살표**다.
- `e3`는 그에 수직인 "12시 방향"이다.

즉 "수직인 평면에서의 0도 방향"이란,
그 시계판 위에서
**"여기서부터 각도를 재기 시작하자"라고 정한 출발 방향 1개**를 뜻한다.

`AB` 축만으로는 "원판"은 정해지지만,
그 원판 위에서 어느 방향을 0도로 둘지는 아직 안 정해진 상태다.
그래서 `e2`라는 기준 화살표를 따로 정해야 한다.

권장:

1. `e1 = normalize(B - A)`
2. apo 구조에서 같은 residue `M_apo`를 가져옴
3. `M_apo - (A_apo+B_apo)/2`를 `e1`에 수직 투영해 `e2`를 만듦
4. `e3 = cross(e1, e2)`

즉 **apo midpoint의 방향을 local frame의 기준 방향**으로 쓰는 것이다.

여기서 중요한 점:

- **protein 전체의 center of mass는 쓰지 않는다.**
- 쓰는 것은 오직 **그 local interval의 apo midpoint residue 방향**이다.

더 정확히 쓰면:

```text
v_ref  = M_apo - 0.5 * (A_apo + B_apo)
v_proj = v_ref - dot(v_ref, e1) * e1
e2     = normalize(v_proj)
e3     = cross(e1, e2)
```

의 형태다.

즉 `v_ref`는
"apo 구조에서 midpoint residue가 local anchor midpoint에서 어느 쪽으로 튀어나와 있었는가"
를 나타내는 벡터이고,
그 벡터를 현재 `AB` 축에 수직인 평면으로 눌러서(projection)
그 결과를 `e2`로 쓰는 것이다.

그래서 사용자가 질문한:

> "원의 중심에서 apo의 center of mass 방향 벡터를 AB에 수직인 평면으로 projection해서 e2를 잡는 건가?"

에 대한 답은:

- `center of mass`는 아니다
- `local anchor midpoint -> apo midpoint residue` 방향 벡터를 쓴다

가 정확하다.

이렇게 하면 apo->holo task에 잘 맞고, angle target의 의미도 안정적이다.

### 3.4b `e3`의 방향은 왜 하나로 정해지는가

이 부분도 좋은 지적이다.

겉으로 보면 `e3`는 두 방향 `+e3`, `-e3`가 가능해 보인다.
실제로 `e1`에 수직이고 `e2`에도 수직인 벡터는 부호를 바꾸면 둘 다 가능하다.

하지만 우리는 **부호 규약(convention)**을 하나 고정해서 그 모호성을 없앤다.

즉:

```text
e3 = cross(e1, e2)
```

라고 **순서를 고정**하면,
`e1`, `e2`가 정해졌을 때 `e3`는 right-handed frame 규약에 의해 하나로 정해진다.

반대로:

```text
cross(e2, e1) = -e3
```

이므로, 순서를 바꾸면 반대 방향이 나온다.
그래서 중요한 건 "둘 중 뭐가 맞냐"보다
**항상 같은 순서를 쓰는 것**이다.

즉 모호성 자체는 수학적으로 존재하지만,
우리가

- `e1`을 먼저 정하고
- `e2`를 apo reference로 정하고
- `e3 = cross(e1, e2)`로 고정

하면 구현상 frame은 하나로 정해진다.

### 3.4c 실제로 sign flip이 생길 수 있는 경우

다만 수치적으로는 `e2`가 거의 불안정할 때 문제가 남는다.
예를 들면:

- `M_apo`가 거의 `AB` 축 위에 있어서 `v_proj`가 거의 0
- apo reference 방향이 애매한 경우

이때는 `e2` 자체가 불안정하므로 `e3` 부호도 흔들릴 수 있다.

그래서 이런 경우엔:

1. deterministic fallback axis를 하나 두고
2. 필요하면 이전 level frame과의 dot product가 양수가 되도록 sign을 맞추는

보정이 있으면 더 안정적이다.

### 3.4d `fallback axis`를 실제로 어떻게 두는가

이 부분은 구현 규칙으로 적어두는 게 훨씬 이해가 쉽다.

문제 상황은:

```text
v_ref  = M_apo - 0.5 * (A_apo + B_apo)
v_proj = v_ref - dot(v_ref, e1) * e1
```

를 계산했는데 `||v_proj||`가 너무 작은 경우다.

이 말은 곧,

- apo midpoint 방향이 거의 `AB` 축과 평행하거나
- local 기준 방향을 정할 만큼 충분한 옆방향 성분이 없다는 뜻이다.

이때는 `v_proj`를 억지로 normalize하면 방향이 노이즈에 민감해진다.
그래서 **항상 같은 규칙으로 고르는 보조 기준축**이 필요하다.

이 보조 기준축이 바로 `fallback axis`다.

#### 가장 단순한 fallback rule

전역 좌표축 셋:

```text
x_axis = (1, 0, 0)
y_axis = (0, 1, 0)
z_axis = (0, 0, 1)
```

중에서 현재 `e1`과 **가장 덜 평행한 축** 하나를 고른다.

예를 들어:

- `e1`이 x축에 가깝다면 `y_axis` 또는 `z_axis`를 고르고
- `e1`이 z축에 가깝다면 `x_axis` 또는 `y_axis`를 고른다

그 다음 그 축을 `e1`에 수직인 평면으로 projection 해서 `e2`를 만든다.

즉:

```text
f      = chosen_fallback_axis
f_proj = f - dot(f, e1) * e1
e2     = normalize(f_proj)
e3     = cross(e1, e2)
```

로 쓰면 된다.

핵심은:

- fallback axis는 물리 의미가 있는 방향이 아니라
- **local frame이 붕괴하지 않도록 하는 deterministic emergency rule**이라는 점이다.

#### 왜 "가장 덜 평행한 축"을 고르나

만약 `e1`과 거의 평행한 축을 고르면,
projection 후 길이가 거의 0이 되어 또 같은 문제가 생긴다.

그래서

```text
argmin_a |dot(a, e1)|
```

형태로, `e1`과 가장 수직에 가까운 전역축을 고르는 게 안전하다.

### 3.4e pseudo-code: robust local frame builder

실제 구현은 아래처럼 생각하면 된다.

```python
def build_local_frame(A, B, A_apo, B_apo, M_apo,
                      prev_e2=None, eps=1e-6, tau=1e-3):
    # 1) local axis
    e1 = normalize(B - A)   # current anchor axis

    # 2) apo reference direction
    v_ref = M_apo - 0.5 * (A_apo + B_apo)
    v_proj = v_ref - torch.dot(v_ref, e1) * e1

    # 3) if apo reference is usable, use it
    if torch.norm(v_proj) > tau:
        e2 = normalize(v_proj)
    else:
        # 4) fallback axis: choose global axis least aligned with e1
        candidates = [
            torch.tensor([1.0, 0.0, 0.0], device=e1.device),
            torch.tensor([0.0, 1.0, 0.0], device=e1.device),
            torch.tensor([0.0, 0.0, 1.0], device=e1.device),
        ]
        f = min(candidates, key=lambda a: abs(torch.dot(a, e1)).item())
        f_proj = f - torch.dot(f, e1) * e1
        e2 = normalize(f_proj)

    # 5) optional sign alignment with previous frame
    if prev_e2 is not None and torch.dot(e2, prev_e2) < 0:
        e2 = -e2

    # 6) right-handed frame
    e3 = torch.cross(e1, e2)
    e3 = normalize(e3)
    return e1, e2, e3
```

여기서:

- `tau`는 "apo reference가 너무 약하면 fallback으로 넘어가는 임계값"
- `prev_e2`는 같은 parent interval 또는 이전 level에서 상속한 기준 방향

으로 보면 된다.

### 3.4f sign alignment는 정확히 뭘 하는가

`e2`는 방향 벡터라서 `e2`와 `-e2`가 둘 다 수학적으로 가능하다.
그래서 연속된 interval이나 level 사이에서 frame 부호가 갑자기 뒤집히지 않게,
이전 frame과 가능한 한 같은 방향을 유지하도록 sign을 맞춘다.

가장 단순한 규칙은:

```text
if dot(e2, prev_e2) < 0:
    e2 = -e2
```

이다.

이 규칙의 의미는:

- 이전 기준 방향과 현재 기준 방향이 90도보다 더 반대로 향하면
- 현재 frame을 뒤집어서 같은 반구(hemisphere)에 놓는다

는 것이다.

그 다음 `e3 = cross(e1, e2)`를 다시 계산하면
right-handed frame도 자동으로 같이 정렬된다.

### 3.4g 구현 관점의 추천

실제로는 아래 우선순위가 가장 무난하다.

1. **기본값**: apo midpoint reference 사용
2. **예외상황**: `||v_proj|| < tau` 이면 global fallback axis 사용
3. **연속성 보정**: 이전 frame이 있으면 sign alignment 적용

즉:

> `apo-based local frame`을 기본으로 쓰되,
> 불안정할 때만 `global deterministic fallback`,
> 마지막으로 `sign alignment`를 덧붙이는 방식

이 가장 안전한 설계다.

### 3.5 `omega`를 정확히 어떻게 재는가

질문하신 해석이 거의 맞다.

- `A`를 중심으로 반지름 `r_L`인 구
- `B`를 중심으로 반지름 `r_R`인 구

를 그리면, 보통 두 구의 교집합은 **원(circle)** 하나가 된다.
`M`은 바로 그 원 위의 한 점이다.

즉 `omega`는:

> **"그 교집합 원 위에서, 기준 방향 `e2`를 0도로 잡았을 때 `M`이 몇 도 돌아가 있느냐"**

를 뜻한다.

여기서 중요한 건:

- 원의 중심은 `M`이 아니라 `C`다
- 각도 기준점도 "원 전체의 중점"이 아니라 **기준 방향 `e2`**다

쉽게 말하면:

- `AB` 축을 정면에서 보면 원 하나가 보이고
- `e2`는 그 원 둘레에서 "맨 처음 0도라고 부를 점"을 정하는 방향이다
- `omega`는 거기서부터 반시계 방향으로 얼마나 돌았는지를 나타낸다

정확한 구성은 아래와 같다.

```text
1. AB 방향 단위벡터
   e1 = normalize(B - A)

2. 원의 중심
   C = A + x_axis * e1

3. 원의 평면
   e1에 수직인 평면

4. 그 평면의 기준축
   e2 = 0도 방향
   e3 = 90도 방향
```

그래서 원 위의 점 `M`은:

```text
M = C + rho * (cos(omega) * e2 + sin(omega) * e3)
```

로 쓸 수 있다.

이 식의 의미는:

- `omega = 0`   이면 `M = C + rho * e2`
- `omega = 90°` 이면 `M = C + rho * e3`
- `omega = 180°`이면 `M = C - rho * e2`
- `omega = 270°`이면 `M = C - rho * e3`

이다.

즉 `omega`는 **원 중심 `C`에서 출발해**
`e2` 방향을 0도로 두고
`e2 -> e3` 방향으로 도는 각도라고 이해하면 된다.

### 3.6 왜 기준 방향이 필요한가

교집합이 원이라는 건,
`r_L`, `r_R`만으로는 `M`이 하나로 정해지지 않는다는 뜻이다.
원 위 어디든 갈 수 있기 때문이다.

그래서 추가로 필요한 마지막 1 자유도가 `omega`이고,
이 `omega`를 재려면 **반드시 "여기를 0도로 하자"는 기준 방향 하나가 필요하다.**

우리 문서에서는 그 기준 방향을 `e2`로 두고,
`e2`는 apo 구조의 midpoint 방향에서 가져오자고 한 것이다.

즉:

- 거리 두 개 `r_L`, `r_R`가 "원"을 정하고
- `omega`가 그 원 위의 "구체적인 위치"를 정한다

고 보면 된다.

### 3.7 GT 좌표에서 `omega_gt`를 어떻게 계산하는가

GT midpoint 좌표 `M_gt`가 있을 때는:

```text
v = M_gt - C
omega_gt = atan2(dot(v, e3), dot(v, e2))
```

로 계산한다.

즉:

- `dot(v, e2)` = 0도 축 방향 성분
- `dot(v, e3)` = 90도 축 방향 성분

을 보고 `atan2`로 각도를 복원하는 것이다.

---

## 4. 왜 이 표현이 lever arm을 줄이는가

기존 CA-only/ICS는:

```text
residue 1 -> residue 2 -> residue 3 -> ... -> residue L
```

로 chain 전체가 순차적이라 앞 오차가 끝까지 전파된다.

하지만 RAICS는:

1. sparse anchor chain만 짧게 생성
2. 그 다음은 각 interval에서 midpoint를 **독립적 local problem**으로 생성

이므로,

- coarse 단계 오차는 sparse anchor 수만큼만 누적
- finer 단계 오차는 해당 interval 내부에만 머묾
- 어떤 midpoint 오차도 단백질 전체 말단까지 연쇄적으로 퍼지지 않음

즉 lever arm 경로가

`O(L)` 전역 사슬

에서

`O(L_coarse)` + `many small local intervals`

로 바뀐다.

이게 이 아이디어의 가장 큰 장점이다.

### 4.1 one-shot 전체 Flow Matching 대비 recursive 설계의 장점과 trade-off

비교 기준을 분명히 하자면, one-shot FM baseline은 보통:

- apo 전체 C-alpha chain
- 또는 backbone 전체 좌표

를 한 번에 holo 쪽으로 flow시키는 방식이다.

반면 RAICS는:

1. coarse anchor chain에서 큰 전역 변형을 먼저 맞추고
2. 각 interval 내부의 local detail은 그 다음에 맞춘다.

즉 **같은 flow matching을 쓰더라도, 학습해야 하는 분포를 더 작은 조건부 문제들로 쪼갠다**는 점이 핵심이다.

#### recursive가 가질 수 있는 장점

1. **문제를 global / local로 분해한다.**  
   apo->holo 변화에는 domain motion, hinge movement, loop rearrangement가 섞여 있는데,
   one-shot FM은 이를 한 번에 다 맞춰야 한다.
   RAICS는 coarse 단계가 global displacement를, fine 단계가 local correction을 담당하게 만들 수 있다.

2. **각 예측의 탐색 공간이 작아진다.**  
   midpoint 예측은 전 단백질 전체 좌표장을 맞추는 문제가 아니라,
   "두 anchor가 주어졌을 때 그 사이의 residue를 어디에 둘까"라는 훨씬 작은 조건부 문제다.
   그래서 overfit test를 통과하기 더 쉬운 쪽으로 bias를 줄 수 있다.

3. **오차 전파가 국소화된다.**  
   one-shot FM은 직접적인 NERF lever arm은 없더라도,
   모델이 전역적으로 일관된 긴 chain geometry를 한 번에 맞춰야 한다는 어려움이 남아 있다.
   RAICS는 coarse 오차는 coarse anchor 수준에 머물고,
   fine 오차는 해당 interval 내부에서 주로 해석되므로 디버깅과 개선 포인트가 더 명확하다.

4. **마지막 단계에서 강한 geometry prior를 넣기 쉽다.**  
   final scale에서는 3.8A 인접 CA 거리, 거의 고정된 결합각, deterministic atomization 같은
   강한 물리 priors를 붙일 수 있다.
   이런 구조적 prior는 one-shot Cartesian FM보다 recursive/local 설계에서 더 자연스럽게 들어간다.

5. **완전한 residue-by-residue serial generation이 아니다.**  
   recursive라고 해서 residue를 처음부터 끝까지 하나씩 순서대로 생성하는 것은 아니다.
   같은 level의 여러 interval midpoint는 **병렬 생성**할 수 있다.
   따라서 global AR chain보다는 계산 구조가 더 유연하다.

#### trade-off도 분명히 있다

1. **파이프라인이 복잡해진다.**  
   anchor tree, local frame, feasibility, atomization까지 설계해야 해서 구현 난이도는 올라간다.

2. **ancestor error는 여전히 아래 level로 내려간다.**  
   coarse anchor가 크게 틀리면 그 자식 interval들도 영향을 받는다.
   다만 그 영향이 "전체 말단까지 누적되는 lever arm"이 아니라
   "해당 subtree 내부 bias"로 제한된다는 점이 차이다.

3. **teacher forcing gap을 관리해야 한다.**  
   학습 때 GT parent anchor를 쓰고 추론 때 predicted parent anchor를 쓰면 분포 차이가 생긴다.
   그래서 scheduled sampling이나 noisy parent augmentation이 중요하다.

정리하면,
**RAICS가 one-shot FM보다 항상 우월하다고 단정할 수는 없지만**,
현재처럼 lever arm 문제가 크고 apo->holo에서 overfit조차 잘 안 되는 상황에서는
더 강한 구조적 inductive bias를 주는 방향으로서 충분히 설득력이 있다.

---

## 5. PAR autoregressive 구조는 어떻게 넣을까

PAR의 핵심은 "다음 residue"가 아니라 "다음 scale 전체"를 생성한다는 점이다.
이 구조는 RAICS와 잘 맞는다.

### 추천 방식

각 scale에서 새로 생성할 것은:

- coarsest scale에서는 sparse anchor chain 전체
- 그 아래 scale에서는 각 interval의 midpoint residue들

이다.

따라서 PAR context는 다음처럼 쓸 수 있다.

### 5.1 context token

이전 scale의 예측 좌표들을 현재 scale 크기로 upsample하거나,
현재 scale residue 위치에 대응되는 coarse anchor embedding으로 바꿔서 넣는다.

예:

```text
ctx^s = ARTransformer([bos, Up(pred^{s+1}), Up(pred^{s+2}), ...])
```

### 5.2 현재 scale decoder 입력

midpoint token 하나당 입력:

- left anchor coord
- right anchor coord
- apo local internal state
- residue ESM / scalar feature
- previous-scale context embedding
- time t

즉 current token은 "이 midpoint를 어디에 놓아야 하는가"에 필요한 정보만 받는다.

### 5.2b 벤치마크용 conditioning은 d3pm feature를 그대로 재사용

초기 benchmark 단계에서는 conditioning을 새로 설계하지 말고,
**기존 d3pm benchmark가 이미 쓰고 있는 residue feature를 그대로 재사용**하는 것이 좋다.

이유는 단순하다.
우리가 먼저 검증하고 싶은 것은:

- recursive anchor factorization이 실제로 도움이 되는가
- local ICS refinement가 실제로 도움이 되는가

이지, 새로운 feature engineering의 효과가 아니다.

그래서 첫 버전의 원칙은 아래처럼 두는 것이 맞다.

1. 입력 source는 기존 d3pm `.pt` 파일을 그대로 사용
2. residue scalar feature는 저장된 `x` 또는 `scalar_features`를 그대로 사용
3. `esm_embedding`도 저장된 값을 그대로 사용
4. 새로운 ESM 재추출이나 새로운 handcrafted feature는 추가하지 않는다

현재 코드베이스 기준으로는 대략 두 계열이 있다.

- `resolution=c_alpha_centered_conf`
  - residue feature: `feat_data.x`
  - `d_featurizer = 145`
- `d3pm_features`
  - residue feature: `scalar_features`
  - `d_featurizer = 83`

RAICS의 첫 benchmark는
**기존 ca/cart d3pm benchmark와 가장 직접 비교 가능한 `resolution=c_alpha_centered_conf` 계열을 우선 추천**한다.

즉 초기 버전에서는:

- residue condition = 기존 d3pm residue feature
- sequence condition = 저장된 `esm_embedding`

을 그대로 가져간다.

scale이 생겼다고 해서 conditioning을 새로 만들 필요는 없다.
처음에는 단순하게:

- coarse anchor token: 해당 anchor residue index의 feature를 gather
- midpoint token: 해당 midpoint residue index의 feature를 gather

로 시작하면 충분하다.

나중에만 ablation으로:

- left/right parent feature concat
- interval pooled feature
- span summary feature

같은 것을 붙여 보면 된다.

한 줄로 정리하면:

> **초기 RAICS benchmark는 모델 구조만 바꾸고, 입력 conditioning은 d3pm baseline과 최대한 동일하게 유지한다.**

### 5.3 teacher forcing / scheduled sampling

학습 초반:

- parent anchor는 GT holo anchor를 사용

후반:

- 일정 확률로 predicted parent anchor 사용

즉 기존 PAR 문서의 scheduled sampling 아이디어를 그대로 계승하면 된다.

---

## 6. 모델을 두 개로 나누는 것이 좋다

구현은 하나의 거대한 모델보다, 아래처럼 두 부분으로 나누는 게 낫다.

### A. Coarse Anchor Flow

역할:

- 가장 sparse한 anchor chain을 apo->holo로 이동

표현:

- **Cartesian C-alpha coordinates**

권장 MVP:

- **coarse anchor는 Cartesian으로 고정**해서 검증

이유:

- coarse anchor에는 강한 화학적 local geometry 제약이 거의 없음
- coarse에서 ICS를 써도 이득이 작고 복잡도만 늘어날 수 있음
- 먼저 "recursive interval generation이 정말 lever arm을 줄이는지"를 확인해야 함

### B. Midpoint Refinement Flow

역할:

- 두 parent anchor가 주어졌을 때 midpoint local ICS를 생성

표현:

- `(u_L, u_R, sin omega, cos omega)` 또는 wrapped angle version

이 모듈이 사실상 이번 아이디어의 본체다.

### C. Backbone Atomizer

역할:

- 최종 예측된 C-alpha trace를 backbone atom(N, CA, C, O)으로 복원

표현:

- **학습 없는 deterministic geometry module**

핵심:

- 모델은 backbone atom 전체를 직접 출력하지 않는다
- 마지막 출력은 어디까지나 **C-alpha only**
- backbone은 마지막에 표준 기하로 복원한다

### 6.1 현재 RAICS에서 flow matching은 어디에 쓰이는가

결론부터 말하면, **그렇다. 현재 문서의 RAICS는 여전히 flow matching 기반 설계다.**
다만 one-shot으로 전체 단백질을 한 번에 flow시키는 대신,
**flow matching을 여러 스케일/모듈에 나눠서 쓴다.**

#### FM이 들어가는 부분

1. **Coarse Anchor Flow**  
   sparse anchor의 Cartesian C-alpha 좌표를 apo에서 holo 쪽으로 이동시키는 FM

2. **Midpoint Refinement Flow**  
   각 anchor pair 사이의 midpoint local state
   `(u_L, u_R, sin omega, cos omega)` 또는 이에 대응되는 local coordinate를 생성하는 FM

#### FM이 들어가지 않는 부분

1. **Deterministic backbone atomization**  
   final C-alpha trace로부터 `N, CA, C, O`를 복원하는 단계는
   학습 기반 generative module이 아니라 geometry module이다.

즉 전체적으로 보면:

```text
apo
 -> coarse anchor FM
 -> recursive midpoint refinement FM
 -> final C-alpha
 -> deterministic atomization
 -> backbone
```

이다.

중요한 점은,
**flow matching은 "반드시 전체 단백질 좌표를 한 번에 생성해야만 하는 방법"이 아니다.**
연속 상태공간만 정의되면 되므로,

- coarse sparse Cartesian state
- interval별 low-dimensional local state

같은 더 작은 상태공간에서도 그대로 사용할 수 있다.

즉 RAICS의 핵심 변화는
**FM을 버리는 것**이 아니라,
**FM이 작동하는 상태공간과 factorization을 lever arm에 맞게 다시 설계하는 것**이다.

### 6.2 `par-protein` 구현에서 바로 가져올 만한 실전 기법

위 구조를 실제 `crypticflow_PAR` 코드로 옮길 때는,
논문의 추상적 PAR 아이디어보다 **`par-protein` 코드가 실제로 채택한 구현 습관**을 참고하는 편이 더 도움이 된다.

핵심은:

- 가져올 것은 **recursive dataflow, conditioning 방식, 학습 안정화 기법**
- 그대로 가져오지 말 것은 **interpolation centroid decomposition 자체**

이다.

#### 6.2a scale-block causal context를 그대로 쓰는 것이 좋다

`par-protein`의 중요한 포인트는
autoregressive성을 residue-by-residue가 아니라
**scale block 단위 causal masking**으로 구현했다는 점이다.

RAICS에도 이 방식이 잘 맞는다.

추천 방식:

- coarse anchor token
- current level midpoint token
- 필요하면 이전 level midpoint token

을 하나의 concat token stream으로 두고,

- 같은 level은 서로 attend 가능
- 이전 level은 attend 가능
- 미래 level은 attend 불가

인 block-causal attention mask를 쓴다.

이렇게 하면:

- "현재 midpoint는 어느 parent context까지 볼 수 있는가"가 명확해지고
- recursive inference와 학습 시 attention 구조가 일치하고
- later scale로 갈수록 context를 더 많이 쓰게 만들 수 있다

즉 RAICS에서도 PAR처럼
**token ordering = coarse-to-fine**
로 두는 것이 가장 자연스럽다.

#### 6.2b 위치 정보는 local index보다 raw residue 축을 유지하는 것이 좋다

`par-protein`은 coarse token에도 interpolated raw-sequence position을 유지했다.
이 아이디어는 RAICS에도 그대로 가져갈 가치가 있다.

권장:

- coarse anchor token: 실제 residue index의 normalized embedding
- midpoint token: 해당 midpoint residue index embedding
- 추가로 scale id embedding

즉 token 위치는 단순히
"현재 level에서 몇 번째 token인가"
보다
"원래 chain의 어디를 대표하는가"
를 유지하는 편이 낫다.

RAICS에서는 여기에 더해 아래 metadata도 같이 넣을 수 있다.

- `span = r-l`
- `n_left`, `n_right`
- `is_leaf`, `is_final_leaf`

즉 위치 정보는
**raw residue 위치 + scale 위치 + interval metadata**
조합으로 가는 것이 좋다.

#### 6.2c current scale 입력은 GT target보다 "이전 scale reconstruction"에 가깝게 설계하는 것이 좋다

`par-protein`에서 다음 scale input은 현재 scale GT가 아니라,
이전 scale reconstruction을 다시 resize한 값이었다.

RAICS에서는 exact same mechanism을 쓰지는 않더라도,
철학은 그대로 가져가는 것이 좋다.

즉 current level module이 보는 입력은:

- "이번 level의 정답 local state"

가 아니라

- **직전 level까지의 parent anchor / partial chain reconstruction**

이 되어야 한다.

권장 해석:

- coarse anchor flow: direct Cartesian target 예측
- midpoint flow: parent anchor와 이전 level partial reconstruction을 condition으로 local ICS target 예측
- final atomizer: 학습 입력이 아니라 deterministic geometry stage

즉 target은 direct하게 두되,
**condition은 항상 previous reconstruction 기반**
으로 맞추는 것이 PAR스럽고, 추론 분포와도 잘 맞는다.

#### 6.2d 첫 구현은 "순차 scale loop"만 만들고, 병렬 all-scale path는 만들지 않는 편이 낫다

`par-protein` 코드도 실제로는 scheduled sampling이 켜진
순차 scale-by-scale 경로가 본류라고 보는 편이 맞다.

RAICS도 마찬가지로,
처음부터 아래 두 경로를 동시에 만들 필요가 없다.

- all-scale 병렬 teacher forcing
- sequential recursive generation

권장 MVP는:

1. scale을 하나씩 도는 순차 loop만 구현
2. 각 scale마다 condition encoder -> local decoder 호출
3. 다음 scale input은 직전 scale 출력으로 갱신

이다.

이렇게 해야:

- 디버깅이 쉽고
- 추론 경로와 학습 경로가 가깝고
- scheduled sampling이나 noisy parent augmentation을 붙이기 쉽다

#### 6.2e scheduled sampling은 RAICS에서 더 중요하다

기존 문서에서도 언급했지만,
`par-protein`을 보면 scheduled sampling은 그냥 optional trick이 아니라
**recursive 구조의 train-test mismatch를 줄이는 핵심 장치**로 보는 편이 맞다.

RAICS에서는 특히:

- coarse anchor 오차
- parent anchor 오차
- local frame 오차

가 아래 level로 전파되므로 scheduled sampling이 더 중요하다.

권장 초기안:

- stage 1-2: `p = 0` 또는 아주 작게
- stage 3 이후: `p`를 점진적으로 올림
- 최종적으로 `p ~ 0.3-0.5` 범위 실험

여기서 replace 대상은:

- GT parent anchor
- GT parent-derived local frame
- GT previous-level partial reconstruction

등이다.

즉 midpoint decoder는 일정 확률로
**predicted parent world**에서 훈련되어야 한다.

#### 6.2f noisy context learning을 "noisy parent augmentation"으로 번역해서 쓰는 것이 좋다

`par-protein`은 decoder의 FM time과 별개로
context input 자체에 noise를 섞는 `noisy_context_learning`을 썼다.

RAICS에서도 이 아이디어가 매우 잘 맞는다.

권장 적용:

- parent anchor 좌표에 작은 Gaussian noise
- parent pair frame에 작은 angular jitter
- previous-level reconstruction에 작은 Cartesian noise
- coarse anchor condition에 interpolation noise

중요한 점은,
이 noise는 FM의 `t`와는 별개라는 것이다.

즉 RAICS에서도

- one noise for flow state
- another noise for recursive context robustness

를 분리해서 생각하는 것이 좋다.

이걸 문서 용어로는
**noisy parent augmentation**
이라고 불러도 된다.

#### 6.2g encoder와 scale decoder를 분리하는 것이 좋다

`par-protein`에서 중요한 구조적 선택은:

- AR transformer는 좌표를 직접 찍지 않고 `z_cond`를 만든다
- 실제 좌표 생성은 scale별 conditional flow decoder가 한다

는 점이었다.

RAICS도 이 separation이 유리하다.

추천 구조:

1. **Context Encoder**
   이전 scale까지의 token들을 받아 current scale condition `z_cond` 생성
2. **Coarse Anchor Flow Decoder**
   sparse Cartesian anchor 생성
3. **Midpoint Flow Decoder**
   local ICS state 생성
4. **Final deterministic decoder**
   `omega-only` 또는 deterministic insertion + atomization

즉 "큰 transformer 하나가 모든 좌표를 직접 출력"하는 구조보다,
**context aggregation과 geometry generation을 분리**하는 편이 디버깅과 ablation에 훨씬 유리하다.

#### 6.2h `diffusion_batch_mul` 스타일의 다중 noise/time 샘플링이 유용하다

`par-protein`은 같은 structural target을 한 번의 batch 안에서 여러 번 반복해
서로 다른 noise/time 샘플로 학습했다.

RAICS에도 이 기법은 그대로 쓸 수 있다.

예:

- 동일한 coarse anchor target에 대해 `K`개의 FM sample
- 동일한 midpoint local target에 대해 `K`개의 FM sample

장점:

- batch diversity가 늘고
- FM loss 추정 분산이 줄고
- 작은 dataset / small batch 상황에서 더 안정적일 수 있다

처음엔 `K=2`나 `K=4` 정도의 소형 버전으로 시작하면 충분하다.

#### 6.2i self-conditioning도 coarse와 midpoint 둘 다에서 실험할 가치가 있다

`par-protein` decoder는 자기 clean prediction을 `x_sc`로 다시 넣는 self-conditioning을 썼다.

RAICS에서도 다음 두 군데에 적용 가능하다.

1. **Coarse Anchor Flow**
   이전 clean anchor prediction을 다음 denoising step condition에 넣기
2. **Midpoint Flow**
   이전 local state prediction 또는 decoded midpoint Cartesian을 다시 condition으로 넣기

특히 midpoint flow에서는 아래 두 방식이 가능하다.

- state-space self-conditioning:
  이전 `(u_L, u_R, sin omega, cos omega)`를 넣기
- Cartesian self-conditioning:
  이전에 decode된 midpoint 좌표를 넣기

초기 구현은 Cartesian self-conditioning이 더 직관적일 가능성이 크다.

#### 6.2j pair bias와 register token은 초기에 넣지 않는 것이 좋다

`par-protein` 분석에서 드러난 것처럼,
pair bias나 register token은 코드에 scaffold는 있지만
기본 검증 경로의 핵심은 아니었다.

RAICS에서도 처음부터 아래를 넣지 않는 편이 좋다.

- pair-biased attention
- register token
- 복잡한 pair representation update

그 이유는 RAICS 자체가 이미

- tree metadata
- local frame
- recursive generation
- deterministic atomization

만으로도 충분히 복잡하기 때문이다.

즉 MVP는:

- plain token transformer
- scale embedding
- interval metadata

정도로 시작하는 것이 좋다.

#### 6.2k "마지막 몇 scale만 생성"하는 force-decoding 실험은 꼭 필요하다

`par-protein`의 `force_decode()`는
앞 scale은 GT를 넣고 마지막 몇 scale만 생성해서
어디서 에러가 커지는지 분리해 보는 도구였다.

RAICS에서는 이게 더 중요하다.

권장 진단 모드:

1. coarse anchor는 GT holo
2. 마지막 1 level만 생성
3. 마지막 2 levels만 생성
4. full recursive generation

이렇게 비교하면 아래를 분리해서 볼 수 있다.

- midpoint local model 자체가 어려운가
- parent error propagation이 주범인가
- coarse anchor generation이 병목인가

즉 `force_decode`는 단순 inference 옵션이 아니라
**recursive error budget을 분해하는 핵심 분석 도구**다.

#### 6.2l sampling 끝부분은 deterministic하게 잠그는 것이 좋다

`par-protein`은 sampling 후반부에 stochastic score mode를 끄고
deterministic vector-field mode로 전환했다.

RAICS에서도 coarse anchor flow에는 같은 발상을 적용할 수 있다.

예:

- 초반 denoising step: stochastic FM / score-like sampling
- 마지막 몇 step: deterministic update only

이건 특히 coarse Cartesian anchor 생성에서 유용할 수 있다.
반면 midpoint local state는 상태공간이 작으므로
처음엔 전부 deterministic ODE-style sampling만 써도 충분할 수 있다.

#### 6.2m baseline에서는 residual target보다 direct target이 더 단순하다

`par-protein`도 실제 기본 config는 residual structure가 아니라
direct multiscale coordinate target을 썼다.

RAICS에서도 첫 구현은 아래가 더 안전하다.

- coarse anchor: direct Cartesian target
- midpoint: direct local ICS target

즉 "이전 scale 잔차를 맞히는 모델"보다
"현재 scale 상태 자체를 맞히는 모델"로 시작하고,
previous-level reconstruction은 condition으로만 쓰는 편이 좋다.

이렇게 해야:

- 표현과 loss가 단순하고
- debug가 쉽고
- 각 level의 absolute error를 바로 볼 수 있다

#### 6.2n zero-centering은 coarse Cartesian state에서만 제한적으로 쓰는 것이 좋다

`par-protein`은 all-scale zero-center를 많이 썼지만,
RAICS는 coarse Cartesian state와 local ICS state가 섞여 있다.

그래서 권장안은:

- coarse anchor Cartesian chain: sample별 zero-center 가능
- midpoint local ICS state: zero-center 개념 불필요
- final deterministic geometry: world frame 유지

즉 zero-center는
**전역 Cartesian branch에만 국소적으로 적용**하는 편이 더 자연스럽다.

한 줄로 요약하면,
`par-protein`에서 정말 가져와야 하는 것은

> **scale-block causal context, sequential recursive training, scheduled sampling, noisy context augmentation, separate condition encoder + scale decoder 구조**

이고,
반대로 처음부터 욕심내지 말아야 하는 것은

> **pair bias, register, interpolation centroid decomposition 자체**

이다.

---

## 7. 구현 순서 제안

### Stage 0. Geometry-only round-trip 검증

학습 전에 먼저 다음이 lossless에 가까운지 확인해야 한다.

1. GT holo에서 anchor tree 구축
2. 각 level midpoint를 local ICS로 encode
3. decode해서 원래 좌표 복원

성공 기준:

- midpoint round-trip error << 0.1A

이 단계가 통과되어야 학습 문제가 표현 문제인지 아닌지 분리할 수 있다.

### Stage 1. Midpoint module만 단독 overfit

가장 쉬운 검증:

- parent anchor는 GT holo를 고정
- midpoint local ICS만 학습

즉 모델은 "주어진 양끝 anchor 사이에 정답 midpoint를 맞히는가"만 본다.

성공 기준:

- midpoint RMSD ~ 0
- local variable error ~ 0

이 단계가 되면 pair-anchored local representation은 usable하다는 뜻이다.

### Stage 2. Recursive teacher-forced refinement

- coarse anchor는 GT holo
- level by level로 midpoint들을 생성
- 하지만 다음 level 입력은 이전 level 예측을 사용

성공 기준:

- full C-alpha RMSD가 stage 1보다 크게 망가지지 않음

### Stage 3. Coarse anchor generation 추가

- sparse Cartesian anchor chain을 apo에서 holo로 생성
- 이후 recursive midpoint refinement 연결

이때부터 진짜 end-to-end 모델이다.

### Stage 4. Deterministic backbone atomization 추가

- 최종 C-alpha trace를 입력으로 받음
- N, CA, C, O를 표준 backbone geometry로 복원
- C-alpha RMSD와 backbone-level geometry validity를 분리해서 평가

### Stage 5. PAR context 추가

처음부터 PAR까지 다 넣지 말고,

1. no-AR baseline
2. simple concat context
3. PAR-style AR transformer

순으로 ablation하는 게 좋다.

---

## 8. 현재 코드베이스에서 재사용 가능한 부분

### 바로 재사용 가능한 것

- `crypticflow/model/encoder.py`
  - `CAOnlyEncoder`
  - angle/dihedral geometry helper
- `crypticflow/data/dataset.py`
  - apo/holo C-alpha, scalar feature, ESM 로딩
- `crypticflow/model/transformer.py`
  - residue/token transformer backbone
- `crypticflow/model/crypticflow.py`
  - flow matching 학습 루프 뼈대

### 새로 필요한 것

```text
crypticflow_par/
├── data/
│   ├── anchor_tree.py              # residue binary tree / scale metadata
│   └── recursive_anchor_dataset.py # per-level target builder
├── model/
│   ├── pair_anchor_geometry.py     # local ICS encode/decode
│   ├── midpoint_flow.py            # midpoint local variable FM
│   ├── coarse_anchor_flow.py       # sparse Cartesian anchor chain FM
│   ├── backbone_atomizer.py        # final C-alpha -> backbone deterministic module
│   ├── par_context.py              # optional AR context
│   └── recursive_anchor_par.py     # orchestration
└── train_recursive_anchor.py
```

### 8.1 파일 단위 구현 순서

실제로는 한 번에 전부 만들지 말고, 아래 순서로 구현하는 것이 가장 안전하다.

#### Step 1. tree / metadata builder 고정

먼저 만들 파일:

```text
crypticflow_par/data/anchor_tree.py
```

이 파일이 해야 하는 일:

- chain length `L`에 대해 ragged dyadic midpoint tree 생성
- level별 `anchor_idx`, `mid_idx`, `left_parent_idx`, `right_parent_idx` 생성
- interval별 `span`, `n_left`, `n_right`, `is_leaf`, `is_final_leaf` 생성

먼저 붙일 테스트:

- `L = 8, 9, 17, 100, 219`에서 tree가 안정적으로 생성되는지
- 모든 residue가 정확히 한 번씩만 "새 midpoint"로 등장하는지
- parent-child interval에 겹침/누락이 없는지

#### Step 2. local pair-anchor geometry 분리

다음 파일:

```text
crypticflow_par/model/pair_anchor_geometry.py
```

이 파일이 해야 하는 일:

- pair-anchor local state encode
- pair-anchor local state decode
- robust local frame builder
- feasibility penalty / optional projection
- final-scale `omega-only` decoder

먼저 붙일 테스트:

- GT holo 좌표 encode -> decode round-trip
- `rho^2 < 0` fallback 동작 확인
- `apo midpoint ~ AB axis`일 때 fallback axis / sign alignment 안정성 확인

#### Step 3. d3pm 재사용 dataset builder

다음 파일:

```text
crypticflow_par/data/recursive_anchor_dataset.py
```

이 파일이 해야 하는 일:

- 기존 d3pm `.pt` 파일 로드
- apo/holo CA 좌표 로드
- 기존 residue feature와 `esm_embedding`을 그대로 로드
- anchor tree metadata 생성
- level별 coarse anchor / midpoint supervision tensor 생성

중요한 정책:

- benchmark 단계에서는 feature를 새로 만들지 않는다
- midpoint token은 midpoint residue의 기존 d3pm feature를 그대로 쓴다
- anchor token도 anchor residue의 기존 d3pm feature를 그대로 쓴다

먼저 붙일 테스트:

- 샘플 1개 로드 후 level별 tensor shape 출력
- `mid_idx`, `left/right parent idx`, `apo/holo_mid_state` 일관성 확인
- residue 수와 ESM 길이가 원본 d3pm 샘플과 정확히 맞는지 확인

#### Step 4. midpoint-only teacher-forced baseline

다음 파일:

```text
crypticflow_par/model/midpoint_flow.py
crypticflow_par/train_midpoint_only.py
crypticflow_par/configs/overfit_midpoint_only.yaml
```

이 단계의 목표:

- coarse generation 없이
- GT parent anchor를 조건으로
- midpoint local state만 복원

즉 가장 먼저 검증할 것은:

> **pair-anchor local ICS representation이 정말 학습 가능한가**

이다.

처음 loss는 단순하게:

- `L_mid`
- `L_feas`
- optional `L_coord`

만 두는 것이 좋다.

먼저 붙일 테스트:

- single-file overfit
- small multi-sample overfit
- level별 midpoint RMSD / omega error / feasibility violation rate 출력

#### Step 5. coarse Cartesian anchor flow 추가

다음 파일:

```text
crypticflow_par/model/coarse_anchor_flow.py
```

이 단계의 목표:

- sparse anchor만 apo -> holo로 Cartesian FM

여기서는 기존 `crypticflow/model/crypticflow.py`의 FM training skeleton과
transformer backbone을 최대한 재사용하는 것이 좋다.

먼저 붙일 테스트:

- anchor-only overfit
- coarse anchor RMSD 출력
- stride 4 / 8 / 16 비교

#### Step 6. recursive orchestration 연결

다음 파일:

```text
crypticflow_par/model/recursive_anchor_par.py
crypticflow_par/train_recursive_anchor.py
```

이 파일이 해야 하는 일:

- coarse anchor 생성
- level별 midpoint refinement 반복
- 기존 anchor와 new midpoint merge
- optional teacher forcing / scheduled sampling

이 단계에서는 아직 backbone atomization 없이
**final CA trace까지만** 맞추는 것이 좋다.

먼저 붙일 테스트:

- GT coarse + predicted midpoint
- predicted coarse + GT midpoint
- predicted coarse + predicted midpoint

이 3개를 따로 돌려서 오차 원인을 coarse / midpoint로 분리한다.

#### Step 7. deterministic backbone atomizer 추가

다음 파일:

```text
crypticflow_par/model/backbone_atomizer.py
crypticflow_par/eval_atomized_backbone.py
```

이 단계의 목표:

- final predicted CA trace에서 backbone atom 복원
- CA quality와 backbone quality를 분리 평가

먼저 붙일 테스트:

- GT CA -> atomizer -> backbone RMSD
- predicted CA -> atomizer -> backbone RMSD

#### Step 8. 마지막에만 PAR context / scheduled sampling 추가

다음 파일:

```text
crypticflow_par/model/par_context.py
```

이 단계는 제일 나중이 좋다.
처음부터 AR context까지 같이 넣으면

- geometry 설계 문제인지
- recursive factorization 문제인지
- context 전달 문제인지

가 섞여 버린다.

추천 순서는:

1. no-AR
2. simple concat context
3. PAR-style context
4. scheduled sampling

이다.

---

## 9. 데이터 구조 초안

샘플 하나에서 level별로 다음을 만든다.

### 9.1 coarse anchor 정보

```python
sample["levels"][s]["anchor_idx"]         # (n_s,)
sample["levels"][s]["apo_anchor_ca"]      # (n_s, 3)
sample["levels"][s]["holo_anchor_ca"]     # (n_s, 3)
```

### 9.2 midpoint interval 정보

```python
sample["levels"][s]["mid_idx"]            # (m_s,)  새로 생성할 residue index
sample["levels"][s]["left_parent_idx"]    # (m_s,)
sample["levels"][s]["right_parent_idx"]   # (m_s,)
sample["levels"][s]["apo_mid_state"]      # (m_s, 4) [uL, uR, sinw, cosw]
sample["levels"][s]["holo_mid_state"]     # (m_s, 4)
sample["levels"][s]["n_left_bonds"]       # (m_s,)
sample["levels"][s]["n_right_bonds"]      # (m_s,)
sample["levels"][s]["esm_mid"]            # (m_s, d_esm) or pooled
sample["levels"][s]["feat_mid"]           # (m_s, d_feat)
```

초기 benchmark에서는 여기의 `esm_mid`, `feat_mid`를 새로 만들지 않고,
**원본 d3pm sample에서 midpoint residue index로 gather** 하는 방식으로 시작한다.

즉:

- `feat_mid = residue_feature[mid_idx]`
- `esm_mid  = esm_embedding[mid_idx + 1]`

처럼 단순 index gather가 기본값이다.

나중에만 필요하면:

- parent anchor feature concat
- interval pooled feature
- coarse-to-fine propagated context

를 추가하면 된다.

---

## 10. Loss 설계

### 10.1 coarse anchor loss

```text
L_coarse = FM_loss(X_anchor_apo^S -> X_anchor_holo^S)
```

즉 coarse 단계는 **Cartesian C-alpha flow matching**이 기본이다.
여기서는 physical validity보다 global shape alignment가 더 중요한 목표다.

### 10.2 midpoint local variable loss

`u_L`, `u_R`는 일반 실수,
`omega`는 주기성이 있으므로 sin/cos로 두는 게 좋다.

```text
L_mid = MSE(u_L_pred, u_L_gt)
      + MSE(u_R_pred, u_R_gt)
      + MSE(sinw_pred, sinw_gt)
      + MSE(cosw_pred, cosw_gt)
```

### 10.3 feasibility / geometry loss

삼각 부등식이 깨지지 않게:

```text
|r_L - r_R| <= |AB| <= r_L + r_R
```

를 projection 또는 hinge penalty로 넣는다.

또한:

```text
r_L <= 3.8 * n_L
r_R <= 3.8 * n_R
```

는 sigmoid parameterization이면 자동으로 보장된다.

### 10.4 final coordinate loss

각 level decode 후 optional auxiliary:

```text
L_coord = RMSD(pred_CA^level, gt_CA^level)
```

최종 full chain에서는:

- Kabsch C-alpha RMSD
- local distance preservation
- steric clash penalty

를 보조항으로 쓸 수 있다.

### 10.4b pseudo-angle 대응 auxiliary loss: `L_skip2`

`CA-CA-CA` pseudo-angle은 마지막 스케일에서 중요한 local geometry이지만,
이를 직접 `arccos` 기반 angle loss로 거는 것보다
**skip-2 distance loss**로 거는 편이 더 안정적이다.

```text
L_skip2 = Σ_i w_i * Huber(||x_i - x_{i+2}|| - d_{i,gt}^{(2)})
```

여기서:

- `x_i` = 예측된 `CA_i` 좌표
- `d_{i,gt}^{(2)}` = GT holo 구조의 `||CA_i - CA_{i+2}||`
- `w_i` = residue별 가중치

이다.

직관은 단순하다.
인접 `CA-CA` 길이가 대체로 `3.8A` 근처라면,
`||CA_i - CA_{i+2}||`는 `angle(CA_i, CA_{i+1}, CA_{i+2})`와 거의 1:1 대응한다.

```text
(d_i^(2))^2 = l_i^2 + l_{i+1}^2 - 2 l_i l_{i+1} cos τ_i
```

즉 pseudo-angle regularization을
**skip-2 end-to-end distance regularization**으로 구현하는 셈이다.

#### 왜 angle loss 대신 이걸 권장하나

- `arccos`를 직접 쓰는 angle loss보다 gradient가 더 안정적이다
- 인접 bond length가 거의 고정일 때 pseudo-angle 정보를 충분히 잘 담는다
- 구현이 간단하고 vectorized하기 쉽다

#### 어디에 거는 것이 맞나

중요한 점은,
`A = CA_i`, `M = CA_{i+1}`, `B = CA_{i+2}`에서
parent anchor `A, B`가 이미 고정돼 있으면 `||A-B||`는 `M`과 무관하다는 것이다.

즉 `L_skip2`는
**단일 midpoint local loss**로는 약하고,
**최종 full C-alpha chain이 조립된 뒤의 global geometry regularizer**로 쓰는 편이 더 자연스럽다.

실제로 새 residue `CA_{i+1}`는

- `||CA_{i-1} - CA_{i+1}||`
- `||CA_{i+1} - CA_{i+3}||`

같은 이웃 skip-2 항들에 들어가므로,
interval 경계 across-scale의 angle consistency를 부드럽게 밀어줄 수 있다.

#### coarse scale에서는 어떻게 일반화하나

이 아이디어를 모든 scale에 똑같이 "pseudo-angle loss"로 적용하는 것은 맞지 않다.
coarse scale로 갈수록 이는 angle이라기보다
**anchor interval span에 대한 end-to-end distance prior**로 해석하는 편이 맞다.

즉 scale `s`에서 인접 anchor pair `(i, j)`가
원래 residue span `j-i`를 덮는다면:

```text
L_span^(s) = Σ_(i,j in level s) w_ij^(s) * Huber(||x_i - x_j|| - d_ij,gt)
```

를 둘 수 있다.

추천 해석은:

- final scale: `L_skip2`를 비교적 강하게
- penultimate / middle scale: 동일한 아이디어를 더 약한 `span-k` distance prior로 사용
- coarse scale: global coordinate supervision이 주역이고, span prior는 가벼운 regularizer로만 사용

실전적인 전체 loss 조합은 예를 들면:

```text
L_total = λ_coarse L_coarse
        + λ_mid    L_mid
        + λ_feas   L_feas
        + λ_coord  L_coord
        + λ_len    L_len
        + λ_skip2  L_skip2
        + λ_span   Σ_s L_span^(s)
        + λ_bbaux  L_backbone_aux
```

처럼 둘 수 있다.

여기서 직관은:

- `L_len`: 인접 `CA-CA` 거리
- `L_skip2`: finest scale pseudo-angle consistency
- `L_span^(s)`: coarser scale interval geometry prior

를 담당하게 하는 것이다.

### 10.5 deterministic backbone atomization loss

모델이 직접 backbone atom을 출력하지 않고
최종 C-alpha trace만 만든 뒤 deterministic atomizer로 backbone을 복원한다면,
아래와 같이 평가/보조 loss를 둘 수 있다.

```text
X_backbone = Atomize(pred_CA_final)
L_backbone_aux = RMSD(X_backbone, X_backbone_gt)
```

중요한 점은:

- 주생성 모델의 출력은 여전히 `pred_CA_final`
- backbone RMSD는 atomizer까지 포함한 end-to-end quality 확인용 보조 신호

라는 점이다.

---

## 11. 추론 알고리즘 스케치

```python
anchors = generate_coarse_anchors(apo_sample)

for level in reversed(levels_to_refine):
    intervals = build_intervals(anchors, level)
    mid_states = midpoint_model(
        left_anchor=intervals.left_coord,
        right_anchor=intervals.right_coord,
        apo_state=intervals.apo_mid_state,
        esm=intervals.esm_mid,
        feat=intervals.feat_mid,
        context=previous_scale_context,
    )
    mid_coords = decode_pair_anchor_state(
        left_anchor, right_anchor, mid_states, n_left, n_right
    )
    anchors = merge_and_sort(anchors, mid_coords)

full_ca = anchors
```

포인트는:

- 매 level에서 현재 생성 대상은 "새 midpoint들"뿐이고
- 기존 parent anchor는 고정된 조건으로 쓰인다는 점이다.

이 구조 덕분에 에러가 local interval 밖으로 크게 퍼지지 않는다.

---

## 12. 가장 먼저 해볼 MVP

현실적인 첫 구현은 아래 순서를 추천한다.

### MVP-1

**GT parent anchor를 조건으로 midpoint만 복원**

- 학습 대상: midpoint local ICS
- 목적: pair-anchor 표현 자체 검증

### MVP-2

**coarse anchor는 Cartesian, refinement만 local ICS**

- 이유: coarse 단계 불안정성과 midpoint 표현 문제를 분리

### MVP-3

**final C-alpha + deterministic backbone atomization**

- backbone 전체를 직접 생성하지 않고도
  atomization으로 full backbone 품질을 확인할 수 있다

### MVP-4

**PAR AR context 추가**

- no-AR baseline과 비교

### 12.1 지금 바로 시작할 첫 스프린트

지금 시점에서 가장 현실적인 첫 스프린트는 아래 4개다.

1. `anchor_tree.py`
   - chain -> level metadata가 완전히 deterministic하게 나오도록 구현
2. `pair_anchor_geometry.py`
   - encode/decode round-trip와 fallback frame을 먼저 검증
3. `recursive_anchor_dataset.py`
   - d3pm feature / ESM을 그대로 실어 level별 sample 생성
4. `train_midpoint_only.py`
   - GT parent anchor 조건 teacher-forced midpoint overfit

즉 첫 주 목표는 end-to-end 모델이 아니라,

> **geometry 표현이 정확하고, dataset이 일관적이며, midpoint module이 단독 overfit 되는가**

를 확인하는 것이다.

이 4개가 통과된 뒤에만:

- coarse anchor flow
- recursive unrolling
- deterministic atomization
- PAR context

를 얹는 것이 맞다.

---

## 13. 추천 ablation

1. `coarse Cartesian + local ICS refinement` vs `coarse Cartesian + local Cartesian refinement`
2. `omega-only final step` vs `full learned final local state`
3. `C-alpha only evaluation` vs `C-alpha + deterministic backbone atomization`
4. `no AR` vs `concat context` vs `PAR AR`
5. stride/coarse level: `4 / 8 / 16`
6. parent anchor conditioning: `GT only` vs `scheduled sampling`

이 비교를 해야 어떤 부분이 실제 개선 원인인지 분리된다.

---

## 14. 예상 리스크

### 리스크 1. local frame flip

apo midpoint가 거의 `AB` 축 위에 있으면 `e2`가 불안정해질 수 있다.

대응:

- norm이 너무 작으면 deterministic fallback axis 사용
- 또는 parent interval frame을 상속

### 리스크 2. triangle feasibility 불안정

예측한 `r_L`, `r_R`가 `AB` 거리와 맞지 않으면 `rho^2 < 0`가 된다.

대응:

- decode 전 differentiable projection
- 또는 feasibility hinge loss 추가

### 리스크 3. coarse stride를 너무 크게 잡음

coarse anchor chain의 virtual distance 분포가 지나치게 넓어질 수 있다.

대응:

- 처음에는 stride 4 또는 8 정도부터 시작
- overfit 통과 후 더 coarse하게 확장

### 리스크 4. deterministic atomization이 local detail을 너무 보수적으로 만들 수 있음

마지막 C-alpha trace는 좋더라도,
deterministic backbone atomization이 apo/holo 차이에서 필요한 미세 local rearrangement를 다 담지 못할 수 있다.

대응:

- 먼저 backbone atomization은 deterministic baseline으로 시작
- 필요하면 이후 residual torsion correction 같은 작은 learned head를 붙이는 방향 검토

---

## 15. 최종 판단

이 아이디어는 충분히 해볼 가치가 있다.  
다만 성공하려면 아이디어를 다음처럼 해석해야 한다.

### 좋은 해석

- stride로 실제 anchor residue를 선택
- coarse scale은 **Cartesian C-alpha anchors**를 생성
- 모델은 **C-alpha only output**을 만든다
- finer/final scale은 anchor-conditioned local refinement를 사용한다
- 최종 backbone은 **deterministic atomization**으로 복원한다
- PAR는 scale-to-scale context 전달에 사용

### 좋지 않은 해석

- stride chain 전체를 매 scale마다 다시 긴 NERF로 끝까지 복원
- coarse anchor에 3.8A 같은 화학 제약을 강제로 적용
- 처음부터 coarse/fine/backbone/PAR를 한 번에 모두 넣음

즉 추천 구현 방향은:

> **"coarse Cartesian C-alpha generation + local recursive refinement + deterministic backbone atomization"**

로 정리하는 것이다.

이게 현재 `crypticflow`의 lever arm 문제를 가장 직접적으로 찌르는 형태다.
