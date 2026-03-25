import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownViewer extends StatelessWidget {
  final String content;

  const MarkdownViewer({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFA),
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              Icon(Icons.visibility_outlined,
                  size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(
                'Markdown 미리보기',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.copy, size: 14, color: Colors.grey.shade400),
                tooltip: '복사',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('클립보드에 복사되었습니다'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: Container(
            color: Colors.white,
            child: Markdown(
              data: content,
              selectable: true,
              padding: const EdgeInsets.all(16),
              styleSheet: MarkdownStyleSheet(
                h1: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  height: 1.6,
                ),
                h2: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  height: 1.6,
                ),
                h3: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                  height: 1.5,
                ),
                p: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  height: 1.7,
                ),
                listBullet: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                ),
                code: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  backgroundColor: const Color(0xFFF1F5F9),
                  color: const Color(0xFF0D9488),
                ),
                codeblockDecoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                tableHead: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
                tableBody: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF334155),
                ),
                tableBorder: TableBorder.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
