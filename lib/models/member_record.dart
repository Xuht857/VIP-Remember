/// 会员记录模型 —— 一个 APP 的会员状态
class MemberRecord {
  final int? id;
  final String appName;
  final String? appIcon;
  final String? category;

  /// 会员等级（如 黑金VIP、普通会员），自由文本
  final String? level;

  /// 到期日 YYYY-MM-DD，允许为空（永久会员/记不清）
  final DateTime? expiresAt;

  /// 是否自动续费
  final bool autoRenew;

  /// 是否开通
  final bool isActive;

  /// 关联登录账号 id（P2，二期启用）
  final int? accountId;

  /// 价格（选填，仅备注用途）
  final double? price;

  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MemberRecord({
    this.id,
    required this.appName,
    this.appIcon,
    this.category,
    this.level,
    this.expiresAt,
    this.autoRenew = false,
    this.isActive = true,
    this.accountId,
    this.price,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 距离到期天数；null 表示无到期日
  int? get daysUntilExpiry {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiresAt!.year, expiresAt!.month, expiresAt!.day);
    return expiry.difference(today).inDays;
  }

  bool get isExpired {
    final d = daysUntilExpiry;
    return d != null && d < 0;
  }

  /// 7 天内即将到期
  bool get isExpiringSoon {
    final d = daysUntilExpiry;
    return d != null && d >= 0 && d <= 7;
  }

  /// 哨兵值：区分"未传参（保留原值）"与"显式传 null（清空字段）"
  static const _unset = Object();

  /// 复制并修改字段。可空字段传 null 表示**清空**，省略表示保留原值。
  MemberRecord copyWith({
    int? id,
    String? appName,
    Object? appIcon = _unset,
    Object? category = _unset,
    Object? level = _unset,
    Object? expiresAt = _unset,
    bool? autoRenew,
    bool? isActive,
    Object? accountId = _unset,
    Object? price = _unset,
    Object? notes = _unset,
  }) {
    return MemberRecord(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      appIcon: identical(appIcon, _unset) ? this.appIcon : appIcon as String?,
      category: identical(category, _unset) ? this.category : category as String?,
      level: identical(level, _unset) ? this.level : level as String?,
      expiresAt: identical(expiresAt, _unset)
          ? this.expiresAt
          : expiresAt as DateTime?,
      autoRenew: autoRenew ?? this.autoRenew,
      isActive: isActive ?? this.isActive,
      accountId:
          identical(accountId, _unset) ? this.accountId : accountId as int?,
      price: identical(price, _unset) ? this.price : price as double?,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'app_name': appName,
      'app_icon': appIcon,
      'category': category,
      'level': level,
      'expires_at': expiresAt?.toIso8601String(),
      'auto_renew': autoRenew ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'account_id': accountId,
      'price': price,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MemberRecord.fromMap(Map<String, dynamic> map) {
    return MemberRecord(
      id: map['id'] as int?,
      appName: map['app_name'] as String,
      appIcon: map['app_icon'] as String?,
      category: map['category'] as String?,
      level: map['level'] as String?,
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'] as String)
          : null,
      autoRenew: (map['auto_renew'] as int? ?? 0) == 1,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      accountId: map['account_id'] as int?,
      price: (map['price'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
