import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_assistant/core/database/database_provider.dart';
import 'package:personal_assistant/core/theme/app_theme.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Map<String, List<Map<String, dynamic>>> _results = {};
  bool _loading = false;
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = {};
        _searched = false;
      });
      return;
    }
    setState(() => _loading = true);
    final db = ref.read(databaseProvider);
    final results = await db.globalSearch(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
      _searched = true;
    });
  }

  void _navigateToTab(int index) {
    Navigator.of(context).pop(index);
  }

  String _truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen)}...';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: SizedBox(
          height: 36,
          child: CupertinoTextField(
            controller: _controller,
            autofocus: true,
            placeholder: '搜索捕捉、日程、意图、项目...',
            style: const TextStyle(fontSize: 16),
            onChanged: _search,
            onSubmitted: _search,
            clearButtonMode: OverlayVisibilityMode.editing,
          ),
        ),
        trailing: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            '取消',
            style: TextStyle(fontSize: 16, color: AppColors.primary),
          ),
        ),
      ),
      child: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (!_searched) {
      return const Center(
        child: Text(
          '输入关键词开始搜索',
          style: TextStyle(color: CupertinoColors.secondaryLabel, fontSize: 15),
        ),
      );
    }

    final totalCount = _results.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );
    if (totalCount == 0) {
      return const Center(
        child: Text(
          '未找到相关结果',
          style: TextStyle(color: CupertinoColors.secondaryLabel, fontSize: 15),
        ),
      );
    }

    final sections = <_ResultSection>[];

    if (_results['captures']?.isNotEmpty ?? false) {
      sections.add(
        _ResultSection(
          icon: CupertinoIcons.lightbulb,
          title: '捕捉 (${_results['captures']!.length})',
          color: const Color(0xFFFF9500),
          items: _results['captures']!,
          tabIndex: 0,
          titleKey: 'content',
          subtitleKey: 'category',
        ),
      );
    }
    if (_results['schedules']?.isNotEmpty ?? false) {
      sections.add(
        _ResultSection(
          icon: CupertinoIcons.calendar,
          title: '日程 (${_results['schedules']!.length})',
          color: const Color(0xFF007AFF),
          items: _results['schedules']!,
          tabIndex: 1,
          titleKey: 'title',
          subtitleKey: 'date',
        ),
      );
    }
    if (_results['intentions']?.isNotEmpty ?? false) {
      sections.add(
        _ResultSection(
          icon: CupertinoIcons.sun_max,
          title: '意图 (${_results['intentions']!.length})',
          color: const Color(0xFFFFCC00),
          items: _results['intentions']!,
          tabIndex: 2,
          titleKey: 'intention_text',
          subtitleKey: 'date',
        ),
      );
    }
    if (_results['projects']?.isNotEmpty ?? false) {
      sections.add(
        _ResultSection(
          icon: CupertinoIcons.chart_bar_alt_fill,
          title: '项目 (${_results['projects']!.length})',
          color: const Color(0xFF34C759),
          items: _results['projects']!,
          tabIndex: 5,
          titleKey: 'title',
          subtitleKey: 'status',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, sectionIndex) {
        final section = sections[sectionIndex];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  children: [
                    Icon(section.icon, size: 14, color: section.color),
                    const SizedBox(width: 6),
                    Text(
                      section.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: section.color,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: CupertinoColors.separator.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: section.items.map((item) {
                    final title = _truncate(
                      item[section.titleKey]?.toString() ?? '(空)',
                      60,
                    );
                    final subtitle =
                        item[section.subtitleKey]?.toString() ?? '';
                    return CupertinoListTile(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      title: Text(title, style: const TextStyle(fontSize: 15)),
                      subtitle: subtitle.isNotEmpty
                          ? Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            )
                          : null,
                      onTap: () => _navigateToTab(section.tabIndex),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ResultSection {
  final IconData icon;
  final String title;
  final Color color;
  final List<Map<String, dynamic>> items;
  final int tabIndex;
  final String titleKey;
  final String subtitleKey;

  _ResultSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.items,
    required this.tabIndex,
    required this.titleKey,
    required this.subtitleKey,
  });
}
