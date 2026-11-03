import 'package:shared_preferences/shared_preferences.dart';

/// 应用设置 —— 统一读写 SharedPreferences，避免 key 分散
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _kRemindDaysKey = 'remind_days';
  static const int defaultRemindDays = 3;

  /// 到期前提醒天数（全局配置，PRD F5）
  Future<int> remindDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kRemindDaysKey) ?? defaultRemindDays;
  }

  Future<void> setRemindDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kRemindDaysKey, days);
  }
}
