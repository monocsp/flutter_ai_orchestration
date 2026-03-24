# Final 종합 계획 프롬프트

당신은 세계 최고 수준의 Flutter/Dart 기술 리드이자 최종 의사결정자입니다.
당신의 역할은 이전 라운드들의 분석과 반박을 종합해서, 실제 개발에 바로 착수할 수 있는 최종 계획서를 만드는 것입니다.

입력은 QA 이슈 대응일 수도 있고, 신규 기능 추가일 수도 있으며, 정책 변경, 버그 수정, 리팩터링, 구조 개선 작업일 수도 있습니다.
입력 유형과 무관하게 실행 가능한 최종 문서로 정리하세요.

## 페르소나와 태도
- 당신은 모호한 요구사항을 실행 항목으로 번역할 수 있어야 합니다.
- 다만 코드 근거 없는 주장이나 반박은 최종안에서 제거해야 합니다.
- 이전 라운드에서 충돌한 주장들은 반드시 정리하고, 어느 쪽을 채택했는지 이유를 밝혀야 합니다.
- "좋아 보이는 방향"보다 "실행 가능한 순서와 검증 가능성"을 우선합니다.

## 핵심 목표
- 실제로 무엇을 먼저 바꿔야 하는지 결정합니다.
- 각 작업 항목의 변경 범위와 영향 범위를 명확히 합니다.
- 구현 순서, 검증 순서, 보류 항목을 분리합니다.
- 다음 개발자가 그대로 작업할 수 있을 정도로 구체성을 확보합니다.

## 종합 원칙
- Round 1, Round 2의 주장 중 코드 근거가 더 강한 쪽을 채택하세요.
- 충돌한 주장들은 `채택 / 기각 / 보류`로 정리하세요.
- 기능 추가 요청이라면 설계와 영향 범위를 중심으로 정리하세요.
- 버그/QA 이슈라면 재현 조건, 원인, 회귀 방지 포인트까지 포함하세요.
- 리팩터링이라면 변경 이득과 위험, 단계적 적용 전략을 포함하세요.

## 반드시 포함할 관점
- 직접 수정 파일
- 간접 영향 파일
- 공통 컴포넌트 영향
- 상태 관리 영향
- 라우팅/라이프사이클 영향
- 번역/문구/디자인 영향
- 테스트 또는 수동 검증 포인트
- 보류해야 할 항목

## 금지사항
- 근거 없는 낙관적 결론 금지
- 작업 순서 없는 계획 금지
- 검증 전략 없는 최종안 금지
- 입력 문서를 그대로 복사하는 수준의 정리 금지

## 필수 출력 형식 (한국어 Markdown)

### 1. 최종 판단
- 작업 성격: 버그 수정 / 기능 추가 / 정책 변경 / 리팩터링 / 복합
- 최종 판단 요약: 2~4줄

### 2. 의사결정 정리
| 쟁점 | 채택안 | 기각안 또는 보류안 | 근거 |

### 3. 최종 작업 보드
| 우선순위 | 작업 항목 | 상태 | 핵심 파일 | 목적 |

상태 분류:
- 즉시수정
- 단계적적용
- 구조개선
- 선확인
- 보류

### 4. 작업 항목별 최종 실행 계획
각 항목마다 아래를 포함하세요.
- **목표**
- **직접 수정 파일**
- **간접 영향 파일**
- **구체적 변경 방향**
- **주의할 회귀 포인트**
- **완료 조건**

### 5. 검증 계획
- 코드 검증
- 수동 검증
- 회귀 확인 순서

### 6. 보류 또는 선확인 항목
- 기획/디자인/정책 확인이 필요한 항목
- 아직 코드 근거가 부족한 항목

### 7. 다음 개발자 전달 메모
- 바로 착수 가능한 순서
- 먼저 보면 좋은 파일
- 함정이 되는 포인트

## 실행 컨텍스트
- 저장소 루트: /Users/pcs/Library/Mobile Documents/com~apple~CloudDocs/2026년 상반기
- 실행 시각: 2026-03-24 11:26:28 +0900

## 종합 입력 자료

--- 원본 입력 ---
근데 플러터앱 쪽에서 이런 유저가 핸드폰에 대고 호흡하는걸 확인할 수 있는 방법이 있을까? 있다면 어떤식으로 구현해야하는지,알려줘 

일단 내가 간단하게 찾아봤을 때 이런식으로 만드는게 낫다고 추천받았어 


실제로 구현할 때 가장 쉬운 방식은 마이크 기반 “후-” 감지야.
즉, 사용자가 폰 하단 마이크 쪽으로 숨을 내쉬면 들어오는 오디오의 에너지(RMS), 피크, 지속시간을 보고 “지금 내쉬는 중”이라고 판단하는 방식이지. 이건 음성 인식까지 갈 필요 없고, 그냥 실시간 오디오 레벨만 봐도 1차 프로토타입은 충분히 돼. noise_meter는 mean/max dB를 바로 받을 수 있고, 더 세밀하게 하려면 record나 flutter_sound로 PCM 스트림을 받아 직접 필터링하면 돼.

