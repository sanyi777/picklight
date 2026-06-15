import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_assistant/core/theme/app_theme.dart';
import 'package:personal_assistant/features/progress/domain/project_model.dart';
import 'package:personal_assistant/features/progress/domain/project_provider.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  void _showAddDialog() {
    final titleController = TextEditingController();
    int totalUnits = 10;
    String unitLabel = '章';

    showCupertinoDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => CupertinoAlertDialog(
          title: const Text('新建项目'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: titleController,
                placeholder: '项目名称',
                autofocus: true,
                padding: const EdgeInsets.all(12),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: 9,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (i) {
                          setDialogState(() => totalUnits = i + 1);
                        },
                        children: List.generate(
                          100,
                          (i) => Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: 0,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (i) {
                          final labels = ['章', '页', '节', '课', '个', '次'];
                          setDialogState(() => unitLabel = labels[i]);
                        },
                        children: const [
                          Center(
                            child: Text('章', style: TextStyle(fontSize: 18)),
                          ),
                          Center(
                            child: Text('页', style: TextStyle(fontSize: 18)),
                          ),
                          Center(
                            child: Text('节', style: TextStyle(fontSize: 18)),
                          ),
                          Center(
                            child: Text('课', style: TextStyle(fontSize: 18)),
                          ),
                          Center(
                            child: Text('个', style: TextStyle(fontSize: 18)),
                          ),
                          Center(
                            child: Text('次', style: TextStyle(fontSize: 18)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                final project = ProjectProgress(
                  title: title,
                  totalUnits: totalUnits,
                  unitLabel: unitLabel,
                  startDate: DateTime.now().toIso8601String(),
                );
                ref.read(projectProgressProvider.notifier).addProject(project);
                Navigator.pop(ctx);
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(ProjectProgress project) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('删除项目'),
        content: Text('确定要删除「${project.title}」吗？'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              ref
                  .read(projectProgressProvider.notifier)
                  .removeProject(project.projectId);
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectProgressProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('项目')),
      child: SafeArea(
        child: projectsAsync.when(
          data: (projects) {
            if (projects.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.chart_bar_alt_fill,
                      size: 48,
                      color: CupertinoColors.systemGrey3,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '暂无项目',
                      style: TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                    const SizedBox(height: 20),
                    CupertinoButton.filled(
                      onPressed: _showAddDialog,
                      child: const Text('创建第一个项目'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      return _ProjectCard(
                        project: project,
                        onIncrement: () => ref
                            .read(projectProgressProvider.notifier)
                            .incrementProgress(project.projectId),
                        onDecrement: () => ref
                            .read(projectProgressProvider.notifier)
                            .decrementProgress(project.projectId),
                        onMarkCompleted: () => ref
                            .read(projectProgressProvider.notifier)
                            .markCompleted(project.projectId),
                        onRemove: () => _confirmRemove(project),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: CupertinoButton(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: _showAddDialog,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.add,
                          size: 20,
                          color: CupertinoColors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '新建项目',
                          style: TextStyle(color: CupertinoColors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (_, __) => const Center(
            child: Text(
              '加载失败',
              style: TextStyle(color: CupertinoColors.destructiveRed),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectProgress project;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onMarkCompleted;
  final VoidCallback onRemove;

  const _ProjectCard({
    required this.project,
    required this.onIncrement,
    required this.onDecrement,
    required this.onMarkCompleted,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = project.status == 'completed';
    final progressPercent = (project.progress * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Expanded(
                child: Text(
                  project.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 30,
                onPressed: onRemove,
                child: const Icon(
                  CupertinoIcons.delete,
                  size: 18,
                  color: CupertinoColors.systemGrey2,
                ),
              ),
            ],
          ),

          // Progress label
          Text(
            '${project.completedUnits} / ${project.totalUnits} ${project.unitLabel}  ($progressPercent%)',
            style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 8),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: (project.progress * 100).round().clamp(0, 100),
                    child: Container(
                      color: isCompleted
                          ? CupertinoColors.activeGreen
                          : AppColors.primary,
                    ),
                  ),
                  Expanded(
                    flex: ((1 - project.progress) * 100).round().clamp(0, 100),
                    child: Container(color: CupertinoColors.systemGrey4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isCompleted) ...[
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minSize: 30,
                  color: CupertinoColors.systemGrey5,
                  borderRadius: BorderRadius.circular(6),
                  onPressed: project.completedUnits > 0 ? onDecrement : null,
                  child: const Text(
                    '-1',
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.label,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minSize: 30,
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                  onPressed: project.completedUnits < project.totalUnits
                      ? onIncrement
                      : null,
                  child: const Text(
                    '+1',
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minSize: 30,
                  color: CupertinoColors.systemGrey5,
                  borderRadius: BorderRadius.circular(6),
                  onPressed: onMarkCompleted,
                  child: const Text(
                    '完成',
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.label,
                    ),
                  ),
                ),
              ] else ...[
                const Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  size: 20,
                  color: CupertinoColors.activeGreen,
                ),
                const SizedBox(width: 6),
                const Text(
                  '已完成',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.activeGreen,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
