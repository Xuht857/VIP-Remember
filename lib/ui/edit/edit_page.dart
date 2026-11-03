import 'package:flutter/material.dart';

import '../../data/app_catalog.dart';
import '../../data/db_helper.dart';
import '../../models/member_record.dart';
import '../../services/notification_service.dart';
import '../../services/settings_service.dart';

/// 添加/编辑页 —— 极简录入
///
/// 流程：点选应用（或自定义）→ 到期日 → [滑动]自动续费 → [滑动]是否开通 → 保存
/// 仅"应用名"必填；等级/金额/备注折叠在选填区。
class EditPage extends StatefulWidget {
  /// 传入为编辑，null 为新建
  final MemberRecord? record;

  const EditPage({super.key, this.record});

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final _nameController = TextEditingController();
  final _levelController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();

  String? _category;
  String? _iconUrl;
  DateTime? _expiresAt;
  bool _autoRenew = false;
  bool _isActive = true;
  bool _showOptional = false;
  bool _saving = false;

  String _catalogQuery = '';

  /// 提醒天数：与设置页联动（SharedPreferences），默认 3 天
  int _remindDays = SettingsService.defaultRemindDays;

  bool get _isEdit => widget.record != null;

  @override
  void initState() {
    super.initState();
    _loadRemindDays();
    final r = widget.record;
    if (r != null) {
      _nameController.text = r.appName;
      _levelController.text = r.level ?? '';
      _priceController.text = r.price?.toString() ?? '';
      _notesController.text = r.notes ?? '';
      _category = r.category;
      _iconUrl = r.appIcon;
      _expiresAt = r.expiresAt;
      _autoRenew = r.autoRenew;
      _isActive = r.isActive;
      _showOptional = r.price != null || (r.notes?.isNotEmpty ?? false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _levelController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRemindDays() async {
    final days = await SettingsService.instance.remindDays();
    if (mounted) setState(() => _remindDays = days);
  }

  void _pickCatalogItem(AppCatalogItem item) {
    setState(() {
      _nameController.text = item.name;
      _category = item.category;
      _iconUrl = item.iconAsset;
      if (_levelController.text.isEmpty && item.defaultLevel != null) {
        _levelController.text = item.defaultLevel!;
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 365)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      helpText: '选择到期日',
    );
    if (picked != null) {
      setState(() => _expiresAt = picked);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先选择或输入应用名称')));
      return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final priceText = _priceController.text.trim();
      final record = MemberRecord(
        id: widget.record?.id,
        appName: name,
        appIcon: _iconUrl,
        category: _category,
        level: _levelController.text.trim().isEmpty
            ? null
            : _levelController.text.trim(),
        expiresAt: _expiresAt,
        autoRenew: _autoRenew,
        isActive: _isActive,
        price: priceText.isEmpty ? null : double.tryParse(priceText),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.record?.createdAt ?? now,
        updatedAt: now,
      );

      final id = _isEdit
          ? (await DbHelper.instance.updateRecord(record), widget.record!.id!).$2
          : await DbHelper.instance.insertRecord(record);

      // 调度到期提醒（调度失败不影响保存结果）
      final saved = record.copyWith(id: id);
      try {
        await NotificationService.instance
            .scheduleExpiryReminder(saved, _remindDays);
      } catch (e) {
        debugPrint('调度到期提醒失败: $e');
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('保存失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('保存失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalogItems = _catalogQuery.isEmpty
        ? kAppCatalog
        : searchCatalog(_catalogQuery);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '编辑会员' : '添加会员'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 第 1 步：选择应用 ──
          const _SectionLabel(text: '1 · 选择应用'),
          if (!_isEdit) ...[
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索应用，如"网易云"…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _catalogQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _catalogQuery = '');
                        },
                      ),
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _catalogQuery = v),
            ),
            const SizedBox(height: 10),
            // 目录网格（点选即填）
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in catalogItems)
                    _CatalogChip(
                      item: item,
                      selected: _nameController.text == item.name,
                      onTap: () => _pickCatalogItem(item),
                    ),
                  if (catalogItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('无匹配，可直接在下方输入自定义名称'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: '应用名称 *',
              hintText: '如：网易云音乐',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 20),

          // ── 第 2 步：到期日 ──
          const _SectionLabel(text: '2 · 到期日'),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _pickDate,
            child: InputDecorator(
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              child: Text(
                _expiresAt == null
                    ? '长期有效 / 记不清（点击选择）'
                    : '${_expiresAt!.year}-${_expiresAt!.month.toString().padLeft(2, '0')}-${_expiresAt!.day.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: _expiresAt == null
                      ? theme.colorScheme.onSurfaceVariant
                      : null,
                ),
              ),
            ),
          ),
          if (_expiresAt != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _expiresAt = null),
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('清除日期'),
              ),
            ),

          const SizedBox(height: 12),

          // ── 第 3 步：两个滑动开关 ──
          const _SectionLabel(text: '3 · 会员状态'),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('是否开通'),
                  subtitle: const Text('关闭表示已退订/暂停'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('自动续费'),
                  subtitle: const Text('开启后到期前提醒你确认是否续费'),
                  value: _autoRenew,
                  onChanged: (v) => setState(() => _autoRenew = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── 选填区（折叠）──
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _showOptional = !_showOptional),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const _SectionLabel(text: '选填信息', padding: EdgeInsets.zero),
                  const Spacer(),
                  Icon(_showOptional
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down),
                ],
              ),
            ),
          ),
          if (_showOptional) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _levelController,
              decoration: InputDecoration(
                labelText: '会员等级',
                hintText: '如：黑金VIP、超级会员',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '价格（仅备注）',
                hintText: '如 15 或 168',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: '备注',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],

          const SizedBox(height: 28),

          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(_isEdit ? '保存修改' : '保存'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;

  const _SectionLabel({required this.text, this.padding = const EdgeInsets.only(bottom: 10)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _CatalogChip extends StatelessWidget {
  final AppCatalogItem item;
  final bool selected;
  final VoidCallback onTap;

  const _CatalogChip({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          item.name,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
