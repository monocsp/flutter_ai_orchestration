### 1. 입력 유형 판별
- 입력 유형: 기능 추가
- 판단 근거: 버그 재현이나 QA 이슈가 아니라, “폰에 대고 내쉬는 호흡을 감지할 수 있는가”와 “어떻게 설계하면 좋은가”를 묻는 신규 기능 탐색 요청입니다. 코드베이스상 이미 `수용호흡` 플로우와 마이크 녹음 기능이 있어, 완전 무관한 신규 도메인보다 기존 호흡 기능 확장 검토가 타당합니다.

### 2. 우선순위 보드
| 우선순위 | 작업 항목 | 유형 | 핵심 문제 | 관련 영역 |
| --- | --- | --- | --- | --- |
| P0 | 내쉼 감지 엔진 분리 설계 | 기능 추가 | 현재는 음성 녹음만 있고 실시간 호흡 판정 로직이 없음 | 마이크, 권한, 오디오 세션 |
| P1 | 기존 수용호흡 UX 통합 여부 결정 | 기능 추가 | 현재 플로우는 “내 목소리 녹음/재생” 중심이라 호흡 감지와 목적이 다름 | 화면, 라우팅, 라이프사이클, 재생 |
| P1 | 저장/백엔드 계약 재정의 | 정책+기능 | 현재 API는 `voice_file` 업로드 전제라 감지 결과 저장 모델과 맞지 않음 | Repository, Provider, 모델, 운영 |

