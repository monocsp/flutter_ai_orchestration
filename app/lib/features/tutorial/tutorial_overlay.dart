import 'dart:ui';
import 'package:flutter/material.dart';

/// A single tutorial step: points at a screen region and shows a balloon.
class TutorialStep {
  final String title;
  final String description;
  final Alignment spotlightAlign;
  final Alignment balloonAlign;
  final double spotlightWidth;
  final double spotlightHeight;

  const TutorialStep({
    required this.title,
    required this.description,
    required this.spotlightAlign,
    required this.balloonAlign,
    this.spotlightWidth = 260,
    this.spotlightHeight = 120,
  });
}

class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onComplete;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < widget.steps.length - 1) {
      _animController.reverse().then((_) {
        setState(() => _currentStep++);
        _animController.forward();
      });
    } else {
      _animController.reverse().then((_) => widget.onComplete());
    }
  }

  void _skip() {
    _animController.reverse().then((_) => widget.onComplete());
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    final size = MediaQuery.of(context).size;

    // Compute spotlight center
    final spotCenter = Offset(
      size.width / 2 + (step.spotlightAlign.x * size.width / 2),
      size.height / 2 + (step.spotlightAlign.y * size.height / 2),
    );
    final spotRect = Rect.fromCenter(
      center: spotCenter,
      width: step.spotlightWidth,
      height: step.spotlightHeight,
    );

    return FadeTransition(
      opacity: _fadeAnim,
      child: Stack(
        children: [
          // Blurred + dimmed background with spotlight cutout
          Positioned.fill(
            child: CustomPaint(
              painter: _SpotlightPainter(spotRect: spotRect),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // Spotlight border
          Positioned(
            left: spotRect.left - 2,
            top: spotRect.top - 2,
            child: IgnorePointer(
              child: Container(
                width: spotRect.width + 4,
                height: spotRect.height + 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0D9488),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          // Balloon
          _Balloon(
            step: step,
            currentStep: _currentStep,
            totalSteps: widget.steps.length,
            balloonAlign: step.balloonAlign,
            onNext: _next,
            onSkip: _skip,
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect spotRect;

  _SpotlightPainter({required this.spotRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    // Full screen path with spotlight hole
    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final innerPath = Path()
      ..addRRect(RRect.fromRectAndRadius(spotRect, const Radius.circular(12)));
    final combinedPath =
        Path.combine(PathOperation.difference, outerPath, innerPath);
    canvas.drawPath(combinedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.spotRect != spotRect;
}

class _Balloon extends StatelessWidget {
  final TutorialStep step;
  final int currentStep;
  final int totalSteps;
  final Alignment balloonAlign;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _Balloon({
    required this.step,
    required this.currentStep,
    required this.totalSteps,
    required this.balloonAlign,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = currentStep == totalSteps - 1;

    return Align(
      alignment: balloonAlign,
      child: Container(
        margin: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step counter
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${currentStep + 1}/$totalSteps',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 24),
                    foregroundColor: Colors.grey.shade500,
                  ),
                  child: const Text('건너뛰기', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Title
            Text(
              step.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            // Description
            Text(
              step.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade300,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            // Next button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isLast ? '시작하기' : '다음',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Default tutorial steps for the setup view
List<TutorialStep> get setupTutorialSteps => const [
      TutorialStep(
        title: '사이드 메뉴',
        description:
            '[+] 버튼을 눌러 새 오케스트레이션을 만들 수 있습니다.\n아래에 진행 중인 오케스트레이션 목록이 표시됩니다.',
        spotlightAlign: Alignment(-0.96, -0.5),
        balloonAlign: Alignment(-0.4, -0.3),
        spotlightWidth: 56,
        spotlightHeight: 200,
      ),
      TutorialStep(
        title: '기준 문서 가져오기',
        description:
            'Markdown 파일을 드래그하거나 클릭해서 분석할 기준 문서를 가져오세요.\n기본 템플릿이 제공되니 바로 시작해볼 수도 있습니다.',
        spotlightAlign: Alignment(-0.62, -0.55),
        balloonAlign: Alignment(-0.2, 0.0),
        spotlightWidth: 280,
        spotlightHeight: 120,
      ),
      TutorialStep(
        title: '오케스트레이션 설정',
        description:
            '프리셋, 분석/검토 Agent, 실행 목적, 비판 강도 등을 선택하세요.\n기본값이 채워져 있으니 그대로 사용해도 됩니다.',
        spotlightAlign: Alignment(-0.62, 0.1),
        balloonAlign: Alignment(0.0, 0.3),
        spotlightWidth: 280,
        spotlightHeight: 200,
      ),
      TutorialStep(
        title: '단계 편집기',
        description:
            '5단계 오케스트레이션의 각 단계를 확인하고 수정할 수 있습니다.\n활성화/비활성화 토글로 원하는 단계만 실행할 수 있습니다.',
        spotlightAlign: Alignment(0.0, 0.0),
        balloonAlign: Alignment(0.3, 0.5),
        spotlightWidth: 350,
        spotlightHeight: 250,
      ),
      TutorialStep(
        title: '오케스트레이션 시작',
        description:
            '설정이 끝나면 "오케스트레이션 시작" 버튼을 누르세요.\n단계별 프롬프트가 생성되고, 진행 상황을 스레드로 확인할 수 있습니다.',
        spotlightAlign: Alignment(-0.62, 0.7),
        balloonAlign: Alignment(0.0, 0.0),
        spotlightWidth: 280,
        spotlightHeight: 60,
      ),
    ];
