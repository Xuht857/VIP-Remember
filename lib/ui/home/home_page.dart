import 'package:flutter/material.dart';

import '../../data/db_helper.dart';
import '../../models/member_record.dart';
import '../../services/notification_service.dart';
import '../edit/edit_page.dart';
import '../settings/settings_page.dart';
import 'record_tile.dart';

/// 首页 —— 横条列表 + 筛选 + 添加入口
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<MemberRecord> _records = [];
  bool _loading = true;

  /// 加载失败提示（null = 正常）
  String? _loadError;

  /// all | expiring | autoRenew
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final records = await DbHelper.instance.getAllRecords();
      if (!mounted) return;
      setState(() {
        _records = records;
        _loadError = null;
        _loading = false;
      });
    } catch (e) {
      debugPrint('加载会员记录失败: $e');
      if (!mounted) return;
      setState(() {
        _loadError = '加载失败，请下拉或点击重试';
        _loading = false;
      });
    }
  }

  List<MemberRecord> get _filtered {
    switch (_filter) {
      case 'expiring':
        return _records
            .where((r) => r.isExpiringSoon || r.isExpired)
            .toList();
      case 'autoRenew':
        return _records.where((r) => r.autoRenew && r.isActive).toList();
      default:
        return _records;
    }
  }

  Future<void> _delete(MemberRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除记录'),
        content: Text('确定删除「${record.appName}」的会员记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await DbHelper.instance.deleteRecord(record.id!);
    await NotificationService.instance.cancel(record.id!);
    if (mounted) _load();
  }

  Future<void> _openEdit([MemberRecord? record]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditPage(record: record)),
    );
    if (changed == true && mounted) _load();
  }

  /// 列表主体：区分 加载失败 / 空库 / 筛选为空 / 正常 四种状态
  Widget _buildBody(List<MemberRecord> filtered) {
    if (_loadError != null) {
      return _scrollable(
        _ErrorView(message: _loadError!, onRetry: _load),
      );
    }
    if (_records.isEmpty) {
      return _scrollable(_EmptyView(onAdd: () => _openEdit()));
    }
    if (filtered.isEmpty) {
      // 有记录但筛选结果为空 —— 不是"还没有会员记录"
      return _scrollable(
        _FilteredEmptyView(onClear: () => setState(() => _filter = 'all')),
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final record = filtered[index];
        return RecordTile(
          record: record,
          onTap: () => _openEdit(record),
          onDelete: () => _delete(record),
        );
      },
    );
  }

  /// 让空态/错误态也可下拉刷新
  Widget _scrollable(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的会员'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 筛选条
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                _FilterChip(
                  label: '全部',
                  selected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '即将到期',
                  selected: _filter == 'expiring',
                  onTap: () => setState(() => _filter = 'expiring'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '自动续费中',
                  selected: _filter == 'autoRenew',
                  onTap: () => setState(() => _filter = 'autoRenew'),
                ),
              ],
            ),
          ),
          // 列表
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _buildBody(filtered),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEdit(),
        icon: const Icon(Icons.add),
        label: const Text('添加'),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyView({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.card_membership_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          const Text('还没有会员记录',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(
            '点击右下角"添加"，3 步记下你的第一个会员',
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('添加会员'),
          ),
        ],
      ),
    );
  }
}

class _FilteredEmptyView extends StatelessWidget {
  final VoidCallback onClear;
  const _FilteredEmptyView({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_alt_off_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          const Text('没有符合当前筛选的会员',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(
            '换个筛选条件，或查看全部记录',
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('清除筛选'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
