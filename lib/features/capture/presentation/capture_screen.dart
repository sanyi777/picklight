import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_assistant/core/theme/app_theme.dart';
import 'package:personal_assistant/features/capture/domain/capture_provider.dart';
import 'package:personal_assistant/features/capture/domain/capture_item_model.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final _textController = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearching = false;
  String _selectedTag = '随想';
  String _searchQuery = '';
  List<CaptureItem> _searchResults = [];
  bool _isSearchLoading = false;

  // Phase 5: preset tag colors
  static const _tagColorOptions = [
    0xFF4A90D9, // blue
    0xFFE67E22, // orange
    0xFF9B59B6, // purple
    0xFF27AE60, // green
    0xFFE74C3C, // red
    0xFFF1C40F, // yellow
    0xFF1ABC9C, // teal
    0xFF95A5A6, // grey
  ];

  @override
  void dispose() {
    _textController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _canSend => _textController.text.trim().isNotEmpty;

  void _submitCapture() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    ref
        .read(captureItemsProvider.notifier)
        .addCaptureItem(CaptureItem(content: text, category: _selectedTag));
    _textController.clear();
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _searchQuery = query;
      _isSearchLoading = true;
    });
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearchLoading = false;
      });
      return;
    }
    await Future.delayed(const Duration(milliseconds: 150));
    if (_searchQuery != query) return;
    final results = await ref
        .read(captureItemsProvider.notifier)
        .searchCaptures(query);
    if (!mounted) return;
    if (_searchQuery != query) return;
    setState(() {
      _searchResults = results;
      _isSearchLoading = false;
    });
  }

  void _showCreateTagDialog() {
    final nameController = TextEditingController();
    int selectedColor = _tagColorOptions[0];

    showCupertinoDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => CupertinoAlertDialog(
          title: const Text('新建标签'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoTextField(
                  controller: nameController,
                  placeholder: '标签名称',
                  autofocus: true,
                  padding: const EdgeInsets.all(10),
                ),
                const SizedBox(height: 16),
                const Text(
                  '选择颜色',
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tagColorOptions.map((c) {
                    final isSelected = c == selectedColor;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: CupertinoColors.label,
                                  width: 2.5,
                                )
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  ref.read(tagProvider.notifier).createTag(name, selectedColor);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTag(Tag tag) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('删除标签「${tag.name}」'),
        content: const Text('已有捕捉项的分类标签不会受影响。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              ref.read(tagProvider.notifier).deleteTag(tag.tagId);
              // Reset selected tag if it was the deleted one
              if (_selectedTag == tag.name) {
                setState(() => _selectedTag = '随想');
              }
              Navigator.pop(ctx);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showStatusSheet(BuildContext context, CaptureItem item) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(
          item.content.length > 30
              ? '${item.content.substring(0, 30)}...'
              : item.content,
        ),
        message: Text('当前状态：${_statusLabel(item.status)}'),
        actions: [
          if (item.status != CaptureStatus.valuable)
            CupertinoActionSheetAction(
              onPressed: () {
                ref
                    .read(captureItemsProvider.notifier)
                    .updateCaptureItemStatus(item.id, CaptureStatus.valuable);
                Navigator.pop(context);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.star_fill,
                    color: CupertinoColors.systemYellow,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text('标记为有价值'),
                ],
              ),
            ),
          if (item.status != CaptureStatus.pending)
            CupertinoActionSheetAction(
              onPressed: () {
                ref
                    .read(captureItemsProvider.notifier)
                    .updateCaptureItemStatus(item.id, CaptureStatus.pending);
                Navigator.pop(context);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.bookmark_fill,
                    color: CupertinoColors.systemOrange,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text('标记为待推进'),
                ],
              ),
            ),
          if (item.status != CaptureStatus.discarded)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                ref
                    .read(captureItemsProvider.notifier)
                    .updateCaptureItemStatus(item.id, CaptureStatus.discarded);
                Navigator.pop(context);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: CupertinoColors.destructiveRed,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text('标记为丢弃'),
                ],
              ),
            ),
          if (item.status != CaptureStatus.unclassified)
            CupertinoActionSheetAction(
              onPressed: () {
                ref
                    .read(captureItemsProvider.notifier)
                    .updateCaptureItemStatus(
                      item.id,
                      CaptureStatus.unclassified,
                    );
                Navigator.pop(context);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.circle,
                    color: CupertinoColors.systemGrey,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text('重置为未分类'),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDefaultAction: true,
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, CaptureItem item) {
    final linkController = TextEditingController();
    final refs = Map<String, dynamic>.from(item.externalRefs ?? {});

    showCupertinoDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => CupertinoAlertDialog(
          title: const Text('编辑捕捉项'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '外部引用',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...refs.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.link,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${e.key}: ${e.value}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.label,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 28,
                          onPressed: () {
                            setDialogState(() => refs.remove(e.key));
                          },
                          child: const Icon(
                            CupertinoIcons.delete,
                            size: 16,
                            color: CupertinoColors.destructiveRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (refs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      '暂无外部引用',
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.systemGrey3,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: linkController,
                  placeholder: '链接或文件路径',
                  padding: const EdgeInsets.all(10),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: (v) {
                    final text = v.trim();
                    if (text.isNotEmpty) {
                      setDialogState(() {
                        refs['ref${refs.length + 1}'] = text;
                      });
                      linkController.clear();
                    }
                  },
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minSize: 28,
                    color: CupertinoColors.systemGrey5,
                    borderRadius: BorderRadius.circular(6),
                    onPressed: () {
                      final text = linkController.text.trim();
                      if (text.isNotEmpty) {
                        setDialogState(() {
                          refs['ref${refs.length + 1}'] = text;
                        });
                        linkController.clear();
                      }
                    },
                    child: const Text('添加', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                final updated = item.copyWith(
                  externalRefs: refs.isEmpty ? null : refs,
                );
                ref
                    .read(captureItemsProvider.notifier)
                    .updateCaptureItem(updated);
                Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(CaptureStatus s) {
    switch (s) {
      case CaptureStatus.valuable:
        return '有价值';
      case CaptureStatus.pending:
        return '待推进';
      case CaptureStatus.discarded:
        return '已丢弃';
      case CaptureStatus.unclassified:
        return '未分类';
    }
  }

  IconData _statusIcon(CaptureStatus s) {
    switch (s) {
      case CaptureStatus.valuable:
        return CupertinoIcons.star_fill;
      case CaptureStatus.pending:
        return CupertinoIcons.bookmark_fill;
      case CaptureStatus.discarded:
        return CupertinoIcons.xmark_circle;
      case CaptureStatus.unclassified:
        return CupertinoIcons.circle;
    }
  }

  Color _statusColor(CaptureStatus s) {
    switch (s) {
      case CaptureStatus.valuable:
        return CupertinoColors.systemYellow;
      case CaptureStatus.pending:
        return CupertinoColors.systemOrange;
      case CaptureStatus.discarded:
        return CupertinoColors.destructiveRed;
      case CaptureStatus.unclassified:
        return CupertinoColors.systemGrey;
    }
  }

  List<CaptureItem> _filteredItems(List<CaptureItem> items) {
    if (_isSearching) return _searchResults;
    return items;
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: CupertinoTextField(
        controller: _searchController,
        placeholder: '搜索捕捉项...',
        prefix: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Icon(
            CupertinoIcons.search,
            size: 20,
            color: CupertinoColors.systemGrey,
          ),
        ),
        suffix: CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 0,
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchQuery = '';
              _searchResults = [];
              _searchController.clear();
            });
          },
          child: const Text(
            '取消',
            style: TextStyle(color: AppColors.primary, fontSize: 15),
          ),
        ),
        onChanged: (v) => _performSearch(v),
        clearButtonMode: OverlayVisibilityMode.editing,
      ),
    );
  }

  /// Phase 5: dynamic tag chip bar
  Widget _buildTagChipBar(List<Tag> tags) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tags.length + 1, // +1 for add button
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          if (index == tags.length) {
            // Add button
            return GestureDetector(
              onTap: _showCreateTagDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: CupertinoColors.systemGrey3,
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.add,
                      size: 16,
                      color: CupertinoColors.secondaryLabel,
                    ),
                    SizedBox(width: 2),
                    Text(
                      '新建',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final tag = tags[index];
          final isSelected = _selectedTag == tag.name;
          final tagColor = Color(tag.color);

          return GestureDetector(
            onTap: () => setState(() => _selectedTag = tag.name),
            onLongPress: () {
              if (!tag.isDefault) {
                _confirmDeleteTag(tag);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? tagColor.withOpacity(0.15)
                    : CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? tagColor : CupertinoColors.systemGrey5,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: tagColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    tag.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? tagColor
                          : CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    final tagsAsync = ref.watch(tagProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 36,
                onPressed: () => setState(() => _isSearching = true),
                child: const Icon(
                  CupertinoIcons.search,
                  size: 22,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoTextField(
                  controller: _textController,
                  placeholder: '记录你的想法...',
                  minLines: 1,
                  maxLines: 4,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  suffix: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 0,
                    onPressed: _canSend ? _submitCapture : null,
                    child: Icon(
                      CupertinoIcons.paperplane_fill,
                      color: _canSend
                          ? AppColors.primary
                          : CupertinoColors.systemGrey3,
                      size: 22,
                    ),
                  ),
                  onSubmitted: (_) => _submitCapture(),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          tagsAsync.when(
            data: (tags) => _buildTagChipBar(tags),
            loading: () => const SizedBox(height: 36),
            error: (_, __) => const SizedBox(height: 36),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final captureAsync = ref.watch(captureItemsProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('捕捉')),
      child: SafeArea(
        child: Column(
          children: [
            _isSearching ? _buildSearchBar() : _buildInputBar(),
            Container(
              height: 1,
              color: CupertinoColors.separator.withOpacity(0.3),
            ),
            Expanded(
              child: captureAsync.when(
                data: (items) {
                  if (_isSearching && _isSearchLoading) {
                    return const Center(child: CupertinoActivityIndicator());
                  }
                  final filtered = _filteredItems(items);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? '没有匹配「$_searchQuery」的内容'
                                : '还没有捕捉任何想法',
                            style: const TextStyle(
                              color: CupertinoColors.secondaryLabel,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollEndNotification &&
                          _scrollController.position.pixels >=
                              _scrollController.position.maxScrollExtent - 50) {
                        ref.read(captureItemsProvider.notifier).loadMore();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final hasRefs =
                            item.externalRefs != null &&
                            item.externalRefs!.isNotEmpty;
                        final tagColor = item.tagColor != null
                            ? Color(item.tagColor!)
                            : AppColors.primary;

                        return Dismissible(
                          key: ValueKey(item.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            return await showCupertinoDialog<bool>(
                              context: context,
                              builder: (ctx) => CupertinoAlertDialog(
                                title: const Text('确认删除'),
                                content: Text(
                                  '确定要删除「${item.content.length > 20 ? "${item.content.substring(0, 20)}..." : item.content}」吗？',
                                ),
                                actions: [
                                  CupertinoDialogAction(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('取消'),
                                  ),
                                  CupertinoDialogAction(
                                    isDestructiveAction: true,
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('删除'),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (_) {
                            ref
                                .read(captureItemsProvider.notifier)
                                .deleteCaptureItem(item.id);
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: CupertinoColors.destructiveRed,
                            child: const Icon(
                              CupertinoIcons.delete,
                              color: CupertinoColors.white,
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () => _showEditDialog(context, item),
                            onLongPress: () => _showStatusSheet(context, item),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    _statusIcon(item.status),
                                    size: 20,
                                    color: _statusColor(item.status),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.content,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: CupertinoColors.label,
                                                ),
                                              ),
                                            ),
                                            if (hasRefs)
                                              const Padding(
                                                padding: EdgeInsets.only(
                                                  left: 6,
                                                ),
                                                child: Icon(
                                                  CupertinoIcons.link,
                                                  size: 14,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            if (item.tagColor != null)
                                              Container(
                                                width: 6,
                                                height: 6,
                                                margin: const EdgeInsets.only(
                                                  right: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: tagColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            Text(
                                              item.category,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: item.tagColor != null
                                                    ? tagColor
                                                    : CupertinoColors
                                                          .secondaryLabel,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                error: (e, _) => Center(
                  child: Text('加载失败', style: TextStyle(color: AppColors.error)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
