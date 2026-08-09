# Amber 튜토리얼 실습 노트: 1.1–1.6, 3.1–3.4

초보자가 `ambermd.org/tutorials/`의 **1.1–1.6 Building Systems**와 **3.1–3.4 Creating Stable Systems and Running MD**를 직접 따라 할 수 있도록 한국어로 다시 정리한 실습용 Markdown입니다.

- 원문 튜토리얼 색인: https://ambermd.org/tutorials/
- 작성 기준: AmberTools/Amber 26 페이지를 기준으로 하되, 일부 튜토리얼 본문에 남아 있는 Amber20/Amber21 예시는 현재 환경에 맞게 `source /path/to/amber.sh` 형태로 고쳐 쓰는 것을 권장합니다.
- 이 문서는 원문을 그대로 번역한 것이 아니라, **실행 순서·파일 이름·검사 포인트·자주 막히는 부분** 중심으로 재구성한 실습 가이드입니다.
- Amber 튜토리얼은 논문용 “완성 프로토콜”이 아니라 출발점입니다. 실제 연구에서는 힘장, protonation, salt, box size, relaxation, production 조건을 시스템에 맞게 검토해야 합니다.

---

## 0. 먼저 알아야 할 Amber 전체 흐름

Amber 실습은 대개 아래 순서로 진행됩니다.

```text
PDB 구조 준비
  ↓
pdb4amber / 수동 편집 / VMD 확인
  ↓
tleap으로 force field 로드, 결합/수화/이온 추가
  ↓
prmtop + inpcrd 또는 rst7 생성
  ↓
minimization / heating / relaxation
  ↓
production MD
  ↓
cpptraj, VMD, MMPBSA.py 등으로 분석
```

핵심 파일은 다음과 같습니다.

| 파일                          | 의미                                                | 보통 누가 만드나                         |
| --------------------------- | ------------------------------------------------- | --------------------------------- |
| `.pdb`                      | 원자 좌표가 들어 있는 구조 파일                                | RCSB PDB, VMD, pdb4amber, cpptraj |
| `.prmtop`, `.parm7`, `.top` | topology/parameter 파일. 원자, 결합, 전하, force field 정보 | `tleap`                           |
| `.inpcrd`, `.rst7`, `.crd`  | 좌표 또는 restart 좌표 파일                               | `tleap`, `pmemd`, `sander`        |
| `.in`, `.mdin`              | MD/minimization 입력 옵션                             | 사용자가 작성                           |
| `.out`, `.mdout`            | 실행 로그와 에너지 출력                                     | `pmemd`, `sander`                 |
| `.nc`, `.mdcrd`             | trajectory                                        | `pmemd`, `sander`                 |

실습 전에 터미널에서 아래를 확인하세요.

```bash
# Amber 환경 로드. 실제 설치 경로로 바꾸세요.
source /path/to/amber26/amber.sh

# 핵심 프로그램 확인
which tleap
which pdb4amber
which parmed
which cpptraj
which pmemd || true
which pmemd.cuda || true

# GPU가 있다면 확인
nvidia-smi
```

권장 작업 방식은 튜토리얼마다 폴더를 따로 만드는 것입니다.

```bash
mkdir -p amber_practice
cd amber_practice
```

---

## 1.1 Preparing Structure: pdb4amber로 PDB 정리하기

원문: https://ambermd.org/tutorials/basic/tutorial9/index.php

### 목표

- 외부에서 받은 PDB가 Amber/LEaP에서 잘 읽히도록 정리합니다.
- `pdb4amber`의 기본 사용법을 익힙니다.
- `pdb4amber` 출력 요약에서 chain, alternate location, non-standard residue, missing atom을 확인합니다.

### 실습 폴더

```bash
mkdir -p 01_1_pdb4amber
cd 01_1_pdb4amber
```

### 예제 1: 원문과 같은 1ESH RNA PDB 준비

RCSB에서 직접 받거나 터미널에서 받을 수 있습니다.

```bash
wget https://files.rcsb.org/download/1ESH.pdb -O 1esh.pdb
```

`pdb4amber` 도움말을 먼저 봅니다.

```bash
pdb4amber -h
```

원문 튜토리얼은 아래처럼 표준 출력 리다이렉션을 사용합니다.

```bash
pdb4amber 1esh.pdb > 1esh.amber.pdb
```

명시적으로 입력/출력을 지정하고 싶으면 다음처럼 해도 됩니다.

```bash
pdb4amber -i 1esh.pdb -o 1esh.amber.pdb
```

### 꼭 확인할 것

실행 후 터미널에 나오는 요약에서 아래 항목을 확인합니다.

```text
Chains
Alternate Locations
Non-standard-resnames
Missing heavy atom(s)
```

- `Alternate Locations`가 있으면 어떤 conformer를 쓸지 정해야 합니다.
- `Non-standard-resnames`가 있으면 Amber force field가 아는 residue인지 확인해야 합니다.
- `Missing heavy atom(s)`가 있으면 바로 MD로 가지 말고 구조 모델링/수정이 필요합니다.

### 산출물

```bash
ls -lh
# 1esh.pdb
# 1esh.amber.pdb
```

`1esh.amber.pdb`를 다음 단계인 `tleap` 입력으로 사용할 수 있습니다.

---

## 1.2 Fundamentals of LEaP: tleap 기본기

원문: https://ambermd.org/tutorials/pengfei/index.php

### 목표

- LEaP가 구조 파일과 force field 파일을 모아 `prmtop`/`inpcrd`를 만든다는 것을 이해합니다.
- `leaprc` 파일을 source하여 force field를 불러오는 방식을 익힙니다.
- `loadPdb`, `solvateOct`, `addIons`, `saveAmberParm`을 사용합니다.

### LEaP가 하는 일

`tleap`은 대략 다음 정보를 합쳐서 시뮬레이션 입력 파일을 만듭니다.

```text
PDB 좌표 + residue library + force field parameter
  → topology(.prmtop/.parm7) + coordinate(.inpcrd/.rst7)
```

표준 force field는 보통 `$AMBERHOME/dat/leap/cmd/` 아래의 `leaprc.*` 파일로 불러옵니다.

```bash
ls $AMBERHOME/dat/leap/cmd/leaprc.* | head
```

### 예제: fasciculin 단백질을 물 박스에 넣기

실습 폴더를 만듭니다.

```bash
cd ../
mkdir -p 01_2_leap_fasciculin
cd 01_2_leap_fasciculin
```

PDB를 받습니다.

```bash
wget https://files.rcsb.org/download/1FSC.pdb -O 1fsc.pdb
```

먼저 PDB를 Amber 친화적으로 정리합니다.

```bash
pdb4amber -i 1fsc.pdb -o 1fsc_amb.pdb
```

> 원문에서는 1FSC에 disulfide bridge가 있고, PDB의 `CONECT` record를 이용해 처리된다고 설명합니다. 다만 실제 연구에서는 항상 `SSBOND`, `CYS/CYX`, LEaP output을 직접 확인해야 합니다.

`tleap.in` 파일을 만듭니다.

```bash
cat > tleap.in <<'EOF'
source leaprc.protein.ff14SB
source leaprc.water.spce

fasciculin = loadPdb "1fsc_amb.pdb"
solvateOct fasciculin SPCBOX 14.0
addIons fasciculin Cl- 4
saveAmberParm fasciculin solvated_1fsc.prmtop solvated_1fsc.inpcrd
quit
EOF
```

실행합니다.

