import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/member_record.dart';
import 'reminder_schedule.dart';

/// 到期提醒服务 —— 系统本地推送，无需联网
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// iOS 系统对待发通知有 64 条硬上限（插件 README 明示），
  /// 只排最近 [iosPendingCap] 条，预留测试通知等名额。
  static const int iosPendingCap = 60;

  /// 测试通知 id（避免与自增记录 id 冲突）
  static const int testNotificationId = 999999;

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    tzdata.initializeTimeZones();
    // 防御性设置本地时区：调度链路基于瞬时量（epoch），不依赖 tz.local；
    // 但 timezone 包默认 tz.local=UTC，墙钟构造/展示场景会偏移 8 小时，
    // 故显式设置。本产品以中国用户为主，固定 Asia/Shanghai，失败保持 UTC 兜底。
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    } catch (_) {/* 保持 UTC；不影响瞬时量调度 */}
    _initialized = true;
  }

  /// 请求通知权限（iOS 首次/Android 13+）
  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// 通知权限是否已开启（Android 13+ 可被用户拒绝；iOS 同理）
  Future<bool> areNotificationsEnabled() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? true;
    }
    // iOS：无法可靠查询时默认视为开启（首次请求会弹系统框）
    return true;
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'member_expiry',
      '会员到期提醒',
      channelDescription: '会员即将到期或自动续费扣款前提醒',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// 为一条记录调度到期提醒
  /// [daysBefore] 提前几天提醒
  Future<void> scheduleExpiryReminder(
    MemberRecord record,
    int daysBefore,
  ) async {
    if (!_initialized) await init();
    if (record.id == null || record.expiresAt == null) return;

    final id = record.id!;
    // 同一记录先取消旧调度，避免重复
    await _plugin.cancel(id);

    if (!record.isActive) return;

    final expiry = record.expiresAt!;
    final now = DateTime.now();
    final instant = computeReminderInstant(
      expiry: expiry,
      daysBefore: daysBefore,
      now: now,
    );
    // null = 已过期，不提醒
    if (instant == null) return;

    // 判定是否为"临期降级触发"（常规提醒点已过、记录未到期）
    final nominal = DateTime(
      expiry.year,
      expiry.month,
      expiry.day - daysBefore,
      10,
    );
    final lateFallback = nominal.isBefore(now);

    final title = record.autoRenew
        ? '${record.appName} 将自动续费'
        : '${record.appName} 即将到期';
    final body = lateFallback
        ? (record.autoRenew
            ? '已临近 ${_fmt(expiry)} 的自动续费扣款，请尽快确认是否关闭'
            : '已临近 ${_fmt(expiry)} 的到期日${record.level != null ? '（${record.level}）' : ''}，请尽快处理')
        : (record.autoRenew
            ? '将于 ${_fmt(expiry)} 自动续费扣款，记得确认是否需要关闭'
            : '将于 ${_fmt(expiry)} 到期${record.level != null ? '（${record.level}）' : ''}');

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(instant, tz.local),
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // payload 携带触发时刻（epoch 毫秒），供 iOS 上限审计裁剪
      payload: instant.millisecondsSinceEpoch.toString(),
    );
  }

  /// 全量重排（启动时/提醒天数变更后调用），并执行 iOS 待发上限审计
  Future<void> rescheduleAll(List<MemberRecord> records, int daysBefore) async {
    if (!_initialized) await init();
    for (final r in records) {
      await scheduleExpiryReminder(r, daysBefore);
    }
    await enforcePendingCap();
  }

  /// iOS 待发通知上限审计：仅保留触发时刻最近的 [iosPendingCap] 条。
  /// （Android 无此上限，不做裁剪，避免多会员用户丢提醒。）
  Future<void> enforcePendingCap() async {
    if (!_initialized) return;
    if (!Platform.isIOS) return;

    final pending = await _plugin.pendingNotificationRequests();
    if (pending.length <= iosPendingCap) return;

    // id -> 触发时刻（epoch ms）；payload 缺失视为最近（保守保留旧数据）
    final keyed = <int, int>{};
    for (final p in pending) {
      keyed[p.id] = int.tryParse(p.payload ?? '') ?? 0;
    }
    final sorted = keyed.keys.toList()
      ..sort((a, b) => keyed[a]!.compareTo(keyed[b]!));
    // 跳过最近的 iosPendingCap 条，取消更远的
    for (final id in sorted.skip(iosPendingCap)) {
      await _plugin.cancel(id);
    }
  }

  /// 发送一条 10 秒后的测试通知（设置页自证提醒链路用）
  Future<void> sendTestNotification() async {
    if (!_initialized) await init();
    final when = DateTime.now().add(const Duration(seconds: 10));
    await _plugin.zonedSchedule(
      testNotificationId,
      '测试提醒',
      '这是一条测试通知，说明到期提醒链路工作正常',
      tz.TZDateTime.from(when, tz.local),
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: when.millisecondsSinceEpoch.toString(),
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
