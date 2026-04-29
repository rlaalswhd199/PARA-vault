# 1_Projects

목표와 데드라인이 있는 **현재 진행 중인 연구**들의 폴더.

## 현재 활성 프로젝트

| 프로젝트 | 상태 | 데드라인 | 비고 |
|---------|------|---------|------|
| [[Project_A/README]] | (작성) | (YYYY-MM-DD) | (한 줄 요약) |
| [[Project_B/README]] | (작성) | (YYYY-MM-DD) | (한 줄 요약) |
| [[Project_C/README]] | (작성) | (YYYY-MM-DD) | (한 줄 요약) |
| [[Project_D/README]] | (작성) | (YYYY-MM-DD) | (한 줄 요약) |

## 새 프로젝트 시작 시

1. `_Templates/Project_Template/` 폴더를 복사하여 `Project_새이름/` 으로 변경
2. `README.md`의 메타데이터 채우기
3. 본 인덱스 표에 추가
4. 프로젝트가 끝나면 `4_Archive/`로 이동

## 프로젝트 폴더 구조 (vault 측)

```
1_Projects/Project_X/
├── README.md              # 목표·단계·KPI·로그
└── Reading_Notes/         # 이 프로젝트와 직접 관련된 논문 노트
```

논문 원고는 `Paper_Writing/Project_X/` (vault 루트), 코드·실험은 별도 코드 repo (`~/code/proj-x/`)에서 관리합니다. 자세한 흐름은 [[Git_Workflow]] 참조.
