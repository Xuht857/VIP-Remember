import 'package:flutter/material.dart';

import '../../models/member_record.dart';

/// 横条 —— 一行展示一个应用的图标和会员信息
///
/// ┌──────────────────────────────────────────────┐
/// │ [图标] 网易云音乐  黑金VIP        2027-03-15到期│
/// │        [自动续费]                  [编辑][删除] │
/// └──────────────────────────────────────────────┘
class RecordTile extends StatelessWidget {
  final MemberRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const RecordTile({
    super.key,
    required this.record,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expiryColor = record.isExpired
        ? theme.colorScheme.outline
        : record.isExpiringSoon
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // 图标 / 首字母头像
              _AppIcon(name: record.appName, iconUrl: record.appIcon),
              const SizedBox(width: 12),
              // 名称 + 徽标
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            record.appName,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (record.level != null &&
                            record.level!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              record.level!,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (record.autoRenew) ...[
                          _Badge(
                            label: '自动续费',
                            color: theme.colorScheme.tertiaryContainer,
                            textColor:
                                theme.colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (!record.isActive)
                          _Badge(
                            label: '已关闭',
                            color: theme.colorScheme.surfaceContainerHighest,
                            textColor:
                                theme.colorScheme.onSurfaceVariant,
                          ),
                        if (record.isExpired)
                          _Badge(
                            label: '已过期',
                            color: theme.colorScheme.errorContainer,
                            textColor: theme.colorScheme.onErrorContainer,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // 到期日
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    record.expiresAt == null
                        ? '长期有效'
                        : _fmt(record.expiresAt!),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: expiryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    record.expiresAt == null
                        ? ''
                        : (record.isExpired
                            ? '已过期'
                            : record.daysUntilExpiry == 0
                                ? '今天到期'
                                : '${record.daysUntilExpiry} 天后到期'),
                    style: TextStyle(fontSize: 11, color: expiryColor),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              // 删除
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.delete_outline,
                    size: 19, color: theme.colorScheme.outline),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _AppIcon extends StatelessWidget {
  final String name;
  final String? iconUrl;

  const _AppIcon({required this.name, this.iconUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 44,
        height: 44,
        child: iconUrl != null && iconUrl!.isNotEmpty
            ? Image.network(
                iconUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _letterAvatar(theme),
              )
            : _letterAvatar(theme),
      ),
    );
  }

  Widget _letterAvatar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, color: textColor),
      ),
    );
  }
}
