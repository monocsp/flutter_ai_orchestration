### 1. 최종 판단
- 작업 성격: 복합
- 최종 판단 요약: 이번 요청은 단순 기능 추가가 아닙니다. 기존 `수용호흡` 흐름 안에 이미 오디오 상태 관리 결함이 있고, 현재 저장/API/문구가 모두 “내 목소리 녹음”을 전제로 묶여 있어 `입김 감지`를 바로 얹으면 기능 의미와 구현이 동시에 흔들립니다.
- 따라서 최종안은 `기존 오디오 상태기계 선행 수정 -> 날숨 감지 PoC 분리 구현 -> UX/저장 정책 분기` 순서로 갑니다.
- 1차 목표는 “의학적 호흡 판정”이 아니라 “폰 하단 마이크에 가까운 날숨(exhale) 이벤트를 안정적으로 감지하는 실사용 PoC”입니다.

### 2. 의사결정 정리
| 쟁점 | 채택안 | 기각안 또는 보류안 | 근거 |
| --- | --- | --- | --- |
| 감지 기능 위치 | 별도 모드 또는 최소한 기존 수용호흡과 분리된 플로우로 구현 | 기존 `수용호흡` 메인 플로우에 즉시 직결 | 홈/메인 카피와 권한 문구가 모두 “내 목소리” 전제이고, 저장도 `voice_file` 업로드를 강제함. [breath_category_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/home/ui/widget/care/breath_category_widget.dart), [breath_accept_main_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/ui/page/breath_accept_main_page.dart), [breath_accept_finish_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/ui/page/breath_accept_finish_page.dart) |
| 선행 작업 | 기존 오디오 상태기계와 위젯 부수효과를 먼저 정리 | 감지 엔진부터 붙여 보고 나중에 정리 | `listen()` 중복 등록, `build` 내부 Cubit 호출, `late Timer` 취소 위험이 이미 존재함. [breath_play_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/cubit/breath_play_cubit.dart), [breath_voice_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/cubit/breath_voice_cubit.dart), [play_breath_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/ui/widget/play_breath_widget.dart) |
| 감지 엔진 구현 방식 | 별도 `BreathDetectionCubit/Service`로 분리 | `BreathVoiceCubit`에 바로 기능 추가 | 현재 `BreathVoiceCubit`은 파일 녹음/재생과 타이머에 이미 결합되어 있음. 실시간 감지까지 합치면 책임이 과도해짐. [breath_voice_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/cubit/breath_voice_cubit.dart) |
| 입력 신호 처리 | 1차는 `record` 기반 amplitude PoC + baseline/hysteresis | 즉시 `flutter_sound`/PCM 전면 도입 | `record`는 이미 사용 중이고 `flutter_sound`는 선언만 있음. 먼저 낮은 비용의 PoC로 정확도 한계를 확인하는 편이 합리적. [pubspec.yaml](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/pubspec.yaml) |
| Android 오디오 처리 | Android 세션 설정 추가와 실기기 비교 로그를 필수로 수행 | 현재 iOS 전용 세션 유지 / 특정 입력 모드 하나를 정답으로 고정 | `FmAudioSession`은 Android에서 모두 조기 `return` 함. 다만 어떤 모드가 최선인지는 코드만으로 확정 불가. [fm_audio_session.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/core/utils/fm_audio_session.dart) |
| 저장 계약 | 1차는 로컬 완료/익명 메트릭 중심, 서버 저장은 별도 계약으로 분리 | 기존 `breath-voice`와 `voice_file` 재사용 | 현재 DTO, 업로드, 상세 화면이 모두 음성 파일 재생을 전제함. [accept_response_param.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/model/accept_response_param.dart), [breath_provider.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath/provider/breath_provider.dart), [accept_detail_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/ui/page/accept_detail_page.dart) |
| UX 범위 | 들숨은 가이드만, 날숨만 실제 감지, 실패 시 수동 진행 제공 | 들숨/날숨 모두 실측 / 실패 시 진행 차단 | 현재 구조와 기기 편차를 고려하면 “입김 감지”를 과장하지 않는 설계가 현실적임. 영상/BGM 재유입도 큼. [play_breath_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/ui/widget/play_breath_widget.dart) |

