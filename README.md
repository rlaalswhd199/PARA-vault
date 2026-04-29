# 연구 Vault — PARA

> Obsidian + Claude Cowork/Code 기반 연구 노트 시스템.
> [PARA 방법론](https://fortelabs.com/blog/para/)에 따라 정리되어 있습니다.

## 폴더 안내

### 1_Projects/ — 목표와 데드라인이 있는 활성 연구
- 학회 제출, 저널 투고, 박사 논문 챕터 등
- 각 프로젝트는 `README.md`에 목표·기한·현재 단계 명시
- 완료/중단되면 `4_Archive/`로 이동

### 2_Areas/ — 책임지고 꾸준히 관리하는 영역
- `Daily_Plans/`: 일일 연구 계획 및 회고
- `Meeting_Minutes/`: 교수님·랩 미팅 기록
- `Health/`: 건강·생활 루틴
- `Admin_행정/`: 학교 행정, 장학·인턴 신청 등

### 3_Resources/ — 주제별 참고 자료 (재사용 가능)
- `Papers/`: 논문 Reading Notes + Papers Index
- `Seminars/`: 외부 세미나·발표 청취 기록
- `References/`: 책·블로그·튜토리얼 노트
- `Tools_MCP/`: Claude Skills, MCP 설정 메모

### 4_Archive/ — 완료/중단된 항목 보관

### _Templates/ — 새 노트 템플릿
- 새 프로젝트 시작 시 `Project_Template/` 복사하여 사용

## Claude와 함께 쓰기

이 Vault 루트에는 [`CLAUDE.md`](CLAUDE.md)가 있어 매 세션마다 자동으로 컨텍스트가 로드됩니다. 새로운 프로젝트나 워크플로우가 생기면 CLAUDE.md를 갱신하세요.

## 코드와 분리

이 vault는 **노트와 논문 원고만** 담습니다. 각 프로젝트의 실제 코드·실험은 별도 git repo (`~/code/proj-x/`)에서 관리합니다. 공용 서버, 로컬 데스크탑, 노트북 사이의 동기화 규칙은 [`3_Resources/Tools_MCP/Git_Workflow.md`](3_Resources/Tools_MCP/Git_Workflow.md) 참고.

## 명명 규칙 (제안)

- 노트: `YYYY-MM-DD_제목.md` (Daily Plan), `Paper_저자YY_제목.md` (논문)
- 폴더: `Project_X/`, `snake_case` 또는 `PascalCase` 일관 유지
- Wiki-link: `[[Papers Index]]`, `[[Project_A/README]]`
