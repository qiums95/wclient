class GetProfileRequest {
  final String action = 'get_profile';

  Map<String, dynamic> toJson() {
    return {
      'action': action,
    };
  }
}

class ProfileInfoResponse {
  final String action;
  final String status;
  final int loginStatus;
  final String wxid;
  final String username;
  final String phone;
  final String signature;
  final String alias;
  final String avatar;

  ProfileInfoResponse({
    required this.action,
    required this.status,
    required this.loginStatus,
    required this.wxid,
    required this.username,
    required this.phone,
    required this.signature,
    required this.alias,
    required this.avatar,
  });

  factory ProfileInfoResponse.fromJson(Map<String, dynamic> json) {
    return ProfileInfoResponse(
      action: json['action'] as String? ?? 'profile_info',
      status: json['status'] as String? ?? '',
      loginStatus: json['login_status'] as int? ?? 0,
      wxid: json['wxid'] as String? ?? '',
      username: json['username'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      signature: json['signature'] as String? ?? '',
      alias: json['alias'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
    );
  }
}