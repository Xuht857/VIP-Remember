/// 内置应用目录 —— 覆盖主流购物/音视频/网盘/游戏/办公/生活类 APP
///
/// 设计说明：
/// - 点选即填 [MemberRecord.appName] / [category]，降低录入成本；
/// - 图标策略：优先内置 assets（后续可逐步补），暂以首字母头像兜底；
/// - [alias] 为搜索别名（拼音/首字母/简称），提升模糊命中率；
/// - 社区可 PR 增补本目录（见 docs/PRD.md 第 6 节）。
class AppCatalogItem {
  final String name;

  /// shopping | video | music | cloud | game | office | life
  final String category;

  /// 预置等级文案（可空，用户可改）
  final String? defaultLevel;

  /// assets 图标路径（预留，为空则用字母头像）
  final String? iconAsset;

  /// 搜索别名：拼音全拼/首字母/常用简称（空格分隔），提升"记不全名字"时的命中率
  final String? alias;

  const AppCatalogItem({
    required this.name,
    required this.category,
    this.defaultLevel,
    this.iconAsset,
    this.alias,
  });
}

/// 分类展示名
const Map<String, String> kCategoryLabels = {
  'shopping': '购物',
  'video': '视频',
  'music': '音乐',
  'cloud': '网盘',
  'game': '游戏',
  'office': '办公',
  'life': '生活',
};

