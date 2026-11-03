import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';

import '../../data/db_helper.dart';
import '../../services/notification_service.dart';
import '../../services/settings_service.dart';

/// 设置页 —— 提醒天数（联动重排）、通知权限引导、测试提醒、关于
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _remindDays = SettingsService.defaultRemindDays;

  /// 通知权限状态：null = 检测中
  bool? _notifEnabled;
  bool _rescheduling = false;

  @override
  void initState() {
    super.initState();
    _load();
    _checkPermission();
  }

  Future<void> _load() async {
    final days = await SettingsService.instance.remindDays();
    if (mounted) setState(() => _remindDays = days);
  }

  Future<void> _checkPermission() async {
    try {
      final enabled = await NotificationService.instance.areNotificationsEnabled();
      if (mounted) setState(() => _notifEnabled = enabled);
    } catch (_) {
      if (mounted) setState(() => _notifEnabled = null);
    }
  }

  /// 保存提醒天数并联动重排全部提醒（PRD F5）
  Future<void> _saveDays(int days) async {
    await SettingsService.instance.setRemindDays(days);
    setState(() {
      _remindDays = days;
      _rescheduling = true;
    });
    try {
      final records = await DbHelper.instance.getAllRecords();
      await NotificationService.instance.rescheduleAll(records, days);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已按「到期前 $days 天」重排全部提醒')),
        );
      }
    } catch (e) {
      debugPrint('重排提醒失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('重排提醒失败，请重试')),
        );
      }
    } finally {
      if (mounted) setState(() => _rescheduling = false);
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      await NotificationService.instance.sendTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('测试提醒已排队，约 10 秒后弹出。若未弹出，请检查上方通知权限'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('测试提醒失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('测试提醒发送失败，请检查通知权限')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifOn = _notifEnabled == true;
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('提醒',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          ListTile(
            title: const Text('到期前提醒天数'),
            subtitle: Text('到期前 $_remindDays 天推送提醒'),
            trailing: _rescheduling
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : DropdownButton<int>(
                    value: _remindDays,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 天')),
                      DropdownMenuItem(value: 3, child: Text('3 天')),
                      DropdownMenuItem(value: 7, child: Text('7 天')),
                      DropdownMenuItem(value: 15, child: Text('15 天')),
                    ],
                    onChanged: (v) {
                      if (v != null) _saveDays(v);
                    },
                  ),
          ),
          ListTile(
            title: const Text('通知权限'),
            subtitle: Text(
              _notifEnabled == null
                  ? '检测中…'
                  : notifOn
                      ? '已开启，到期提醒可正常推送'
                      : '未开启 —— 所有到期提醒将静默丢失！',
              style: TextStyle(
                color: (_notifEnabled == false)
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            ),
            trailing: TextButton(
              onPressed: () async {
                if (_notifEnabled == false) {
                  await AppSettings.openAppSettings(
                      type: AppSettingsType.notification);
                } else {
                  await NotificationService.instance.requestPermissions();
                }
                if (mounted) _checkPermission();
              },
              child: Text(_notifEnabled == false ? '去系统设置' : '重新检测'),
            ),
          ),
          ListTile(
            title: const Text('发送测试提醒'),
            subtitle: const Text('10 秒后推送一条测试通知，验证提醒链路是否正常'),
            trailing: const Icon(Icons.notifications_active_outlined),
            onTap: _sendTestNotification,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('关于',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const ListTile(
            title: Text('版本'),
            trailing: Text('0.1.0'),
          ),
          const ListTile(
            title: Text('开源协议'),
            trailing: Text('MIT'),
          ),
          const ListTile(
            title: Text('数据存储'),
            subtitle: Text('全部数据保存在本机 SQLite，不上传任何服务器'),
          ),
        ],
      ),
    );
  }
}
