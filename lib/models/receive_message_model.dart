abstract class Message {
  final int type;
  final int isSelf;
  final String chatId;
  final String senderId;
  final String content;
  final int msgid;
  final String msgtime;

  Message({
    required this.type,
    required this.isSelf,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.msgid,
    required this.msgtime,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as int;

    switch (type) {
      case 1:
        return TextMessage.fromJson(json);
      case 3:
        return ImageMessage.fromJson(json);
      default:
        throw UnimplementedError();
    }
  }

  Map<String, dynamic> toJson();
}

class TextMessage extends Message {
  TextMessage({
    required super.type,
    required super.isSelf,
    required super.chatId,
    required super.senderId,
    required super.content,
    required super.msgid,
    required super.msgtime,
  });

  factory TextMessage.fromJson(Map<String, dynamic> json) {
    return TextMessage(
      type: json['type'] as int? ?? 1,
      isSelf: json['isSelf'] as int? ?? 0,
      chatId: json['chatId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      msgid: json['msgid'] as int? ?? 0,
      msgtime: json['msgtime'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'isSelf': isSelf,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'msgid': msgid,
      'msgtime': msgtime,
    };
  }
}

class ImageMessage extends Message {
  final String thumb;
  final String img;

  ImageMessage({
    required super.type,
    required super.isSelf,
    required super.chatId,
    required super.senderId,
    required super.content,
    required super.msgid,
    required super.msgtime,
    required this.thumb,
    required this.img,
  });

  factory ImageMessage.fromJson(Map<String, dynamic> json) {
    return ImageMessage(
      type: json['type'] as int? ?? 3,
      isSelf: json['isSelf'] as int? ?? 0,
      chatId: json['chatId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      msgid: json['msgid'] as int? ?? 0,
      msgtime: json['msgtime'] as String? ?? '',
      thumb: json['thumb'] as String? ?? '',
      img: json['img'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'isSelf': isSelf,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'msgid': msgid,
      'msgtime': msgtime,
      'thumb': thumb,
      'img': img,
    };
  }
}