```bash
tleap -f tleap.in | tee tleap.out
```

### 출력 확인

```bash
ls -lh
# solvated_1fsc.prmtop
# solvated_1fsc.inpcrd
# leap.log
# tleap.out
```

`leap.log`와 `tleap.out`에서 다음을 확인합니다.

```bash
grep -i "warning\|error\|fatal" leap.log tleap.out
```

- `Errors = 0`이어야 다음 단계로 넘어가기 좋습니다.
- Warning이 있으면 무시하지 말고, 어떤 residue/atom 때문에 발생했는지 확인합니다.
- `addIons fasciculin Cl- 4`는 예제 시스템의 양전하를 중화하기 위한 것입니다. 자신의 시스템에서는 전체 전하가 달라질 수 있습니다.

### 최신 force field로 바꾸고 싶을 때

원문 예제는 `ff14SB + SPC/E`를 씁니다. 최근 단백질 예제에서는 `ff19SB + OPC` 조합을 자주 사용합니다. 다만 물 모델, ion parameter, 기존 결과 재현성을 고려해야 하므로 튜토리얼을 그대로 따라 할 때는 원문 조합을 유지하는 편이 안전합니다.

---

## 1.3 Building Systems with CHARMM-GUI

원문: https://ambermd.org/tutorials/CHARMM-GUI.php

### 이 튜토리얼의 성격

이 페이지는 Amber 내부 명령을 직접 실습하는 페이지라기보다, **CHARMM-GUI에서 Amber 입력 파일을 만드는 외부 튜토리얼 모음**입니다.

CHARMM-GUI를 쓰면 다음처럼 복잡한 시스템을 GUI로 구성한 뒤 Amber용 입력을 내려받을 수 있습니다.

- 단백질/N-glycan/ligand/membrane 복합체 예제: 5O8F
- protein/DNA/RNA 복합체 예제: 6O0Z
- PDB2PQR로 protonation state를 바꾸고 Amber force field residue name을 읽는 예제: 6IYC

### 언제 CHARMM-GUI가 유용한가

- 막 단백질, lipid bilayer, glycan, ligand가 섞인 복잡한 시스템
- PDB의 missing residue를 GUI로 보완하고 싶을 때
- 처음부터 `tleap` 명령만으로 만들기 부담스러운 시스템

### 주의점

CHARMM-GUI에서 Amber force field를 선택할 때는 반드시 아래를 확인합니다.

1. 내가 쓰려는 Amber force field가 CHARMM-GUI에서 지원되는가?
2. 단백질, 핵산, lipid, glycan, water, ion parameter가 서로 호환되는가?
3. 내려받은 Amber 입력 파일을 그대로 실행하기 전에 `prmtop`, `inpcrd`, `mdin`을 확인했는가?
4. CHARMM-GUI가 만든 protonation state가 내 연구 조건과 맞는가?

### 실습 메모

이 페이지는 명령어 예제가 적습니다. 처음 배우는 경우에는 1.1, 1.2, 1.5, 1.6을 먼저 해보고, 막/복합체가 필요할 때 CHARMM-GUI로 넘어가는 것을 권합니다.

---

## 1.4 Hydrogen Mass Repartitioning: HMR

원문: https://ambermd.org/tutorials/basic/tutorial12/index.php

### 목표

- 수소 질량을 키우고, 연결된 heavy atom 질량을 줄여 전체 질량을 보존합니다.
- 더 긴 time step, 예를 들어 4 fs를 쓸 수 있는 topology를 만듭니다.
- `parmed`의 `hmassrepartition` 명령을 사용합니다.

### 개념

HMR은 hydrogen의 빠른 진동을 완화하여 MD time step을 늘릴 때 쓰입니다. 원문 예제에서는 alanine dipeptide topology `diala.parm7`에 대해 수소 질량을 3.024 Da로 재분배합니다. 물 수소 질량은 기본적으로 바꾸지 않습니다.

### 실습 폴더

```bash
cd ../
mkdir -p 01_4_hmr
cd 01_4_hmr
```

원문 튜토리얼의 `diala.parm7`를 페이지에서 내려받아 같은 폴더에 둡니다. 또는 이미 만든 topology가 있으면 그 파일을 사용합니다.

### 실행

```bash
parmed diala.parm7
```

`ParmEd` 프롬프트가 나오면 다음을 입력합니다.

```text
hmassrepartition
outparm diala_hmass.parm7
quit
```

한 번에 실행하고 싶으면 입력 파일을 만들어도 됩니다.

```bash
cat > hmr.parmed <<'EOF'
hmassrepartition
outparm diala_hmass.parm7
quit
EOF

parmed diala.parm7 < hmr.parmed | tee hmr.out
```

### 확인

```bash
ls -lh diala.parm7 diala_hmass.parm7
```

`hmr.out`에 다음과 비슷한 메시지가 있는지 확인합니다.

```text
Repartitioning hydrogen masses to 3.024 daltons.
Not changing water hydrogen masses.
```

### 주의점

- HMR을 한 topology와 하지 않은 topology를 섞어 쓰면 안 됩니다.
- HMR을 했다고 무조건 4 fs가 안전한 것은 아닙니다. force field, constraints, thermostat, temperature, system type을 함께 확인해야 합니다.
- 기존 restart/trajectory를 HMR topology로 분석할 때 mass 관련 분석이 바뀔 수 있습니다.

---

## 1.5 Building a Peptide Sequence: chignolin 만들기

원문: https://ambermd.org/tutorials/basic/tutorial10/index.php

### 목표

- 실험 구조가 없을 때 `sequence` 명령으로 peptide를 만듭니다.
- implicit solvent GB 계산용 radii를 지정합니다.
- `savepdb`, `saveamberparm`을 사용합니다.

### 실습 폴더

```bash
cd ../
mkdir -p 01_5_chignolin
cd 01_5_chignolin
```

### tleap 입력 파일 작성

원문 예제는 chignolin 10개 residue를 extended structure로 만듭니다.

```bash
cat > tleap.in <<'EOF'
source leaprc.protein.ff14SBonlysc
set default PBradii mbondi3

chig = sequence { GLY TYR ASP PRO GLU THR GLY THR TRP GLY }
savepdb chig chignolin_ext.pdb
saveamberparm chig chig_ext.parm7 chig_ext.crd
quit
EOF
```

실행합니다.

```bash
tleap -f tleap.in | tee tleap.out
```

### 결과 확인

```bash
ls -lh chignolin_ext.pdb chig_ext.parm7 chig_ext.crd leap.log
```

Warning이 있는지 확인합니다.

```bash
grep -i "warning\|error\|fatal" tleap.out leap.log
```

원문 예제에서는 전체 전하가 -2라는 Warning이 나옵니다. **implicit solvent 계산에서는 중화 ion 없이 진행할 수 있지만**, explicit solvent 계산에서는 보통 counterion을 넣어 전체 전하를 중화합니다.

### 핵심 포인트

- `source leaprc.protein.ff14SBonlysc`: peptide force field를 불러옵니다.
- `set default PBradii mbondi3`: GBneck2 등 implicit solvent 설정에 맞는 radii를 지정합니다.
- `sequence { ... }`: residue를 순서대로 연결합니다.
- `savepdb`: 구조를 눈으로 확인할 수 있게 PDB를 저장합니다.
- `saveamberparm`: 실제 계산에 필요한 topology와 좌표를 저장합니다.

---

## 1.6 Building Protein Systems in Explicit Solvent: RAMP1 시스템 만들기

