abstract class SendMessageRequest {
  final String action;

  SendMessageRequest({required this.action});

  Map<String, dynamic> toJson();
}

class SendTextMessage extends SendMessageRequest {
  final String to;
  final String msg;

  SendTextMessage({
    required this.to,
    required this.msg,
  }) : super(action: 'send_text');

  @override
  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'to': to,
      'msg': msg,
    };
  }
}