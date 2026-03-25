import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/workbench/workbench_screen.dart';

class OrchestratorApp extends StatelessWidget {
  const OrchestratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Orchestration Workbench',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const WorkbenchScreen(),
    );
  }
}