### 3. 최종 작업 보드
| 우선순위 | 작업 항목 | 상태 | 핵심 파일 | 목적 |
| --- | --- | --- | --- | --- |
| P0 | 오디오 상태기계/라이프사이클 정상화 | 즉시수정 | [breath_play_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/cubit/breath_play_cubit.dart), [breath_voice_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/cubit/breath_voice_cubit.dart), [play_breath_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/ui/widget/play_breath_widget.dart) | 감지 기능을 넣을 수 있는 최소 안정성 확보 |
| P0 | 날숨 감지 엔진 PoC 구현 | 즉시수정 | [fm_audio_session.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/core/utils/fm_audio_session.dart), 신규 `breath_detection_*`, [permission_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/core/cubit/permission/permission_cubit.dart) | 실기기에서 쓸 수 있는 exhale 판정 확보 |
| P1 | 전용 UX/라우트/문구 분리 | 단계적적용 | [router.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/core/navigation/router.dart), [breath_category_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/home/ui/widget/care/breath_category_widget.dart), [breath_accept_main_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/ui/page/breath_accept_main_page.dart), [Info.plist](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/ios/Runner/Info.plist) | 제품 의미와 사용자 기대를 맞춤 |
| P1 | 저장/API/히스토리 분리 | 선확인 | [accept_response_param.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/model/accept_response_param.dart), [breath_provider.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath/provider/breath_provider.dart), [accept_detail_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/ui/page/accept_detail_page.dart) | 음성 저장 전제 제거 |
| P2 | 중복 컴포넌트 정리와 테스트 보강 | 구조개선 | [rec_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/ui/widget/rec_widget.dart), [accetp_rec_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/ui/widget/accetp_rec_widget.dart), [widget_test.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/test/widget_test.dart) | 회귀 방지와 유지보수성 확보 |

### 4. 작업 항목별 최종 실행 계획
#### 4-1. 오디오 상태기계/라이프사이클 정상화
- **목표**: 감지 기능 추가 전, 재생/녹음/일시정지/백그라운드 전환이 누수 없이 동작하도록 정리합니다.
- **직접 수정 파일**: [breath_play_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/cubit/breath_play_cubit.dart), [breath_voice_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/cubit/breath_voice_cubit.dart), [play_breath_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/ui/widget/play_breath_widget.dart), [breath_accept_play_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/ui/page/breath_accept_play_page.dart)
- **간접 영향 파일**: [vibrate_interaction_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/settings/cubit/interaction/vibrate/vibrate_interaction_cubit.dart), [sound_interaction_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/settings/cubit/interaction/sound/sound_interaction_cubit.dart)
- **구체적 변경 방향**: `processingStateStream.listen()`은 Cubit 생성 시 1회만 등록하고 `close()`에서 해제합니다. `PlayBreathWidget`의 `build` 내부 부수효과는 `BlocListener`나 `didUpdateWidget`로 이동합니다. `Timer`는 nullable로 바꾸고 미초기화 취소를 방지합니다. 앱 pause/resume 시에는 타이머, 비디오, 오디오, 진동을 한 곳에서 멈추고 재개합니다.
- **주의할 회귀 포인트**: 기존 수용호흡 재생 타이밍, 미리듣기 종료 상태, 뒤로가기 다이얼로그 후 이어하기, 비디오와 진동 싱크.
- **완료 조건**: `build` 안에서 Cubit 명령이 사라지고, 반복 재생해도 리스너 수가 증가하지 않으며, pause/resume/back 후 상태가 꼬이지 않습니다.

