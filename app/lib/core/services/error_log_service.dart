import 'dart:io';
import 'package:path/path.dart' as p;

class ErrorLogService {
  static final _logDir = p.join(
    Directory.current.path,
    'logs',
  );

  /// 에러를 로그 파일에 저장하고 경로를 반환
  static Future<String> log({
    required String stage,
    required String error,
    String? stdout,
    String? command,
    int? exitCode,
  }) async {
    final dir = Directory(_logDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final now = DateTime.now();
    final timestamp =
        '${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
    final fileName = 'error_${timestamp}_${_sanitize(stage)}.log';
    final filePath = p.join(_logDir, fileName);

    final buf = StringBuffer();
    buf.writeln('=== Orchestration Error Log ===');
    buf.writeln('Time: $now');
    buf.writeln('Stage: $stage');
    if (exitCode != null) buf.writeln('Exit Code: $exitCode');
    if (command != null) {
      buf.writeln('Command: $command');
    }
    buf.writeln('');
    buf.writeln('=== Error ===');
    buf.writeln(error);
    if (stdout != null && stdout.isNotEmpty) {
      buf.writeln('');
      buf.writeln('=== Stdout ===');
      buf.writeln(stdout);
    }

    await File(filePath).writeAsString(buf.toString());
    return filePath;
  }

  /// 최근 에러 로그 파일 경로 반환 (가장 최신 1개)
  static Future<String?> getLatestLogPath() async {
    final dir = Directory(_logDir);
    if (!await dir.exists()) return null;

    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.log'))
        .cast<File>()
        .toList();

    if (files.isEmpty) return null;

    files.sort((a, b) => b.path.compareTo(a.path));
    return files.first.path;
  }

  /// 최근 에러 로그 내용 반환
  static Future<String?> getLatestLog() async {
    final path = await getLatestLogPath();
    if (path == null) return null;
    return File(path).readAsString();
  }

  /// 모든 에러 로그 경로 반환 (최신순)
  static Future<List<String>> getAllLogPaths() async {
    final dir = Directory(_logDir);
    if (!await dir.exists()) return [];

    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.log'))
        .cast<File>()
        .toList();

    files.sort((a, b) => b.path.compareTo(a.path));
    return files.map((f) => f.path).toList();
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static String _sanitize(String s) =>
      s.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣_-]'), '_').toLowerCase();
}
