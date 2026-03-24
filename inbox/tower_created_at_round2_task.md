# 작업 제목

- 홈 돌탑 시간 기준 `registeredAt` -> `createdAt` 전환 2차 검증

## 작업 유형

- 정책 변경
- 최종 실행 계획 검증

## 작업 배경

- 1차 오케스트레이션으로 홈 돌탑 `createdAt` 전환 계획을 검증했다.
- 2차 오케스트레이션에서는 1차 최종 결과를 다시 비판적으로 검토해서, 구현 직전 기준의 더 좁고 정확한 실행 계획으로 다듬으려 한다.
- 이 저장소의 오케스트레이터는 매 실행 시 `ai/result`를 덮어쓰므로, 1차 최종 결과는 별도 보관 파일을 참고 자료로 사용해야 한다.

## 목표

- 1차 오케스트레이션 최종 결과의 약한 가정, 과한 수정안, 누락 파일을 다시 검증한다.
- 실제 구현 직전 사용할 최종 작업 순서를 더 좁게 정리한다.
- 직접 수정 파일, 검증 전용 파일, 정책 확인 필요 항목을 분리한다.

## 필수 입력 자료

- `docs/tower_created_at_migration_plan.md`
- `ai/docs/tower_created_at_round1_final.md`

## 상세 요구사항

### 필수 동작

- 1차 최종 결과와 원본 migration 문서를 함께 읽고 충돌하거나 과도한 부분을 검토한다.
- 실제 구현에 꼭 필요한 파일과 참고 수준 파일을 다시 분리한다.
- 아래 파일들의 수정 필요성을 다시 검증한다.
  - `lib/feature/home/ui/page/tower_page.dart`
  - `lib/feature/home/ui/widget/tower/tower_widget.dart`
  - `lib/feature/home/ui/widget/tower/tower_dol_scroll_widget.dart`
  - `lib/feature/home/cubit/tower/tower_cubit.dart`
  - `lib/feature/dol_list/usecase/dol_list_usecase.dart`
  - `lib/feature/home/ui/widget/tower/tower_scroll_fade_date_time_widget.dart`
  - `lib/feature/home/ui/page/home_page.dart`
- `TowerDolScrollWidget`이 코드 수정 없이 QA 검증만으로 충분한지 다시 판단한다.
- 구현 순서를 "즉시 수정", "검증 중심", "보류/기획 확인 필요"로 나눠 최종 정리한다.

### 검증 포인트

- `createdAt` 기준 정렬이 실제 홈 돌탑 UX와 일치하는지
- 날짜 라벨, 오늘 기록 판정, 연도 판정이 모두 같은 기준을 써야 하는지
- `HomePage` 파생값까지 이번 작업 범위에 포함하는 게 맞는지
- `tower_page.dart`는 실제 수정 대상인지, 단순 전달자 수준인지

## 관련 화면 또는 기능

- 홈 돌탑 화면
- 홈 상단 날짜/웰컴 메시지
- 스크롤 날짜 오버레이
- 홈 돌탑 포커싱

## 완료 조건

- 최종 결과 문서가 구현 직전 바로 사용할 수 있는 수준의 작업 순서를 제공한다.
- 직접 수정 파일과 검증 전용 파일이 명확히 분리된다.
- 기획 확인이 필요한 정책 포인트가 별도 섹션으로 분리된다.

## 확인 필요

- `ai/docs/tower_created_at_round1_final.md`가 1차 실행 후 최신 결과로 보관되었는지
- `createdAt` 기준 전환이 홈 외 다른 화면에도 영향을 주는지

## 참고 자료

- `docs/tower_created_at_migration_plan.md`
- `ai/docs/tower_created_at_round1_final.md`

## 오케스트레이션 실행 메모

- 1차 결과를 맹신하지 말고 실제 코드와 다시 대조할 것
- 구현 직전 기준의 최소 수정 범위와 회귀 위험을 더 중요하게 볼 것
