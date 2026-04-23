import 'package:wclient/models/receive_message_model.dart';

/// 拉取方向枚举，防止字符串拼写错误
enum PullDirection {
  backward, // 向老消息方向拉取（用户上滑查看历史记录）
  forward,  // 向新消息方向拉取（冷启动拉取离线增量消息）
}

/// 发送包：获取历史/增量消息请求
class GetMessageRequest {
  final String action;
  final int msgid;
  final PullDirection direction;
  final int limit;

  GetMessageRequest({
    this.action = 'get_message',
    required this.msgid,
    required this.direction,
    this.limit = 50,
  });

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'msgid': msgid,
      'direction': direction.name, // .name 会自动将其转换为 'backward' 或 'forward' 字符串
      'limit': limit,
    };
  }
}

/// 接收包：消息列表回包 (保持不变)
class MessageListResponse {
  final String action;
  final List<Message> data;

  MessageListResponse({
    required this.action,
    required this.data,
  });

  factory MessageListResponse.fromJson(Map<String, dynamic> json) {
    return MessageListResponse(
      action: json['action'] as String? ?? 'message_list',
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}