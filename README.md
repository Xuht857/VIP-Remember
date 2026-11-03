# member_vault

> 🇨🇳 中文 · [English](#english)

**记住"我在哪些 APP 有会员、什么等级、几时到期、有没有自动续费"的手机备忘录。**

你是不是也经常想不起来自己在网易云音乐、京东、淘宝、百度网盘、哔哩哔哩……开了哪些会员？
到期被自动续费扣款才发现？`member_vault` 帮你把所有会员状态记在一处，到期前提醒你。

## 特性

- 📱 **极简录入**：选应用 → 选到期日 → 两个滑动开关 → 完成，仅 1 个必填项
- 🗂️ **内置应用目录**：预置购物/音视频/网盘/游戏/办公等主流 APP，点选即填
- 🔔 **本地到期提醒**：系统推送，断网也能收到，不依赖任何服务器
- 🔒 **数据本地存储**：SQLite 存手机里，隐私优先，完全离线可用
- 🏷️ **会员状态可视化**：横条列表一目了然——等级、到期日、自动续费徽标
- 🆓 **开源免费**：MIT 协议，欢迎 PR 增补应用目录

## 快速开始

```bash
flutter pub get
flutter run
```

要求：Flutter 3.x stable。

## 为什么手动录入？

很多用户期望"输入手机号一键查所有平台的会员"——很遗憾这**技术上不可行**：
各 APP（网易云、京东、B站……）都是独立孤岛，不存在类似"银联 Findcard"的统一会员查询接口。
任何第三方都无法按手机号反查你在各平台的会员状态。

因此本产品选择**手动录入 + 极致简化交互**这条路：把录入成本压到最低（3 步、1 个必填），
同时用可靠的本地提醒守住核心价值："到期前让我知道"。

详细设计见 [docs/PRD.md](docs/PRD.md)。

## 路线图

- ✅ P1：会员记录 CRUD、应用目录、横条列表、滑动开关录入、本地到期提醒
- 🔜 P2：多登录账号、云同步/备份、统计视图、CSV 导入导出、小程序版

欢迎提交 Issue/PR——尤其是 `lib/data/app_catalog.dart` 的应用目录增补。

## 已知限制（v0.1.0）

- **Android Doze 延迟**：提醒采用 `inexactAllowWhileIdle`（省电友好），深度 Doze 下可能延迟数小时。
  如需严格准点，未来版本可选精确闹钟（需 `SCHEDULE_EXACT_ALARM` 权限与系统授权检查）。
- **iOS 待发通知上限 64 条**：系统硬限制。本应用自动只排**触发时刻最近的 60 条**，
  超出部分在启动/重排时自动裁剪（记录数据不丢失，只是更远的提醒延后到临近时再排）。
- **时区**：调度基于瞬时量（epoch），设备任意时区均在"到期日 - N 天的本地 10:00"触发；
  `tz.local` 显式设为 `Asia/Shanghai`（中国用户为主），仅影响展示。
- **v0.1.0 为预览版**：release 构建暂用 debug 签名，正式发布前将换 release keystore。
- **应用图标**：暂用 Flutter 默认图标，后续补品牌图标。

## License

[MIT](LICENSE)

---

<a name="english"></a>

## English

**A mobile membership logbook — remember which apps you hold memberships in, what tier, when they expire, and whether auto-renew is on.**

- Minimal input: pick an app → pick an expiry date → two toggles → done (only 1 required field)
- Built-in catalog of popular apps (shopping / video / cloud / gaming / productivity)
- Local notifications for expiry reminders — works offline, no server required
- Local-first SQLite storage — your data stays on your phone

Why manual entry? Because "one-tap query all platforms by phone number" is technically
infeasible — there is no central membership registry across apps (unlike UnionPay's
Findcard for bank cards). See [docs/PRD.md](docs/PRD.md) for the full analysis.

License: [MIT](LICENSE)
