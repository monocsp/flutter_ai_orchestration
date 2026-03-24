# 작업 제목

- 앱 잠금 + 생체인증 + Isar 정합성 기능 추가

## 작업 유형

- 기능 추가

## 작업 배경

- 현재 저장소에는 앱 잠금 기능이 일부 이미 구현되어 있다.
- 잠금 메타데이터는 `LockLocalProvider`를 통해 Hive/Isar로 저장되고, PIN 관련 암호화 키/IV는 `FlutterSecureStorage`를 사용한다.
- 하지만 앱 내부에서 생체인증 사용 여부, 자동 생체인증 잠금 해제 UX, 생체정보 변경 감지 정책은 아직 정리되지 않았거나 구현이 부족하다.
- 이번 작업은 기존 잠금 구조를 버리지 않고, 현재 저장소 패턴에 맞춰 생체인증 기능을 확장하는 것이다.

## 목표

- 앱 잠금 기능에 생체인증 설정과 잠금 해제 플로우를 추가한다.
- Isar/Hive/secure storage 저장 책임을 명확히 유지한다.
- 앱 resume 시 잠금 화면에서 자동 생체인증 1회 시도 후 PIN 폴백이 가능하도록 설계하고 구현한다.
- 생체정보 변경 감지, 실패/취소/락아웃/미지원 상태를 구분하는 정책을 정리하고 반영한다.

## 사용자 시나리오

1. 사용자가 설정 화면에서 `앱 잠금` 기능을 켠다.
2. 사용자는 암호 등록 화면에서 PIN을 입력하고, 가능한 경우 생체인증 사용 옵션을 기본 체크 상태로 본다.
3. 암호 등록이 완료되면 즉시 생체인증을 시도하고, 성공 시 앱 잠금과 생체인증이 함께 활성화된다.
4. 이후 앱이 background -> resume 되면 잠금 화면이 뜨고, 생체인증이 활성화된 경우 자동으로 1회 인증을 시도한다.
5. 생체인증이 실패하거나 취소되면 사용자는 PIN으로 잠금을 해제할 수 있고, 필요 시 생체 버튼을 눌러 수동 재시도할 수 있다.
6. 사용자가 기기 생체정보를 변경하면 앱은 이를 감지하고, 재등록 또는 비활성화 정책에 따라 복구 플로우를 제공한다.

## 상세 요구사항

### 필수 동작

- iOS/Android에서 현재 사용 가능한 대표 생체인증 타입을 식별해야 한다.
- 암호 신규 등록 화면에서 생체인증 사용 옵션을 기본 체크 상태로 노출해야 한다.
- 생체인증 사용이 불가한 경우 비활성 상태와 안내 정책이 필요하다.
- 암호 등록 완료 후 생체인증 체크가 켜져 있으면 즉시 생체인증을 시도해야 한다.
- 생체인증 성공 시 앱 잠금과 생체인증이 모두 활성화되어야 한다.
- 생체인증 실패/불가 시 최종 상태는 잠금 미설정으로 되돌아가야 한다.
- 설정 화면에는 앱 잠금 on/off, 생체인증 on/off, 암호 변경 진입, 안내 문구가 있어야 한다.
- 잠금 화면은 생체인증 활성 상태면 자동 1회 인증 시도를 해야 한다.
- 자동 생체인증 실패/취소/불가 시 PIN 입력 폴백이 가능해야 한다.
- 잠금 화면에서 수동 생체인증 재시도가 가능해야 한다.
- 기기 생체정보 변경을 감지하고, 재등록 또는 비활성화 정책을 적용해야 한다.

### 예외 동작

- 사용자 취소
- 시스템 취소
- 단순 인증 실패
- 연속 실패에 따른 락아웃
- 생체 미지원
- 생체 미등록
- OS 정책상 사용 불가

### 문구 / 정책 / UX 요구

- 대표 생체 라벨은 플랫폼별로 자연스럽게 보여야 한다.
- 예시:
  - `Face ID 사용하기`
  - `지문 인식 사용하기`
  - `생체인증 사용하기`
- 설정 화면 하단에는 `암호를 잊으면 앱을 재설치해야 돼요` 문구가 필요하다.
- 자동 생체인증은 잠금 화면 노출 직후 1회만 시도해야 한다.
- 생체인증 실패와 취소는 같은 정책으로 뭉개지지 않아야 한다.