원문: https://ambermd.org/tutorials/basic/tutorial7/index.php

### 목표

- 단백질 PDB를 실제 MD에 쓸 수 있게 검사하고 수정합니다.
- disulfide bond, protonation state, 물 모델, counterion, salt를 처리합니다.
- `tleap`으로 explicit water system의 `prmtop`과 `inpcrd`를 만듭니다.

### 전체 흐름

```text
2YX8.pdb 다운로드
  ↓
VMD로 구조 확인
  ↓
MSE → MET 수정
  ↓
CYS(disulfide) → CYX 수정
  ↓
H++ 등으로 His protonation 검토: His75 HIP, His97 HID
  ↓
CONECT 제거, RAMP1.pdb 저장
  ↓
tleap: ff19SB + OPC, disulfide bond 생성, Na+ 중화, 물 박스, 150 mM NaCl 추가
  ↓
RAMP1_ion.prmtop / RAMP1_ion.inpcrd 생성
```

### 실습 폴더

```bash
cd ../
mkdir -p 01_6_ramp1_explicit
cd 01_6_ramp1_explicit
```

### 1) PDB 다운로드

```bash
wget https://files.rcsb.org/download/2YX8.pdb -O 2yx8.pdb
```

VMD가 있으면 구조를 확인합니다.

```bash
vmd 2yx8.pdb
```

VMD에서 확인할 것:

- 단백질 backbone이 끊긴 곳이 있는가?
- 물, ion, buffer, ligand, non-standard residue가 있는가?
- cysteine/disulfide bond가 있는가?
- histidine protonation이 중요한 위치에 있는가?

### 2) MSE를 MET로 수정

2YX8는 MAD 실험 때문에 methionine이 selenomethionine(MSE)으로 들어 있습니다. Amber 표준 단백질 force field로 처리하려면 MET로 바꿉니다.

```bash
cp 2yx8.pdb 2yx8_fxMET.pdb
```

텍스트 에디터로 `2yx8_fxMET.pdb`를 열어 다음을 수정합니다.

| 원래 | 바꿀 값 | 이유 |
|---|---|---|
| `HETATM` | `ATOM  ` | 표준 residue로 peptide chain에 연결되도록 |
| residue name `MSE` | `MET` | 표준 methionine으로 처리 |
| atom name `SE` | `SD` | MET의 sulfur atom 이름 |
| element `SE` | `S` | 원소 표기 수정 |

> PDB는 고정 폭 형식이라 열 위치가 중요합니다. find/replace 후 열이 밀리지 않았는지 확인하세요.

### 3) disulfide cysteine을 CYX로 수정

PDB 상단의 `SSBOND` record를 확인합니다.

```bash
grep '^SSBOND' 2yx8_fxMET.pdb
```

원문 예제에서는 disulfide에 참여하는 cysteine을 `CYS`에서 `CYX`로 바꿉니다.

```bash
cp 2yx8_fxMET.pdb 2yx8_fxMET_fxCYS.pdb
```

텍스트 에디터에서 disulfide에 해당하는 cysteine residue name만 `CYX`로 바꿉니다. 모든 CYS를 무조건 CYX로 바꾸면 안 됩니다.

### 4) protonation state 확인

원문은 H++ 서버를 사용해 pH 7.0 조건의 histidine protonation을 검토합니다. 예제에서 반영할 값은 다음과 같습니다.

| residue | Amber residue name |
|---|---|
| His75 | `HIP` |
| His97 | `HID` |

복사본을 만들고 수정합니다.

```bash
cp 2yx8_fxMET_fxCYS.pdb 2yx8_fxMET_fxCYS_fxHIS.pdb
```

자주 쓰는 Amber protonation residue name은 다음과 같습니다.

| 상태 | Amber residue name |
|---|---|
| protonated/neutral Asp | `ASH` |
| protonated/neutral Glu | `GLH` |
| deprotonated/neutral Lys | `LYN` |
| His epsilon protonated | `HIE` |
| His delta protonated | `HID` |
| His doubly protonated/charged | `HIP` |
| deprotonated Cys 또는 metal-bound Cys | `CYM` |
| disulfide Cys | `CYX` |

### 5) CONECT 제거 후 최종 PDB 저장

```bash
cp 2yx8_fxMET_fxCYS_fxHIS.pdb 2yx8_fxMET_fxCYS_fxHIS_noCONECT.pdb
# CONECT 줄 제거
awk '!/^CONECT/' 2yx8_fxMET_fxCYS_fxHIS_noCONECT.pdb > RAMP1.pdb
```

확인합니다.

```bash
grep '^CONECT' RAMP1.pdb || echo "CONECT removed"
grep -E 'MSE|HETATM' RAMP1.pdb | head
```

### 6) tleap으로 explicit solvent 시스템 만들기

`tleap.in`을 작성합니다.

```bash
cat > tleap.in <<'EOF'
# RAMP1 explicit solvent system
source leaprc.protein.ff19SB
source leaprc.water.opc
# 현재 Amber에서는 leaprc.water.opc가 관련 ion parameter를 함께 다루지만,
# 원문 예제와 맞추기 위해 명시적으로 로드한다.
loadamberparams frcmod.ions1lm_126_hfe_opc

ramp = loadpdb RAMP1.pdb

# disulfide bond 지정. CYX 이름만으로는 어떤 SG끼리 결합하는지 알 수 없다.
bond ramp.27.SG ramp.82.SG
bond ramp.40.SG ramp.72.SG
bond ramp.57.SG ramp.104.SG

# 단백질만 있는 gas-phase topology도 저장해 둔다. 나중에 확인/분석에 유용하다.
saveAmberParm ramp RAMP1_gas.prmtop RAMP1_gas.inpcrd

# 예제 단백질 전하가 -2이므로 Na+ 2개로 중화한다.
addIons ramp Na+ 2

# truncated octahedral OPC water box. 단백질 표면에서 최소 10 Å buffer.
solvateOct ramp OPCBOX 10.0

# 원문 예제의 box volume 기준 150 mM NaCl에 해당하는 Na+/Cl- 19쌍 추가.
addIonsRand ramp Na+ 19 Cl- 19

saveAmberParm ramp RAMP1_ion.prmtop RAMP1_ion.inpcrd
quit
EOF
```

실행합니다.

```bash
tleap -f tleap.in | tee tleap.out
```

### 7) 오류 검사

```bash
grep -i "error\|fatal\|warning" tleap.out leap.log
```

- `Errors = 0`인지 확인합니다.
- 일부 Amber 버전에서 `No sp2 improper torsion term...`류의 warning이 나올 수 있습니다. 원문은 특정 warning은 무시 가능하다고 안내하지만, 처음에는 정확히 어떤 residue/atom에서 나는지 확인하세요.

### 8) 생성된 시스템을 PDB로 변환해 VMD에서 보기

```bash
cat > pdb.in <<'EOF'
trajin RAMP1_ion.inpcrd
trajout RAMP1_wions_water.pdb PDB
run
EOF

cpptraj -p RAMP1_ion.prmtop -i pdb.in > pdb.out
vmd RAMP1_wions_water.pdb
```

확인할 것:

1. 단백질 backbone이 끊기지 않았는가?
2. disulfide bond가 맞는가?
3. His75/HIP, His97/HID가 반영되었는가?
4. 물 박스가 단백질 주변에 충분한가?
5. Na+/Cl-가 들어갔는가?
6. 이상하게 겹친 atom이나 멀리 떨어진 조각이 없는가?

