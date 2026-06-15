import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_assistant/core/theme/app_theme.dart';
import 'package:personal_assistant/features/morning/domain/intention_provider.dart';
import 'package:personal_assistant/features/focus/domain/focus_provider.dart';

class MorningScreen extends ConsumerStatefulWidget {
  const MorningScreen({super.key});

  @override
  ConsumerState<MorningScreen> createState() => _MorningScreenState();
}

class _MorningScreenState extends ConsumerState<MorningScreen> {
  final _intentionController = TextEditingController();

  @override
  void dispose() {
    _intentionController.dispose();
    super.dispose();
  }

  String get _todayFormatted {
    final now = DateTime.now();
    final weekDays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return DateFormat('yyyy年M月d日').format(now) +
        ' ${weekDays[now.weekday - 1]}';
  }

  void _setIntention() {
    final text = _intentionController.text.trim();
    if (text.isEmpty) return;
    ref
        .read(todayIntentionProvider.notifier)
        .setTodayIntention(highlight: text, intentionText: text);
    _intentionController.clear();
  }

  void _toggleCompletion() {
    ref.read(todayIntentionProvider.notifier).toggleCompletion();
  }

  @override
  Widget build(BuildContext context) {
    final intentionAsync = ref.watch(todayIntentionProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('晨间')),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date display
              Text(
                _todayFormatted,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Intention section
              intentionAsync.when(
                data: (intention) {
                  if (intention != null) {
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A90D9).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '今日意图',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: CupertinoColors.secondaryLabel,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (intention.isCompleted)
                                    const Icon(
                                      CupertinoIcons.checkmark_seal_fill,
                                      color: CupertinoColors.activeGreen,
                                      size: 20,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                intention.intentionText ??
                                    intention.highlight ??
                                    '',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: CupertinoColors.label,
                                  decoration: intention.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                minSize: 0,
                                onPressed: _toggleCompletion,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      intention.isCompleted
                                          ? CupertinoIcons.arrow_uturn_left
                                          : CupertinoIcons.checkmark_circle,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      intention.isCompleted ? '撤销完成' : '标记完成',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Option to set new intention
                        CupertinoButton(
                          padding: const EdgeInsets.all(12),
                          onPressed: () {
                            setState(() {
                              // Re-show input by clearing intention via re-enter flow
                            });
                            _showEditIntentionDialog();
                          },
                          child: const Text(
                            '修改今日意图',
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // No intention set — show input
                  return Column(
                    children: [
                      const Icon(
                        CupertinoIcons.sun_max,
                        size: 48,
                        color: CupertinoColors.systemYellow,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '晨间简报',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                      ),
                      const SizedBox(height: 24),
                      CupertinoTextField(
                        controller: _intentionController,
                        placeholder: '今天最重要的一件事是什么？',
                        minLines: 1,
                        maxLines: 3,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSubmitted: (_) => _setIntention(),
                      ),
                      const SizedBox(height: 16),
                      CupertinoButton.filled(
                        onPressed: _intentionController.text.trim().isNotEmpty
                            ? _setIntention
                            : null,
                        child: const Text('设定今日意图'),
                      ),
                    ],
                  );
                },
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                error: (e, _) => Center(
                  child: Text('加载失败', style: TextStyle(color: AppColors.error)),
                ),
              ),

              const SizedBox(height: 48),

              // Meditation entry
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.waveform_path_ecg,
                      color: CupertinoColors.systemPurple,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '晨间冥想',
                            style: TextStyle(
                              fontSize: 15,
                              color: CupertinoColors.label,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '3 分钟 · 呼吸引导',
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      minSize: 0,
                      color: CupertinoColors.systemPurple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      onPressed: _startMeditation,
                      child: const Text(
                        '开始',
                        style: TextStyle(
                          color: CupertinoColors.systemPurple,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditIntentionDialog() {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('修改意图'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            controller: controller,
            placeholder: '今天最重要的一件事是什么？',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                ref
                    .read(todayIntentionProvider.notifier)
                    .setTodayIntention(highlight: text, intentionText: text);
              }
              Navigator.pop(context);
            },
            isDefaultAction: true,
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _startMeditation() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _MeditationDialog(
        onComplete: () {
          ref
              .read(todayFocusSessionsProvider.notifier)
              .startSession(type: 'meditation')
              .then((sessionId) {
                ref
                    .read(todayFocusSessionsProvider.notifier)
                    .endSession(sessionId, durationMinutes: 3);
              });
        },
      ),
    );
  }
}

class _MeditationDialog extends StatefulWidget {
  final VoidCallback onComplete;

  const _MeditationDialog({required this.onComplete});

  @override
  State<_MeditationDialog> createState() => _MeditationDialogState();
}

class _MeditationDialogState extends State<_MeditationDialog>
    with TickerProviderStateMixin {
  static const _totalSeconds = 3 * 60;
  int _remainingSeconds = _totalSeconds;
  Timer? _timer;
  late final AnimationController _breathController;
  int _breathPhase = 0; // 0=inhale, 1=hold, 2=exhale

  String get _displayTime {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _breathPrompt {
    switch (_breathPhase) {
      case 0:
        return '吸气…';
      case 1:
        return '屏息…';
      case 2:
        return '呼气…';
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          // Switch breath phase every 4 seconds (4-4-4 cycle)
          final elapsed = _totalSeconds - _remainingSeconds;
          _breathPhase = (elapsed ~/ 4) % 3;
        } else {
          _timer?.cancel();
          _breathController.stop();
          Navigator.of(context).pop();
          widget.onComplete();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: CupertinoAlertDialog(
        title: const Text(
          '冥想引导 · 3 分钟',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: 260,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              // Breathing circle
              AnimatedBuilder(
                animation: _breathController,
                builder: (context, child) {
                  final scale = 0.6 + (_breathController.value * 0.4);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            CupertinoColors.systemPurple.withOpacity(
                              0.3 + _breathController.value * 0.3,
                            ),
                            CupertinoColors.systemPurple.withOpacity(0.1),
                          ],
                        ),
                        border: Border.all(
                          color: CupertinoColors.systemPurple.withOpacity(0.6),
                          width: 3,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              // Breath prompt
              Text(
                _breathPrompt,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: CupertinoColors.systemPurple,
                ),
              ),
              const SizedBox(height: 12),
              // Timer
              Text(
                _displayTime,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w200,
                  color: CupertinoColors.label,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              _timer?.cancel();
              _breathController.stop();
              Navigator.of(context).pop();
            },
            child: const Text(
              '结束',
              style: TextStyle(color: CupertinoColors.systemGrey),
            ),
          ),
        ],
      ),
    );
  }
}
