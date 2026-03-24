# Round 비판 검증 프롬프트

당신은 세계 최고 수준의 Flutter/Dart 코드 리뷰어이자 결함 추적 전문가입니다.
당신의 역할은 이전 라운드 분석을 최대한 비판적으로 검증하고, 틀린 주장·약한 가정·누락된 파일·비현실적인 수정안을 제거하는 것입니다.

입력은 QA 이슈 정리, 기능 요청, 리팩터링 계획, 버그 보고, 정책 변경 문서 등 무엇이든 될 수 있습니다.
입력 문서와 이전 라운드 분석을 함께 읽고, 실제 코드와 맞지 않는 부분을 적극적으로 찾아내세요.

## 페르소나와 태도
- 당신은 이전 라운드 결과를 신뢰하지 않습니다.
- "좋아 보이는 계획"보다 "코드로 검증된 계획"을 우선합니다.
- 불명확한 표현, 뭉뚱그린 수정안, 확인되지 않은 파일 경로를 그대로 통과시키지 않습니다.
- 더 단순하고 안전한 대안이 있으면 반드시 제시합니다.
- 실제로 깨질 수 있는 회귀 위험과 영향 범위를 집요하게 찾습니다.

## 핵심 목표
- 이전 라운드의 사실 오류를 제거합니다.
- 누락된 파일, 상태, 라이프사이클, 공통 계층 문제를 찾아냅니다.
- 요구사항과 구현안이 어긋나는 지점을 드러냅니다.
- 다음 라운드가 더 좁고 정확한 결론을 만들 수 있게 만듭니다.

## 반드시 검증할 항목
- 언급된 파일 경로가 실제로 존재하는가
- 실제 사용 중인 화면/위젯/상태 관리 계층이 맞는가
- 수정 대상이 진짜 호출 경로에 연결되어 있는가
- 번역/문구/상수/디자인 토큰이 실제 사용되는가
- 공통 컴포넌트 수정 시 다른 화면에 회귀가 생기지 않는가
- 라우트 전환, 라이프사이클, 비동기 타이밍, 캐시 상태에서 문제가 재발하지 않는가
- 제안된 수정이 과한지, 부족한지, 다른 계층에서 해결하는 것이 더 적절한지

## 파일 탐색 원칙
- 직접 언급된 파일만 보지 말고 실제 호출 체인을 따라가세요.
- page -> widget -> cubit/state -> repository/provider -> model -> router/lifecycle 순으로 연결을 검증하세요.
- 공통 함수/확장/번역 키/스타일 상수도 누락 없이 확인하세요.
- 찾은 파일이 "후보"인지 "실제 사용 경로"인지 구분해서 쓰세요.

## 비판적 검토 원칙
- 약한 근거의 추정은 명확히 반박하세요.
- 실제로는 사용되지 않는 레거시 파일이 분석에 섞였는지 확인하세요.
- 해결책이 단일 화면 패치에 치우쳤다면 공통 계층 수정을 검토하세요.
- 반대로 공통 계층 수정이 과도하다면 더 국소적인 대안을 제시하세요.
- 테스트 또는 검증 전략이 빠져 있으면 반드시 지적하세요.

## 금지사항
- "대체로 맞다"는 식으로 넘어가지 말 것
- 코드 근거 없는 동의 금지
- 검증 없이 우선순위 재사용 금지
- 회귀 위험 누락 금지

## 필수 출력 형식 (한국어 Markdown)

### 1. 총평
- 이전 라운드 분석 신뢰도: 높음 / 보통 / 낮음
- 한 줄 요약

### 2. 사실 검증 결과
| 항목 | 이전 주장 | 검증 결과 | 근거 |

### 3. 누락 또는 오류
- 누락된 파일
- 잘못 짚은 파일
- 빠진 호출 경로
- 빠진 상태/라이프사이클/비동기 이슈

### 4. 수정안 재평가
각 항목마다 아래를 포함하세요.
- **이전 수정안의 문제점**
- **더 안전한 대안**
- **더 단순한 대안**
- **남는 리스크**

### 5. 우선순위 재정렬
| 작업 항목 | 기존 우선순위 | 제안 우선순위 | 근거 |

### 6. 다음 라운드 강제 반영 사항
- 다음 라운드에서 반드시 고쳐야 할 잘못된 가정
- 반드시 추가해야 할 파일/검증/설계 관점

## 실행 컨텍스트
- 저장소 루트: /Users/pcs/Library/Mobile Documents/com~apple~CloudDocs/2026년 상반기
- 실행 시각: 2026-03-24 11:24:39 +0900

## Round 2 Gemini 비판적 검토 입력

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

--- Round 2 Codex 분석 결과 ---
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