### 9) salt 개수 계산 메모

원문 예제에서 LEaP가 출력한 box volume은 약 `208141.839 Å^3`이고, 150 mM NaCl을 넣기 위해 19쌍의 NaCl을 추가합니다.

계산식은 다음과 같습니다.

```text
이온쌍 수 = 농도(mol/L) × 부피(Å^3) × 1e-27(L/Å^3) × Avogadro 수
          = 0.150 × 208141.839 × 1e-27 × 6.022e23
          ≈ 18.8 → 19쌍
```

---

## 3.1 Relaxation of Explicit Water Systems

원문: https://ambermd.org/tutorials/basic/tutorial13/index.php

### 목표

- 1.6에서 만든 explicit solvent 시스템을 안정화합니다.
- 물/이온 minimization → heating → constant pressure relaxation → restraint 감소 → 무구속 relaxation 순서로 진행합니다.
- `relaxation`은 예전 튜토리얼에서 흔히 말하던 `equilibration`과 비슷하지만, “열역학적으로 완전히 수렴했다”는 의미를 피하기 위해 요즘은 relaxation이라는 표현을 선호합니다.

### 입력 파일 준비

실습 폴더를 만들고 1.6 결과를 복사합니다.

```bash
cd ../
mkdir -p 03_1_explicit_relax
cd 03_1_explicit_relax

cp ../01_6_ramp1_explicit/RAMP1_ion.prmtop .
cp ../01_6_ramp1_explicit/RAMP1_ion.inpcrd .
```

처음 테스트할 때는 아래 각 MD input의 `nstlim`을 5000 또는 10000으로 줄여서 명령이 제대로 도는지만 확인하세요. 문제없이 돌아가면 원문 값으로 되돌립니다.

### 단계 요약

| 단계 | 파일 | 목적 | restraint |
|---|---|---|---|
| 1 | `1min.in` | 물과 이온 minimization | solute residue 1–81, 100 |
| 2 | `2mdheat.in` | 100 K → 298 K, constant V | solute 100 |
| 3 | `3md.in` | 298 K, constant P | solute 100 |
| 4 | `4md.in` | constant P, restraint 낮춤 | solute 10 |
| 5 | `5min.in` | backbone만 고정하고 minimization | `@CA,N,C`, 10 |
| 6 | `6md.in` | constant P, backbone restraint | 10 |
| 7 | `7md.in` | backbone restraint 감소 | 1 |
| 8 | `8md.in` | backbone restraint 더 감소 | 0.1 |
| 9 | `9md.in` | 무구속 relaxation | 없음 |

> `restraintmask=':1-81'`는 RAMP1 예제에서 단백질 residue가 1–81이라는 뜻입니다. 자신의 시스템에서는 residue 번호를 반드시 바꿔야 합니다.

### 1min.in

```bash
cat > 1min.in <<'EOF'
minimization of solvent
 &cntrl
  imin = 1, maxcyc = 1000,
  ncyc = 20, ntx = 1,
  ntwe = 0, ntwr = 500, ntpr = 50,
  ntc = 2, ntf = 2, ntb = 1, ntp = 0,
  cut = 10.0,
  ntr = 1, restraintmask = ':1-81',
  restraint_wt = 100.0,
  ioutfm = 1, ntxo = 2,
 /
EOF
```

### 2mdheat.in

```bash
cat > 2mdheat.in <<'EOF'
heating from 100 K to 298 K at constant volume
 &cntrl
  imin = 0, nstlim = 1000000, dt = 0.001,
  irest = 0, ntx = 1, ig = -1,
  tempi = 100.0, temp0 = 298.0,
  ntc = 2, ntf = 2, tol = 0.00001,
  ntwx = 10000, ntwe = 0, ntwr = 1000, ntpr = 1000,
  cut = 8.0, iwrap = 0,
  ntt = 3, gamma_ln = 1.0, ntb = 1, ntp = 0,
  nscm = 0,
  ntr = 1, restraintmask = ':1-81', restraint_wt = 100.0,
  nmropt = 1,
  ioutfm = 1, ntxo = 2,
 /
 &wt TYPE='TEMP0', istep1=0, istep2=1000000, value1=100.0, value2=298.0, /
 &wt TYPE='END', /
EOF
```

### 3md.in

```bash
cat > 3md.in <<'EOF'
constant pressure relaxation with strong solute restraints
 &cntrl
  imin = 0, nstlim = 1000000, dt = 0.001,
  irest = 1, ntx = 5, ig = -1,
  temp0 = 298.0,
  ntc = 2, ntf = 2, tol = 0.00001,
  ntwx = 10000, ntwe = 0, ntwr = 1000, ntpr = 1000,
  cut = 8.0, iwrap = 0,
  ntt = 3, gamma_ln = 1.0, ntb = 2, ntp = 1, barostat = 2,
  nscm = 0,
  ntr = 1, restraintmask = ':1-81', restraint_wt = 100.0,
  ioutfm = 1, ntxo = 2,
 /
EOF
```

### 4md.in

```bash
cat > 4md.in <<'EOF'
constant pressure relaxation with weaker solute restraints
 &cntrl
  imin = 0, nstlim = 1000000, dt = 0.001,
  irest = 1, ntx = 5, ig = -1,
  temp0 = 298.0,
  ntc = 2, ntf = 2, tol = 0.00001,
  ntwx = 10000, ntwe = 0, ntwr = 1000, ntpr = 1000,
  cut = 8.0, iwrap = 0,
  ntt = 3, gamma_ln = 1.0, ntb = 2, ntp = 1, barostat = 2,
  nscm = 0,
  ntr = 1, restraintmask = ':1-81', restraint_wt = 10.0,
  ioutfm = 1, ntxo = 2,
 /
EOF
```

### 5min.in

```bash
cat > 5min.in <<'EOF'
minimization with backbone restraints
 &cntrl
  imin = 1, maxcyc = 1000,
  ncyc = 30, ntx = 1,
  ntwe = 0, ntwr = 500, ntpr = 50,
  ntc = 2, ntf = 2, ntb = 1, ntp = 0,
  cut = 8.0,
  ntr = 1, restraintmask = '@CA,N,C', restraint_wt = 10.0,
  ioutfm = 1, ntxo = 2,
 /
EOF
```

### 6md.in

```bash
cat > 6md.in <<'EOF'
constant pressure relaxation with backbone restraints
 &cntrl
  imin = 0, nstlim = 1000000, dt = 0.001,
  irest = 0, ntx = 1, ig = -1,
  tempi = 298.0, temp0 = 298.0,
  ntc = 2, ntf = 2, tol = 0.00001,
  ntwx = 10000, ntwe = 0, ntwr = 1000, ntpr = 1000,
  cut = 8.0, iwrap = 0,
  ntt = 3, gamma_ln = 1.0, ntb = 2, ntp = 1, barostat = 2,
  nscm = 0,
  ntr = 1, restraintmask = '@CA,N,C', restraint_wt = 10.0,
  ioutfm = 1, ntxo = 2,
 /
EOF
```

### 7md.in