#### 4-2. 날숨 감지 엔진 PoC 구현
- **목표**: 실기기에서 “후”를 안정적으로 감지하고, 실패 시에도 세션이 끊기지 않게 합니다.
- **직접 수정 파일**: [fm_audio_session.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/core/utils/fm_audio_session.dart), [main.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/main.dart), 신규 `breath_detection_cubit.dart`, `breath_detection_state.dart`, `breath_detection_service.dart`, PoC 페이지/위젯
- **간접 영향 파일**: [permission_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/core/cubit/permission/permission_cubit.dart), [AndroidManifest.xml](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/android/app/src/main/AndroidManifest.xml), [Info.plist](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/ios/Runner/Info.plist)
- **구체적 변경 방향**: 1차는 `record` amplitude 기반으로 구현합니다. `baseline 0.5~1초 측정 -> moving average -> 상향/하향 임계치 분리 -> 최소 유지시간 1.5초 -> 종료 cooldown` 상태기계로 갑니다. 감지는 날숨 구간에서만 켜고, 실패 시 `수동 완료` 버튼을 항상 남깁니다. Android는 세션 설정을 추가하되 입력 모드는 실기기 로그 비교 대상으로 둡니다.
- **주의할 회귀 포인트**: 이어폰 연결, 선풍기/카페 소음, 케이스로 마이크 가림, 앱 자체 오디오 재유입, 백그라운드 복귀 후 baseline 오염.
- **완료 조건**: Android 2대 이상과 iPhone 1대 이상에서 quiet 환경 기준 날숨 시작/종료가 일관되게 감지되고, 실패 시에도 수동 진행으로 이탈이 막힙니다.

#### 4-3. 전용 UX/라우트/문구 분리
- **목표**: 기능 의미를 “내 목소리 녹음”과 분리하고, 사용자 오해를 줄입니다.
- **직접 수정 파일**: [router.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/core/navigation/router.dart), 신규 intro/play/result 페이지, [breath_category_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/home/ui/widget/care/breath_category_widget.dart), [breath_accept_main_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/ui/page/breath_accept_main_page.dart), [Info.plist](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/ios/Runner/Info.plist)
- **간접 영향 파일**: 로컬라이징 리소스, 디자인 에셋, 프리미엄 노출 지점, [breath_accept_msg_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/ui/page/breath_accept_msg_page.dart)
- **구체적 변경 방향**: 카피는 “목소리 녹음”이 아니라 “폰 가까이 천천히 내쉬기”로 바꿉니다. 권한 문구도 저장보다 감지 목적 중심으로 분리합니다. 1차는 홈 공개 대신 내부 라우트 또는 실험 토글로 노출하고, `BreathAcceptMsgPage`는 재사용하지 않고 별도 용도 확인 전까지 건드리지 않습니다.
- **주의할 회귀 포인트**: 기존 수용호흡 브랜딩 훼손, 프리미엄 결제 노출 위치, 온보딩 흐름 중복.
- **완료 조건**: 사용자가 새 모드를 기존 음성 녹음 기능과 혼동하지 않고, 권한/가이드/결과 화면의 문구가 기능과 일치합니다.

#### 4-4. 저장/API/히스토리 분리
- **목표**: 입김 감지를 음성 파일 업로드 모델에서 분리합니다.
- **직접 수정 파일**: [accept_response_param.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/model/accept_response_param.dart), [breath_provider.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath/provider/breath_provider.dart), [breath_accept_finish_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/ui/page/breath_accept_finish_page.dart), [accept_detail_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/ui/page/accept_detail_page.dart)
- **간접 영향 파일**: 관련 DTO/도메인 모델, 통계/히스토리 화면, 개인정보 문구
- **구체적 변경 방향**: 1차는 저장하지 않거나 익명 메트릭만 남깁니다. 서버 저장이 필요하면 `duration_ms`, `peak/confidence`, `pass_fail`, `device_mode`용 별도 계약을 만듭니다. 기존 `voice_file` 업로드 경로는 입김 모드에서 재사용하지 않습니다.
- **주의할 회귀 포인트**: 상세 화면이 `filePath` 재생을 전제하는 현재 구조, 히스토리 목록 타입 혼합, 개인정보 범위 확대.
- **완료 조건**: 입김 세션이 기존 `breath-voice` API 없이도 끝까지 동작하거나, 별도 계약으로 저장되더라도 상세/히스토리에서 음성 파일을 기대하지 않습니다.

