import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/orchestration_stage.dart';
import '../../core/models/template_preset.dart';
import '../../providers/session_providers.dart';

class StageCard extends ConsumerStatefulWidget {
  final OrchestrationStage stage;
  final int stageIndex;
  final Color color;
  final ValueChanged<OrchestrationStage> onChanged;

  const StageCard({
    super.key,
    required this.stage,
    required this.stageIndex,
    required this.color,
    required this.onChanged,
  });

  @override
  ConsumerState<StageCard> createState() => _StageCardState();
}

class _StageCardState extends ConsumerState<StageCard> {
  String? _templateContent;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isCustom = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController();
    _loadTemplate();
  }

  @override
  void didUpdateWidget(covariant StageCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stage.promptTemplate != widget.stage.promptTemplate ||
        oldWidget.stage.templatePreset != widget.stage.templatePreset ||
        oldWidget.stageIndex != widget.stageIndex) {
      _isEditing = false;
      _loadTemplate();
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplate() async {
    setState(() => _isLoading = true);
    try {
      final stage = widget.stage;
      final configLoader = ref.read(configLoaderProvider);

      // 직접입력이면 customPromptContent 사용
      if (stage.templatePreset == TemplatePreset.custom) {
        if (mounted) {
          setState(() {
            _templateContent = stage.customPromptContent ?? '';
            _isCustom = true;
            _isLoading = false;
            _isEditing = true;
            _editController.text = _templateContent!;
          });
        }
        return;
      }

      final content = await configLoader.loadTemplateForPreset(
          stage.promptTemplate, stage.templatePreset);
      final hasCustom =
          await configLoader.hasCustomTemplate(stage.resolvedTemplateKey);
      if (mounted) {
        setState(() {
          _templateContent = content.isNotEmpty ? content : null;
          _isCustom = hasCustom;
          _isLoading = false;
          if (_templateContent != null) {
            _editController.text = _templateContent!;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _templateContent = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveCustom() async {
    final content = _editController.text;

    if (widget.stage.templatePreset == TemplatePreset.custom) {
      // 직접입력 모드: session state에 저장
      ref.read(sessionProvider.notifier).setStageCustomPrompt(
          widget.stageIndex, content);
    } else {
      // 프리셋 기반 커스텀: 파일로 저장
      final configLoader = ref.read(configLoaderProvider);
      await configLoader.saveCustomTemplate(
          widget.stage.resolvedTemplateKey, content);
    }

    setState(() {
      _templateContent = content;
      _isEditing = false;
      _isCustom = true;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('프롬프트가 저장되었습니다'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _resetToDefault() async {
    final configLoader = ref.read(configLoaderProvider);
    await configLoader.deleteCustomTemplate(widget.stage.promptTemplate);
    _isEditing = false;
    await _loadTemplate();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('기본 템플릿으로 되돌렸습니다'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.stage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${stage.stepNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        stage.role == StageRole.analysis
                            ? '분석 Agent 담당'
                            : '검토 Agent 담당',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: stage.enabled,
                  activeThumbColor: widget.color,
                  onChanged: (v) {
                    widget.onChanged(stage.copyWith(enabled: v));
                  },
                ),
              ],
            ),

            // Description
            if (stage.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  stage.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    height: 1.4,
                  ),
                ),
              ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Stage info
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _infoChip(
                  icon: Icons.output_rounded,
                  label: '출력',
                  value: stage.outputFileName,
                ),
                _infoChip(
                  icon: Icons.article_outlined,
                  label: '템플릿',
                  value: stage.promptTemplate,
                ),
                if (_isCustom)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Text(
                      '커스텀',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // 프롬프트 프리셋 선택
            Row(
              children: [
                const Text(
                  '프롬프트 유형',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: '1단계에서 선택하면 수동 편집하지 않은 나머지 단계도 함께 변경됩니다.',
                  child: Icon(Icons.help_outline_rounded, size: 14, color: Colors.grey.shade400),
                ),
                const Spacer(),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<TemplatePreset>(
                    initialValue: stage.templatePreset,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: TemplatePreset.values.map((preset) {
                      return DropdownMenuItem<TemplatePreset>(
                        value: preset,
                        child: Text(
                          preset.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: preset == TemplatePreset.custom
                                ? const Color(0xFF0D9488)
                                : const Color(0xFF0F172A),
                            fontWeight: preset == TemplatePreset.custom
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (preset) {
                      if (preset == null) return;
                      // 1단계(index 0)에서 변경하면 cascade
                      ref.read(sessionProvider.notifier).setStageTemplatePreset(
                        widget.stageIndex,
                        preset,
                        cascadeFromFirst: widget.stageIndex == 0,
                      );
                      _loadTemplate();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              stage.templatePreset.description,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 12),

            // Template content toolbar
            Row(
              children: [
                const Text(
                  '프롬프트 내용',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const Spacer(),
                if (!_isEditing && _templateContent != null)
                  TextButton.icon(
                    onPressed: () => setState(() => _isEditing = true),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('편집'),
                    style: TextButton.styleFrom(
                      foregroundColor: widget.color,
                      textStyle: const TextStyle(fontSize: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 30),
                    ),
                  ),
                if (_isEditing) ...[
                  TextButton.icon(
                    onPressed: () {
                      _editController.text = _templateContent ?? '';
                      setState(() => _isEditing = false);
                    },
                    icon: const Icon(Icons.close, size: 14),
                    label: const Text('취소'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade500,
                      textStyle: const TextStyle(fontSize: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 30),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: _saveCustom,
                    icon: const Icon(Icons.save, size: 14),
                    label: const Text('저장'),
                    style: TextButton.styleFrom(
                      foregroundColor: widget.color,
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 30),
                    ),
                  ),
                ],
                if (_isCustom && !_isEditing)
                  TextButton.icon(
                    onPressed: _resetToDefault,
                    icon: const Icon(Icons.restore, size: 14),
                    label: const Text('기본값'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade500,
                      textStyle: const TextStyle(fontSize: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 30),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Template content
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _isEditing
                      ? Colors.white
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isEditing
                        ? widget.color
                        : const Color(0xFFE2E8F0),
                    width: _isEditing ? 2 : 1,
                  ),
                ),
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _templateContent != null
                        ? _isEditing
                            ? TextField(
                                controller: _editController,
                                maxLines: null,
                                expands: true,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: Color(0xFF334155),
                                  height: 1.6,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(12),
                                ),
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(12),
                                child: SelectableText(
                                  _templateContent!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: Color(0xFF334155),
                                    height: 1.6,
                                  ),
                                ),
                              )
                        : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info_outline,
                                    size: 24, color: Colors.grey.shade300),
                                const SizedBox(height: 8),
                                Text(
                                  '템플릿 파일을 찾을 수 없습니다',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade400),
                                ),
                                Text(
                                  stage.promptTemplate,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
