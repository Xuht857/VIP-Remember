import 'package:flutter_test/flutter_test.dart';
import 'package:member_vault/data/app_catalog.dart';
import 'package:member_vault/models/member_record.dart';

void main() {
  group('MemberRecord', () {
    test('daysUntilExpiry / isExpired / isExpiringSoon', () {
      final now = DateTime.now();
      final record = MemberRecord(
        appName: '测试',
        expiresAt: DateTime(now.year, now.month, now.day + 5),
        createdAt: now,
        updatedAt: now,
      );
      expect(record.daysUntilExpiry, 5);
      expect(record.isExpired, false);
      expect(record.isExpiringSoon, true);

      final expired = MemberRecord(
        appName: '测试',
        expiresAt: DateTime(now.year, now.month, now.day - 1),
        createdAt: now,
        updatedAt: now,
      );
      expect(expired.isExpired, true);
      expect(expired.isExpiringSoon, false);

      final noDate = MemberRecord(
        appName: '测试',
        createdAt: now,
        updatedAt: now,
      );
      expect(noDate.daysUntilExpiry, null);
      expect(noDate.isExpired, false);
    });

    test('toMap / fromMap round-trip', () {
      final now = DateTime.now();
      final record = MemberRecord(
        id: 1,
        appName: '网易云音乐',
        category: 'music',
        level: '黑胶VIP',
        expiresAt: DateTime(2027, 3, 15),
        autoRenew: true,
        isActive: true,
        price: 15,
        notes: '年卡',
        createdAt: now,
        updatedAt: now,
      );
      final restored = MemberRecord.fromMap(record.toMap());
      expect(restored.appName, '网易云音乐');
      expect(restored.level, '黑胶VIP');
      expect(restored.autoRenew, true);
      expect(restored.price, 15);
    });

    test('copyWith 可空字段显式置 null，省略则保留原值', () {
      final now = DateTime.now();
      final record = MemberRecord(
        appName: '测试',
        level: '黄金VIP',
        expiresAt: DateTime(2027, 3, 15),
        notes: '备注',
        createdAt: now,
        updatedAt: now,
      );
      // 显式置 null：清空
      final cleared = record.copyWith(expiresAt: null, level: null, notes: null);
      expect(cleared.expiresAt, null);
      expect(cleared.level, null);
      expect(cleared.notes, null);
      // 省略参数：保留
      final kept = record.copyWith(appName: '改名');
      expect(kept.expiresAt, DateTime(2027, 3, 15));
      expect(kept.level, '黄金VIP');
      expect(kept.notes, '备注');
    });
  });

  group('AppCatalog', () {
    test('search by name', () {
      final result = searchCatalog('网易');
      expect(result.any((e) => e.name == '网易云音乐'), true);
    });

    test('search by alias（拼音/首字母/简称）', () {
      expect(searchCatalog('wy163').any((e) => e.name == '网易云音乐'), true);
      expect(searchCatalog('bili').any((e) => e.name == '哔哩哔哩'), true);
      expect(searchCatalog('b站').any((e) => e.name == '哔哩哔哩'), true);
      expect(searchCatalog('pdd').any((e) => e.name == '拼多多'), true);
    });

    test('grouped by category', () {
      final groups = groupCatalogByCategory();
      expect(groups.containsKey('shopping'), true);
      expect(groups.containsKey('video'), true);
      expect(groups['music']!.any((e) => e.name == 'QQ音乐'), true);
    });
  });
}
