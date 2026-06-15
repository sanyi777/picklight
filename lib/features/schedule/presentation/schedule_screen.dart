import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_assistant/core/theme/app_theme.dart';
import 'package:personal_assistant/features/schedule/domain/schedule_item_model.dart';
import 'package:personal_assistant/features/schedule/domain/schedule_provider.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isWeekView = false;
  Map<String, List<ScheduleItem>> _weekData = {};
  bool _weekLoading = false;

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  String get _dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final diff = selected.difference(today).inDays;

    const weekDays = ['一', '二', '三', '四', '五', '六', '日'];
    final wd = weekDays[_selectedDate.weekday - 1];

    if (diff == 0) return '今天 周$wd';
    if (diff == 1) return '明天 周$wd';
    if (diff == -1) return '昨天 周$wd';
    return '${DateFormat('M月d日').format(_selectedDate)} 周$wd';
  }

  String _weekMondayFor(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return DateFormat('yyyy-MM-dd').format(monday);
  }

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  void _loadSchedule() {
    ref.read(scheduleProvider.notifier).loadScheduleForDate(_dateKey);
  }

  Future<void> _loadWeekData() async {
    setState(() => _weekLoading = true);
    final monday = _weekMondayFor(_selectedDate);
    final data = await ref
        .read(scheduleProvider.notifier)
        .loadScheduleForWeek(monday);
    if (!mounted) return;
    setState(() {
      _weekData = data;
      _weekLoading = false;
    });
  }

  void _toggleView() {
    setState(() {
      _isWeekView = !_isWeekView;
      if (_isWeekView) {
        _loadWeekData();
      } else {
        _loadSchedule();
      }
    });
  }

  void _previousDay() {
    setState(
      () => _selectedDate = _selectedDate.subtract(const Duration(days: 1)),
    );
    _loadSchedule();
  }

  void _nextDay() {
    setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
    _loadSchedule();
  }

  void _goToDay(String dateKey) {
    setState(() {
      _selectedDate = DateTime.parse(dateKey);
      _isWeekView = false;
    });
    _loadSchedule();
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    int selectedHour = 9;
    int selectedMinute = 0;
    String selectedPeriod = '上午';

    showCupertinoDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => CupertinoAlertDialog(
          title: const Text('添加日程'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: titleController,
                placeholder: '日程标题',
                autofocus: true,
                padding: const EdgeInsets.all(12),
              ),
              const SizedBox(height: 16),
              const Text(
                '选择时间',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: 0,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (i) {
                          setDialogState(
                            () => selectedPeriod = i == 0 ? '上午' : '下午',
                          );
                        },
                        children: const [
                          Center(
                            child: Text('上午', style: TextStyle(fontSize: 18)),
                          ),
                          Center(
                            child: Text('下午', style: TextStyle(fontSize: 18)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: 9,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (i) {
                          setDialogState(() => selectedHour = i);
                        },
                        children: List.generate(
                          12,
                          (i) => Center(
                            child: Text(
                              i.toString(),
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Center(
                      child: Text(':', style: TextStyle(fontSize: 22)),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: 0,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (i) {
                          setDialogState(() => selectedMinute = i);
                        },
                        children: List.generate(
                          60,
                          (i) => Center(
                            child: Text(
                              i.toString().padLeft(2, '0'),
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                final timeSlot =
                    '$selectedPeriod $selectedHour:${selectedMinute.toString().padLeft(2, '0')}';

                final item = ScheduleItem(
                  date: _dateKey,
                  title: title,
                  timeSlot: timeSlot,
                );

                ref.read(scheduleProvider.notifier).addItem(item);
                Navigator.pop(context);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('日程')),
      child: SafeArea(
        child: Column(
          children: [
            // View toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _isWeekView ? _toggleView : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: _isWeekView
                              ? CupertinoColors.systemGrey6
                              : AppColors.primary,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '日视图',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _isWeekView
                                ? CupertinoColors.secondaryLabel
                                : CupertinoColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isWeekView ? null : _toggleView,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: _isWeekView
                              ? AppColors.primary
                              : CupertinoColors.systemGrey6,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '周视图',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _isWeekView
                                ? CupertinoColors.white
                                : CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Day view controls
            if (!_isWeekView) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.all(8),
                      onPressed: _previousDay,
                      child: const Icon(CupertinoIcons.chevron_left, size: 22),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        setState(() => _selectedDate = DateTime.now());
                        _loadSchedule();
                      },
                      child: Text(
                        _dateLabel,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CupertinoButton(
                      padding: const EdgeInsets.all(8),
                      onPressed: _nextDay,
                      child: const Icon(CupertinoIcons.chevron_right, size: 22),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: CupertinoColors.separator.withOpacity(0.3),
              ),
            ],

            // Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _isWeekView ? _buildWeekView() : _buildDayView(),
              ),
            ),

            // Add button (day view only)
            if (!_isWeekView)
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
                        '添加日程',
                        style: TextStyle(color: CupertinoColors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayView() {
    final scheduleAsync = ref.watch(scheduleProvider);

    return scheduleAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.calendar,
                  size: 48,
                  color: CupertinoColors.systemGrey3,
                ),
                SizedBox(height: 12),
                Text(
                  '暂无日程安排',
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: CupertinoListTile(
                leading: GestureDetector(
                  onTap: () => ref
                      .read(scheduleProvider.notifier)
                      .toggleCompleted(item.id),
                  child: Icon(
                    item.isCompleted
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    color: item.isCompleted
                        ? CupertinoColors.activeGreen
                        : CupertinoColors.systemGrey3,
                    size: 24,
                  ),
                ),
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 16,
                    decoration: item.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: item.isCompleted
                        ? CupertinoColors.secondaryLabel
                        : CupertinoColors.label,
                  ),
                ),
                subtitle: item.timeSlot != null
                    ? Text(
                        item.timeSlot!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      )
                    : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (_, __) => const Center(
        child: Text(
          '加载失败',
          style: TextStyle(color: CupertinoColors.destructiveRed),
        ),
      ),
    );
  }

  Widget _buildWeekView() {
    if (_weekLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    final entries = _weekData.entries.toList();
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          '加载失败',
          style: TextStyle(color: CupertinoColors.destructiveRed),
        ),
      );
    }

    const weekDayNames = ['一', '二', '三', '四', '五', '六', '日'];
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: entries.asMap().entries.map((entry) {
          final colIdx = entry.key;
          final e = entry.value;
          final dateKey = e.key;
          final items = e.value;
          final isToday = dateKey == today;
          final dateObj = DateTime.parse(dateKey);

          return GestureDetector(
            onTap: () => _goToDay(dateKey),
            child: Container(
              width: 130,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isToday
                    ? AppColors.primary.withOpacity(0.08)
                    : CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
                border: isToday
                    ? Border.all(color: AppColors.primary, width: 1.5)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day header
                  Text(
                    '周${weekDayNames[colIdx]}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isToday
                          ? AppColors.primary
                          : CupertinoColors.label,
                    ),
                  ),
                  Text(
                    DateFormat('M/d').format(dateObj),
                    style: const TextStyle(
                      fontSize: 11,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${items.length} 个日程',
                    style: TextStyle(
                      fontSize: 10,
                      color: items.isEmpty
                          ? CupertinoColors.systemGrey3
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Schedule items
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '空闲',
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey3,
                        ),
                      ),
                    )
                  else
                    ...items
                        .take(6)
                        .map(
                          (item) => Container(
                            margin: const EdgeInsets.only(bottom: 3),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                decoration: item.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ),
                  if (items.length > 6)
                    Text(
                      '... 还有${items.length - 6}个',
                      style: const TextStyle(
                        fontSize: 10,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
