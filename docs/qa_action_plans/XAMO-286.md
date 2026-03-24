# XAMO-286 액션 플랜

- Jira: https://dolomood.atlassian.net/browse/XAMO-286
- 주제: 감정 피드백 표정 크기/비율 불일치

## QA 결과 요약
- 현재 체크리스트 기준 전 항목 ✅
- 다만 회귀 방지를 위해 비율 계산 기준을 문서화하고 비교 기준을 고정합니다.

## 원인/리스크 관점
- 돌 형태별(가로/정사각/세로) 컨테이너 높이와 표정 렌더링 스케일이 다른 경로에서 계산되면 재발 가능
- 피드백 화면과 저장/공유 카드 간 소스 데이터가 다를 경우 체감 비율 차이 발생 가능

## 관련 파일
- `lib/feature/home/ui/widget/mood_dol.dart`
- `lib/feature/home/ui/widget/dol/foundation_dol_widget.dart`
- `lib/feature/home/ui/widget/dol/mood_dol_face.dart`

## 유지/보강 계획
1. 비율 계산 기준 단일화
- 표정 크기 계산(`faceHeight/faceWidth * moodScale`)과 형태별 높이 보정 규칙의 기준값을 문서화합니다.

2. 화면 간 비교 포인트 고정
- 피드백/저장/공유 화면에서 동일 감정 강도·동일 스타일 기준 스냅샷 비교 절차를 정의합니다.

3. 회귀 테스트 케이스 추가
- 가로/정사각/세로 각각에서 찌그러짐 여부와 역전 현상을 체크하는 QA 케이스를 회귀 목록에 포함합니다.

## 완료 기준
- XAMO-286 현 상태(✅) 유지
- 다음 릴리즈에서도 동일 체크리스트 재검증 시 회귀 없음