#### 4-5. 중복 컴포넌트 정리와 테스트 보강
- **목표**: 감지 기능 추가 후에도 유지보수 비용이 폭증하지 않게 만듭니다.
- **직접 수정 파일**: [rec_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/ui/widget/rec_widget.dart), [accetp_rec_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/ui/widget/accetp_rec_widget.dart), 신규 detector unit test, widget/lifecycle test
- **간접 영향 파일**: 공통 버튼/다이얼로그, arc/countdown 위젯
- **구체적 변경 방향**: 권한 요청/녹음 버튼 상태/UI 문구가 중복된 두 위젯을 공통화합니다. Detection engine은 순수 Dart 클래스로 분리해 threshold 로직을 테스트 가능하게 만듭니다. 현재 샘플 테스트만 있는 상태를 종료합니다.
- **주의할 회귀 포인트**: 녹음 UX의 텍스트 차이, 공통화 과정에서 기존 수용호흡 레이아웃 깨짐.
- **완료 조건**: detector 로직 unit test가 생기고, 최소한 play/record 핵심 상태 전이에 대한 회귀 테스트가 추가됩니다.

### 5. 검증 계획
- **코드 검증**
  - `flutter analyze`
  - detector 상태기계 unit test: baseline, threshold 진입/이탈, cooldown, fail fallback
  - play/record lifecycle test: pause/resume, dispose, repeated start/stop
- **수동 검증**
  - 실기기 필수: Android 2대 이상, iPhone 1대 이상
  - 환경별: 조용한 방, 선풍기/카페 소음, 이어폰 연결, 케이스 장착, 볼륨 on/off
  - UX별: 권한 허용/거부, 감지 실패 후 수동 진행, 앱 백그라운드 전환, 뒤로가기 후 재진입
- **회귀 확인 순서**
  1. 기존 수용호흡 녹음/미리듣기/완료 저장이 그대로 되는지 확인
  2. 기존 재생 페이지의 pause/resume/back/video/vibration 싱크 확인
  3. 새 입김 감지 PoC에서 날숨 시작/종료와 fallback 버튼 확인
  4. 저장 기능을 붙였다면 히스토리/상세 화면이 음성 파일 없이도 안전한지 확인

### 6. 보류 또는 선확인 항목
- 기획/디자인/정책 확인이 필요한 항목
  - 새 기능을 별도 홈 카드로 노출할지, 실험 플래그로만 열지
  - 프리미엄 정책을 기존 수용호흡과 공유할지
  - 감지 중 가이드 음성을 `mute`로 갈지 `ducking`으로 갈지
  - 결과 저장을 아예 하지 않을지, 익명 메트릭만 보낼지, 세션 히스토리로 남길지
- 아직 코드 근거가 부족한 항목
  - Android 입력 모드 중 무엇이 최선인지
  - `record` amplitude만으로 충분한지, 2차로 PCM/native bridge가 필요한지
  - `BreathAcceptMsgPage`를 재활용할 가치가 있는지

### 7. 다음 개발자 전달 메모
- 바로 착수 가능한 순서
  1. `play/voice cubit`과 `PlayBreathWidget`의 상태 누수부터 정리
  2. 별도 detector service/cubit으로 PoC 구현
  3. 새 route와 문구를 분리하고 fallback UI 추가
  4. 저장 정책 확정 후 API/히스토리 분기
- 먼저 보면 좋은 파일
  - [play_breath_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/ui/widget/play_breath_widget.dart)
  - [breath_play_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/cubit/breath_play_cubit.dart)
  - [breath_voice_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/cubit/breath_voice_cubit.dart)
  - [fm_audio_session.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/core/utils/fm_audio_session.dart)
  - [breath_accept_finish_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026%E1%84%82%E1%85%A7%E1%86%AB%20%E1%84%89%E1%85%A1%E1%86%BC%E1%84%87%E1%85%A1%E1%86%AB%E1%84%80%E1%85%B5/dolomood-app/lib/feature/samatha/breath_accept/ui/page/breath_accept_finish_page.dart)
- 함정이 되는 포인트
  - `build` 안의 상태 전이를 그대로 두면 감지 스트림까지 같이 꼬입니다.
  - 현재 권한/카피/API/상세는 모두 “목소리 저장” 기준입니다.
  - 테스트는 사실상 비어 있으므로 실기기 검증 없이는 정확도 판단이 불가능합니다.