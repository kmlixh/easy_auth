import 'dart:async';
import 'package:flutter/services.dart' as flutter_services;
import 'package:shared_preferences/shared_preferences.dart';
import 'easy_auth_models.dart';
import 'easy_auth_api_client.dart';
import 'easy_auth_exception.dart' as auth_exception;

/// EasyAuth核心类
/// 提供完整的登录、登出、Token管理等功能
class EasyAuth {
  static const flutter_services.MethodChannel _channel =
      flutter_services.MethodChannel('easy_auth');

  EasyAuthConfig? _config;
  EasyAuthApiClient? _apiClient;
  UserInfo? _currentUser;
  String? _currentToken;
  Timer? _refreshTimer;

  static final EasyAuth _instance = EasyAuth._internal();
  factory EasyAuth() => _instance;
  EasyAuth._internal();

  /// 初始化EasyAuth
  Future<void> init(EasyAuthConfig config) async {
    _config = config;
    _apiClient = EasyAuthApiClient(
      baseUrl: config.baseUrl,
      tenantId: config.tenantId,
      sceneId: config.sceneId,
    );

    // 尝试从本地恢复token和用户信息
    await _restoreSession();

    // 启动自动刷新
    if (config.enableAutoRefresh && _currentToken != null) {
      _startAutoRefresh();
    }
  }

  /// 当前配置
  EasyAuthConfig get config {
    if (_config == null) {
      throw auth_exception.ConfigurationException(
        'EasyAuth not initialized. Call init() first.',
      );
    }
    return _config!;
  }

  /// API客户端
  EasyAuthApiClient get apiClient {
    if (_apiClient == null) {
      throw auth_exception.ConfigurationException(
        'EasyAuth not initialized. Call init() first.',
      );
    }
    return _apiClient!;
  }

  /// 当前用户
  UserInfo? get currentUser => _currentUser;

  /// 当前Token
  String? get currentToken => _currentToken;

  /// 是否已登录
  bool get isLoggedIn => _currentToken != null;

  // ========================================
  // 验证码登录相关
  // ========================================

  /// 发送短信验证码
  Future<void> sendSMSCode(String phoneNumber) async {
    print('🔍 [EasyAuth.sendSMSCode] 开始发送验证码');
    print('   _config: ${_config != null ? "已初始化" : "未初始化"}');
    print('   _apiClient: ${_apiClient != null ? "已创建" : "未创建"}');
    if (_config != null) {
      print('   TenantID: ${_config!.tenantId}');
      print('   BaseURL: ${_config!.baseUrl}');
    }

    try {
      await apiClient.sendSMSCode(phoneNumber);
    } catch (e) {
      print('❌ [EasyAuth.sendSMSCode] 发送失败: $e');
      throw auth_exception.VerificationCodeException(
        'Failed to send SMS code: $e',
      );
    }
  }

  /// 发送邮箱验证码
  Future<void> sendEmailCode(String email) async {
    try {
      await apiClient.sendEmailCode(email);
    } catch (e) {
      throw auth_exception.VerificationCodeException(
        'Failed to send email code: $e',
      );
    }
  }

