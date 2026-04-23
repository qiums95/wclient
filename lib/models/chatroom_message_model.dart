class GetChatroomsRequest {
  final String action = 'get_chatrooms';

  Map<String, dynamic> toJson() {
    return {
      'action': action,
    };
  }
}

class ChatroomData {
  final String wxid;
  final String nickname;
  final String avatar;

  ChatroomData({
    required this.wxid,
    required this.nickname,
    required this.avatar,
  });

  factory ChatroomData.fromJson(Map<String, dynamic> json) {
    return ChatroomData(
      wxid: json['wxid'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
    );
  }
}

class ChatroomListResponse {
  final String action;
  final int totalCount;
  final List<ChatroomData> data;

  ChatroomListResponse({
    required this.action,
    required this.totalCount,
    required this.data,
  });

  factory ChatroomListResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List? ?? [];
    List<ChatroomData> dataList = list.map((i) => ChatroomData.fromJson(i)).toList();

    return ChatroomListResponse(
      action: json['action'] as String? ?? 'chatroom_list',
      totalCount: json['total_count'] as int? ?? 0,
      data: dataList,
    );
  }
}