다만 한계도 분명해.
Android 공식 문서에서도 기본 오디오 소스는 신호에 후처리(가공)가 들어갈 수 있고, 가능한 경우 UNPROCESSED나 VOICE_RECOGNITION 소스를 고려하라고 안내해. 즉 기기마다 AGC, 노이즈 억제, 마이크 튜닝이 달라서 같은 숨이라도 반응이 달라질 수 있어. 그래서 앱이 “정확한 들숨/날숨”을 판정한다기보다, “입김이 들어왔다 / 충분히 길게 내쉬었다” 정도로 해석하는 게 안전해. 그리고 Android 에뮬레이터는 오디오 녹음을 못 해서 반드시 실기기 테스트가 필요해.

그래서 UX적으로는 들이마심은 측정하지 말고 가이드만 주고, 내쉼만 측정하는 구조가 제일 좋아.
예를 들면:

“들이마시기 4초”는 화면 애니메이션으로만 안내

“내쉬기 6초”는 마이크로 실제 감지

일정 세기 이상이 1.5초 이상 유지되면 exhaleStart

세기가 떨어지면 exhaleEnd
이렇게 하면 정확도/구현난이도/재미 균형이 좋아져. 이건 공식 문서의 오디오 스트림 가능 여부와 처리 특성을 바탕으로 한 실무적 추론이야.

개발을 어떻게하면 좋을지, 여기에서 에러케이스 또는 유저들의 불편함을 겪을것들 이런 예외케이스들을 최대한 생각해서 어떻게 만들면 좋을지 아이디어 내줘 

--- Round 1 Codex 분석 ---
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
--- Round 1 Gemini 비판적 검토 ---
I will now begin the critical review of the Round 1 analysis by verifying the actual implementation of the breath-related features in the `dolomood-app` codebase, focusing on the audio session handling, cubit logic, and existing recording implementations.

I will now examine the `pubspec.yaml` to confirm the audio packages and then investigate the `breath_accept` cubits and UI to understand the current implementation of recording and playback.

I will now examine `lib/core/utils/fm_audio_session.dart` to verify its implementation and check if it lacks Android-specific configurations as claimed.

I will now examine `breath_voice_cubit.dart` and `breath_play_cubit.dart` to verify the state machine logic and investigate the potential duplicate listener issue mentioned in Round 1.

I will now examine `breath_voice_cubit.dart` to understand its use of the `record` package and check the current recording logic.

I have confirmed that `BreathVoiceCubit` only handles file recording and duration without real-time analysis. I will now examine `breath_play_cubit.dart` to investigate the duplicate listener risk and understand the "Acceptance Breath" flow.

I've confirmed that `onBreathPlayInhale` and `onBreathPlayExhale` create redundant listeners. I'll now examine how these methods are used in the UI, specifically within `BreathAcceptPlayPage`, to further assess the impact.

I will now examine `breath_accept_play_page.dart`.

`PlayBreathWidget` contains the breath logic; I'll examine it now.

`PlayBreathWidget` manages a 15-second breathing cycle using `BreathPlayCubit` to play voice files, but its repeated calls to `onBreathPlayInhale` and `onBreathPlayExhale` cause listener leaks. Additionally, the simultaneous playback of video and guide audio confirms the risk of microphone feedback during breath detection. I'll now check `ConfigReader.voiceFiles` to identify the specific audio files being used.

`voiceFiles` are hardcoded as `['voice0.aac', 'voice1.aac']`, recorded by `BreathVoiceCubit` and replayed by `PlayBreathWidget`. I'll now examine the repository/provider to assess the backend impact of this voice saving, as noted in Round 1.

Checking `breath_provider.dart`.

`requestAddBreathAcceptDol` uploads a single `voiceFile` to `/file`, then sends the file ID in a subsequent request. I'll now examine `AcceptResponseParam` and the remaining logic in `requestAddBreathAcceptDol`.

`breath-voice` receives the request. My findings show `FmAudioSession` lacks Android configuration, hampering audio capture. `BreathVoiceCubit` and `BreathPlayCubit` suffer from listener leaks due to redundant cycle-triggered attachments. `PlayBreathWidget` follows a fixed 15s cycle, using hardcoded user-recorded assets, while simultaneous video and audio playback creates microphone noise. Although `record` supports amplitude monitoring, it's unused, and `flutter_sound` is largely ignored. For Round 2, I'll emphasize the need for a separate detection engine, mandatory Android `audio_session` configuration to bypass AGC, and addressing the masking effect of guide audio in `PlayBreathWidget`, while also prioritizing the fix for the existing listener leak. I'll now structure the report.

### 1. 총평
- 이전 라운드 분석 신뢰도: **보통**
- 한 줄 요약: 기존 코드의 리스너 누수와 Android 오디오 세션 제어 부재를 정확히 짚었으나, '가장 쉬운 방식'으로 제안된 단순 레벨 폴링은 현재의 앱 배경음/영상 오디오와 섞여 오탐이 매우 높을 위험을 과소평가함.

### 2. 사실 검증 결과
| 항목 | 이전 주장 | 검증 결과 | 근거 |
| :--- | :--- | :--- | :--- |
| **Android 오디오 세션** | Android 설정이 거의 비어 있음 | **사실** | `fm_audio_session.dart`에서 `Platform.isAndroid`일 때 조기 리턴함. |
| **리스너 중복 등록** | 반복 재생 시 리스너가 누적됨 | **사실** | `BreathPlayCubit`의 `onBreathPlayInhale/Exhale`에서 매 호출마다 `listen()`을 수행함. |
| **음성 녹음 로직** | 단순 파일 생성 위주임 | **사실** | `BreathVoiceCubit`은 `AudioRecorder.start()` 후 타이머로 시간만 잴 뿐, 실시간 진폭 분석 로직이 없음. |
| **패키지 의존성** | `record`, `flutter_sound` 존재 | **사실** | `pubspec.yaml`에 포함되어 있으나 `flutter_sound`는 주석 처리되거나 거의 사용 안 됨. |

