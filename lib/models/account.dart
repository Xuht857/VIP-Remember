/// 登录账号模型（P2 二期启用；建表先就位）
///
/// 一个用户可能有多个手机号/APP 登录账号，
/// 每条会员记录可关联"该会员用哪个账号开通"。
class Account {
  final int? id;

  /// 昵称，如 "常用手机号"、"小号"
  final String label;

  /// 手机号 / 邮箱 / 自定义标识
  final String identifier;

  /// phone | email | other
  final String type;

  /// 是否为默认账号（默认 = 本机注册手机号）
  final bool isDefault;

  final DateTime createdAt;

  const Account({
    this.id,
    required this.label,
    required this.identifier,
    this.type = 'phone',
    this.isDefault = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'identifier': identifier,
      'type': type,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?,
      label: map['label'] as String,
      identifier: map['identifier'] as String,
      type: map['type'] as String? ?? 'phone',
      isDefault: (map['is_default'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
