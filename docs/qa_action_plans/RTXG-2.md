# RTXG-2 액션 플랜

- Jira: https://dolomood.atlassian.net/browse/RTXG-2
- 주제: 스낵바 스와이프 dismiss

## QA 결과 요약
- 실패(⚠️)
  - 홈-리포트 구간에서 수직 스와이프 dismiss 미적용
  - 특정 방향 제한 없는지 확인 실패
  - dismiss 후 동일 타입 재노출 검증 불충분(타로 재현 환경 제한)

## 원인 가설
- 공통 스낵바 컴포넌트는 dismiss 처리됐지만, 일부 화면에서 다른 토스트/스낵바 경로를 사용 중일 가능성
- QA 환경에서 타로 재시도 버튼 조건 미충족으로 재현 시나리오가 막힘

## 관련 파일
- `lib/core/ui/dialog/toast/fm_snackbar.dart`
- `lib/feature/tarot/ui/page/home/tarot_home_page.dart`
- `lib/feature/tarot/ui/page/start/tarot_reading_loading_page.dart`
- `lib/feature/home/ui/widget/first_dolo_listener.dart`

## 수정 계획
1. 적용 범위 점검
- 홈/리포트/타로에서 실제 호출 컴포넌트가 `fmSnackbar`인지 전수 확인합니다.

2. dismiss 방향 정책 고정
- 수직 드래그 상/하 모두 dismiss 되는지 테스트 코드 또는 수동 시나리오를 표준화합니다.

3. 재노출 동작 보장
- dismiss 직후 동일 타입 재노출 시 타이머/큐 상태가 초기화되는지 확인하고 필요 시 상태 리셋 로직 보강합니다.

4. QA 재현 조건 문서화
- 타로 재시도 버튼 노출 조건(예: 사용 기회, 오류 상태)을 사전 충족하도록 재현 절차를 명시합니다.

## 검증 시나리오
- 홈-리포트에서 상/하 스와이프 dismiss 확인
- dismiss 직후 동일 스낵바 재노출 확인
- 타로 오류 스낵바 경로에서도 동일 동작 확인

## 완료 기준
- RTXG-2 체크리스트 3개 항목 모두 ✅
- 홈/리포트/타로 3개 경로에서 동작 일치
