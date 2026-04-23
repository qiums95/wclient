import 'dart:convert';
import 'dart:async';

import 'package:wclient/services/network/websocket_service.dart';
import 'package:wclient/managers/data_manager.dart';

import 'package:wclient/models/receive_message_model.dart';
import 'package:wclient/models/send_message_model.dart';
import 'package:wclient/models/profile_message_model.dart';
import 'package:wclient/models/chatroom_message_model.dart';
import 'package:wclient/models/sync_message_model.dart';

class MessageManager {
  static final MessageManager _instance = MessageManager._internal();
  factory MessageManager() => _instance;
  MessageManager._internal() {
    _init();
  }

  final WebSocketManager _wsManager = WebSocketManager();

  // 全局流：负责分发所有实时收到的新消息（用于红点、系统通知）
  final _globalStreamController = StreamController<Message>.broadcast();
  Stream<Message> get globalStream => _globalStreamController.stream;

  // 异步 Completer 处理
  Completer<ProfileInfoResponse>? _profileCompleter;
  Completer<ChatroomListResponse>? _chatroomsCompleter;
  Completer<MessageListResponse>? _messageListCompleter;

  // [初始化：建立 WebSocket 原始流的监听]
  void _init() {
    _wsManager.messageStream.listen((data) => _handleRawData(data));
  }

  // [核心调度：根据数据类型分发至全局流或活跃流]
  void _handleRawData(dynamic data) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map<String, dynamic>) return;

      final String? action = decoded['action'];

      // 处理实时推送（收/发消息）
      if (decoded.containsKey('type')) {
        final msg = Message.fromJson(decoded);

        // 分发到数据管理器中的List
        DataManager().handleIncomingMessage(msg);

        // 无论当前在哪个页面，新消息一律进入全局流供通知系统使用
        _globalStreamController.add(msg);
      }


      // 处理个人资料请求回调
      else if (action == 'profile_info') {
        _profileCompleter?.complete(ProfileInfoResponse.fromJson(decoded));
        _profileCompleter = null;
      }
      // 处理通讯录列表请求回调
      else if (action == 'chatroom_list') {
        _chatroomsCompleter?.complete(ChatroomListResponse.fromJson(decoded));
        _chatroomsCompleter = null;
      }
      else if (action == 'message_list') {
        _messageListCompleter?.complete(MessageListResponse.fromJson(decoded));
        _messageListCompleter = null;
      }
    } catch (e) {
      print("MessageManager 分发异常: $e");
    }
  }

  // [消息发送：将本地生成的 ID 转换为服务端识别的发送包]
  void sendText(String to, String content) {
    final request = SendTextMessage(to: to, msg: content);
    _wsManager.sendMessage(jsonEncode(request.toJson()));
  }

  // [资料拉取：通过 Future 机制等待异步的 profile_info 回包]
  Future<ProfileInfoResponse?> getProfile() async {
    if (_profileCompleter != null) return _profileCompleter!.future;
    _profileCompleter = Completer<ProfileInfoResponse>();
    _wsManager.sendMessage(jsonEncode(GetProfileRequest().toJson()));
    return _profileCompleter!.future.timeout(const Duration(seconds: 5), onTimeout: () {
      _profileCompleter = null;
      throw TimeoutException("获取个人资料超时");
    });
  }

  // [通讯录拉取：通过 Future 机制等待异步的 chatroom_list 回包]
  Future<ChatroomListResponse?> getChatrooms() async {
    if (_chatroomsCompleter != null) return _chatroomsCompleter!.future;
    _chatroomsCompleter = Completer<ChatroomListResponse>();
    _wsManager.sendMessage(jsonEncode(GetChatroomsRequest().toJson()));
    return _chatroomsCompleter!.future.timeout(const Duration(seconds: 10), onTimeout: () {
      _chatroomsCompleter = null;
      throw TimeoutException("获取通讯录超时");
    });
  }

  // [通用的拉取消息接口，支持向上或向后拉取]
  Future<List<Message>?> getMessages({
    required int msgid,
    required PullDirection direction,
    int limit = 50,
  }) async {
    // 防止重复发起相同请求
    if (_messageListCompleter != null) {
      final response = await _messageListCompleter!.future;
      return response.data;
    }

    _messageListCompleter = Completer<MessageListResponse>();

    // 组装请求体并发送网络请求
    final request = GetMessageRequest(
      msgid: msgid,
      direction: direction,
      limit: limit,
    );
    _wsManager.sendMessage(jsonEncode(request.toJson()));

    // 等待 WebSocket 回包，并设置超时保护
    try {
      final response = await _messageListCompleter!.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            _messageListCompleter = null;
            throw TimeoutException("获取消息列表超时");
          }
      );
      // 直接返回 List<Message> 方便业务层调用
      return response.data;
    } catch (e) {
      _messageListCompleter = null;
      rethrow;
    }
  }

  // [资源释放：关闭所有的广播流控制器]
  void dispose() {
    _globalStreamController.close();
  }
}