```bash
cat > 7md.in <<'EOF'
constant pressure relaxation with reduced backbone restraints
 &cntrl
  imin = 0, nstlim = 1000000, dt = 0.001,
  irest = 1, ntx = 5, ig = -1,
  temp0 = 298.0,
  ntc = 2, ntf = 2, tol = 0.00001,
  ntwx = 10000, ntwe = 0, ntwr = 1000, ntpr = 1000,
  cut = 8.0, iwrap = 0,
  ntt = 3, gamma_ln = 1.0, ntb = 2, ntp = 1, barostat = 2,
  nscm = 0,
  ntr = 1, restraintmask = '@CA,N,C', restraint_wt = 1.0,
  ioutfm = 1, ntxo = 2,
 /
EOF
```

### 8md.in

```bash
cat > 8md.in <<'EOF'
constant pressure relaxation with very weak backbone restraints
 &cntrl
  imin = 0, nstlim = 1000000, dt = 0.001,
  irest = 1, ntx = 5, ig = -1,
  temp0 = 298.0,
  ntc = 2, ntf = 2, tol = 0.00001,
  ntwx = 10000, ntwe = 0, ntwr = 1000, ntpr = 1000,
  cut = 8.0, iwrap = 0,
  ntt = 3, gamma_ln = 1.0, ntb = 2, ntp = 1, barostat = 2,
  nscm = 0,
  ntr = 1, restraintmask = '@CA,N,C', restraint_wt = 0.1,
  ioutfm = 1, ntxo = 2,
 /
EOF
```

### 9md.in

```bash
cat > 9md.in <<'EOF'
constant pressure relaxation without restraints
 &cntrl
  imin = 0, nstlim = 1000000, dt = 0.001,
  irest = 1, ntx = 5, ig = -1,
  temp0 = 298.0,
  ntc = 2, ntf = 2, tol = 0.00001,
  ntwx = 10000, ntwe = 0, ntwr = 1000, ntpr = 1000,
  cut = 8.0, iwrap = 0,
  ntt = 3, gamma_ln = 1.0, ntb = 2, ntp = 1, barostat = 2,
  nscm = 1000,
  ioutfm = 1, ntxo = 2,
 /
EOF
```

### 실행 스크립트

GPU가 있다면 `pmemd.cuda`, 없으면 `pmemd` 또는 `sander`로 바꿔 실행합니다.

```bash
cat > run_relax.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

: "${AMBERHOME:?AMBERHOME is not set. Run: source /path/to/amber.sh}"

PMEMD_CPU="$AMBERHOME/bin/pmemd"
PMEMD_GPU="$AMBERHOME/bin/pmemd.cuda"

# GPU가 없으면 다음 줄을 PMEMD_GPU="$AMBERHOME/bin/pmemd"로 바꾸세요.
# export CUDA_VISIBLE_DEVICES=0

$PMEMD_CPU -O -i 1min.in -o 1min.out -p RAMP1_ion.prmtop -c RAMP1_ion.inpcrd -r 1min.rst7 -inf 1min.info -ref RAMP1_ion.inpcrd -x mdcrd.1min
$PMEMD_GPU -O -i 2mdheat.in -o 2mdheat.out -p RAMP1_ion.prmtop -c 1min.rst7 -r 2mdheat.rst7 -inf 2mdheat.info -ref 1min.rst7 -x mdcrd.2mdheat
$PMEMD_GPU -O -i 3md.in -o 3md.out -p RAMP1_ion.prmtop -c 2mdheat.rst7 -r 3md.rst7 -inf 3md.info -ref 2mdheat.rst7 -x mdcrd.3md
$PMEMD_GPU -O -i 4md.in -o 4md.out -p RAMP1_ion.prmtop -c 3md.rst7 -r 4md.rst7 -inf 4md.info -ref 3md.rst7 -x mdcrd.4md
$PMEMD_CPU -O -i 5min.in -o 5min.out -p RAMP1_ion.prmtop -c 4md.rst7 -r 5min.rst7 -inf 5min.info -ref 4md.rst7 -x mdcrd.5min
$PMEMD_GPU -O -i 6md.in -o 6md.out -p RAMP1_ion.prmtop -c 5min.rst7 -r 6md.rst7 -inf 6md.info -ref 5min.rst7 -x mdcrd.6md
$PMEMD_GPU -O -i 7md.in -o 7md.out -p RAMP1_ion.prmtop -c 6md.rst7 -r 7md.rst7 -inf 7md.info -ref 6md.rst7 -x mdcrd.7md
$PMEMD_GPU -O -i 8md.in -o 8md.out -p RAMP1_ion.prmtop -c 7md.rst7 -r 8md.rst7 -inf 8md.info -ref 7md.rst7 -x mdcrd.8md
$PMEMD_GPU -O -i 9md.in -o 9md.out -p RAMP1_ion.prmtop -c 8md.rst7 -r 9md.rst7 -inf 9md.info -ref 8md.rst7 -x mdcrd.9md
EOF
chmod +x run_relax.sh
```

실행합니다.

```bash
./run_relax.sh | tee run_relax.log
```

### relaxation 확인

각 `.out` 끝부분을 확인합니다.

```bash
tail -n 40 1min.out
tail -n 40 9md.out
```

정상 종료 여부를 대략 확인합니다.

```bash
grep -H "TIMINGS\|A V E R A G E S\|ERROR\|NaN\|LINMIN" *.out
```

restart를 PDB로 바꿔 VMD에서 봅니다.

```bash
cat > netcdf_to_pdb.in <<'EOF'
parm RAMP1_ion.prmtop
trajin 6md.rst7
trajout 6md_rst7.pdb PDB
run
EOF
cpptraj -i netcdf_to_pdb.in > cpptraj.out
vmd 6md_rst7.pdb
```

밀도 같은 값을 확인하려면 `cpptraj`에서 mdout data를 읽습니다.

```bash
cat > cpptraj_density.in <<'EOF'
readdata 3md.out 4md.out 6md.out name MyOutput
list datasets
writedata Density.agr MyOutput[Density]
run
EOF
cpptraj -i cpptraj_density.in > cpptraj_density.out
```

---

## 3.2 Relaxation of Implicit Solvent Systems (GB)

원문: https://ambermd.org/tutorials/basic/tutorial15/index.php

### 목표

- explicit water 없이 Generalized Born(GB) implicit solvent로 작은 단백질을 안정화합니다.
- 예제 시스템은 trp-cage mini-protein 변이체 `1L2Y`입니다.
- `igb=8`, `gbsa=3`, `mbondi3` radii를 사용하는 흐름을 익힙니다.

### 실습 폴더

```bash
cd ../
mkdir -p 03_2_implicit_gb_relax
cd 03_2_implicit_gb_relax
```

### 1) PDB 준비

```bash
wget https://files.rcsb.org/download/1L2Y.pdb -O 1l2y.pdb
pdb4amber -i 1l2y.pdb -o 1l2y.amber.pdb
```

### 2) tleap으로 topology/coordinates 만들기

```bash
cat > tleap.in <<'EOF'
source leaprc.protein.ff14SBonlysc
tc5b = loadpdb 1l2y.amber.pdb
set default pbradii mbondi3
saveamberparm tc5b tc5b.1l2y.parm7 tc5b.1l2y.rst7
quit
EOF

tleap -f tleap.in | tee tleap.out
```

### 3) HMR 적용

```bash
cat > hmr.parmed <<'EOF'
hmassrepartition
outparm tc5b.1l2y.hmass.parm7
quit
EOF

parmed tc5b.1l2y.parm7 < hmr.parmed | tee hmr.out
```

결과:

```bash
ls -lh tc5b.1l2y.hmass.parm7 tc5b.1l2y.rst7
```

### 4) minimization input: min.in

