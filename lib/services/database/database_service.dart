import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'package:wclient/models/receive_message_model.dart';

class DatabaseManager {

  // 单例模式
  static final DatabaseManager _instance = DatabaseManager._internal();
  static Database? _database;

  factory DatabaseManager()=> _instance;
  DatabaseManager._internal();

  // 初始化数据库
  Future<Database> get database async {
    if(_database != null) return _database!;
    _database = await _initDB('wechat_chat.db');
    return _database!;
  }

  // 建表语句
  Future<Database> _initDB(String fileName) async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {

    // 创建消息明细表（存储聊天记录）
    await db.execute('''
    CREATE TABLE messages (
      msgid INTEGER PRIMARY KEY,
      chatId TEXT,
      senderId TEXT,
      content TEXT,
      type INTEGER,
      isSelf INTEGER,
      msgtime TEXT
    )
  ''');

    // 为 chatId 创建索引，极大地提升点进聊天界面的加载速度
    await db.execute('CREATE INDEX idx_messages_chatId ON messages (chatId)');

    // 创建会话表（存储首页列表，即 latestMessages 的持久化）
    await db.execute('''
      CREATE TABLE sessions (
        chatId TEXT PRIMARY KEY,
        senderId TEXT,
        content TEXT,
        type INTEGER,
        isSelf INTEGER,
        msgid INTEGER,
        msgtime TEXT
      )
    ''');

  }

  // --- messages 表专属操作 ---
  // 保存单条具体的聊天记录
  Future<void> saveMessage(Message msg) async {
    final db = await database;

    await db.insert(
      'messages',
      {
        'msgid': msg.msgid,
        'chatId': msg.chatId,
        'senderId': msg.senderId,
        'content': msg.content,
        'type': msg.type,
        'isSelf': msg.isSelf,
        'msgtime': msg.msgtime,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

// 获取特定聊天的历史记录（基于 msgid 游标拉取）
  Future<List<Map<String, dynamic>>> getChatHistory(
      String chatId, {
        int limit = 20,
        int? cursorMsgId, // 传入当前列表中最小的（最老的）msgid
      }) async {
    final db = await database;

    String whereClause = 'chatId = ?';
    List<dynamic> whereArgs = [chatId];

    // 如果传入了游标，则拉取比当前 msgid 更小的数据（即更老的消息）
    if (cursorMsgId != null) {
      whereClause += ' AND msgid < ?';
      whereArgs.add(cursorMsgId);
    }

    // 按 msgid 倒序拉取（紧贴着游标往下拿 limit 条），完美适配 UI 的 reverse 列表
    return await db.query(
      'messages',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'msgid DESC', // 直接按照 msgid 排序
      limit: limit,
    );
  }

  // --- sessions 表专属操作 ---
  // 保存/更新会话（对应 latestMessages）
  Future<void> saveSession(Message msg) async {
    final db = await database;

    await db.insert(
      'sessions',
      {
        'chatId': msg.chatId,
        'senderId': msg.senderId,
        'content': msg.content,
        'type': msg.type,
        'isSelf': msg.isSelf,
        'msgid': msg.msgid,
        'msgtime': msg.msgtime,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 冷启动时：加载所有会话记录
  Future<List<Map<String, dynamic>>> getSessions() async {
    final db = await database;
    // 按时间倒序排列，确保最近聊天的排在前面
    return await db.query('sessions', orderBy: 'msgtime DESC');
  }

  // 获取最新消息的 msgid (用于同步)
  Future<int?> getLatestMsgId({String? chatId}) async {
    final db = await database;

    List<Map<String, dynamic>> result;

    if (chatId != null && chatId.isNotEmpty) {
      // 获取指定聊天的最新 msgid
      result = await db.query(
        'messages',
        columns: ['msgid'],
        where: 'chatId = ?',
        whereArgs: [chatId],
        orderBy: 'msgid DESC',
        limit: 1,
      );
    } else {
      // 获取全局整个数据库中最新的 msgid
      result = await db.query(
        'messages',
        columns: ['msgid'],
        orderBy: 'msgid DESC',
        limit: 1,
      );
    }

    if (result.isNotEmpty) {
      return result.first['msgid'] as int;
    }

    // 如果数据库是空的，返回 null
    return null;
  }
}