# 작업 제목

- BGM 오디오 포커스 정책 변경 및 breath 영상 재생 시 오디오 제어 정리

## 작업 유형

- 정책 변경
- 기능 개선

## 작업 배경

- 현재 앱에는 홈, 타로, 호흡 관련 화면에서 BGM 또는 영상 오디오가 재생되는 구간이 있다.
- 그러나 화면/기능별로 디바이스 외부 음악과 앱 내부 오디오의 공존 정책이 명확하게 분리되어 있지 않다.
- 이번 요구사항 변경의 핵심은 `홈/타로` 와 `breath` 계열의 오디오 포커스 정책을 다르게 가져가는 것이다.
- 특히 breath 시작 시에는 영상 재생과 함께 디바이스 음악 및 앱 BGM을 모두 정리해야 하고, 종료 후에는 앱 BGM 복구 정책도 다시 맞춰야 한다.

## 목표

- 홈과 타로 BGM은 디바이스 외부 음악과 동시에 재생되도록 정책을 변경한다.
- breath 영상 시작 시 디바이스 음악을 중지시키고, 앱 BGM도 함께 중지시키는 흐름을 정의한다.
- breath 종료 또는 중도 종료 후에는 앱 BGM을 다시 시작하고, 가능한 경우 디바이스 음악도 OS 정책 범위 내에서 복구되도록 검토한다.
- iOS / Android 모두 동일한 사용자 체감 동작을 목표로 구현 방향과 한계를 정리한다.
- 기존 BGM on/off 및 볼륨 설정 로직은 유지한다.

## 사용자 시나리오

1. 사용자가 홈 화면에서 앱 BGM을 켠 상태로 디바이스 음악을 재생 중이어도, 홈 BGM은 디바이스 음악을 멈추지 않고 함께 재생된다.
2. 사용자가 타로 화면으로 이동해도 동일하게 디바이스 음악은 유지되고, 타로 BGM도 함께 재생된다.
3. 사용자가 breath 세션을 시작하면 영상 재생과 함께 앱 BGM은 멈추고, 디바이스 음악도 중지된다.
4. 사용자가 breath 세션을 정상 종료하거나 중간에 종료해 mov 영상 재생이 끝나면, 앱 BGM은 다시 시작된다.
5. 디바이스 음악 재개는 OS 정책상 가능한 경우에만 복구되고, 불가능하다면 앱이 무리하게 보장하지 않는다.
6. 사용자가 BGM off 상태면 위 정책과 무관하게 앱 BGM은 계속 꺼진 상태를 유지해야 한다.
7. 사용자가 BGM 볼륨을 조절해 둔 경우에도 breath 종료 후 복구되는 BGM은 기존 볼륨 설정을 유지해야 한다.

## 상세 요구사항

### 필수 동작

- 홈 BGM은 디바이스 외부 음악과 동시에 재생되어야 한다.
- 타로 BGM은 디바이스 외부 음악과 동시에 재생되어야 한다.
- breath 관련 영상 재생 시작 시 앱 BGM은 중지되어야 한다.
- breath 관련 영상 재생 시작 시 디바이스 외부 음악도 중지되도록 오디오 포커스 정책을 적용해야 한다.
- breath 관련 영상 재생 종료 시 앱 BGM은 다시 시작되어야 한다.
- breath 관련 영상이 중간 종료되어도 종료 시점에 앱 BGM 복구 로직이 실행되어야 한다.
- breath 종료 후 디바이스 외부 음악 재개는 가능 여부를 플랫폼 제약과 함께 검토해야 한다.
- iOS와 Android 모두 동일한 정책으로 동작해야 한다.
- BGM on/off 설정은 기존과 동일하게 동작해야 한다.
- BGM 볼륨 설정은 기존과 동일하게 동작해야 한다.

### 정책 구분

- 홈 / 타로:
  - 앱 BGM 재생
  - 디바이스 음악 유지
  - 오디오 믹싱 허용
- breath 시작 시:
  - breath 영상 오디오 재생
  - 앱 BGM 중지
  - 디바이스 음악 중지 시도
  - 오디오 포커스 독점 또는 우선 확보 정책 검토
