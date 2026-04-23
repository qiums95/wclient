import 'package:flutter/material.dart';

import 'package:wclient/services/database/database_service.dart';
import 'package:wclient/managers/message_manager.dart';

import 'package:wclient/models/receive_message_model.dart';
import 'package:wclient/models/profile_message_model.dart';
import 'package:wclient/models/chatroom_message_model.dart';
import 'package:wclient/models/sync_message_model.dart';

class DataManager extends ChangeNotifier {
  // 单例模式封装
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  // 个人信息存储
  ProfileInfoResponse? selfProfile;

  // 通讯录与群聊缓存 (使用 wxid 作为 Key)
  final Map<String, ChatroomData> contactCache = {};

  // 首页最新消息缓存 (使用 chatId 作为 Key)
  final Map<String, Message> latestMessages = {};

  // 当前聊天列表
  String? activeChatId;
  List<Message> activeMessages = [];

  // --- 数据更新方法 ---

  // 更新个人信息
  Future<void> loadProfile() async {
    try {
      final profile = await MessageManager().getProfile();
      if (profile != null) {
        selfProfile = profile;
        notifyListeners();
      }
    } catch (e) {
      print("获取个人信息失败或超时: $e");
    }
  }

  // 更新通讯录数据
  Future<void> loadContacts() async {
    try {
      final response = await MessageManager().getChatrooms();
      if (response != null) {
        final List<ChatroomData> chatroomList = response.data;
        for (var contact in chatroomList) {
          contactCache[contact.wxid] = contact;
        }
        notifyListeners();
      }
    } catch (e) {
      print("获取通讯录失败或超时: $e");
    }
  }

  // 处理接收到的新消息
  void handleIncomingMessage(Message message) {
    // 1. 更新内存 Map（保证 UI 响应快）
    latestMessages[message.chatId] = message;
    // 2. 异步存入数据库（保证下次启动还在）
    DatabaseManager().saveSession(message);
    DatabaseManager().saveMessage(message);

    // 3. 如果当前正在和这个人聊天，将新消息推入活跃列表
    if (message.chatId == activeChatId) {
      activeMessages.insert(0, message);
    }

    notifyListeners(); // 触发全应用相关 UI 刷新
  }

  // --- UI 展示逻辑 ---

// 获取排序后的首页列表
// 将 Map 的所有值转为 List，并根据 msgtime 进行倒序排列
  List<Message> getSortedChatList() {
    var list = latestMessages.values.toList();
    // 假设 msgtime 格式支持字符串比较 (例如 yyyy-MM-dd HH:mm:ss)
    list.sort((a, b) => b.msgtime.compareTo(a.msgtime));
    return list;
  }

  // 从数据库读取所有会话记录
  Future<void> loadSessions() async {

    final List<Map<String, dynamic>> sessionMaps = await DatabaseManager().getSessions();

    if (sessionMaps.isEmpty) return;

    // 将数据库的 Map 转换为 Message 对象并填充到内存缓存
    for (var map in sessionMaps) {
      try {
        final msg = Message.fromJson(map);
        latestMessages[msg.chatId] = msg;
      } catch (e) {
        print("从数据库恢复消息失败: $e");
      }
    }

    notifyListeners();
  }

  // 从数据库加载历史记录
  Future<void> loadChatHistory(String chatId) async {
    activeChatId = chatId;
    activeMessages.clear();
    notifyListeners(); // 先清空并通知 UI（防止闪烁上一个人的记录）

    // 从 SQLite 读取该人的历史消息
    final List<Map<String, dynamic>> maps = await DatabaseManager().getChatHistory(chatId);

    activeMessages = maps.map((map) {
      // 如果你之前用了手动映射规避类型错误，这里也建议使用相同的手动映射逻辑
      return Message.fromJson(map);
    }).toList();

    notifyListeners();
  }

// --- 网络数据同步与落盘 ---

  /// 冷启动专属：拉取离线增量消息并自动存入数据库
  Future<void> syncMessagesFromServer() async {
    try {
      // 获取本地数据库中全局最新的一条 msgid 作为游标
      int requestMsgId = 0;
      final latestId = await DatabaseManager().getLatestMsgId();
      if (latestId != null) {
        requestMsgId = latestId;
      }

      // 向服务端发起网络请求，固定向新消息方向 (forward) 拉取
      final List<Message>? messages = await MessageManager().getMessages(
        msgid: requestMsgId,
        direction: PullDirection.forward,
        limit: 50,
      );

      // 判空拦截
      if (messages == null || messages.isEmpty) {
        return;
      }

      // 遍历落盘与更新缓存
      for (var msg in messages) {
        // 保存聊天记录明细
        await DatabaseManager().saveMessage(msg);

        // 更新首页会话列表的内存与数据库
        latestMessages[msg.chatId] = msg;
        await DatabaseManager().saveSession(msg);
      }

      // 通知 UI 刷新
      notifyListeners();

    } catch (e) {
      // 仅保留真实的报错输出，防止出现问题时无法排查
      print("同步离线消息异常: $e");
    }
  }

  // 翻译名称逻辑
  // 优先级：通讯录昵称 > 个人用户名 > 原始 ID
  String getDisplayName(String wxid) {
    // 先查通讯录
    if (contactCache.containsKey(wxid)) {
      return contactCache[wxid]!.nickname;
    }
    // 再看是不是自己
    if (selfProfile != null && selfProfile!.wxid == wxid) {
      return selfProfile!.username;
    }
    // 都没有则返回原始 ID
    return wxid;
  }

  // 获取头像逻辑
  String getAvatar(String wxid) {
    if (contactCache.containsKey(wxid)) {
      return contactCache[wxid]!.avatar;
    }
    if (selfProfile != null && selfProfile!.wxid == wxid) {
      return selfProfile!.avatar;
    }
    return ""; // 返回空字符串，UI 层可据此显示默认头像
  }
}