### 3. 작업 항목별 분석
#### 항목 1. 내쉼 감지 엔진 분리 설계
- **현재 이해한 요구사항**: 사용자가 폰 마이크 쪽으로 숨을 내쉴 때 이를 “날숨 시작/유지/종료” 수준으로 감지하고, UX에 활용하려는 요청입니다.
- **확인된 증상 또는 목표**: 코드상 확인된 것은 녹음 시작/정지/재생뿐입니다. `BreathVoiceCubit`은 AAC 파일 녹음과 경과시간만 관리하고, 레벨/PCM/진폭 분석은 없습니다. [breath_voice_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/cubit/breath_voice_cubit.dart#L15)
- **관련 코드 파일**: [breath_voice_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/cubit/breath_voice_cubit.dart#L15), [accetp_rec_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/widget/accetp_rec_widget.dart#L17), [rec_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/widget/rec_widget.dart#L16), [permission_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/core/cubit/permission/permission_cubit.dart#L79), [pubspec.yaml](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/pubspec.yaml#L96), [AndroidManifest.xml](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/android/app/src/main/AndroidManifest.xml#L31), [Info.plist](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/ios/Runner/Info.plist#L103)
- **간접 영향 파일**: [fm_audio_session.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/core/utils/fm_audio_session.dart#L5), [config_reader.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/core/utils/config_reader.dart#L24)
- **원인 가설 또는 구현 쟁점**: 현재 구조는 “녹음 파일 생성”과 “호흡 감지”가 섞이면 안 맞습니다. 무음 녹음도 성공 처리될 수 있고, 권한 문구도 “목소리 녹음/저장” 기준입니다. `FmAudioSession`은 Android에서 아무 설정도 하지 않아 플랫폼별 차이도 큽니다. [fm_audio_session.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/core/utils/fm_audio_session.dart#L13)
- **추천 접근 방식**: `BreathVoiceCubit`을 건드리기보다 별도 `BreathDetectionCubit/Service`를 두고, `baseline 측정 0.5~1초 -> 이동평균 -> 임계치 상향/하향 분리(hysteresis) -> 최소 유지시간 -> 종료 cooldown` 상태기계로 구현하는 편이 맞습니다. 들숨은 측정하지 말고 날숨만 감지하는 방향이 현 구조와 가장 잘 맞습니다.
- **대안 접근 방식**: 1차 프로토타입은 기존 `record` 계열로 레벨 폴링만 쓰고, 오탐이 심하면 이미 의존성에 들어있는 `flutter_sound` 기반 raw stream/PCM 쪽으로 확장하는 2단계 전략이 현실적입니다. 코드상 `flutter_sound`는 선언만 있고 실제 사용은 확인되지 않았습니다. [pubspec.yaml](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/pubspec.yaml#L107)
- **확인 필요**: 감지 결과만 쓸지, 오디오 자체를 저장할지. 현재 수용호흡 브랜딩과 권한 문구는 “내 목소리” 기준입니다.

#### 항목 2. 기존 수용호흡 UX 통합 여부 결정
- **현재 이해한 요구사항**: 이 기능을 현재 `수용호흡`에 넣을지, 별도 호흡 모드로 만들지 결정해야 합니다.
- **확인된 증상 또는 목표**: 현재 `수용호흡`은 홈에서 별도 메뉴로 노출되고, 메인 카피도 “내 목소리로 나를 위로하는 수용호흡”입니다. 재생 플로우는 15초 주기 4초 들숨, 4초 멈춤, 나머지 날숨 타이밍으로 고정돼 있고, 영상/오디오/진동이 함께 동작합니다. [care_home_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/home/ui/page/care_home_page.dart#L259), [breath_accept_main_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/page/breath_accept_main_page.dart#L189), [play_breath_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/widget/play_breath_widget.dart#L87)
- **관련 코드 파일**: [router.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/core/navigation/router.dart#L999), [breath_accept_play_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/page/breath_accept_play_page.dart#L71), [play_breath_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/widget/play_breath_widget.dart#L166), [breath_play_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/cubit/breath_play_cubit.dart#L47), [breath_category_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/home/ui/widget/care/breath_category_widget.dart#L13)
- **간접 영향 파일**: [app_lifecycle_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/core/cubit/lifecycle/app_lifecycle_cubit.dart#L8), `sound/vibrate interaction cubit`들, `SkipLocalProvider`
- **원인 가설 또는 구현 쟁점**: 현재 재생 중에는 영상 오디오와 사용자 녹음 음성이 함께 나옵니다. 이 상태에서 마이크 감지를 동시에 돌리면 앱 스피커 소리나 사용자의 말소리가 날숨으로 오인될 가능성이 높습니다. 또 `BreathPlayCubit`은 반복 구간마다 `processingStateStream.listen()`을 다시 붙여 중복 이벤트 리스크가 있습니다. [breath_play_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/cubit/breath_play_cubit.dart#L51)
- **추천 접근 방식**: 기존 `수용호흡`에 바로 덧붙이더라도 “날숨 구간에서만 감지”, “감지 중에는 안내 음성 ducking 또는 무음”, “실패 시 수동 진행 버튼 제공”이 필요합니다. 구현 전에 `RecWidget`과 `AccetpRecWidget` 중복도 정리하는 편이 안전합니다.
- **대안 접근 방식**: `수용호흡`은 그대로 두고, 별도 `입김 호흡` 모드를 추가하는 쪽이 제품 의미와 기술 요구를 분리하기 쉽습니다.
- **확인 필요**: 새 기능이 프리미엄 정책을 공유하는지, 홈 카드/가이드/온보딩을 새로 둘지.

#### 항목 3. 저장/백엔드 계약 재정의
- **현재 이해한 요구사항**: 감지 결과를 저장하거나 분석에 쓰려면 현재 API 계약과 맞는지 봐야 합니다.
- **확인된 증상 또는 목표**: 현재 완료 단계는 `voice1.aac` 하나만 업로드하고, API도 `voice_file` 포함 `breath-voice` 저장을 전제합니다. 감지 메트릭 필드는 보이지 않습니다. [breath_accept_finish_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/page/breath_accept_finish_page.dart#L186), [breath_provider.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath/provider/breath_provider.dart#L239), [accept_response_param.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/model/accept_response_param.dart#L8)
- **관련 코드 파일**: [breath_repository.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath/repository/breath_repository.dart#L64), [breath_provider.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath/provider/breath_provider.dart#L238), [breath_accept_finish_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/page/breath_accept_finish_page.dart#L198)
- **간접 영향 파일**: 상세 조회 화면, 통계/분석, 개인정보/권한 문구, 에러 재시도 UI
- **원인 가설 또는 구현 쟁점**: 제품이 원하는 게 “숨을 잘 내쉬었는지”이지 “목소리 파일 저장”이 아니면, 현재 API를 재사용하면 개인정보 범위와 저장 데이터가 어긋납니다.
- **추천 접근 방식**: 서버는 1차로 분리하는 게 좋습니다. `exhale_started_at`, `duration_ms`, `peak_level`, `pass/fail`, `device_calibration` 같은 요약 메트릭만 보내는 별도 계약이 더 맞습니다. 초반에는 서버 저장 없이 로컬 실험도 가능합니다.
- **대안 접근 방식**: 아주 빠른 PoC라면 서버 저장 없이 온디바이스 판정만 넣고, 성공률/이탈률만 익명 이벤트로 수집합니다.
- **확인 필요**: 원시 오디오 저장 허용 여부, 개인정보 보관정책, 실패 시 재시도/건너뛰기 정책. 테스트도 현재는 기본 샘플 하나뿐이라 회귀 방어가 사실상 없습니다. [widget_test.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/test/widget_test.dart#L1)

### 4. 공통 리스크 및 의존성
| 리스크 | 심각도 | 설명 | 영향 범위 |
| --- | --- | --- | --- |
| 오탐/미탐 | 높음 | 현재 코드엔 캘리브레이션, baseline, threshold 상태기계가 전혀 없음 | 감지 정확도, UX 신뢰 |
| 앱 자체 오디오가 마이크에 섞임 | 높음 | 재생 영상/가이드 음성/진동이 이미 존재함 | `breath_accept_play` 전반 |
| 플랫폼 편차 | 높음 | Android 오디오 세션 제어가 비어 있고 iOS만 별도 처리 | Android/iOS 일관성 |
| 제품 의미 충돌 | 중간 | 현 `수용호흡`은 “내 목소리 녹음/저장” 중심 카피와 API를 가짐 | 홈 IA, 온보딩, 권한 문구 |
| 스트림 중복 리스너 | 중간 | 반복 재생마다 `processingStateStream.listen()` 추가 | 오디오 상태 꼬임, 메모리/이벤트 중복 |
| 번역/문구 누락 | 중간 | 호흡 화면 문자열이 다수 하드코딩이라 다국어 반영 경로가 약함 | i18n, 권한 안내 |
| 테스트 공백 | 높음 | 호흡 기능 회귀 테스트가 확인되지 않음 | 배포 안정성 |

### 5. 다음 라운드 검증 포인트
- Codex가 반드시 반박/검증해야 할 주장: “기존 `수용호흡`에 그대로 얹는 것이 가장 쉽다.”
- Codex가 반드시 반박/검증해야 할 주장: “현재 `record` 사용 방식만 조금 바꾸면 충분하다.”
- 아직 코드 근거가 약한 부분: `record` 또는 `flutter_sound`로 현재 앱 구조에서 원하는 수준의 실시간 레벨/PCM 확보가 가능한지.
- 아직 코드 근거가 약한 부분: 감지 중 스피커 재생을 유지해도 오탐이 관리 가능한지.
- 우선순위가 바뀔 가능성이 있는 부분: 서버 저장이 필요한지 여부. 이 결정에 따라 `기존 수용호흡 확장`과 `별도 호흡 모드 추가`의 우선순위가 달라집니다.