import 'package:flutter/material.dart';

/// 配置类
class EasyAuthConfig {
  final String baseUrl;
  final String tenantId;
  final String sceneId;
  final bool enableAutoRefresh;
  final Duration? autoRefreshInterval;
  final Color? primaryColor;
  final Color? backgroundColor;
  final Color? surfaceColor;

  const EasyAuthConfig({
    required this.baseUrl,
    required this.tenantId,
    required this.sceneId,
    this.enableAutoRefresh = true,
    this.autoRefreshInterval,
    this.primaryColor,
    this.backgroundColor,
    this.surfaceColor,
  });
}

/// 用户信息
class UserInfo {
  final String userId;
  final String? username;
  final String? nickname;
  final String? email;
  final String? phone;
  final String? avatar;
  final Map<String, dynamic>? extra;

  UserInfo({
    required this.userId,
    this.username,
    this.nickname,
    this.email,
    this.phone,
    this.avatar,
    this.extra,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String?,
      nickname: json['nickname'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      extra: json['extra'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      if (username != null) 'username': username,
      if (nickname != null) 'nickname': nickname,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (avatar != null) 'avatar': avatar,
      if (extra != null) 'extra': extra,
    };
  }
}

/// 登录结果
class LoginResult {
  final LoginStatus status;
  final String? token;
  final UserInfo? userInfo;
  final String? message;

  bool get isSuccess => status == LoginStatus.success;

  LoginResult({required this.status, this.token, this.userInfo, this.message});

  /// 创建失败结果
  factory LoginResult.failure(String message) {
    return LoginResult(status: LoginStatus.failed, message: message);
  }

  /// 创建成功结果
  factory LoginResult.success({
    required String token,
    UserInfo? userInfo,
    String? message,
  }) {
    return LoginResult(
      status: LoginStatus.success,
      token: token,
      userInfo: userInfo,
      message: message,
    );
  }

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String?;
    final status = LoginStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => LoginStatus.pending,
    );

    return LoginResult(
      status: status,
      token: json['token'] as String?,
      userInfo: json['user_info'] != null
          ? UserInfo.fromJson(json['user_info'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      if (token != null) 'token': token,
      if (userInfo != null) 'user_info': userInfo!.toJson(),
      if (message != null) 'message': message,
    };
  }
}

/// 登录状态
enum LoginStatus {
  /// 等待中（轮询中）
  pending,

  /// 成功（已完成，且登录成功）
  success,

  /// 失败（已完成，但登录失败）
  failed,

  /// 超时
  timeout,

  /// 取消
  cancelled,
}

/// 登录渠道
enum LoginChannel {
  wechat,
  apple,
  google,
  sms,
  email;

  String get id {
    switch (this) {
      case LoginChannel.wechat:
        return 'wechat';
      case LoginChannel.apple:
        return 'apple';
      case LoginChannel.google:
        return 'google';
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
      case LoginChannel.google:
        return 'Google登录';
      case LoginChannel.sms:
        return '短信验证码登录';
      case LoginChannel.email:
        return '邮箱验证码登录';
    }
  }
}

/// 支持的登录渠道信息
class SupportedChannelInfo {
  final String channelId;
  final String channelName;
  final String channelTitle;
  final int sortOrder;
  final Map<String, String>? config;

  SupportedChannelInfo({
    required this.channelId,
    required this.channelName,
    required this.channelTitle,
    required this.sortOrder,
    this.config,
  });

  factory SupportedChannelInfo.fromJson(Map<String, dynamic> json) {
    // 处理config字段
    Map<String, String>? config;
    if (json['config'] != null) {
      config = Map<String, String>.from(json['config'] as Map);
    }

    return SupportedChannelInfo(
      channelId: json['channel_id'] as String? ?? '',
      channelName: json['channel_name'] as String? ?? '',
      channelTitle: json['channel_title'] as String? ?? '',
      sortOrder: json['sort_order'] as int? ?? 0,
      config: config,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channel_id': channelId,
      'channel_name': channelName,
      'channel_title': channelTitle,
      'sort_order': sortOrder,
      if (config != null) 'config': config,
    };
  }
}

/// 租户配置信息
class TenantConfig {
  final String tenantId;
  final String tenantName;
  final String? icon;
  final List<SupportedChannelInfo> supportedChannels;
  final String? defaultChannel;

  TenantConfig({
    required this.tenantId,
    required this.tenantName,
    this.icon,
    required this.supportedChannels,
    this.defaultChannel,
  });

  factory TenantConfig.fromJson(Map<String, dynamic> json) {
    final channelsJson = json['supported_channels'] as List<dynamic>? ?? [];
    final channels = channelsJson
        .map((ch) => SupportedChannelInfo.fromJson(ch as Map<String, dynamic>))
        .toList();

    return TenantConfig(
      tenantId: json['tenant_id'] as String? ?? '',
      tenantName: json['tenant_name'] as String? ?? '',
      icon: json['icon'] as String?,
      supportedChannels: channels,
      defaultChannel: json['default_channel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'tenant_name': tenantName,
      if (icon != null) 'icon': icon,
      'supported_channels': supportedChannels.map((e) => e.toJson()).toList(),
      if (defaultChannel != null) 'default_channel': defaultChannel,
    };
  }
}

/// 用户信息页面内的动作
enum UserInfoAction { none, edited, loggedOut }