```bash
cat > min.in <<'EOF'
energy minimization with GB implicit solvent
 &cntrl
  imin = 1,
  maxcyc = 100,
  ntx = 1,
  ntwr = 100,
  ntpr = 10,
  ioutfm = 0,
  ntxo = 1,
  cut = 1000.0,
  ntb = 0,
  igb = 8,
  gbsa = 3,
  surften = 0.007,
  saltcon = 0.0,
 /
EOF
```

실행:

```bash
pmemd.cuda -O -i min.in \
  -p tc5b.1l2y.hmass.parm7 -c tc5b.1l2y.rst7 \
  -o min.out -x min.crd -inf min.info -r min.rst7
```

GPU가 없으면 `pmemd.cuda` 대신 `pmemd` 또는 `sander`를 사용합니다.

### 5) heating input: heat.in

```bash
cat > heat.in <<'EOF'
heating with backbone restraints, GB implicit solvent
 &cntrl
  ntx = 1,
  ntwx = 5000,
  ntwe = 0,
  ntwr = 500,
  ntpr = 5000,
  ioutfm = 0,
  ntxo = 1,
  imin = 0,
  nstlim = 500000,
  dt = 0.002,
  ntt = 3,
  gamma_ln = 1.0,
  temp0 = 100.0,
  nscm = 1000,
  ig = -1,
  ntc = 2,
  ntf = 2,
  cut = 1000.0,
  igb = 8,
  gbsa = 3,
  surften = 0.007,
  ntb = 0,
  saltcon = 0.0,
  ntr = 1,
  restraintmask = '@CA,N,C,O',
  restraint_wt = 10.0,
  nmropt = 1,
 /
 &wt TYPE='TEMP0', istep1=0, istep2=500000, value1=100.0, value2=300.0, /
 &wt TYPE='END', /
EOF
```

실행:

```bash
pmemd.cuda -O -i heat.in \
  -p tc5b.1l2y.hmass.parm7 -c min.rst7 -ref min.rst7 \
  -o heat.out -x heat.crd -inf heat.info -r heat.rst7
```

확인할 것:

- `heat.out`에서 temperature가 100 K에서 300 K로 서서히 올라가는지 확인합니다.
- 갑자기 NaN, 매우 큰 에너지, SHAKE error가 나오는지 확인합니다.

### 6) relaxation stage 1: eq1.in

```bash
cat > eq1.in <<'EOF'
GB relaxation stage 1, weak backbone restraints
 &cntrl
  ntx = 5,
  ntwx = 5000,
  ntwe = 0,
  ntwr = 500,
  ntpr = 5000,
  ioutfm = 0,
  ntxo = 1,
  imin = 0,
  nstlim = 125000,
  dt = 0.002,
  ntt = 3,
  gamma_ln = 1.0,
  temp0 = 300.0,
  nscm = 1000,
  ig = -1,
  irest = 1,
  ntc = 2,
  ntf = 2,
  cut = 1000.0,
  igb = 8,
  gbsa = 3,
  surften = 0.007,
  ntb = 0,
  saltcon = 0.0,
  ntr = 1,
  restraintmask = '@CA,N,C,O',
  restraint_wt = 1.0,
 /
EOF
```

### 7) relaxation stage 2: eq2.in

```bash
cat > eq2.in <<'EOF'
GB relaxation stage 2, very weak backbone restraints
 &cntrl
  ntx = 5,
  ntwx = 5000,
  ntwe = 0,
  ntwr = 500,
  ntpr = 5000,
  ioutfm = 0,
  ntxo = 1,
  imin = 0,
  nstlim = 125000,
  dt = 0.002,
  ntt = 3,
  gamma_ln = 1.0,
  temp0 = 300.0,
  nscm = 1000,
  ig = -1,
  irest = 1,
  ntc = 2,
  ntf = 2,
  cut = 1000.0,
  igb = 8,
  gbsa = 3,
  surften = 0.007,
  ntb = 0,
  saltcon = 0.0,
  ntr = 1,
  restraintmask = '@CA,N,C,O',
  restraint_wt = 0.1,
 /
EOF
```

실행:

```bash
pmemd.cuda -O -i eq1.in \
  -p tc5b.1l2y.hmass.parm7 -c heat.rst7 -ref heat.rst7 \
  -o eq1.out -x eq1.crd -inf eq1.info -r eq1.rst7

pmemd.cuda -O -i eq2.in \
  -p tc5b.1l2y.hmass.parm7 -c eq1.rst7 -ref eq1.rst7 \
  -o eq2.out -x eq2.crd -inf eq2.info -r eq2.rst7
```

### implicit solvent에서 중요한 설정

| 옵션 | 의미 |
|---|---|
| `ntb=0` | periodic boundary 없음 |
| `igb=8` | GBneck2 implicit solvent model |
| `gbsa=3` | fast pairwise surface area approximation |
| `cut=1000.0` | nonbonded cutoff를 사실상 매우 크게 둠 |
| `set default pbradii mbondi3` | GBneck2에 맞는 radii |

---

## 3.3 Running MD with pmemd: production MD

원문: https://ambermd.org/tutorials/basic/tutorial14/index.php

### 목표

- relaxation이 끝난 시스템으로 production MD를 실행합니다.
- `pmemd.cuda` job script를 작성합니다.
- `nstlim`, `dt`, `ntpr`, `ntwx`, `ntwr`, `ntt`, `ntp`의 의미를 이해합니다.

### 필요한 파일

원문 예제는 RAMP1 explicit solvent system을 사용합니다.

```text
RAMP1.prmtop
RAMP1_equil.rst7
md.mdin
```

이 문서의 3.1을 따라 했다면 비슷한 역할의 파일은 다음입니다.

```text
RAMP1_ion.prmtop
9md.rst7
```

이 파일들을 production 폴더로 복사합니다.

```bash
cd ../
mkdir -p 03_3_production_pmemd
cd 03_3_production_pmemd

cp ../03_1_explicit_relax/RAMP1_ion.prmtop ./RAMP1.prmtop
cp ../03_1_explicit_relax/9md.rst7 ./RAMP1_equil.rst7
```

### md.mdin 작성

원문은 50 ns production run 예제를 제시합니다.

```bash
cat > md.mdin <<'EOF'
Explicit solvent molecular dynamics, constant pressure, 50 ns MD
 &cntrl
  imin = 0, irest = 1, ntx = 5,
  ntpr = 500000, ntwx = 500000, ntwr = 500000, nstlim = 25000000,
  dt = 0.002, ntt = 3, tempi = 300.0,
  temp0 = 300.0, gamma_ln = 1.0, ig = -1,
  ntp = 1, ntc = 2, ntf = 2, cut = 9.0,
  ntb = 2, iwrap = 1, ioutfm = 1,
 /
EOF
```

처음에는 반드시 짧은 테스트를 권합니다.

```bash
cp md.mdin md.test.mdin
perl -0777 -pi -e 's/nstlim\s*=\s*25000000/nstlim = 5000/' md.test.mdin
```

### 주요 옵션 해석

| 옵션               | 의미                                      |
| ---------------- | --------------------------------------- |
| `nstlim`         | MD step 수. `nstlim × dt`가 전체 시간(ps)입니다. |
| `dt=0.002`       | 0.002 ps = 2 fs                         |
| `ntpr`           | mdout에 에너지/온도 등을 출력하는 주기                |
| `ntwx`           | trajectory 좌표를 쓰는 주기                    |
| `ntwr`           | restart 파일을 쓰는 주기                       |
| `ntt=3`          | Langevin thermostat                     |
| `ig=-1`          | 매 실행마다 시간 기반 random seed                |
| `ntb=2`, `ntp=1` | periodic box에서 constant pressure        |
| `ntc=2`, `ntf=2` | H 결합 SHAKE/force 생략 설정                  |
| `ioutfm=1`       | NetCDF trajectory 형식                    |

