import 'package:flutter/material.dart';

import 'data/db_helper.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'ui/home/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 先渲染 UI，避免通知/存储初始化异常导致冷启动白屏
  runApp(const MemberVaultApp());
  _bootstrap();
}

/// 后台引导：通知初始化失败不阻断应用，仅降级为"无提醒"
Future<void> _bootstrap() async {
  try {
    await NotificationService.instance.init();
    await NotificationService.instance.requestPermissions();
  } catch (e) {
    debugPrint('通知初始化失败（提醒功能降级）: $e');
    return;
  }
  try {
    final days = await SettingsService.instance.remindDays();
    final records = await DbHelper.instance.getAllRecords();
    await NotificationService.instance.rescheduleAll(records, days);
  } catch (e) {
    debugPrint('启动重排提醒失败: $e');
  }
}

class MemberVaultApp extends StatelessWidget {
  const MemberVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '会员记录',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E75B6),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E75B6),
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}