## 관련 화면 또는 기능

- 설정 화면의 앱 잠금 토글
- 암호 등록 / 암호 변경 화면
- 앱 잠금 해제 화면
- 앱 lifecycle pause / resume 처리

## 예상 영향 범위

- 상태 관리: `DoloLockCubit`, `DoloLockState`
- 로컬 저장소: `LockLocalProvider`, Hive/Isar lock 저장 구조
- 보안 저장소: `FlutterSecureStorage`
- UI: `AppLockScreenPage`, `MoodPasswordPage`, settings 화면
- 라우팅: 필요 시 앱 잠금 전용 설정 페이지 추가
- 라이프사이클: `DoloAppLockWidget`
- 문구 / 토스트 / 다이얼로그 정책
- build_runner 필요 여부는 실제 모델 구조 변경 방식에 따라 판단

## 완료 조건

- 생체인증 기능이 기존 잠금 구조를 깨지 않고 연결된다.
- 저장 책임이 lock metadata / secure storage 로 분리된다.
- 자동 생체인증 1회 시도와 PIN 폴백 흐름이 구현된다.
- 실패 / 취소 / 락아웃 / 변경 감지 정책이 코드와 QA 기준에 반영된다.
- `flutter analyze`를 통과한다.
- 필요 시 build_runner, Android build, iOS build 여부와 결과가 기록된다.
- 코드상 확인 항목과 UI 직접 확인 항목이 분리되어 최종 보고에 남는다.

## 확인 필요

- `local_auth`만으로 생체정보 변경 감지가 충분한지
- iOS Keychain / Android Keystore invalidation 전략이 별도 구현 없이 가능한지
- 설정 화면 확장으로 충분한지, 전용 앱 잠금 설정 페이지를 추가할지
- 생체 실패 횟수 정책을 앱이 직접 셀지, OS 결과만 해석할지

## 참고 자료

### 기획 / 분석 문서

- `docs/기획서/codex_cli_app_lock_biometric_isar_prompt.md`
- `docs/feature-addition/2026-03-10_app-lock-biometric-isar/01_requirement_analysis.md`
- `docs/feature-addition/2026-03-10_app-lock-biometric-isar/02_impact_analysis.md`
- `docs/feature-addition/2026-03-10_app-lock-biometric-isar/03_feature_plan.md`
- `docs/feature-addition/2026-03-10_app-lock-biometric-isar/04_qa_testcases.md`
- `docs/feature-addition/2026-03-10_app-lock-biometric-isar/05_detailed_implementation_plan.md`

### 우선 확인할 코드 파일

- `lib/core/cubit/lock/app_lock_cubit.dart`
- `lib/core/cubit/lock/app_lock_state.dart`
- `lib/core/app/app_lock_widget.dart`
- `lib/core/ui/page/app_lock_screen.dart`
- `lib/feature/my_dolo/ui/page/mood_password_page.dart`
- `lib/feature/settings/ui/page/settings_page.dart`
- `lib/feature/settings/provider/local/lock_local_provider.dart`
- `lib/feature/settings/provider/local/lock_local_provider_hive.dart`
- `lib/feature/settings/provider/local/lock_local_provider_isar.dart`
- `lib/core/hive/lock/app_lock_model.dart`
- `lib/core/local/migration/local_data_migration_service.dart`
- `lib/core/navigation/route.dart`
- `lib/core/navigation/router.dart`

## 오케스트레이션 실행 메모

- 입력 문서만으로 단정하지 말고, 반드시 실제 코드와 대조해서 분석할 것
- 기존 잠금 구조를 무시하고 새 저장소 체계를 임의로 만들지 말 것
- `feature-addition-workflow` 절차를 참고해 요구사항, 영향 범위, 계획, QA, 구현 순서를 유지할 것
- 최종 결과는 실행 가능한 작업 순서와 검증 기준이 포함된 계획서여야 한다

## 실행 명령

```bash
ai/scripts/orchestrate_ai.sh --task-file ai/inbox/app_lock_biometric_isar_task.md
```

## dry-run 명령

```bash
ai/scripts/orchestrate_ai.sh --task-file ai/inbox/app_lock_biometric_isar_task.md --dry-run
```
