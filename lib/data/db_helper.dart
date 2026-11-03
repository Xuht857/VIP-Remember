import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/account.dart';
import '../models/member_record.dart';

/// SQLite 数据层 —— 本地优先，无服务器
class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  static const _dbName = 'member_vault.db';
  static const _dbVersion = 1;

  Database? _db;
  Future<Database>? _opening;

  Future<Database> get database async {
    if (_db != null) return _db!;
    // 防并发双开：共享同一个 opening future，失败后允许重试
    try {
      _opening ??= _open();
      _db = await _opening!;
      return _db!;
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      join(dir, _dbName),
      version: _dbVersion,
      // 外键约束 SQLite 默认关闭，需显式开启（account_id → accounts.id）
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 迁移骨架：升版本时在此按版本号逐级执行 ALTER
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE member_records ADD COLUMN ...');
    // }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE member_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        app_name TEXT NOT NULL,
        app_icon TEXT,
        category TEXT,
        level TEXT,
        expires_at TEXT,
        auto_renew INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        account_id INTEGER,
        price REAL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        label TEXT NOT NULL,
        identifier TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'phone',
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_member_expires ON member_records (expires_at)');
    await db.execute(
        'CREATE INDEX idx_member_active ON member_records (is_active)');
  }

  // ── MemberRecord CRUD ──

  Future<int> insertRecord(MemberRecord record) async {
    final db = await database;
    return db.insert('member_records', record.toMap()..remove('id'));
  }

  Future<int> updateRecord(MemberRecord record) async {
    final db = await database;
    return db.update(
      'member_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteRecord(int id) async {
    final db = await database;
    return db.delete('member_records', where: 'id = ?', whereArgs: [id]);
  }

  /// 全部会员记录，按到期日升序（无到期日的排最后）
  Future<List<MemberRecord>> getAllRecords() async {
    final db = await database;
    final rows = await db.query(
      'member_records',
      orderBy: "expires_at IS NULL, expires_at ASC",
    );
    return rows.map(MemberRecord.fromMap).toList();
  }

  Future<MemberRecord?> getRecord(int id) async {
    final db = await database;
    final rows =
        await db.query('member_records', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return MemberRecord.fromMap(rows.first);
  }

  // ── Account CRUD（P2 就位） ──

  Future<int> insertAccount(Account account) async {
    final db = await database;
    return db.insert('accounts', account.toMap()..remove('id'));
  }

  Future<List<Account>> getAllAccounts() async {
    final db = await database;
    final rows = await db.query('accounts', orderBy: 'is_default DESC, id ASC');
    return rows.map(Account.fromMap).toList();
  }

  Future<int> deleteAccount(int id) async {
    final db = await database;
    return db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }
}