- breath 종료 시:
  - 앱 BGM 복구
  - 디바이스 음악 재개 가능 여부 확인
  - OS에서 자동 재개가 불가능하면 앱은 강제 보장하지 않음

### 예외 / 검토 포인트

- breath 진입 직전 BGM이 off 상태인 경우 종료 후에도 off 유지가 맞는지 확인 필요
- breath 진입 직전 디바이스 음악이 없던 경우 복구 로직이 불필요한지 확인 필요
- mov 영상 pause / resume / dispose / page pop 시점마다 오디오 복구가 중복 실행되지 않도록 해야 한다
- Android audio focus 와 iOS AVAudioSession category 설정이 현재 어떤 값으로 되어 있는지 먼저 확인해야 한다
- 외부 음악 `재개`는 앱에서 직접 제어할 수 없는 경우가 많으므로, 플랫폼별 한계를 문서에 남겨야 한다

## 관련 화면 또는 기능

- 홈 화면 BGM
- 타로 화면 BGM
- breath 관련 화면 및 mov 영상 재생 구간
- 앱 전역 BGM player / audio session / audio focus 처리
- BGM 설정 화면의 on/off 및 volume 제어

## 예상 영향 범위

- 앱 전역 BGM service 또는 audio manager
- 홈 BGM 진입/이탈 처리 코드
- 타로 BGM 진입/이탈 처리 코드
- breath 영상 재생 시작/종료 처리 코드
- iOS audio session 설정
- Android audio focus / audio attributes 설정
- 설정 저장소의 BGM on/off 및 volume 적용 흐름

## 완료 조건

- 홈과 타로에서 디바이스 음악이 끊기지 않고 앱 BGM과 함께 재생된다.
- breath 시작 시 앱 BGM이 중지된다.
- breath 시작 시 디바이스 음악이 중지되도록 구현되거나, 플랫폼 한계가 있으면 그 범위가 문서로 명확히 남는다.
- breath 종료 또는 중도 종료 후 앱 BGM 복구가 동작한다.
- BGM on/off 및 volume 동작이 회귀 없이 유지된다.
- iOS / Android 각각에 대해 구현 결과 또는 한계가 정리된다.
- `flutter analyze` 와 필요 시 실제 디바이스 수동 테스트 항목이 정리된다.

## 확인 필요

- 현재 프로젝트에서 홈 / 타로 / breath 오디오가 각각 어떤 플레이어 또는 패키지를 사용하는지
- iOS에서 현재 `AVAudioSession` category / options 가 어떻게 설정되는지
- Android에서 현재 audio focus 요청 방식이 있는지
- breath 영상 종료 이벤트가 정상 종료 / 중도 종료 / 뒤로가기 종료에서 각각 어디서 잡히는지
- 외부 음악 재개를 앱이 직접 제어 가능한지, 아니면 OS에 맡겨야 하는지

## 참고 자료

### 우선 확인할 코드 파일

- 홈 BGM 관련 service / cubit / page
- 타로 BGM 관련 service / cubit / page
- breath 영상 재생 page / widget / controller
- 앱 전역 audio manager 또는 background music service
- 설정 화면의 BGM on/off 및 volume 저장/적용 코드
- iOS `Runner` 오디오 세션 관련 설정 파일
- Android 오디오 포커스 관련 설정 및 플레이어 초기화 코드

## 오케스트레이션 실행 메모

- 실제 구현 전에 반드시 현재 오디오 재생 구조와 패키지 의존성을 먼저 파악할 것
- 홈/타로와 breath의 오디오 포커스 정책을 명확히 분리해서 분석할 것
- 외부 음악 `중지`와 `재개` 가능 범위를 플랫폼별로 구분해서 기록할 것
- BGM on/off 및 volume 회귀 여부를 별도 체크리스트로 분리할 것
- iOS / Android 각각에서 필요한 세션 설정 변경과 테스트 시나리오를 문서화할 것

## 실행 명령

```bash
ai/scripts/orchestrate_ai.sh --task-file ai/inbox/bgm_audio_focus_policy_task.md
```

## dry-run 명령

```bash
ai/scripts/orchestrate_ai.sh --task-file ai/inbox/bgm_audio_focus_policy_task.md --dry-run
```
