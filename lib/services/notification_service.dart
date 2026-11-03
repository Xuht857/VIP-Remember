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
  /// 只排最近 [iosPendingCap] 条（其余 cancel），预留测试通知等名额，
  /// 同时避免占用远景提醒挤掉临期提醒（见交叉审核 P1-B）。
  static const int iosPendingCap = 60;

  /// 测试通知 id（避免与自增记录 id 冲突）
  static const int testNotificationId = 999999;
  static const int testNotificationImmediateId = 1000000;

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

  /// 通知权限是否已开启（用于设置页引导）。
  /// - Android 13+：取真实开关状态；
  /// - iOS：areNotificationsEnabled 在插件层恒返回 true，改用 checkPermissions
  ///   取真实状态；无法判定时返回 null（UI 显示"检测中…"）。
  Future<bool?> areNotificationsEnabled() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? true;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      try {
        final opts = await ios.checkPermissions();
        // null = 无法判定（保守视为未知，UI 显示"检测中"）
        return opts?.isEnabled;
      } catch (_) {
        return null;
      }
    }
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

  /// 为单条记录在指定 instant 调度提醒（内部共用，不做"是否跳过"判断）。
  Future<void> _scheduleAt(
    MemberRecord record,
    DateTime instant,
    int daysBefore,
  ) async {
    if (record.id == null) return;
    final expiry = record.expiresAt!;
    final now = DateTime.now();
    final nominal = DateTime(
      expiry.year,
      expiry.month,
      expiry.day - daysBefore,
      10,
    );
    // 判定是否为"临期降级触发"（常规提醒点已过、记录未到期）
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
      record.id!,
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

  /// 为一条记录调度到期提醒。
  /// [daysBefore] 提前几天提醒；[allowFallback] 见 computeReminderInstant。
  /// 仅新建/编辑保存时传 allowFallback=true，启动重排/改设置时传 false。
  Future<void> scheduleExpiryReminder(
    MemberRecord record,
    int daysBefore, {
    bool allowFallback = true,
  }) async {
    if (!_initialized) await init();
    if (record.id == null || record.expiresAt == null) return;

    final id = record.id!;
    // 同一记录先取消旧调度，避免重复
    await _plugin.cancel(id);

    if (!record.isActive) return;

    final now = DateTime.now();
    final instant = computeReminderInstant(
      expiry: record.expiresAt!,
      daysBefore: daysBefore,
      now: now,
      allowFallback: allowFallback,
    );
    // null = 已过期 或（allowFallback=false 且常规提醒点已过的临期记录）→ 不提醒
    if (instant == null) return;

    await _scheduleAt(record, instant, daysBefore);
  }

  /// 全量重排（启动时/提醒天数变更后调用）。
  ///
  /// - Android：全部记录均调度。
  /// - iOS：受 64 条待发上限约束，只排触发时刻最近的 [iosPendingCap] 条，
  ///   其余显式 cancel（不在 iOS 上"先排完再裁"，避免最远的被保留、临期的被丢弃，
  ///   见交叉审核 P1-B）。
  /// [allowFallback]：启动重排/改设置默认 false（跳过已过提醒点记录，不补发打扰）。
  Future<void> rescheduleAll(
    List<MemberRecord> records,
    int daysBefore, {
    bool allowFallback = false,
  }) async {
    if (!_initialized) await init();
    final now = DateTime.now();

    // 先取消全部记录相关的旧调度，避免残留
    for (final r in records) {
      if (r.id != null) await _plugin.cancel(r.id!);
    }

    // 计算每条的触发时刻
    final entries = <_PendingEntry>[];
    for (final r in records) {
      if (r.id == null || r.expiresAt == null || !r.isActive) continue;
      final instant = computeReminderInstant(
        expiry: r.expiresAt!,
        daysBefore: daysBefore,
        now: now,
        allowFallback: allowFallback,
      );
      if (instant != null) entries.add(_PendingEntry(r, instant));
    }

    // iOS 上限：只保留触发时刻最近的 iosPendingCap 条，其余 cancel
    if (Platform.isIOS && entries.length > iosPendingCap) {
      entries.sort((a, b) => a.instant.compareTo(b.instant));
      for (final e in entries.skip(iosPendingCap)) {
        if (e.record.id != null) await _plugin.cancel(e.record.id!);
      }
      entries.removeRange(iosPendingCap, entries.length);
    }

    // 统一调度
    for (final e in entries) {
      await _scheduleAt(e.record, e.instant, daysBefore);
    }
  }

  /// 发送测试提醒：立即弹一条（验证 show 通道，不受 Doze/inexact 延迟影响）
  /// + 另排一条 10 秒后的定时通知（验证 zonedSchedule 调度链路）。
  Future<void> sendTestNotification() async {
    if (!_initialized) await init();
    await _plugin.show(
      testNotificationImmediateId,
      '测试提醒（即时）',
      '这是一条立即显示的测试通知，说明通知通道正常',
      _details,
    );
    final when = DateTime.now().add(const Duration(seconds: 10));
    await _plugin.zonedSchedule(
      testNotificationId,
      '测试提醒（定时）',
      '这是一条 10 秒后定时推送的测试通知，验证到期提醒调度链路',
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

/// 待调度条目（记录 + 触发时刻），用于 iOS 上限裁剪排序
class _PendingEntry {
  final MemberRecord record;
  final DateTime instant;
  _PendingEntry(this.record, this.instant);
}