50 ns 계산 확인:

```text
25,000,000 steps × 0.002 ps/step = 50,000 ps = 50 ns
```

출력 주기 확인:

```text
500,000 steps × 0.002 ps/step = 1,000 ps = 1 ns
```

즉 trajectory frame이 1 ns마다 저장됩니다. 더 촘촘한 분석이 필요하면 `ntwx`를 줄이세요. 단, 파일 크기가 커집니다.

### jobfile 작성

```bash
cat > jobfile_production.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

: "${AMBERHOME:?AMBERHOME is not set. Run: source /path/to/amber.sh}"

export CUDA_VISIBLE_DEVICES=0

$AMBERHOME/bin/pmemd.cuda -O \
  -i md.mdin \
  -p RAMP1.prmtop \
  -c RAMP1_equil.rst7 \
  -ref RAMP1_equil.rst7 \
  -o RAMP1_md.mdout \
  -r RAMP1_md.rst7 \
  -x RAMP1_md.nc \
  -inf mdinfo
EOF
chmod +x jobfile_production.sh
```

GPU 번호는 `nvidia-smi`로 확인합니다.

```bash
nvidia-smi
```

예를 들어 GPU 3이 비어 있으면 스크립트에서 다음처럼 바꿉니다.

```bash
export CUDA_VISIBLE_DEVICES=3
```

### 실행

테스트부터 합니다.

```bash
$AMBERHOME/bin/pmemd.cuda -O \
  -i md.test.mdin \
  -p RAMP1.prmtop \
  -c RAMP1_equil.rst7 \
  -ref RAMP1_equil.rst7 \
  -o test.mdout \
  -r test.rst7 \
  -x test.nc \
  -inf test.mdinfo
```

정상이라면 full production을 실행합니다.

```bash
./jobfile_production.sh > production.log 2>&1 &
```

### 실행 상태 확인

```bash
nvidia-smi
tail -f mdinfo
tail -f production.log
```

프로세스를 확인합니다.

```bash
top
# q를 누르면 종료
```

문제가 있어 job을 죽여야 하면 PID를 확인한 후 다음처럼 합니다.

```bash
kill -9 PID
```

PID가 어느 폴더에서 실행된 것인지 확인하려면:

```bash
pwdx PID
```

---

## 3.4 Running MD in Parallel: multisander / multipmemd

원문: https://ambermd.org/tutorials/basic/tutorial21/index.php

### 목표

- `groupfile`을 사용해 여러 independent simulation을 병렬로 실행합니다.
- `pmemd.MPI` 또는 `pmemd.cuda.MPI`를 사용합니다.
- 고급 샘플링, replica exchange, NEB 등에서 필요한 groupfile 개념을 익힙니다.

### 전제 조건

- Amber가 MPI 지원으로 빌드되어 있어야 합니다.
- GPU 병렬이면 `pmemd.cuda.MPI`가 필요합니다.
- HPC/SLURM 환경에서는 cluster 규칙에 맞는 job script가 필요합니다.

확인:

```bash
which pmemd.MPI || true
which pmemd.cuda.MPI || true
which mpirun || true
```

### 실습 폴더와 파일

```bash
cd ../
mkdir -p 03_4_parallel_groupfile
cd 03_4_parallel_groupfile
```

원문 예제는 하나의 topology와 네 개의 시작 좌표를 사용합니다.

```text
RAMP1.prmtop
RAMP1_equil.01.rst7
RAMP1_equil.02.rst7
RAMP1_equil.03.rst7
RAMP1_equil.04.rst7
```

직접 실습할 때는 3.1 relaxation에서 서로 다른 시점의 restart를 복사해 네 개의 시작점으로 사용할 수 있습니다. 엄밀한 독립 replica가 필요하면 solvent/ion randomization부터 독립적으로 반복하는 것이 더 낫습니다.

```bash
cp ../03_1_explicit_relax/RAMP1_ion.prmtop ./RAMP1.prmtop
cp ../03_1_explicit_relax/6md.rst7 ./RAMP1_equil.01.rst7
cp ../03_1_explicit_relax/7md.rst7 ./RAMP1_equil.02.rst7
cp ../03_1_explicit_relax/8md.rst7 ./RAMP1_equil.03.rst7
cp ../03_1_explicit_relax/9md.rst7 ./RAMP1_equil.04.rst7
```

### md.in 작성

원문 예제는 10 ns production입니다.

```bash
cat > md.in <<'EOF'
Explicit solvent MD, constant pressure, 10 ns MD, print every 10 ps
 &cntrl
  imin = 0, irest = 1, ntx = 5,
  ntpr = 5000, ntwx = 5000, ntwr = 5000, nstlim = 5000000,
  dt = 0.002, ntt = 3, tempi = 300.0,
  temp0 = 300.0, gamma_ln = 1.0, ig = -1,
  ntp = 1, ntc = 2, ntf = 2, cut = 9.0,
  ntb = 2, iwrap = 1, ioutfm = 1,
 /
EOF
```

테스트용으로는 `nstlim=5000` 정도로 줄여 먼저 실행하세요.

### groupfile 작성

`groupfile`에는 executable 이름을 쓰지 않습니다. `pmemd.cuda.MPI` 뒤에 붙일 옵션만 각 줄에 씁니다. 한 줄이 하나의 independent run입니다.

```bash
cat > groupfile <<'EOF'
-O -i md.in -p RAMP1.prmtop -c RAMP1_equil.01.rst7 -ref RAMP1_equil.01.rst7 -x md.nc.01 -r 01.rst7 -o md.out.01 -inf md.info.01 -l logfile.01
-O -i md.in -p RAMP1.prmtop -c RAMP1_equil.02.rst7 -ref RAMP1_equil.02.rst7 -x md.nc.02 -r 02.rst7 -o md.out.02 -inf md.info.02 -l logfile.02
-O -i md.in -p RAMP1.prmtop -c RAMP1_equil.03.rst7 -ref RAMP1_equil.03.rst7 -x md.nc.03 -r 03.rst7 -o md.out.03 -inf md.info.03 -l logfile.03
-O -i md.in -p RAMP1.prmtop -c RAMP1_equil.04.rst7 -ref RAMP1_equil.04.rst7 -x md.nc.04 -r 04.rst7 -o md.out.04 -inf md.info.04 -l logfile.04
EOF
```

### interactive 실행

4개의 group을 4개의 MPI process에서 실행합니다.

```bash
mpirun -np 4 $AMBERHOME/bin/pmemd.cuda.MPI -O -ng 4 -groupfile groupfile
```

의미:

| 옵션 | 의미 |
|---|---|
| `-np 4` | MPI process 4개 |
| `-ng 4` | group 4개 |
| `-groupfile groupfile` | 각 group별 pmemd 옵션 파일 |

CPU MPI로 실행하려면:

```bash
mpirun -np 4 $AMBERHOME/bin/pmemd.MPI -O -ng 4 -groupfile groupfile
```

### SLURM 예시

cluster마다 설정이 다르므로 반드시 기관의 예시 스크립트에 맞게 바꾸세요.

