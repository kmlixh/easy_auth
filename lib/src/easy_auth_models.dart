/// 登录结果
class LoginResult {
  final LoginStatus status;
  final String? token;
  final UserInfo? userInfo;
  final String? message;
  final String? tempToken;

  LoginResult({
    required this.status,
    this.token,
    this.userInfo,
    this.message,
    this.tempToken,
  });

  bool get isSuccess => status == LoginStatus.success;
  bool get isFailed => status == LoginStatus.failed;
  bool get isPending => status == LoginStatus.pending;
  bool get isTimeout => status == LoginStatus.timeout;

  @override
  String toString() {
    return 'LoginResult(status: $status, token: $token, message: $message)';
  }
}

/// 登录状态枚举
enum LoginStatus {
  success, // 登录成功
  failed, // 登录失败
  pending, // 等待中
  timeout, // 超时
}

/// 用户信息
class UserInfo {
  final String userId;
  final String? username;
  final String? nickname;
  final String? avatar;
  final String? email;
  final String? phone;
  final Map<String, dynamic>? rawData;

  UserInfo({
    required this.userId,
    this.username,
    this.nickname,
    this.avatar,
    this.email,
    this.phone,
    this.rawData,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['user_id'] as String? ?? json['id'] as String,
      username: json['username'] as String?,
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'nickname': nickname,
      'avatar': avatar,
      'email': email,
      'phone': phone,
      ...?rawData,
    };
  }

  @override
  String toString() {
    return 'UserInfo(userId: $userId, nickname: $nickname, email: $email)';
  }
}

/// 验证码发送结果
class VerificationCodeResult {
  final bool success;
  final String? message;
  final int? retryAfter; // 多少秒后可以重试

  VerificationCodeResult({
    required this.success,
    this.message,
    this.retryAfter,
  });

  @override
  String toString() {
    return 'VerificationCodeResult(success: $success, message: $message, retryAfter: $retryAfter)';
  }
}

/// 登录配置
class EasyAuthConfig {
  final String baseUrl;
  final String tenantId;
  final String sceneId;
  final Duration tokenExpiry;
  final bool enableAutoRefresh;

  EasyAuthConfig({
    required this.baseUrl,
    required this.tenantId,
    required this.sceneId,
    this.tokenExpiry = const Duration(days: 7),
    this.enableAutoRefresh = true,
  });

  @override
  String toString() {
    return 'EasyAuthConfig(baseUrl: $baseUrl, tenantId: $tenantId, sceneId: $sceneId)';
  }
}

/// 第三方登录渠道
enum LoginChannel {
  wechat, // 微信
  apple, // Apple ID
  sms, // 短信
  email, // 邮箱
}

extension LoginChannelExtension on LoginChannel {
  String get channelId {
    switch (this) {
      case LoginChannel.wechat:
        return 'wechat';
      case LoginChannel.apple:
        return 'apple';
      case LoginChannel.sms:
        return 'sms';
      case LoginChannel.email:
        return 'email';
    }
  }

  String get displayName {
    switch (this) {
      case LoginChannel.wechat:
        return '微信登录';
      case LoginChannel.apple:
        return 'Apple ID登录';
      case LoginChannel.sms:
        return '短信验证码登录';
      case LoginChannel.email:
        return '邮箱验证码登录';
    }
  }
}
