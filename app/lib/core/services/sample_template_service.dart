import 'dart:io';
import 'package:path/path.dart' as p;

class SampleTemplateService {
  static const sampleContent = '''# 샘플 기획서: 사용자 프로필 화면 개선

## 1. 배경
현재 사용자 프로필 화면에서 다음과 같은 문제가 보고되고 있습니다.

- 프로필 이미지 변경 시 캐시가 갱신되지 않아 이전 이미지가 계속 표시됨
- 닉네임 변경 후 다른 화면에서 이전 닉네임이 잠시 노출됨
- 설정 항목이 한 화면에 모두 나열되어 스크롤이 길어짐

## 2. 요구사항

### 2-1. 프로필 이미지 캐시 문제 해결
- 이미지 변경 즉시 모든 화면에서 새 이미지가 표시되어야 함
- 네트워크 오류 시 이전 이미지를 유지하되 재시도 버튼 제공

### 2-2. 닉네임 동기화
- 닉네임 변경 시 앱 전체에 즉시 반영
- 변경 중 로딩 상태 표시

### 2-3. 설정 화면 구조 개선
- 카테고리별 섹션 분리 (계정, 알림, 표시, 개인정보)
- 각 섹션은 접이식으로 동작
- 자주 사용하는 항목을 상단에 배치

## 3. 기술적 고려사항
- 현재 상태 관리는 Provider 패턴 사용 중
- 이미지 캐시는 cached_network_image 패키지 사용
- API 응답 형식 변경 없이 클라이언트 측에서 해결 필요

## 4. 우선순위
1. 프로필 이미지 캐시 (사용자 불만 가장 많음)
2. 닉네임 동기화 (간헐적 발생)
3. 설정 화면 구조 (UX 개선)
''';

  /// 샘플 Markdown 파일을 임시 디렉터리에 생성하고 경로를 반환
  static Future<String> createSampleFile(String outputDir) async {
    final dir = Directory(outputDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final filePath = p.join(outputDir, 'sample_profile_improvement.md');
    await File(filePath).writeAsString(sampleContent);
    return filePath;
  }
}
