import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:docx_to_text/docx_to_text.dart';
import 'package:excel/excel.dart';

class FileConverterService {
  /// 지원하는 파일 확장자 목록
  static const supportedExtensions = [
    'md', 'txt', 'csv', 'pdf', 'docx', 'doc', 'xlsx', 'xls',
  ];

  /// 파일 선택기에서 허용할 확장자
  static const pickerExtensions = [
    'md', 'txt', 'csv', 'pdf', 'docx', 'xlsx',
  ];

  /// 확장자가 지원되는지 확인
  static bool isSupported(String path) {
    final ext = p.extension(path).toLowerCase().replaceFirst('.', '');
    return supportedExtensions.contains(ext);
  }

  /// 텍스트로 바로 읽을 수 있는 형식인지
  static bool isTextFormat(String path) {
    final ext = p.extension(path).toLowerCase().replaceFirst('.', '');
    return ['md', 'txt', 'csv'].contains(ext);
  }

  /// 파일을 텍스트(md)로 변환하여 반환
  static Future<ConvertResult> convertToText(String filePath) async {
    final ext = p.extension(filePath).toLowerCase().replaceFirst('.', '');
    final file = File(filePath);

    if (!await file.exists()) {
      return ConvertResult(
        success: false,
        error: '파일이 존재하지 않습니다: $filePath',
      );
    }

    try {
      switch (ext) {
        case 'md':
        case 'txt':
          final content = await file.readAsString();
          return ConvertResult(success: true, content: content);

        case 'csv':
          final content = await file.readAsString();
          return ConvertResult(
            success: true,
            content: _csvToMarkdown(content),
            converted: true,
            originalFormat: 'CSV',
          );

        case 'pdf':
          return await _convertPdf(filePath);

        case 'docx':
        case 'doc':
          return await _convertDocx(filePath);

        case 'xlsx':
        case 'xls':
          return await _convertExcel(filePath);

        default:
          return ConvertResult(
            success: false,
            error: '지원하지 않는 파일 형식입니다: .$ext',
          );
      }
    } catch (e) {
      return ConvertResult(
        success: false,
        error: '파일 변환 중 오류가 발생했습니다: $e',
      );
    }
  }

  /// CSV → Markdown 테이블 변환
  static String _csvToMarkdown(String csvContent) {
    final lines = csvContent.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return csvContent;

    final buf = StringBuffer();
    buf.writeln('# CSV 데이터\n');

    for (var i = 0; i < lines.length; i++) {
      final cells = lines[i].split(',').map((c) => c.trim()).toList();
      buf.writeln('| ${cells.join(' | ')} |');
      if (i == 0) {
        buf.writeln('| ${cells.map((_) => '---').join(' | ')} |');
      }
    }

    return buf.toString();
  }

  /// PDF → 텍스트 변환 (OS 도구 활용)
  static Future<ConvertResult> _convertPdf(String filePath) async {
    try {
      String text = '';

      if (Platform.isWindows) {
        // PowerShell의 iTextSharp 또는 기본 COM을 통한 추출 시도
        final result = await Process.run(
          'powershell',
          ['-Command', '''
\$pdf = [System.IO.File]::ReadAllBytes("$filePath")
\$text = ""
\$content = [System.Text.Encoding]::UTF8.GetString(\$pdf)
# 간단한 스트림 텍스트 추출
\$matches = [regex]::Matches(\$content, '\\(([^)]+)\\)')
foreach(\$m in \$matches) {
  \$val = \$m.Groups[1].Value
  if(\$val.Length -gt 1 -and \$val -notmatch '^[\\\\/<>]') {
    \$text += \$val + " "
  }
}
if(\$text.Trim().Length -eq 0) { Write-Output "PDF_EXTRACT_FAILED" }
else { Write-Output \$text }
'''],
        ).timeout(const Duration(seconds: 30));

        text = (result.stdout as String).trim();
      } else if (Platform.isMacOS) {
        // macOS: mdimport 또는 textutil 사용 불가 → pdftotext 시도
        final result = await Process.run(
          'bash',
          ['-c', 'which pdftotext && pdftotext "$filePath" - || cat "$filePath" | strings'],
        ).timeout(const Duration(seconds: 30));
        text = (result.stdout as String).trim();
      }

      if (text.isEmpty || text == 'PDF_EXTRACT_FAILED') {
        return ConvertResult(
          success: false,
          error: 'PDF에서 텍스트를 추출할 수 없습니다.\n'
              'PDF를 텍스트 에디터에서 직접 복사하거나,\n'
              'md/txt 파일로 변환한 후 다시 시도해주세요.',
        );
      }

      return ConvertResult(
        success: true,
        content: '# PDF 문서\n\n$text',
        converted: true,
        originalFormat: 'PDF',
      );
    } catch (e) {
      return ConvertResult(
        success: false,
        error: 'PDF 변환 실패: $e\n'
            'PDF를 텍스트 에디터에서 직접 복사하거나,\n'
            'md/txt 파일로 변환한 후 다시 시도해주세요.',
      );
    }
  }

  /// DOCX → 텍스트 변환
  static Future<ConvertResult> _convertDocx(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final text = docxToText(bytes);
      if (text.trim().isEmpty) {
        return ConvertResult(
          success: false,
          error: 'DOCX에서 텍스트를 추출할 수 없습니다.',
        );
      }
      return ConvertResult(
        success: true,
        content: '# Word 문서\n\n$text',
        converted: true,
        originalFormat: 'DOCX',
      );
    } catch (e) {
      return ConvertResult(
        success: false,
        error: 'DOCX 변환 실패: $e',
      );
    }
  }

  /// XLSX → Markdown 테이블 변환
  static Future<ConvertResult> _convertExcel(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final buf = StringBuffer();
      buf.writeln('# Excel 문서\n');

      for (final sheetName in excel.tables.keys) {
        final sheet = excel.tables[sheetName]!;
        buf.writeln('## 시트: $sheetName\n');

        for (var rowIdx = 0; rowIdx < sheet.maxRows; rowIdx++) {
          final row = sheet.row(rowIdx);
          final cells = row.map((c) => c?.value?.toString() ?? '').toList();
          buf.writeln('| ${cells.join(' | ')} |');
          if (rowIdx == 0) {
            buf.writeln('| ${cells.map((_) => '---').join(' | ')} |');
          }
        }
        buf.writeln('');
      }

      return ConvertResult(
        success: true,
        content: buf.toString(),
        converted: true,
        originalFormat: 'Excel',
      );
    } catch (e) {
      return ConvertResult(
        success: false,
        error: 'Excel 변환 실패: $e',
      );
    }
  }
}

class ConvertResult {
  final bool success;
  final String? content;
  final String? error;
  final bool converted;
  final String? originalFormat;

  const ConvertResult({
    required this.success,
    this.content,
    this.error,
    this.converted = false,
    this.originalFormat,
  });
}