```bash
cat > qsub.sh <<'EOF'
#!/bin/bash
#SBATCH -t 46:00:00
#SBATCH --gres=gpu:4
#SBATCH --cpus-per-gpu=1
#SBATCH --mem=4G
#SBATCH -J ramp1_multipmemd

source /path/to/amber26/amber.sh
SANDER=pmemd.cuda.MPI

cd $SLURM_SUBMIT_DIR
mpirun -np 4 $AMBERHOME/bin/$SANDER -O -ng 4 -groupfile groupfile
EOF
```

제출:

```bash
sbatch qsub.sh
```

상태 확인:

```bash
squeue -u $USER
```

결과 파일:

```text
md.out.01, md.out.02, md.out.03, md.out.04
01.rst7, 02.rst7, 03.rst7, 04.rst7
md.nc.01, md.nc.02, md.nc.03, md.nc.04
md.info.01, md.info.02, md.info.03, md.info.04
```

---

## 4. 자주 막히는 부분과 빠른 점검표

### AMBERHOME 관련 오류

```bash
echo $AMBERHOME
which tleap
```

비어 있으면:

```bash
source /path/to/amber26/amber.sh
```

### tleap에서 residue를 모른다고 할 때

가능한 원인:

- PDB residue name이 Amber 표준 이름과 다름
- ligand/cofactor/non-standard residue parameter가 없음
- histidine, cysteine, protonation state를 적절히 바꾸지 않음
- `source leaprc.*`를 잘못 선택함

확인:

```bash
grep -i "unknown\|fatal\|error\|warning" leap.log tleap.out
```

### `restraintmask`가 틀렸을 때

RAMP1 예제의 `:1-81`은 예제 단백질 residue 번호입니다. 자신의 시스템에서 residue 범위를 확인하려면:

```bash
cpptraj -p your.prmtop <<'EOF'
resinfo
quit
EOF
```

또는 PDB에서 residue 번호를 확인합니다.

### production을 바로 길게 돌리지 말기

모든 단계는 먼저 짧은 test run으로 검증합니다.

- minimization: `maxcyc=50` 또는 100
- MD: `nstlim=5000`
- output이 정상인지 확인한 뒤 full run

### NaN, SHAKE error, 구조 폭발

가능한 원인:

- PDB 구조가 잘못됨, atom overlap
- disulfide bond 누락
- protonation/residue name 오류
- minimization/relaxation이 너무 급함
- timestep이 너무 큼
- HMR topology와 일반 topology를 섞음

대처:

1. VMD로 input PDB와 restart 확인
2. `cpptraj check` 사용
3. minimization step 늘리기
4. heating을 더 천천히 하기
5. time step 줄이기

### LINMIN FAILURE

minimization에서 `LINMIN FAILURE`가 나오면 원문은 `ncyc` 조정을 언급합니다. 실제로는 구조 문제나 restraint mask 오류도 함께 의심해야 합니다.

### `IEEE_UNDERFLOW_FLAG`, `IEEE_DENORMAL`

원문 3.1 튜토리얼은 이런 메시지가 항상 치명적 오류는 아니라고 설명합니다. 그래도 output 마지막에 정상 종료가 있었는지, 에너지가 비정상적으로 발산하지 않았는지 확인하세요.

---

## 5. 다음에 공부할 전체 튜토리얼 지도

아래는 `ambermd.org/tutorials/`의 전체 카테고리를 학습 순서 중심으로 다시 정리한 것입니다. 이 문서에서는 1.1–1.6과 3.1–3.4만 상세 실습으로 정리했습니다.

### 1 Building Systems

- 1.1 Preparing Structure
- 1.2 Fundamentals of LEaP
- 1.3 Building Systems with CHARMM-GUI
- 1.4 Hydrogen Mass Repartitioning
- 1.5 Building a Peptide Sequence
- 1.6 Building Protein Systems in Explicit Water
- 1.7 Simulation of a protein crystal
- 1.8 Un-natural amino acids: Amber ff15ipq-m force field
- 1.9 Building Membrane Systems
- 1.10 Using the Pantetheine Force Field Library
- 1.11 Building and Simulating an Ionic Liquid
- 1.12 Material Systems
- 1.13 Using 3D-RISM and MOFT to place waters and ions

### 2 Developing Nonstandard Parameters

- 2.1 Simulating a pharmaceutical compound with Antechamber and GAFF
- 2.2 Setting up a DNA-Ligand System
- 2.3 Simulating GFP and building a modified amino acid residue
- 2.4 Metal Ion Modeling Tutorial
- 2.5 Electrostatic Parameterization with Pyresp.py
- 2.6 Deriving Implicitly Polarized Charges with mdgx
- 2.7 Deriving Custom Force Field Parameters with mdgx
- 2.8 Adding Custom Extra Points to a Model

### 3 Creating Stable Systems and Running MD

- 3.1 Relaxation of Explicit Water Systems
- 3.2 Relaxation of Implicit Solvent System (GB)
- 3.3 Running MD with pmemd
- 3.4 Running MD in Parallel

### 4 Trajectory Analysis

- 4.1 Introduction to CPPTRAJ
- 4.2 RMSD Analysis in CPPTRAJ
- 4.3 Principal Component Analysis with CPPTRAJ
- 4.4 Combined Clustering Analysis with CPPTRAJ
- 4.5 AMBER-Hub CPPTRAJ website
- 4.6 Analysis of MAD2 using PCA, tICA, and Markov State Models
- 4.7 Temperature Replica Exchange MD analysis

### 5 Case Studies

- 5.1 Alanine dipeptide simulation
- 5.2 GFP modified residue case
- 5.3 mdgx small molecule manipulation
- 5.4 Ion distributions around DNA using 3D-RISM

### 6 Sampling Configuration Space

- Adaptive Steered MD
- Unified middle thermostat scheme
- Weighted Ensemble using WESTPA
- Temperature Replica Exchange MD

### 7 Free Energies

- Thermodynamic Integration
- ACES
- pKa calculations
- MM-PBSA
- Umbrella sampling
- EMIL
- binding enthalpy
- FEW
- GIST
- APR
- Nonequilibrium Free Energy toolkit

### 8 Chemical Reactions and Equilibria

- Constant pH MD
- Constant pH + Redox Potential MD
- Quantum dynamical effects in liquid water

### 추천 다음 순서

이 문서의 범위를 끝낸 뒤에는 아래 순서를 권합니다.

```text
4.1 cpptraj 기초
  ↓
4.2 RMSD 분석
  ↓
2.1 ligand/GAFF가 필요한 경우
  ↓
7.4 MM-PBSA 또는 7.5 umbrella sampling 등 목적별 free energy 튜토리얼
```

---

## 6. 최종 체크리스트

production MD로 넘어가기 전 아래를 모두 확인하세요.

- [ ] `tleap`에서 `Errors = 0`
- [ ] 전체 전하와 counterion 개수가 의도와 맞음
- [ ] 물 모델과 ion parameter가 호환됨
- [ ] disulfide bond가 정확함
- [ ] histidine/protonation state가 연구 조건과 맞음
- [ ] minimization output이 정상 종료됨
- [ ] heating에서 온도가 서서히 올라감
- [ ] constant pressure relaxation에서 density/volume이 안정적으로 변함
- [ ] VMD에서 구조가 폭발하지 않음
- [ ] 짧은 production test run이 정상 종료됨
- [ ] production trajectory 저장 주기가 분석 목적에 충분함