### 3. 누락 또는 오류
- **누락된 파일**: `lib/feature/settings/cubit/interaction/vibrate/vibrate_interaction_cubit.dart` (호흡 시 진동 제어 계층)
- **잘못 짚은 포인트**: 단순히 "기존 `record` 사용 방식만 바꾸면 충분하다"는 전략은 위험함. 현재 `PlayBreathWidget`은 **영상(`VideoPlayer`)과 가이드 음성**을 동시에 출력하므로, 스피커 소리가 마이크로 재유입되는 **AEC(Echo Cancellation) 영향**을 반드시 고려해야 함.
- **빠진 호출 경로**: `PlayBreathWidget` 내의 `Timer.periodic(100.ms, ...)`가 전체 호흡 사이클(15초)을 제어하며, 이 타이머 안에서 `Cubit` 메서드들을 반복 호출하고 있음.

### 4. 수정안 재평가
- **이전 수정안의 문제점**: 
    - `BreathVoiceCubit`에 기능을 추가하자는 제안은 기존의 '내 목소리 녹음' 기능과 '실시간 입김 감지' 기능의 라이프사이클(파일 저장 vs 스트림 분석)을 섞어 복잡도를 높임.
    - 단순히 `mean/max dB`만 보는 것은 배경음악이 있는 환경에서 '입김'과 '음악'을 구분하지 못함.
- **더 안전한 대안**: 
    - **AEC(에코 제거) 활성화된 오디오 소스** 사용 필수. 
    - `UNPROCESSED` 소스는 입김 감지엔 유리하나 배경음 재유입에 취약하므로, Android에서는 `VOICE_COMMUNICATION` 모드를 활용해 하드웨어 AEC의 도움을 받는 편이 나을 수 있음.
- **더 단순한 대안**: 
    - `record` 패키지의 `onAmplitudeChanged` 스트림을 구독하되, **호흡 가이드 음성이 나오는 구간과 나오지 않는 구간의 Baseline을 동적으로 보정**하는 로직 필요.
- **남는 리스크**: 
    - 사용자가 이어폰을 낀 경우 마이크 위치가 입에서 멀어져 감지 불가.
    - 저가형 기기에서의 하드웨어 노이즈 억제(Noise Suppression)가 입김 소리를 노이즈로 판단해 지워버릴 가능성.

### 5. 우선순위 재정렬
| 작업 항목 | 기존 우선순위 | 제안 우선순위 | 근거 |
| :--- | :--- | :--- | :--- |
| **리스너 누수 버그 수정** | 미정 | **P0** | 현재도 사이클 반복 시 메모리/이벤트가 쌓이는 구조적 결함임. |
| **Android 오디오 세션 보강** | P0 | **P0** | Android에서 시스템 후처리를 제어하지 못하면 입김 감지 자체가 불가능함. |
| **별도 Detection Cubit 생성** | P0 | **P1** | 기존 녹음 로직과의 결합도 분리를 위해 필수적이나, 엔진 검증이 선행되어야 함. |
| **UX 통합 및 에코 캔슬링 대응** | P1 | **P1** | 스피커 소리 유입 차단이 기술적 성패를 결정함. |

### 6. 다음 라운드 강제 반영 사항
- **구조적 개선**: `BreathPlayCubit`의 `listen()` 호출을 `constructor` 또는 별도 `init` 단계로 옮겨 1회만 등록되도록 수정할 것.
- **기술적 검증**: `record` 패키지의 `onAmplitudeChanged`가 `just_audio`의 배경음 재생 중에도 입김(High-frequency white noise 성분)에 의한 진폭 변화를 유의미하게 잡아내는지 실기기 로그 확인 전략 포함.
- **파일 경로 고정**: `ConfigReader.voiceFiles`에 정의된 `voice0.aac`, `voice1.aac`를 활용하는 현재의 수용호흡 플로우와 충돌하지 않도록 감지 모드 시에는 파일 저장을 건너뛰는 옵션 고려.

---
비판 검토 완료. 다음 라운드는 위 우선순위와 에코 캔슬링 리스크를 반영하여 구체적인 구현 설계를 진행하세요.

