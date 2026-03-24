# 작업 제목

- 홈 돌탑 `createdAt` / thread `registeredAt` 이중 정렬 + 화면별 pagination 분리 설계

## 작업 유형

- 정책 변경
- 구조 개선

## 작업 배경

- 홈 돌탑은 `createdAt` 기준 정렬이 맞고, thread는 `registeredAt` 기준 정렬이 맞다.
- 두 화면은 같은 `/dol` 계열 데이터를 사용하지만, 무한스크롤과 cursor pagination 이 걸려 있어서 단순 클라이언트 재정렬만으로는 일관성을 보장하기 어렵다.
- 서버는 `sort_field=registered_at`, `sort_field=created_at` 둘 다 지원한다.
- 따라서 이번 오케스트레이션 목표는 "공용 데이터는 하나로 유지하면서, 화면별 정렬과 pagination 을 어떻게 분리할지"를 코드 구조 기준으로 다시 정리하는 것이다.

## 목표

- `tower`와 `thread`가 서로 다른 정렬 기준을 가져도 안전하게 공존하는 구조를 정의한다.
- 공통 entity store 1개와 화면별 pagination/index state 2개로 분리하는 방향이 현재 코드베이스에 맞는지 검증한다.
- 중복 응답, 덮어쓰기, 메모리 사용, 캐시 동기화, 무한스크롤 cursor 충돌을 어떻게 처리할지 실행 가능한 계획으로 정리한다.

## 사용자 시나리오

1. 홈 돌탑에서는 최근 생성된 돌이 `createdAt desc` 기준으로 쌓여야 한다.
2. thread timeline/calendar 에서는 사용자가 기록한 날짜인 `registeredAt desc` 기준이 유지되어야 한다.
3. 사용자가 홈에서 여러 페이지를 스크롤한 뒤 thread 로 가도, thread 는 자기 정렬 기준으로 첫 페이지부터 자연스럽게 보여야 한다.
4. 같은 돌이 두 화면의 응답에 중복으로 포함되더라도, 앱 내부 저장 구조가 꼬이지 않아야 한다.

## 상세 요구사항

### 필수 동작

- `tower`는 `createdAt` 기준 pagination 을 사용한다.
- `thread`는 `registeredAt` 기준 pagination 을 사용한다.
- 서버 정렬 필드가 다르므로, 두 화면은 cursor 와 next page state 를 별도로 가져야 한다.
- 하지만 동일한 `DolEntity` 본문은 화면별로 두 벌 저장하지 않고 공통 entity store 한 곳에서 관리하는 방향을 우선 검토한다.
- 화면별로는 최소한 아래 상태를 분리 관리하는 방향을 검토한다.
  - `orderedIds`
  - `nextCursor`
  - `hasMore`
  - 필요 시 `isLoading`, `lastFetchedAt`
- 같은 `dol.id`가 서로 다른 화면 응답에서 반복으로 오면, entity store 에서는 `id` 기준 upsert/overwrite 로 정리하는 방향을 검토한다.
- 화면별 `orderedIds` 내부에서는 dedupe 가 필요하다.
- `towerOrderedIds` 와 `threadOrderedIds` 사이의 중복은 허용된다.

### 중점 검토 포인트

- 현재 `DolListUsecase` 와 shared cache 구조가 "리스트 전체 캐시"인지, "entity + index 분리"로 바꾸기 쉬운지
- `TowerCubit`, `ThreadTimelineCubit`, `ThreadCalendarCubit` 가 각각 어떤 캐시/정렬 전제를 갖는지
- 공통 cache save 시 thread 와 tower 가 서로의 정렬에 오염되는 지점이 어디인지
- add/update/delete 시 entity store 와 화면별 orderedIds 를 어떻게 동기화해야 하는지
- 메모리 측면에서 `entity 두 벌 저장`보다 `entity 1벌 + orderedIds 2개`가 더 합리적인지

## 메모리 / 성능 관점 가정

- 화면별로 `DolEntity` 전체를 중복 저장하는 방식은 비추천한다.
- 우선 검토 방향은 `entityById` 공통 저장 + 화면별 `orderedIds/cursor` 분리다.
- 중복 응답은 발생할 수 있지만, 본문 엔티티를 `id` 기준으로 1벌만 유지하면 메모리 중복을 줄일 수 있다.
- 이번 오케스트레이션에서는 이 구조가 현재 코드와 얼마나 잘 맞는지, 구현 난도가 어느 정도인지도 평가해달라.

## 관련 화면 또는 기능

- 홈 돌탑 화면
- thread timeline
- thread calendar
- `/dol` 계열 무한스크롤
- cache / pagination / cursor 관리

## 예상 영향 범위

- `lib/feature/home/cubit/tower/tower_cubit.dart`
- `lib/feature/home/ui/widget/tower/tower_widget.dart`
- `lib/feature/home/ui/widget/tower/tower_dol_scroll_widget.dart`
- `lib/feature/thread/cubit/timeline/thread_timeline_cubit.dart`
- `lib/feature/thread/cubit/calendar/thread_calendar_cubit.dart`
- `lib/feature/dol_list/usecase/dol_list_usecase.dart`
- `lib/feature/dol_list/cache/dol_list_cache_share.dart`
- `lib/feature/dol_list/model/param/dol_list_param.dart`
- `lib/feature/dol_list/provider/dol_list_remote_provider.dart`

## 완료 조건

- 최종 결과 문서가 아래를 명확히 분리해서 제시한다.
  - 공통 entity store
  - tower pagination state
  - thread pagination state
- 중복 응답 처리 방식이 문서로 정리된다.
- add/update/delete 시 정렬 인덱스와 entity 동기화 전략이 정리된다.
- 1차 구현 범위와 2차 구조 개선 범위가 구분된다.

## 확인 필요

- 현재 shared cache 가 실제로 어느 범위에서 single source of truth 로 쓰이는지
- thread calendar 가 `registeredAt` grouping 전제를 얼마나 강하게 갖는지
- home tower 가 truly infinite scroll 이어야 하는지, 또는 일부 제한된 범위로도 충분한지
- `createdAt` 기준 pagination 을 홈에서만 도입할 때 analytics / first-date 계산까지 같이 바꿔야 하는지

## 참고 자료

- `docs/tower_created_at_migration_plan.md`
- `ai/result/final/final_codex_result.md`

## 오케스트레이션 실행 메모

- `createdAt` / `registeredAt` 둘 다 서버 지원된다는 점을 전제로 분석할 것
- "공용 `/dol` 정렬 하나로 통일" 방향보다 "공통 entity store + 화면별 pagination/index state 분리" 방향을 우선 검토할 것
- 중복 응답은 정상 상황으로 보고, 이를 어떤 저장 구조로 소화할지에 집중할 것
- 실제 코드 기준으로 가장 작은 1차 구현안과, 더 큰 구조 개선안을 구분해서 제시할 것
