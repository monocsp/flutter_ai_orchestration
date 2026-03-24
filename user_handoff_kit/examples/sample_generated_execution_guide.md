# 예시 실행 가이드

## 1. 준비
- 기준 문서: `examples/sample_request.md`
- 사용 AI: `Codex CLI`
- 실행 목적: `비판 검토 포함 실행 계획`
- 비판 검토 강도: `높음`
- 리스크 포커스: `공통 토스트 컴포넌트, 상태 중복 처리, API 재호출`
- 결과 형식: `상세 실행 계획`

## 2. 실행 순서
1. 대상 프로젝트 루트에서 AI CLI를 엽니다.
2. `01_analysis_prompt.md`와 기준 문서를 함께 넣어 초기 분석을 받습니다.
3. 결과를 `11_analysis_result.md`에 저장합니다.
4. `02_critical_review_prompt.md`, 기준 문서, `11_analysis_result.md`를 함께 넣어 비판 검토를 받습니다.
5. 결과를 `12_critical_review_result.md`에 저장합니다.
6. `03_final_plan_prompt.md`, 기준 문서, 앞선 두 결과를 함께 넣어 최종 계획을 받습니다.
7. 결과를 `13_final_plan_result.md`에 저장합니다.

## 3. 대화 시 유의사항
- 파일 경로와 호출 체인이 없으면 다시 검증하게 합니다.
- 사실과 가정이 섞이면 분리해서 다시 작성하게 합니다.
- 공통 컴포넌트 회귀 위험과 검증 계획이 빠지면 보완하게 합니다.