--- Round 2 Codex 심화 분석 ---
### 0. Round 1 / Gemini 반영표
| 지적 사항 | 수용 여부 | 반영 내용 |
| --- | --- | --- |
| Android 오디오 세션 설정이 사실상 비어 있음 | 수용 | [fm_audio_session.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/core/utils/fm_audio_session.dart#L13)에서 Android는 모두 조기 `return`입니다. 다만 이는 “감지가 불가능”의 확정 근거가 아니라 “입력 제어가 약하다”는 근거로만 반영했습니다. |
| `BreathPlayCubit` 리스너 누수 | 수용 | [breath_play_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/cubit/breath_play_cubit.dart#L47)와 [play_breath_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/widget/play_breath_widget.dart#L223) 기준으로 선행 버그 수정 항목으로 올렸습니다. |
| `record` 진폭/PCM 미사용, `flutter_sound` 사실상 미사용 | 수용 | 검색 결과 `onAmplitudeChanged/getAmplitude/startStream` 호출은 없고, `AudioRecorder()`만 [breath_voice_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/cubit/breath_voice_cubit.dart#L15)에서 사용됩니다. `flutter_sound`는 [pubspec.yaml](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/pubspec.yaml#L107) 선언만 확인됐습니다. |
| 비디오/가이드 오디오의 마이크 재유입 리스크 | 수용 | [play_breath_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/widget/play_breath_widget.dart#L121)에서 영상 볼륨이 켜질 수 있고, 같은 위젯이 녹음된 음성 재생도 트리거합니다. |
| `BreathVoiceCubit`에 바로 감지 기능을 붙이는 전략 위험 | 수용 | 별도 감지 엔진 분리를 추천으로 유지하되, 근거를 더 강화했습니다. 현재 `BreathVoiceCubit`은 파일 녹음/재생과 타이머에 이미 결합돼 있습니다. |
| Android에서 `VOICE_COMMUNICATION`/AEC를 정답으로 고정해야 함 | 부분 수용 | 코드상 확인된 것은 “Android 입력 제어 부재”뿐입니다. 어떤 소스가 최선인지는 실기기 검증이 필요하므로 후보 전략으로만 반영했습니다. |
| 진동 계층 누락 | 수용 | [vibrate_interaction_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/settings/cubit/interaction/vibrate/vibrate_interaction_cubit.dart#L142)가 실제 호흡 단계와 연결돼 있어 영향 파일에 포함했습니다. |

### 1. 입력 유형 판별
- 입력 유형: 기능 추가
- 판단 근거: 사용자가 “폰에 대고 내쉬는 호흡을 감지할 수 있는가”와 “예외 케이스까지 포함한 구현 아이디어”를 요청했습니다. 다만 실제 코드베이스에는 이 기능을 바로 얹기 전에 정리해야 할 기존 오디오/상태 결함이 함께 존재합니다.

### 2. 우선순위 보드
| 우선순위 | 작업 항목 | 유형 | 핵심 문제 | 관련 영역 |
| --- | --- | --- | --- | --- |
| P0 | 재생/녹음 상태기계 선행 정리 | 버그 수정 | 리스너 누수, 타이머 정리 누락, 상태 emit 불일치가 현재도 존재 | Cubit, Widget lifecycle, Audio player |
| P0 | 날숨 감지 입력 엔진 PoC | 기능 추가 | 실시간 호흡 판정 로직과 Android 입력 제어가 없음 | 마이크, 오디오 세션, 권한 |
| P1 | 수용호흡 UX 통합 경계 재정의 | 기능 추가 | 현재 플로우가 “내 목소리 녹음/재생” 중심이라 입김 감지와 목적이 다름 | 화면, 라우팅, 영상/오디오, 진동 |
| P1 | 저장/권한/상세 계약 분리 | 정책+기능 | 현재 서버/상세보기는 `voice_file` 저장과 재생을 전제 | API, 모델, 상세 화면, 문구 |

### 3. 작업 항목별 분석
#### 항목 1. 재생/녹음 상태기계 선행 정리
- **현재 이해한 요구사항**: 새 기능 이전에, 최소한 기존 수용호흡 재생/미리듣기 흐름이 반복 호출과 중단 상황에서 안정적으로 동작해야 합니다.
- **확인된 증상 또는 목표**: `BreathPlayCubit`은 매 호출마다 `processingStateStream.listen()`을 추가합니다([breath_play_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/cubit/breath_play_cubit.dart#L47)). 같은 패턴이 `BreathVoiceCubit` 미리듣기에도 있습니다([breath_voice_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/cubit/breath_voice_cubit.dart#L66)). `PlayBreathWidget`은 `build` 안에서 단계 전환 부수효과를 발생시키고([play_breath_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/widget/play_breath_widget.dart#L201)), `late Timer`를 무조건 `cancel()`합니다([play_breath_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/widget/play_breath_widget.dart#L76)).
- **관련 코드 파일**: [breath_play_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/cubit/breath_play_cubit.dart#L47), [breath_voice_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/cubit/breath_voice_cubit.dart#L23), [breath_voice_state.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/cubit/breath_voice_state.dart#L5), [play_breath_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/widget/play_breath_widget.dart#L166)
- **간접 영향 파일**: [play_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/widget/play_widget.dart#L25), [breath_accept_intro_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/page/breath_accept_intro_page.dart#L42), [accetp_rec_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/widget/accetp_rec_widget.dart#L42)
- **원인 가설 또는 구현 쟁점**: 현재 구조는 “화면 렌더링”이 “오디오 상태 전이”를 직접 일으킵니다. 여기에 마이크 스트림까지 추가하면 pause/resume, 앱 백그라운드, 조기 종료에서 오작동 가능성이 더 커집니다.
- **추천 접근 방식**: 감지 기능 전에 `listen()`을 1회 등록 구조로 바꾸고, 타이머/구독 해제를 `close/dispose`에 명시적으로 넣고, 재생 완료는 `stopPlay`를 emit하도록 정리하는 것이 맞습니다.
- **대안 접근 방식**: 기능 PoC를 별도 실험 화면에 격리해 기존 수용호흡은 건드리지 않는 방법도 있습니다. 다만 본 플로우 통합 전에는 결국 같은 정리가 필요합니다.
- **확인 필요**: 이번 요청 범위에 기존 결함 선행 수정을 포함할지. 포함하지 않으면 이후 Round에서 “감지 실패”와 “기존 재생 버그”가 섞여 분석 품질이 떨어집니다.

#### 항목 2. 날숨 감지 입력 엔진 PoC
- **현재 이해한 요구사항**: 들숨/날숨 전체 생체 판정이 아니라, 폰 하단 마이크 근처의 “후”를 실용적으로 감지하는 1차 기능이 목표입니다.
- **확인된 증상 또는 목표**: `BreathVoiceCubit`은 AAC 파일 녹음과 경과 시간만 다룹니다([breath_voice_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/cubit/breath_voice_cubit.dart#L37)). `record`와 `flutter_sound`는 의존성에 있으나([pubspec.yaml](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/pubspec.yaml#L103)), 코드상 진폭/PCM 호출은 확인되지 않았습니다. Android는 오디오 세션 제어가 없습니다([fm_audio_session.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/core/utils/fm_audio_session.dart#L13)).
- **관련 코드 파일**: [breath_voice_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/cubit/breath_voice_cubit.dart#L37), [fm_audio_session.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/core/utils/fm_audio_session.dart#L27), [permission_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/core/cubit/permission/permission_cubit.dart#L79), [main.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/main.dart#L114)
- **간접 영향 파일**: [AndroidManifest.xml](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/android/app/src/main/AndroidManifest.xml#L31), [Info.plist](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/ios/Runner/Info.plist#L103)
- **원인 가설 또는 구현 쟁점**: 핵심 쟁점은 판정 알고리즘보다 입력 품질입니다. AGC/NS/AEC가 기기별로 다르고, 현재 앱 구조에서는 baseline 보정과 임계치 상태기계가 전혀 없습니다.
- **추천 접근 방식**: `BreathDetectionCubit/Service`를 별도로 두고 `baseline 0.5~1초 -> 이동평균 -> hysteresis threshold -> 최소 유지시간 -> cooldown -> fail fallback` 흐름으로 가는 것이 적절합니다. Android 입력 소스는 `default`, `voice communication`, `unprocessed`를 실기기에서 비교해야 합니다. 여기서의 “최선”은 아직 코드로 확인되지 않았습니다.
- **대안 접근 방식**: 1차는 `record` 진폭 스트림 기반의 조용한 구간 감지만 실험하고, 재유입이 심하면 raw PCM 또는 별도 모드로 전환합니다.
- **확인 필요**: 허용 가능한 미탐/오탐 수준, 지원 기기 범위, 이어폰 사용 시 감지 실패를 허용할지.

#### 항목 3. 수용호흡 UX 통합 경계 재정의
- **현재 이해한 요구사항**: 새 감지 기능을 기존 `수용호흡`에 그대로 붙일지, 별도 “입김 호흡” 모드로 분리할지 판단해야 합니다.
- **확인된 증상 또는 목표**: 현재 수용호흡은 홈/메인 카피부터 “내 목소리” 전제입니다([breath_category_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/home/ui/widget/care/breath_category_widget.dart#L150), [breath_accept_main_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/page/breath_accept_main_page.dart#L188)). 녹음 페이지는 문장 읽기와 미리듣기 UX이고([breath_accept_rec_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/page/breath_accept_rec_page.dart#L29)), 재생 페이지는 영상+고정 15초 호흡 주기+진동을 사용합니다([breath_accept_play_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/page/breath_accept_play_page.dart#L181), [play_breath_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/widget/play_breath_widget.dart#L121), [vibrate_interaction_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/settings/cubit/interaction/vibrate/vibrate_interaction_cubit.dart#L142)).
- **관련 코드 파일**: [router.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/core/navigation/router.dart#L999), [breath_accept_main_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/page/breath_accept_main_page.dart#L201), [breath_accept_play_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/page/breath_accept_play_page.dart#L87), [breath_accept_intro_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/page/breath_accept_intro_page.dart#L42)
- **간접 영향 파일**: [sound_interaction_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/settings/cubit/interaction/sound/sound_interaction_cubit.dart#L147), [play_countdown_widget.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/widget/play_countdown_widget.dart#L23), [breath_accept_msg_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/page/breath_accept_msg_page.dart#L25)
- **원인 가설 또는 구현 쟁점**: 제품 의미가 이미 “내 목소리로 위로”에 맞춰져 있어, 입김 감지는 같은 화면에 넣더라도 다른 성공 기준을 가집니다. 특히 현재 재생 중 마이크 감지를 병행하면 영상/녹음 음성의 재유입을 먼저 처리해야 합니다.
- **추천 접근 방식**: 제품적으로는 별도 모드 분리가 가장 안전합니다. 수용호흡 안에 넣더라도 “날숨 구간에서만 감지”, “감지 중 가이드 음성 ducking/mute”, “실패 시 수동 진행”이 필요합니다.
- **대안 접근 방식**: 기존 수용호흡은 유지하고, 홈에서 실험적 카드나 옵션 토글로만 노출하는 방식이 있습니다.
- **확인 필요**: 프리미엄 정책 공유 여부, 인트로도 새로 만들어야 하는지, `breathAcceptMsg` 같은 비활성 경로를 이번 범위에서 정리할지.

#### 항목 4. 저장/권한/상세 계약 분리
- **현재 이해한 요구사항**: 감지 결과를 기록할지, 원시 오디오를 저장할지, 아예 저장 없이 세션 UX만 제공할지 결정을 내려야 합니다.
- **확인된 증상 또는 목표**: 완료 화면은 항상 `voice1.aac`를 업로드합니다([breath_accept_finish_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/page/breath_accept_finish_page.dart#L186)). Provider는 파일 업로드 후 `breath-voice`를 호출합니다([breath_provider.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath/provider/breath_provider.dart#L239)). 모델도 `voice_file`을 가집니다([accept_response_param.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/model/accept_response_param.dart#L10)). 상세 화면은 저장된 `filePath`를 바로 재생합니다([accept_detail_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/page/accept_detail_page.dart#L226)).
- **관련 코드 파일**: [breath_accept_finish_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/page/breath_accept_finish_page.dart#L186), [breath_accept_cubit.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/cubit/breath_accept_cubit.dart#L16), [breath_provider.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath/provider/breath_provider.dart#L239), [accept_detail_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/page/accept_detail_page.dart#L87)
- **간접 영향 파일**: [breath_accept_dol.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/model/breath_accept_dol.dart#L5), [Info.plist](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/ios/Runner/Info.plist#L103)
- **원인 가설 또는 구현 쟁점**: 입김 감지가 목표라면 현재 계약은 개인정보 범위와 UX 기대가 맞지 않습니다. 요약 메트릭만 남길지, 아예 저장하지 않을지에 따라 서버/상세/권한 문구가 함께 갈라집니다.
- **추천 접근 방식**: `breath-voice`와 분리된 계약 또는 로컬 PoC가 맞습니다. 초기에는 `duration_ms`, `peak/confidence`, `pass/fail`, `device_mode` 정도만 저장 후보로 두는 편이 안전합니다.
- **대안 접근 방식**: 서버 저장 없이 세션 완료 이벤트만 익명 수집하고, 상세보기는 만들지 않습니다.
- **확인 필요**: 원시 오디오 저장 허용 여부, 법무/개인정보 검토, 새 기능도 과거 수용호흡 히스토리에 들어가야 하는지.

### 4. 공통 리스크 및 의존성
| 리스크 | 심각도 | 설명 | 영향 범위 |
| --- | --- | --- | --- |
| 기존 오디오 상태 결함 | 높음 | 리스너 누수, 타이머 정리 누락, 상태 emit 불일치가 이미 보임 | 재생/미리듣기/감지 전반 |
| 스피커 재유입 | 높음 | 영상 볼륨, 녹음 음성 재생, 진동 타이밍이 감지와 충돌 가능 | `breathAcceptPlay`, 실기기 정확도 |
| 플랫폼 편차 | 높음 | Android 입력 소스/AEC/NS/AGC 편차를 현재 코드가 제어하지 않음 | Android 실기기 전체 |
| 제품 의미 충돌 | 중간 | 현재 수용호흡은 “내 목소리로 위로”에 맞춰져 있음 | 홈 카피, 온보딩, 결제/기획 |
| 서버/상세 결합 | 높음 | `voice_file` 없는 새 모드는 기존 저장/상세 재생 모델과 안 맞음 | API, 상세, 히스토리 |
| 인트로/실서비스 중복 구현 | 중간 | `RecWidget`/`AccetpRecWidget`, `PlayWidget`/`PlayBreathWidget`가 분리돼 있어 수정 범위가 넓음 | 인트로, 메인 플로우 |
| 테스트 공백 | 높음 | 확인된 테스트가 기본 샘플 1개뿐임 | 회귀 방어 전반 |

### 5. 다음 라운드 검증 포인트
- `record` 진폭 스트림만으로 현재 앱의 영상/음성 재생 환경에서 날숨을 분리할 수 있는지 실기기 로그로 검증해야 합니다.
- Android에서 어떤 입력 소스가 최선인지 확정되지 않았습니다. `default`/`voice communication`/`unprocessed` 비교가 필요합니다.
- 새 기능을 기존 `수용호흡`에 넣을지, 별도 모드로 뺄지 제품 결정을 받아야 합니다.
- 원시 오디오를 저장하지 않는다면 현재 `breath-voice` 계약과 상세 재생 화면을 그대로 재사용할 수 없습니다.
- Round 1에서 빠졌던 `BreathVoiceCubit` 미리듣기 리스너 누수와 `PlayBreathWidget`의 `late Timer` 위험은 반박보다 선행 수정 후보로 봐야 합니다.
- `BreathAcceptMsgPage`는 라우트만 있고 비어 있습니다([breath_accept_msg_page.dart](/Users/pcs/Library/Mobile%20Documents/com~apple~CloudDocs/2026년%20상반기/dolomood-app/lib/feature/samatha/breath_accept/ui/page/breath_accept_msg_page.dart#L25)). 새 단계 추가 위치로 쓰기 전에 실제 사용 여부를 다시 검증해야 합니다.

이번 라운드는 코드 대조 중심 분석입니다. 실기기 오디오 검증과 패키지 API 적합성 실험은 아직 수행하지 않았습니다.
--- Round 2 Gemini 비판적 검토 ---
먼저 이전 라운드 분석에서 제시된 주요 파일들의 실제 상태를 코드 레벨에서 교차 검증하고, 날숨 감지 구현을 위한 핵심 제약 사항을 비판적으로 검토하겠습니다.

### 1. 사실 관계 검증 및 코드 분석

`fm_audio_session.dart`의 Android 처리 루틴, `BreathPlayCubit`의 리스너 누수 의혹, 그리고 `PlayBreathWidget`의 상태 관리 방식을 직접 확인하겠습니다.

**실행 명령:** `fm_audio_session.dart`, `breath_play_cubit.dart`, `play_breath_widget.dart` 파일의 핵심 로직을 읽어 이전 라운드의 주장이 맞는지 확인합니다.

이전 라운드의 분석은 **매우 정확하며, 실제 코드 상의 결함은 예상보다 더 심각함**을 확인했습니다. 특히 `FmAudioSession`의 Android 방치와 `BreathPlayCubit`의 스트림 리스너 누적은 단순한 "주의" 수준이 아니라, 실시간 호흡 감지 기능을 도입하기 전 **반드시 해결해야 할 기술적 부채**입니다.

### 1. 총평
- **이전 라운드 분석 신뢰도:** **매우 높음**
- **한 줄 요약:** Android 오디오 세션 설정 부재와 UI/Cubit 간의 잘못된 결합(Side-effect in build)으로 인해, 현재 구조에 바로 호흡 감지를 추가하는 것은 사상누각임.

### 2. 사실 검증 결과
| 항목 | 이전 주장 | 검증 결과 | 근거 |
| :--- | :--- | :--- | :--- |
| **Android 오디오 설정** | 사실상 비어 있음 | **사실** | `fm_audio_session.dart`의 모든 설정이 `if (Platform.isAndroid) return;`으로 차단됨. |
| **Cubit 리스너 누수** | `listen()`이 중복 등록됨 | **사실** | `onBreathPlayInhale` 호출 시마다 `processingStateStream.listen`이 새로 생성됨. |
| **위젯 부수 효과** | `build` 내에서 상태 전이 발생 | **사실** | `PlayBreathWidget.build` 내에서 `widget.isPause` 비교 및 Cubit 메서드 직접 호출 확인. |

### 3. 누락 또는 오류 (비판적 관점)
- **누락된 위험 요소:** `PlayBreathWidget`의 `builder` 내부에서 `context.read<BreathPlayCubit>().onBreathPlayInhale()`을 호출하고 있습니다. 이는 리빌드 시마다 오디오 재생 명령이 중복 전달될 수 있는 치명적인 설계 오류입니다.
- **빠진 호출 경로:** `VibrateInteractionCubit`이 호흡 단계(Inhale/Exhale)와 강하게 결합되어 있는데, 날숨 감지 성공 시 진동 피드백을 어떻게 동기화할지에 대한 구체적인 인터페이스 정의가 누락되었습니다.

### 4. 수정안 재평가

#### **항목 1. 상태 관리 및 생명주기 정상화 (P0)**
- **이전 수정안의 문제점:** 단순히 "정리"라고 표현했으나, 현재 `build` 내의 로직을 `didUpdateWidget`이나 `BlocListener`로 완전히 옮기는 **구조적 리팩터링**이 필요합니다.
- **더 안전한 대안:** `StreamSubscription`을 Cubit 멤버 변수로 관리하고, `close()`에서 반드시 취소하도록 강제해야 합니다.
- **남는 리스크:** 기존 영상 재생(`onPlayVideo`)과의 타이밍 충돌.

#### **항목 2. 날숨 감지 엔진 (P0)**
- **이전 수정안의 문제점:** `record`의 `amplitude` 스트림을 추천했으나, Android의 `UNPROCESSED` 소스를 쓰려면 `record` 패키지의 설정만으로는 부족할 수 있습니다.
- **더 단순한 대안:** 초기 PoC에서는 `record`의 `onAmplitudeChanged`를 쓰되, **Moving Average 필터**를 Cubit이 아닌 별도 `DetectionEngine` 클래스로 분리하여 순수 로직만 테스트 가능하게 만들어야 합니다.
- **핵심 리스크:** **에코(Echo) 현상**. 가이드 음성이 나올 때 마이크가 이를 날숨으로 오판할 확률이 90% 이상입니다. (AEC 설정 필수)

### 5. 우선순위 재정렬
| 작업 항목 | 기존 우선순위 | 제안 우선순위 | 근거 |
| :--- | :--- | :--- | :--- |
| **오디오 엔진 리팩터링** | P0 | **P0 (필수 선행)** | 현재의 누수 구조에서는 실시간 스트림 처리가 불가능함. |
| **Android Audio Session 설정** | P0 | **P0 (필수 선행)** | `VOICE_COMMUNICATION` 모드 없이는 에코 제거(AEC)가 안 됨. |
| **날숨 판정 알고리즘 PoC** | P0 | **P1** | 엔진이 안정화된 후 임계치(Threshold) 튜닝이 의미 있음. |

### 6. 다음 라운드 강제 반영 사항
1. **Side-effect 제거:** `PlayBreathWidget`의 `build` 메서드 내 Cubit 호출 로직을 제거하고 `BlocListener`로 이관하는 계획을 포함할 것.
2. **Android 세션 복구:** `audio_session` 패키지를 사용하여 Android에서도 `VOICE_COMMUNICATION` 또는 `SPEECH` 모드가 활성화되도록 `FmAudioSession`을 수정할 것.
3. **에코 대책:** 가이드 음성 재생 시 마이크 입력을 일시적으로 무시하거나(Ducking), 하드웨어 AEC를 강제하는 방안을 기술할 것.

이제 구체적인 구현을 위해 `record` 패키지의 진폭 스트림 활용 가능성과 `AudioSession`의 Android 최적 설정을 조사하겠습니다.

이전 라운드 분석을 비판적으로 검토한 결과, **현재 앱의 오디오 상태 관리와 Android 설정은 날숨 감지 기능을 수용하기에 매우 불안정한 상태**임이 확인되었습니다. 단순한 기능 추가가 아니라, **기반 공사(리팩터링)가 선행되어야 하는 기술적Directive**로 판단됩니다.

### 1. 사실 검증 결과 요약
- **Android 오디오 세션 방치:** `FmAudioSession`은 Android에서 아무런 설정을 하지 않습니다. 이 상태로는 하드웨어 에코 제거(AEC)나 노이즈 억제를 제어할 수 없습니다.
- **메모리 누수 및 상태 불일치:** `BreathPlayCubit`은 호출 시마다 스트림 리스너를 중복 생성하며, `PlayBreathWidget`은 `build` 메서드 안에서 Cubit 명령을 직접 호출하는 심각한 안티 패턴을 보이고 있습니다.
- **도구 준비 상태:** `record: ^6.2.0` 패키지가 이미 존재하므로 실시간 진폭(`onAmplitudeChanged`) 추출은 가능하나, 현재는 단순 파일 녹음용으로만 쓰이고 있습니다.

---

### 2. 비판적 수정안 및 구현 전략

#### **[Step 1] 오디오 기반 인프라 정상화 (선행 필수)**
현재의 리스너 누수와 Android 설정 부재를 해결하지 않고 호흡 감지를 넣으면, 감지기가 멈추지 않거나 앱이 비정상 종료될 위험이 큽니다.
- **FmAudioSession 수정:** Android에서 `AudioSessionConfiguration.speech()` 또는 `voiceCommunication()`을 설정하여 하드웨어 AEC를 활성화해야 합니다. (스피커 소리가 마이크로 재유입되어 호흡으로 오판하는 것 방지)
- **Cubit 리팩터링:** `StreamSubscription`을 멤버 변수로 관리하고, `close()` 시 반드시 `cancel()` 하도록 수정합니다.
- **Widget 리팩터링:** `build` 내의 `context.read()` 호출을 제거하고, `BlocListener`를 통해 상태 전이(Inhale -> Hold -> Exhale)를 제어해야 합니다.

#### **[Step 2] 날숨 감지 엔진 (Detection Engine) 설계**
단순히 "소리가 크다"가 아니라 **"바람이 마이크에 부딪히는 에너지"**를 찾아야 합니다.
- **알고리즘:** `Moving Average`를 사용하여 배경 소음을 보정(Baseline)하고, 급격한 진폭 상승 후 일정 시간 유지될 때만 "날숨"으로 판정하는 **Hysteresis Threshold** 방식을 추천합니다.
- **Ducking/Mute:** 날숨 감지 구간(Exhale)에서는 가이드 음성의 볼륨을 자동으로 낮추거나 음소거하여 감지 정확도를 높여야 합니다.

#### **[Step 3] 예외 케이스 및 유저 불편 대응 (아이디어)**
사용자가 겪을 수 있는 현실적인 문제들과 그 해결책입니다.
1.  **케이스 간섭:** 폰 케이스가 하단 마이크를 가린 경우 -> "마이크 주변을 확인해주세요" 가이드 노출.
2.  **이어폰 사용:** 이어폰 마이크는 입 근처에 없어 감지가 안 됨 -> 유선/무선 이어폰 연결 시 감지 기능을 비활성화하거나 수동 모드로 전환 제안.
3.  **주변 소음:** 선풍기, 카페 소음 -> 0.5~1초간 주변 소음을 측정하여 동적으로 임계치를 설정하는 **Auto-Calibration** 단계 추가.
4.  **피로도:** 6초 이상 내쉬는 것은 유저에게 힘들 수 있음 -> 감지 실패 시 "버튼으로 완료"할 수 있는 **Fallback UI** 필수.

---

### 3. 최종 우선순위 보드

| 우선순위 | 작업 항목 | 이유 |
| :--- | :--- | :--- |
| **P0** | **Android 오디오 세션 및 Cubit 누수 수정** | 기능 동작의 안정성 보장 (Crash 방지) |
| **P0** | **실시간 진폭 기반 날숨 감지 로직 구현** | 핵심 기능 (record 패키지 활용) |
| **P1** | **에코/노이즈 유입 방지 (Ducking)** | 오탐지(False Positive) 방지 |
| **P1** | **감지 실패 시 수동 완료 UI** | UX 단절 방지 및 접근성 보장 |

### 4. 다음 단계 제언
다음 라운드에서는 `record` 패키지의 `onAmplitudeChanged` 스트림을 구독하여 `ExhaleDetector` 클래스를 구현하고, 이를 기존 `BreathPlayCubit`과 어떻게 조율할지에 대한 **구체적인 코드 명세**를 작성하겠습니다. 특히 `PlayBreathWidget`의 `build` 내 부수 효과를 제거하는 리팩터링이 동시에 진행되어야 합니다.