  /// 短信验证码登录
  Future<LoginResult> loginWithSMS({
    required String phoneNumber,
    required String code,
  }) async {
    try {
      final result = await apiClient.loginWithSMS(
        phoneNumber: phoneNumber,
        code: code,
      );

      if (result.isSuccess && result.token != null) {
        await _saveSession(result.token!, result.userInfo);
        _startAutoRefresh();
      }

      return result;
    } catch (e, stackTrace) {
      throw auth_exception.AuthenticationException(
        'SMS login failed: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 邮箱验证码登录
  Future<LoginResult> loginWithEmail({
    required String email,
    required String code,
  }) async {
    try {
      final result = await apiClient.loginWithEmail(email: email, code: code);

      if (result.isSuccess && result.token != null) {
        await _saveSession(result.token!, result.userInfo);
        _startAutoRefresh();
      }

      return result;
    } catch (e, stackTrace) {
      throw auth_exception.AuthenticationException(
        'Email login failed: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ========================================
  // 第三方登录相关（通过原生SDK）
  // ========================================

  /// 微信登录
  Future<LoginResult> loginWithWechat() async {
    try {
      // 1. 调用原生SDK获取授权码
      final authCode = await _channel.invokeMethod<String>('wechatLogin');

      if (authCode == null || authCode.isEmpty) {
        throw auth_exception.PlatformException(
          'Wechat auth code is null or empty',
          platform: 'wechat',
        );
      }

      // 2. 使用授权码登录
      final result = await apiClient.loginWithWechat(authCode);

      if (result.isSuccess && result.token != null) {
        await _saveSession(result.token!, result.userInfo);
        _startAutoRefresh();
      }

      return result;
    } on auth_exception.PlatformException catch (e) {
      throw auth_exception.PlatformException(
        'Wechat login failed: ${e.message}',
        platform: 'wechat',
        originalError: e,
      );
    } catch (e, stackTrace) {
      throw auth_exception.AuthenticationException(
        'Wechat login failed: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Apple ID登录
  Future<LoginResult> loginWithApple() async {
    try {
      // 1. 调用原生SDK获取授权信息
      final result = await _channel.invokeMethod<Map>('appleLogin');

      if (result == null) {
        throw auth_exception.PlatformException(
          'Apple login result is null',
          platform: 'apple',
        );
      }

      final authCode = result['authCode'] as String?;
      final idToken = result['idToken'] as String?;

      if (authCode == null || authCode.isEmpty) {
        throw auth_exception.PlatformException(
          'Apple auth code is null or empty',
          platform: 'apple',
        );
      }

      // 2. 使用授权码登录
      final loginResult = await apiClient.loginWithApple(
        authCode: authCode,
        idToken: idToken,
      );

      if (loginResult.isSuccess && loginResult.token != null) {
        await _saveSession(loginResult.token!, loginResult.userInfo);
        _startAutoRefresh();
      }

      return loginResult;
    } on auth_exception.PlatformException catch (e) {
      throw auth_exception.PlatformException(
        'Apple login failed: ${e.message}',
        platform: 'apple',
        originalError: e,
      );
    } catch (e, stackTrace) {
      throw auth_exception.AuthenticationException(
        'Apple login failed: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Google登录
  Future<LoginResult> loginWithGoogle() async {
    try {
      // 1. 调用原生SDK获取授权信息
      final result = await _channel.invokeMethod<Map>('googleLogin');

      if (result == null) {
        throw auth_exception.PlatformException(
          'Google login result is null',
          platform: 'google',
        );
      }

      final authCode = result['authCode'] as String?;
      final idToken = result['idToken'] as String?;

      if (authCode == null || authCode.isEmpty) {
        throw auth_exception.PlatformException(
          'Google auth code is null or empty',
          platform: 'google',
        );
      }

      // 2. 使用授权码登录
      final loginResult = await apiClient.loginWithGoogle(
        authCode: authCode,
        idToken: idToken,
      );

      if (loginResult.isSuccess && loginResult.token != null) {
        await _saveSession(loginResult.token!, loginResult.userInfo);
        _startAutoRefresh();
      }

      return loginResult;
    } on auth_exception.PlatformException catch (e) {
      throw auth_exception.PlatformException(
        'Google login failed: ${e.message}',
        platform: 'google',
        originalError: e,
      );
    } catch (e, stackTrace) {
      throw auth_exception.AuthenticationException(
        'Google login failed: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ========================================
  // Token和用户信息管理
  // ========================================

  /// 刷新Token
  Future<String> refreshToken() async {
    if (_currentToken == null) {
      throw auth_exception.TokenExpiredException('No token to refresh');
    }

    try {
      final newToken = await apiClient.refreshToken(_currentToken!);
      await _saveSession(newToken, _currentUser);
      return newToken;
    } catch (e, stackTrace) {
      throw auth_exception.AuthenticationException(
        'Token refresh failed: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 获取用户信息
  Future<UserInfo> getUserInfo({bool forceRefresh = false}) async {
    if (_currentToken == null) {
      throw auth_exception.AuthenticationException('Not logged in');
    }

    if (!forceRefresh && _currentUser != null) {
      return _currentUser!;
    }

    try {
      final userInfo = await apiClient.getUserInfo(_currentToken!);
      _currentUser = userInfo;
      await _saveUserInfo(userInfo);
      return userInfo;
    } catch (e, stackTrace) {
      throw auth_exception.AuthenticationException(
        'Failed to get user info: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 登出
  Future<void> logout() async {
    _stopAutoRefresh();

    if (_currentToken != null) {
      try {
        await apiClient.logout(_currentToken!);
      } catch (e) {
        // 即使服务器登出失败，也要清除本地数据
        print('Logout API failed: $e');
      }
    }

    await _clearSession();
  }

  // ========================================
  // 内部辅助方法
  // ========================================

  /// 保存会话信息
  Future<void> _saveSession(String token, UserInfo? userInfo) async {
    _currentToken = token;
    _currentUser = userInfo;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('easy_auth_token', token);

    if (userInfo != null) {
      await _saveUserInfo(userInfo);
    }
  }

  /// 保存用户信息
  Future<void> _saveUserInfo(UserInfo userInfo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('easy_auth_user_id', userInfo.userId);
    if (userInfo.nickname != null) {
      await prefs.setString('easy_auth_user_nickname', userInfo.nickname!);
    }
    if (userInfo.avatar != null) {
      await prefs.setString('easy_auth_user_avatar', userInfo.avatar!);
    }
    if (userInfo.email != null) {
      await prefs.setString('easy_auth_user_email', userInfo.email!);
    }
    if (userInfo.phone != null) {
      await prefs.setString('easy_auth_user_phone', userInfo.phone!);
    }
  }

  /// 恢复会话信息
  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('easy_auth_token');

    if (token != null) {
      _currentToken = token;

      // 尝试恢复用户信息
      final userId = prefs.getString('easy_auth_user_id');
      if (userId != null) {
        _currentUser = UserInfo(
          userId: userId,
          nickname: prefs.getString('easy_auth_user_nickname'),
          avatar: prefs.getString('easy_auth_user_avatar'),
          email: prefs.getString('easy_auth_user_email'),
          phone: prefs.getString('easy_auth_user_phone'),
        );
      }
    }
  }

  /// 清除会话信息
  Future<void> _clearSession() async {
    _currentToken = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('easy_auth_token');
    await prefs.remove('easy_auth_user_id');
    await prefs.remove('easy_auth_user_nickname');
    await prefs.remove('easy_auth_user_avatar');
    await prefs.remove('easy_auth_user_email');
    await prefs.remove('easy_auth_user_phone');
  }

  /// 启动自动刷新Token
  void _startAutoRefresh() {
    _stopAutoRefresh();

    if (_config?.enableAutoRefresh != true) {
      return;
    }

    // 每6天刷新一次Token（Token有效期7天）
    final refreshInterval = Duration(days: 6);
    _refreshTimer = Timer.periodic(refreshInterval, (timer) async {
      try {
        await refreshToken();
        print('Token refreshed automatically');
      } catch (e) {
        print('Auto refresh token failed: $e');
        timer.cancel();
      }
    });
  }

  /// 停止自动刷新
  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// 释放资源
  void dispose() {
    _stopAutoRefresh();
    _apiClient?.close();
  }
}
