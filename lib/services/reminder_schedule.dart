/// 到期提醒调度计算 —— 纯函数，无任何平台/插件依赖，供单测锁定语义。
///
/// 规则（与 PRD F5 一致）：
/// 1. 到期日已过（按日历日比较）→ 返回 null，不再提醒；
/// 2. 常规提醒时刻 = 到期日 - [daysBefore] 天，当天 10:00（设备本地墙钟）；
/// 3. 若常规提醒时刻已过、但记录尚未到期 → 降级为 [now] + 10 秒尽快触发
///    （修复"临期新建记录收不到任何提醒"的静默丢弃问题）。
DateTime? computeReminderInstant({
  required DateTime expiry,
  required int daysBefore,
  required DateTime now,
}) {
  final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
  final today = DateTime(now.year, now.month, now.day);
  if (expiryDay.isBefore(today)) return null;

  // 日历日减法（DateTime 构造器自动归一化，正确处理月末/闰年）
  final scheduled = DateTime(
    expiry.year,
    expiry.month,
    expiry.day - daysBefore,
    10,
  );
  if (scheduled.isBefore(now)) {
    return now.add(const Duration(seconds: 10));
  }
  return scheduled;
}
