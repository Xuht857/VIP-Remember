import 'package:flutter_test/flutter_test.dart';
import 'package:member_vault/services/reminder_schedule.dart';

void main() {
  group('computeReminderInstant', () {
    // 固定参照时间，避免用 DateTime.now() 导致测试不确定
    final now = DateTime(2027, 3, 10, 9);

    test('正常：到期前 N 天 10:00 触发', () {
      final t = computeReminderInstant(
        expiry: DateTime(2027, 3, 15),
        daysBefore: 3,
        now: now,
      );
      expect(t, DateTime(2027, 3, 12, 10));
    });

    test('daysBefore=0：到期日当天 10:00 触发', () {
      final t = computeReminderInstant(
        expiry: DateTime(2027, 3, 15),
        daysBefore: 0,
        now: now,
      );
      expect(t, DateTime(2027, 3, 15, 10));
    });

    test('已过点 fallback：常规提醒点已过、未到期 → 尽快触发（now+10s）', () {
      final t = computeReminderInstant(
        expiry: DateTime(2027, 3, 12), // 2 天后到期
        daysBefore: 3, // 提醒点 = 3 月 9 日 10:00，已过
        now: now,
      );
      expect(t, isNotNull);
      expect(t!, now.add(const Duration(seconds: 10)));
    });

    test('临期新建：明天到期也降级为尽快触发，不再静默丢弃', () {
      final t = computeReminderInstant(
        expiry: DateTime(2027, 3, 11),
        daysBefore: 3,
        now: now,
      );
      expect(t, now.add(const Duration(seconds: 10)));
    });

    test('已过期：返回 null 不提醒', () {
      final t = computeReminderInstant(
        expiry: DateTime(2027, 3, 9),
        daysBefore: 3,
        now: now,
      );
      expect(t, null);
    });

    test('今天到期：未过期，降级为尽快触发', () {
      final t = computeReminderInstant(
        expiry: DateTime(2027, 3, 10),
        daysBefore: 3,
        now: now,
      );
      expect(t, now.add(const Duration(seconds: 10)));
    });

    test('月末归一：3 月 1 日 - 5 天 = 2 月 24 日', () {
      final t = computeReminderInstant(
        expiry: DateTime(2027, 3, 1),
        daysBefore: 5,
        now: DateTime(2027, 2, 20, 9),
      );
      expect(t, DateTime(2027, 2, 24, 10));
    });

    test('闰年：2028-03-01 - 1 天 = 2028-02-29', () {
      final t = computeReminderInstant(
        expiry: DateTime(2028, 3, 1),
        daysBefore: 1,
        now: DateTime(2028, 2, 20, 9),
      );
      expect(t, DateTime(2028, 2, 29, 10));
    });

    test('平年二月：2027-03-01 - 1 天 = 2027-02-28', () {
      final t = computeReminderInstant(
        expiry: DateTime(2027, 3, 1),
        daysBefore: 1,
        now: DateTime(2027, 2, 20, 9),
      );
      expect(t, DateTime(2027, 2, 28, 10));
    });

    test('跨天：提醒日与到期日不同天', () {
      final t = computeReminderInstant(
        expiry: DateTime(2027, 4, 1),
        daysBefore: 7,
        now: DateTime(2027, 3, 1, 8),
      );
      expect(t, DateTime(2027, 3, 25, 10));
      expect(t!.day, 25);
    });

    test('年末跨月：1 月 3 日 - 5 天 = 上一年 12 月 29 日', () {
      final t = computeReminderInstant(
        expiry: DateTime(2028, 1, 3),
        daysBefore: 5,
        now: DateTime(2027, 12, 20, 9),
      );
      expect(t, DateTime(2027, 12, 29, 10));
    });

    test('allowFallback=false（启动重排/改设置）：已过提醒点但未过期 → 返回 null 跳过', () {
      // 会员 2 天后到期（在 3 天窗口内），常规提醒点(3/9 10:00)已过。
      // 若此时冷启动 rescheduleAll(allowFallback=false) 仍返回 now+10s，
      // 用户每次打开 App 都会被补发一条"即将到期"——这正是 P1-A 要消除的打扰。
      final t = computeReminderInstant(
        expiry: DateTime(2027, 3, 12),
        daysBefore: 3,
        now: now,
        allowFallback: false,
      );
      expect(t, null);
    });

    test('allowFallback 默认 true：与显式 true 行为一致（尽快触发）', () {
      final tDefault = computeReminderInstant(
        expiry: DateTime(2027, 3, 12),
        daysBefore: 3,
        now: now,
      );
      final tTrue = computeReminderInstant(
        expiry: DateTime(2027, 3, 12),
        daysBefore: 3,
        now: now,
        allowFallback: true,
      );
      expect(tDefault, now.add(const Duration(seconds: 10)));
      expect(tTrue, now.add(const Duration(seconds: 10)));
    });
  });
}
