# Fastlane Prod Deploy Plan

## 1) 현재 상태 분석

### 공통
- `deploy` 폴더는 없음. 실제 진입점은 루트 `deploy.sh`.
- 공용 환경변수 파일: `fastlane_env` (iOS/Android Fastfile에서 로드).
- `deploy.sh` 기준 Production 배포는 현재 **iOS만 지원** (`upload_testflight` 호출).

### iOS (`ios/fastlane/Fastfile`)
- Dev 배포 lane: `distribute_dev`
  - `pubspec.yaml` 버전을 `Runner/Info.plist`에 동기화.
  - `build_app` 후 Firebase App Distribution 업로드.
  - Crashlytics dSYM 업로드 포함.
- Prod 배포 lane: `upload_testflight`
  - `pubspec.yaml`에서 버전/빌드 읽어서 `increment_version_number`, `increment_build_number` 실행.
  - `scheme: prod`, `configuration: prod`, `export_method: app-store`.
  - `upload_to_testflight` 실행.

### Android (`android/fastlane/Fastfile`)
- Dev 배포 lane: `distribute_dev`만 존재.
  - `fvm flutter build apk --flavor dev` 후 Firebase App Distribution 업로드.
- Prod 배포 lane 없음.
- Google Play 업로드(`upload_to_play_store/supply`)는 주석 처리된 과거 코드만 존재.

## 2) 확인된 리스크

1. 비밀정보 관리
- `fastlane_env`, `ios/fastlane/env`, `android/fastlane/env`에 계정/토큰/앱 비밀번호 평문 존재.
- 즉시 비밀값 분리(로컬 `.env.local`/CI secret) 및 토큰 재발급 필요.

2. iOS 버전 정책
- App Store 업로드 실패 방지를 위해 `CFBundleShortVersionString`/`CFBundleVersion` 관리 일원화 필요.
- 현재는 `pubspec.yaml` 기반 관리가 맞고, 수동 plist 고정값 충돌 가능성 존재.

3. iOS dSYM 이슈(objective_c.framework)
- native asset(`objective_c.framework`) dSYM 누락 이슈 재발 가능.
- Archive 시 자동 dSYM 생성 단계 유지 필요.

4. Android prod 공백
- 배포 자동화에서 Android production 경로가 없음.
- 현재 스크립트는 prod 선택 시 Android를 명시적으로 막고 있음.

## 3) 권장 운영 플로우 (지금 당장)

### iOS Production 배포 (즉시 가능)
1. 버전 확정: `pubspec.yaml` (`x.y.z+build`) 증가.
2. 사전 빌드:
   - `fvm flutter clean`
   - `fvm flutter pub get`
   - `(cd ios && pod install)`
3. Fastlane 실행:
   - `cd ios`
   - `bundle exec fastlane upload_testflight`
4. App Store Connect에서 TestFlight processing 확인.

### Android Production 배포 (현재 불가, lane 추가 필요)
- 우선 `android_prod_release` lane 신규 작성 후 Play Console internal track부터 적용.

## 4) 구현 계획 (단계별)

### Phase A: iOS prod 안정화 (우선)
- `upload_testflight` lane 실행 전 체크 추가:
  - `scheme/configuration=prod` 유효성.
  - `pubspec.yaml` 버전 포맷/증가 여부.
- dSYM 누락 방지 스크립트 유지 확인.
- 실패 시 재시도 절차(runbook) 문서화.

### Phase B: Android prod lane 신설
- 신규 lane 예시:
  - `build_appbundle_prod` (`fvm flutter build appbundle --flavor prod`)
  - `upload_to_play_store(track: internal)`
- 필요한 값:
  - `json_key_data` 또는 `json_key_file` (Google Play service account)
  - `package_name` (`fm.ai.dolomood` 계열 prod 패키지)
- 첫 배포는 internal track → closed track → production 순차 진행.

### Phase C: 시크릿 분리
- 저장소 평문 제거:
  - `fastlane_env`, `ios/fastlane/env`, `android/fastlane/env`에서 민감정보 제거.
- 로컬/CI 주입 방식으로 변경:
  - 로컬: `.env.local` (gitignore)
  - CI: GitHub Actions/Bitrise secret store
- 이미 노출된 토큰/앱 비밀번호는 즉시 폐기 후 재발급.

### Phase D: 배포 단일 진입점 정리
- `deploy.sh`를 유지하되 아래로 명확화:
  - `prod ios` → `bundle exec fastlane upload_testflight`
  - `prod android` → 신규 lane 호출
- interactive 모드 + non-interactive(CI) 모드 분리.

## 5) 실행 커맨드 제안

### iOS prod 수동 실행
```bash
cd ios
bundle install
bundle exec fastlane upload_testflight
```

### Android prod(신설 후)
```bash
cd android/fastlane
bundle install
bundle exec fastlane deploy_prod
```

## 6) 결론
- 현재 구조에서 **iOS prod(TestFlight) 자동화는 이미 가능**.
- **Android prod는 lane 부재로 미완성**.
- 먼저 iOS 안정화 + 시크릿 분리, 이후 Android prod lane 추가가 최적 순서.
