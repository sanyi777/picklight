import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_assistant/core/theme/app_theme.dart';
import 'package:personal_assistant/core/services/notification_service.dart';
import 'package:personal_assistant/features/focus/domain/focus_provider.dart';

class _ProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _ProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.strokeWidth = 6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final sweepAngle = 2 * pi * progress;
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweepAngle,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  int _remainingSeconds = 25 * 60;
  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;
  String? _currentSessionId;
  final List<_BrainDumpEntry> _brainDumpEntries = [];
  final _brainDumpController = TextEditingController();

  // Configurable duration
  int _pomodoroMinutes = 25;
  static const _durationPresets = [15, 25, 45, 60];

  int get _totalSecondsFromSelection => _pomodoroMinutes * 60;

  String get _displayTime {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress {
    final total = _totalSecondsFromSelection;
    if (total == 0) return 1.0;
    return 1.0 - (_remainingSeconds / total);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _brainDumpController.dispose();
    super.dispose();
  }

  Future<void> _startTimer() async {
    final sessionId = await ref
        .read(todayFocusSessionsProvider.notifier)
        .startSession();
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _currentSessionId = sessionId;
      _brainDumpEntries.clear();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
          _isRunning = false;
          _onTimerComplete();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = true;
    });
  }

  void _resumeTimer() {
    _startTimerRaw();
  }

  void _startTimerRaw() {
    setState(() => _isRunning = true);
    _isPaused = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
          _isRunning = false;
          _onTimerComplete();
        }
      });
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _remainingSeconds = _totalSecondsFromSelection;
      _currentSessionId = null;
      _brainDumpEntries.clear();
    });
  }

  void _setDuration(int minutes) {
    if (_isRunning || _isPaused) return; // only allow change when idle
    setState(() {
      _pomodoroMinutes = minutes;
      _remainingSeconds = minutes * 60;
    });
  }

  void _addBrainDump() {
    final text = _brainDumpController.text.trim();
    if (text.isEmpty) return;
    final now = DateTime.now();
    final ts =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    setState(() {
      _brainDumpEntries.add(_BrainDumpEntry(timestamp: ts, text: text));
    });
    _brainDumpController.clear();
    if (_currentSessionId != null) {
      ref
          .read(todayFocusSessionsProvider.notifier)
          .addBrainDumpItem(_currentSessionId!, text);
    }
  }

  void _onTimerComplete() {
    HapticFeedback.heavyImpact();
    NotificationService().showFocusComplete();
    final dumpCount = _brainDumpEntries.length;
    final duration = _pomodoroMinutes;
    if (_currentSessionId != null) {
      ref
          .read(todayFocusSessionsProvider.notifier)
          .endSession(_currentSessionId!, durationMinutes: duration);
    }
    final title = dumpCount > 0 ? '专注完成（被打断 $dumpCount 次）' : '专注完成！';
    final content = dumpCount > 0
        ? '恭喜你完成了 $duration 分钟的番茄钟。期间记录了 $dumpCount 条分心事项，休息一下吧。'
        : '恭喜你完成了 $duration 分钟的番茄钟，休息一下吧。';
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _resetTimer();
            },
            child: const Text('好的'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('专注')),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Duration selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _durationPresets.map((minutes) {
                    final isSelected = _pomodoroMinutes == minutes;
                    final isDisabled = _isRunning || _isPaused;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        minSize: 0,
                        borderRadius: BorderRadius.circular(16),
                        color: isSelected
                            ? AppColors.primary
                            : CupertinoColors.systemGrey6,
                        onPressed: isDisabled
                            ? null
                            : () => _setDuration(minutes),
                        child: Text(
                          '${minutes}分',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? CupertinoColors.white
                                : isDisabled
                                ? CupertinoColors.tertiaryLabel
                                : CupertinoColors.label,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Progress ring
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CustomPaint(
                        painter: _ProgressPainter(
                          progress: _progress,
                          color: AppColors.primary,
                          backgroundColor: CupertinoColors.systemGrey5,
                          strokeWidth: 6,
                        ),
                      ),
                    ),
                    Text(
                      _displayTime,
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w200,
                        color: CupertinoColors.label,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '番茄钟 · ${_pomodoroMinutes}分钟',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.secondaryLabel.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 40),

              // Control buttons
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.06),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Row(
                  key: ValueKey<String>(
                    '${_isRunning}_${_isPaused}_$_remainingSeconds',
                  ),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_isRunning && _isPaused)
                      CupertinoButton.filled(
                        onPressed: _resumeTimer,
                        child: const Text('继续'),
                      )
                    else if (!_isRunning)
                      CupertinoButton.filled(
                        onPressed: _remainingSeconds > 0 ? _startTimer : null,
                        child: Text(
                          _remainingSeconds < _totalSecondsFromSelection
                              ? '重新开始'
                              : '开始专注',
                        ),
                      )
                    else
                      CupertinoButton(
                        color: CupertinoColors.systemOrange,
                        borderRadius: BorderRadius.circular(24),
                        onPressed: _pauseTimer,
                        child: const Text(
                          '暂停',
                          style: TextStyle(color: CupertinoColors.white),
                        ),
                      ),
                    if (_isRunning || _isPaused) ...[
                      const SizedBox(width: 16),
                      CupertinoButton(
                        padding: const EdgeInsets.all(12),
                        onPressed: _resetTimer,
                        child: const Icon(
                          CupertinoIcons.stop_fill,
                          color: CupertinoColors.systemGrey,
                          size: 24,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Brain dump section (visible when timer is running)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SizeTransition(sizeFactor: animation, child: child),
                  );
                },
                child: _isRunning
                    ? Column(
                        key: const ValueKey('brain_dump'),
                        children: [
                          const SizedBox(height: 28),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '分心记录',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.secondaryLabel,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CupertinoTextField(
                                        controller: _brainDumpController,
                                        placeholder: '走神了？记下来...',
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        style: const TextStyle(fontSize: 14),
                                        onSubmitted: (_) => _addBrainDump(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    CupertinoButton(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(8),
                                      onPressed: _addBrainDump,
                                      child: const Text(
                                        '记录',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: CupertinoColors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_brainDumpEntries.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    height: 1,
                                    color: CupertinoColors.separator,
                                  ),
                                  const SizedBox(height: 8),
                                  ..._brainDumpEntries.map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 3,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.timestamp,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color:
                                                  CupertinoColors.tertiaryLabel,
                                              fontFeatures: [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              entry.text,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: CupertinoColors.label,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 32),

              // Today completed count
              Consumer(
                builder: (context, ref, _) {
                  final sessionsAsync = ref.watch(todayFocusSessionsProvider);
                  return sessionsAsync.when(
                    data: (sessions) {
                      final completed = sessions
                          .where((s) => s.completed)
                          .length;
                      if (completed == 0) return const SizedBox.shrink();
                      return Text(
                        '今日已完成 $completed 个番茄钟',
                        style: const TextStyle(
                          color: CupertinoColors.secondaryLabel,
                          fontSize: 13,
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrainDumpEntry {
  final String timestamp;
  final String text;

  _BrainDumpEntry({required this.timestamp, required this.text});
}