/// 内置应用目录
const List<AppCatalogItem> kAppCatalog = [
  // ── 购物 ──
  AppCatalogItem(
      name: '京东PLUS',
      category: 'shopping',
      defaultLevel: 'PLUS会员',
      alias: 'jd jingdong jdplus'),
  AppCatalogItem(
      name: '淘宝88VIP',
      category: 'shopping',
      defaultLevel: '88VIP',
      alias: 'tb taobao 88vip'),
  AppCatalogItem(name: '拼多多', category: 'shopping', alias: 'pdd pinduoduo'),
  AppCatalogItem(
      name: '亚马逊Prime',
      category: 'shopping',
      defaultLevel: 'Prime会员',
      alias: 'ymx yamaxun amazon prime'),
  AppCatalogItem(
      name: '苏宁易购', category: 'shopping', alias: 'sn suning'),
  AppCatalogItem(
      name: '唯品会', category: 'shopping', alias: 'wph vip vipshop'),

  // ── 视频 ──
  AppCatalogItem(
      name: '哔哩哔哩',
      category: 'video',
      defaultLevel: '大会员',
      alias: 'bili bilibili b站 bzhan'),
  AppCatalogItem(
      name: '爱奇艺',
      category: 'video',
      defaultLevel: '黄金VIP',
      alias: 'iqiyi aiqiyi'),
  AppCatalogItem(
      name: '腾讯视频',
      category: 'video',
      defaultLevel: 'VIP',
      alias: 'txsp tengxunshipin tencentvideo'),
  AppCatalogItem(
      name: '优酷', category: 'video', defaultLevel: '黄金VIP', alias: 'yk youku'),
  AppCatalogItem(
      name: '芒果TV', category: 'video', defaultLevel: '全屏会员', alias: 'mgtv mangguo'),
  AppCatalogItem(name: 'Netflix', category: 'video', alias: 'nflx'),
  AppCatalogItem(name: 'Disney+', category: 'video', alias: 'disney disneyplus'),
  AppCatalogItem(
      name: 'YouTube Premium', category: 'video', alias: 'yt youtube premium'),

  // ── 音乐 ──
  AppCatalogItem(
      name: '网易云音乐',
      category: 'music',
      defaultLevel: '黑胶VIP',
      alias: 'wy wy163 wangyiyun netease'),
  AppCatalogItem(
      name: 'QQ音乐',
      category: 'music',
      defaultLevel: '豪华绿钻',
      alias: 'qqyinyue qqmusic'),
  AppCatalogItem(
      name: '酷狗音乐',
      category: 'music',
      defaultLevel: '豪华VIP',
      alias: 'kg kugou'),
  AppCatalogItem(name: '酷我音乐', category: 'music', alias: 'kw kuwo'),
  AppCatalogItem(name: 'Apple Music', category: 'music', alias: 'applemusic apple'),
  AppCatalogItem(name: 'Spotify', category: 'music', alias: 'spotify'),

  // ── 网盘 ──
  AppCatalogItem(
      name: '百度网盘',
      category: 'cloud',
      defaultLevel: '超级会员',
      alias: 'bdwp baiduwangpan baidu'),
  AppCatalogItem(name: '阿里云盘', category: 'cloud', alias: 'alyp aliyunpan'),
  AppCatalogItem(name: '腾讯微云', category: 'cloud', alias: 'txwy weiyun'),
  AppCatalogItem(name: 'iCloud+', category: 'cloud', alias: 'icloud'),
  AppCatalogItem(name: 'OneDrive', category: 'cloud', alias: 'onedrive'),
  AppCatalogItem(name: 'Google One', category: 'cloud', alias: 'googleone google'),
  AppCatalogItem(name: 'Dropbox', category: 'cloud', alias: 'dropbox'),

  // ── 游戏 ──
  AppCatalogItem(name: '腾讯游戏', category: 'game', alias: 'txyx tencentgame'),
  AppCatalogItem(name: '网易游戏', category: 'game', alias: 'wyyx neteasegame'),
  AppCatalogItem(name: 'Steam', category: 'game', alias: 'steam'),
  AppCatalogItem(
      name: 'PlayStation Plus',
      category: 'game',
      alias: 'psn psplus playstation'),
  AppCatalogItem(name: 'Xbox Game Pass', category: 'game', alias: 'xbox gamepass'),
  AppCatalogItem(
      name: 'Nintendo Switch Online',
      category: 'game',
      alias: 'nso nintendo switch'),
  AppCatalogItem(name: 'EA Play', category: 'game', alias: 'ea eaplay'),

  // ── 办公 ──
  AppCatalogItem(
      name: 'WPS会员',
      category: 'office',
      defaultLevel: '超级会员',
      alias: 'wps'),
  AppCatalogItem(name: '腾讯文档', category: 'office', alias: 'txwd tencentdocs'),
  AppCatalogItem(
      name: '印象笔记', category: 'office', alias: 'yxbj yinxiang evernote'),
  AppCatalogItem(name: 'Notion', category: 'office', alias: 'notion'),
  AppCatalogItem(
      name: 'Adobe Creative Cloud', category: 'office', alias: 'adobe cc creativecloud'),
  AppCatalogItem(
      name: 'Microsoft 365', category: 'office', alias: 'ms365 m365 microsoft office'),
  AppCatalogItem(
      name: 'ChatGPT Plus', category: 'office', alias: 'chatgpt gpt openai'),
  AppCatalogItem(
      name: '百度文库', category: 'office', alias: 'bdwk baiduwenku'),

  // ── 生活 ──
  AppCatalogItem(name: '美团', category: 'life', alias: 'mt meituan'),
  AppCatalogItem(name: '饿了么', category: 'life', alias: 'elm eleme'),
  AppCatalogItem(name: '肯德基', category: 'life', alias: 'kdj kfc'),
  AppCatalogItem(name: '麦当劳', category: 'life', alias: 'mdl mcdonalds mcd'),
  AppCatalogItem(name: '叮咚买菜', category: 'life', alias: 'ddmc dingdong'),
  AppCatalogItem(
      name: '山姆会员商店',
      category: 'life',
      defaultLevel: '卓越会员',
      alias: 'sm sam samclub sams'),
];

/// 按分类分组
Map<String, List<AppCatalogItem>> groupCatalogByCategory() {
  final map = <String, List<AppCatalogItem>>{};
  for (final item in kAppCatalog) {
    map.putIfAbsent(item.category, () => []).add(item);
  }
  return map;
}

/// 搜索（名称 + 别名模糊匹配，别名覆盖拼音/首字母/简称）
List<AppCatalogItem> searchCatalog(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return kAppCatalog;
  return kAppCatalog
      .where((e) =>
          e.name.toLowerCase().contains(q) ||
          (e.alias != null && e.alias!.toLowerCase().contains(q)))
      .toList();
}
