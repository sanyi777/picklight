import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_assistant/features/evening/domain/evening_provider.dart';
import 'package:personal_assistant/features/morning/domain/intention_provider.dart';
import 'package:personal_assistant/features/capture/domain/capture_provider.dart';
import 'package:personal_assistant/features/capture/domain/capture_item_model.dart';
import 'package:personal_assistant/core/theme/app_theme.dart';

class EveningScreen extends ConsumerStatefulWidget {
  const EveningScreen({super.key});

  @override
  ConsumerState<EveningScreen> createState() => _EveningScreenState();
}

class _EveningScreenState extends ConsumerState<EveningScreen> {
  final _reflectionController = TextEditingController();
  final _activityController = TextEditingController();
  final List<String> _actualActivities = [];

  @override
  void dispose() {
    _reflectionController.dispose();
    _activityController.dispose();
    super.dispose();
  }

  String get _todayFormatted {
    final now = DateTime.now();
    const weekDays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return DateFormat('yyyy年M月d日').format(now) +
        ' ${weekDays[now.weekday - 1]}';
  }

  void _addActivity() {
    final text = _activityController.text.trim();
    if (text.isEmpty) return;
    setState(() => _actualActivities.add(text));
    _activityController.clear();
  }

  void _saveLog() {
    final reflection = _reflectionController.text.trim();
    ref
        .read(todayLogProvider.notifier)
        .saveDailyLog(
          actualActivities: _actualActivities,
          reflectionNotes: reflection,
        );
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        content: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.checkmark_seal_fill,
              color: CupertinoColors.activeGreen,
            ),
            SizedBox(width: 8),
            Text('复盘已保存'),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('好的'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final intentionAsync = ref.watch(todayIntentionProvider);
    final captureAsync = ref.watch(captureItemsProvider);
    final logAsync = ref.watch(todayLogProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('复盘')),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date
              Text(
                _todayFormatted,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Deviation Analysis Card
              _buildDeviationCard(intentionAsync),
              const SizedBox(height: 12),

              // Intention section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          CupertinoIcons.sun_max,
                          size: 18,
                          color: CupertinoColors.systemYellow,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '今日意图',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    intentionAsync.when(
                      data: (intention) {
                        if (intention != null) {
                          return Row(
                            children: [
                              Icon(
                                intention.isCompleted
                                    ? CupertinoIcons.checkmark_circle_fill
                                    : CupertinoIcons.circle,
                                color: intention.isCompleted
                                    ? CupertinoColors.activeGreen
                                    : CupertinoColors.systemGrey3,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  intention.intentionText ??
                                      intention.highlight ??
                                      '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: CupertinoColors.label,
                                    decoration: intention.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        return const Text(
                          '今日未设定意图',
                          style: TextStyle(
                            color: CupertinoColors.tertiaryLabel,
                            fontSize: 14,
                          ),
                        );
                      },
                      loading: () => const CupertinoActivityIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Category distribution
              _buildCategoryDistribution(captureAsync),
              const SizedBox(height: 12),

              // Capture stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          CupertinoIcons.lightbulb,
                          size: 18,
                          color: CupertinoColors.systemYellow,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '今日捕捉',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    captureAsync.when(
                      data: (items) {
                        if (items.isEmpty) {
                          return const Text(
                            '今日还没有捕捉任何想法',
                            style: TextStyle(
                              color: CupertinoColors.tertiaryLabel,
                              fontSize: 14,
                            ),
                          );
                        }
                        final total = items.length;
                        final valuable = items
                            .where((i) => i.status == CaptureStatus.valuable)
                            .length;
                        final pending = items
                            .where((i) => i.status == CaptureStatus.pending)
                            .length;
                        final discarded = items
                            .where((i) => i.status == CaptureStatus.discarded)
                            .length;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statItem(
                              '总数',
                              total.toString(),
                              CupertinoColors.label,
                            ),
                            _statItem(
                              '有价值',
                              valuable.toString(),
                              CupertinoColors.systemYellow,
                            ),
                            _statItem(
                              '待推进',
                              pending.toString(),
                              CupertinoColors.systemOrange,
                            ),
                            _statItem(
                              '已丢弃',
                              discarded.toString(),
                              CupertinoColors.destructiveRed,
                            ),
                          ],
                        );
                      },
                      loading: () => const CupertinoActivityIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Actual activities input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          CupertinoIcons.checkmark_alt,
                          size: 18,
                          color: CupertinoColors.systemGreen,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '实际完成',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoTextField(
                            controller: _activityController,
                            placeholder: '今天实际完成了什么？',
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            style: const TextStyle(fontSize: 14),
                            onSubmitted: (_) => _addActivity(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                          onPressed: _addActivity,
                          child: const Text(
                            '添加',
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_actualActivities.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(height: 1, color: CupertinoColors.separator),
                      const SizedBox(height: 8),
                      ..._actualActivities.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Text(
                                '${entry.key + 1}.',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: CupertinoColors.tertiaryLabel,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.value,
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
              const SizedBox(height: 24),

              // Pre-fill log data
              logAsync.when(
                data: (log) {
                  if (log != null) {
                    if (log.reflectionNotes != null &&
                        log.reflectionNotes!.isNotEmpty) {
                      _reflectionController.text = log.reflectionNotes!;
                    }
                    if (log.actualActivities.isNotEmpty &&
                        _actualActivities.isEmpty) {
                      _actualActivities.addAll(log.actualActivities);
                    }
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Reflection input
              CupertinoTextField(
                controller: _reflectionController,
                placeholder: '今天的反思与收获...',
                minLines: 3,
                maxLines: 6,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                onPressed: _saveLog,
                child: const Text('保存复盘'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviationCard(AsyncValue<dynamic> intentionAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.arrow_right_arrow_left,
                size: 18,
                color: CupertinoColors.systemPurple,
              ),
              SizedBox(width: 8),
              Text(
                '意图 vs 实际',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          intentionAsync.when(
            data: (intention) {
              if (intention == null) {
                return const Text(
                  '今日未设定意图，无法对比',
                  style: TextStyle(
                    color: CupertinoColors.tertiaryLabel,
                    fontSize: 14,
                  ),
                );
              }
              final intentionText =
                  intention.intentionText ?? intention.highlight ?? '';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '意图目标：$intentionText',
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.label,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    intention.isCompleted ? '状态：已完成' : '状态：未完成',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: intention.isCompleted
                          ? CupertinoColors.activeGreen
                          : CupertinoColors.systemOrange,
                    ),
                  ),
                ],
              );
            },
            loading: () => const CupertinoActivityIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDistribution(
    AsyncValue<List<CaptureItem>> captureAsync,
  ) {
    return captureAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        final categoryCounts = <String, int>{
          '随想': 0,
          '待办': 0,
          '灵感': 0,
          '笔记': 0,
        };
        for (final item in items) {
          categoryCounts[item.category] =
              (categoryCounts[item.category] ?? 0) + 1;
        }
        final total = items.length;
        if (total == 0) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    CupertinoIcons.chart_pie,
                    size: 18,
                    color: CupertinoColors.systemBlue,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '捕捉分类分布',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Segmented bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      _barSegment(
                        categoryCounts['随想']! / total,
                        CupertinoColors.systemBlue,
                      ),
                      _barSegment(
                        categoryCounts['待办']! / total,
                        CupertinoColors.systemOrange,
                      ),
                      _barSegment(
                        categoryCounts['灵感']! / total,
                        CupertinoColors.systemYellow,
                      ),
                      _barSegment(
                        categoryCounts['笔记']! / total,
                        CupertinoColors.systemGreen,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _legendItem(
                    '随想',
                    categoryCounts['随想']!,
                    CupertinoColors.systemBlue,
                  ),
                  _legendItem(
                    '待办',
                    categoryCounts['待办']!,
                    CupertinoColors.systemOrange,
                  ),
                  _legendItem(
                    '灵感',
                    categoryCounts['灵感']!,
                    CupertinoColors.systemYellow,
                  ),
                  _legendItem(
                    '笔记',
                    categoryCounts['笔记']!,
                    CupertinoColors.systemGreen,
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _barSegment(double fraction, Color color) {
    if (fraction <= 0) return const SizedBox.shrink();
    return Expanded(
      flex: (fraction * 1000).round().clamp(1, 1000),
      child: Container(color: color),
    );
  }

  Widget _legendItem(String label, int count, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label,
          ),
        ),
      ],
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: CupertinoColors.tertiaryLabel,
          ),
        ),
      ],
    );
  }
}
