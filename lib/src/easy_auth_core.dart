import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'easy_auth_models.dart';
import 'easy_auth_api_client.dart';
import 'easy_auth_exception.dart' as auth_exception;
import 'services/google_sign_in_service.dart';
import 'services/web_apple_login_service.dart';

/// EasyAuth核心类 - 纯Flutter包
/// 提供统一的登录、登出、Token管理功能
class EasyAuth {
  EasyAuthConfig? _config;
  EasyAuthApiClient? _apiClient;
  UserInfo? _currentUser;
  String? _currentToken;

  // 第三方登录回调（由宿主应用设置）
  Future<Map<String, dynamic>?> Function()? _appleLoginCallback;
  Future<Map<String, dynamic>?> Function()? _wechatLoginCallback;

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

    // 获取租户配置并设置Google配置
    await _loadTenantConfig();

    await _restoreSession();
  }

  /// 加载租户配置
  Future<void> _loadTenantConfig() async {
    try {
      await apiClient.getTenantConfig();
      // Google登录现在使用Web方式，不需要设置配置
    } catch (e) {
      print('⚠️ 加载租户配置失败: $e');
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
  // 短信/邮箱登录
  // ========================================

  /// 发送短信验证码
  Future<void> sendSMSCode(String phoneNumber) async {
    try {
      await apiClient.sendSMSCode(phoneNumber);
    } catch (e, stackTrace) {
      throw auth_exception.AuthenticationException(
        'Send SMS code failed: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 发送邮箱验证码
  Future<void> sendEmailCode(String email) async {
    try {
      await apiClient.sendEmailCode(email);
    } catch (e, stackTrace) {
      throw auth_exception.AuthenticationException(
        'Send email code failed: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 短信验证码登录
  Future<LoginResult> loginWithSms({
    required String phoneNumber,
    required String verificationCode,
  }) async {
    try {
      final result = await apiClient.loginWithSMS(
        phoneNumber: phoneNumber,
        code: verificationCode,
      );

      if (result.isSuccess && result.token != null) {
        await _saveSession(result.token!, result.userInfo);
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
    required String verificationCode,
  }) async {
    try {
      final result = await apiClient.loginWithEmail(
        email: email,
        code: verificationCode,
      );

      if (result.isSuccess && result.token != null) {
        await _saveSession(result.token!, result.userInfo);
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
  // 第三方登录
  // ========================================

  /// Google登录（支持多平台）
  Future<LoginResult> loginWithGoogle(BuildContext context) async {
    try {
      // 使用Google登录服务
      final googleService = GoogleSignInService();
      final result = await googleService.signIn(context);

      if (result == null) {
        throw auth_exception.PlatformException(
          'User cancelled',
          platform: 'google',
        );
      }

      // 检查WebView是否返回了callback_url
      if (result.containsKey('callbackUrl')) {
        print('✅ WebView返回回调URL，调用后端登录接口');

        // 使用callback_url调用后端登录接口
        final callbackUrl = result['callbackUrl'] as String;
        final platform = result['platform'] as String? ?? 'web';

        final loginResult = await apiClient.loginWithGoogle(
          callbackUrl: callbackUrl,
          platform: platform,
        );

        if (loginResult.isSuccess && loginResult.token != null) {
          await _saveSession(loginResult.token!, loginResult.userInfo);
        }

        return loginResult;
      } else {
        // 传统方式：使用authCode和idToken调用API
        final platform = _detectPlatform();
        print('🔍 Google登录 - 检测到平台: $platform');

        final loginResult = await apiClient.loginWithGoogle(
          authCode: result['authCode'] ?? '',
          idToken: result['idToken'],
          platform: platform, // 传递平台信息
        );

        if (loginResult.isSuccess && loginResult.token != null) {
          await _saveSession(loginResult.token!, loginResult.userInfo);
        }

        return loginResult;
      }
    } catch (e, stackTrace) {
      throw auth_exception.AuthenticationException(
        'Google login failed: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 检测当前平台
  String _detectPlatform() {
    if (kIsWeb) {
      return 'web';
    }

    // 使用GoogleSignInService的平台检测逻辑
    final googleService = GoogleSignInService();
    return googleService.getCurrentPlatform();
  }

  /// Apple登录
  Future<LoginResult> loginWithApple() async {
    try {
      if (_appleLoginCallback == null) {
        throw auth_exception.PlatformException(
          'Apple login callback not set',
          platform: 'apple',
        );
      }

      final result = await _appleLoginCallback!();
      if (result == null) {
        throw auth_exception.PlatformException(
          'User cancelled',
          platform: 'apple',
        );
      }

      final loginResult = await apiClient.loginWithApple(
        authCode: result['authCode'] ?? '',
        idToken: result['idToken'],
      );

      if (loginResult.isSuccess && loginResult.token != null) {
        await _saveSession(loginResult.token!, loginResult.userInfo);
      }

      return loginResult;
    } catch (e, stackTrace) {
      throw auth_exception.AuthenticationException(
        'Apple login failed: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Apple Web登录
  Future<LoginResult> loginWithAppleWeb(BuildContext context) async {
    try {
      print('🍎 启动Apple Web登录...');

      // 导入WebAppleLoginService
      final webAppleService = WebAppleLoginService();
      final result = await webAppleService.signIn(context);

      if (result == null) {
        throw auth_exception.PlatformException(
          'User cancelled',
          platform: 'apple',
        );
      }

      print('🔍 Apple Web登录结果: $result');

      // 检查是否是WebView回调结果
      if (result.containsKey('callbackUrl')) {
        print('✅ WebView返回回调URL，调用后端登录接口');

        // 使用callback_url调用后端登录接口
        final callbackUrl = result['callbackUrl'] as String;
        final platform = result['platform'] as String? ?? 'web';

        final loginResult = await apiClient.loginWithAppleWeb(
          callbackUrl: callbackUrl,
          platform: platform,
        );

        if (loginResult.isSuccess && loginResult.token != null) {
          await _saveSession(loginResult.token!, loginResult.userInfo);
        }

        return loginResult;
      } else {
        // 传统方式：使用authCode和idToken调用API
        final platform = _detectPlatform();
        print('🔍 Apple登录 - 检测到平台: $platform');

        final loginResult = await apiClient.loginWithApple(
          authCode: result['authCode'] ?? '',
          idToken: result['idToken'],
        );

        if (loginResult.isSuccess && loginResult.token != null) {
          await _saveSession(loginResult.token!, loginResult.userInfo);
        }

        return loginResult;
      }
    } catch (e, stackTrace) {
      throw auth_exception.AuthenticationException(
        'Apple Web login failed: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 微信登录
  Future<LoginResult> loginWithWechat() async {
    try {
      if (_wechatLoginCallback == null) {
        throw auth_exception.PlatformException(
          'Wechat login callback not set',
          platform: 'wechat',
        );
      }

      final result = await _wechatLoginCallback!();
      if (result == null) {
        throw auth_exception.PlatformException(
          'User cancelled',
          platform: 'wechat',
        );
      }

      final loginResult = await apiClient.loginWithWechat(
        result['authCode'] ?? '',
      );

      if (loginResult.isSuccess && loginResult.token != null) {
        await _saveSession(loginResult.token!, loginResult.userInfo);
      }

      return loginResult;
    } catch (e, stackTrace) {
      throw auth_exception.AuthenticationException(
        'Wechat login failed: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ========================================
  // 回调设置
  // ========================================

  void setAppleLoginCallback(
    Future<Map<String, dynamic>?> Function() callback,
  ) {
    _appleLoginCallback = callback;
  }

  void setWechatLoginCallback(
    Future<Map<String, dynamic>?> Function() callback,
  ) {
    _wechatLoginCallback = callback;
  }

  // ========================================
  // 会话管理
  // ========================================

  /// 登出
  Future<void> logout() async {
    try {
      if (_currentToken != null) {
        await apiClient.logout(_currentToken!);
      }
    } catch (e) {
      print('Warning: Logout API failed: $e');
    } finally {
      await _clearSession();
    }
  }

  /// 刷新Token
  Future<void> refreshToken() async {
    if (_currentToken == null) return;

    try {
      final newToken = await apiClient.refreshToken(_currentToken!);
      _currentToken = newToken;
      await _saveToken(newToken);
    } catch (e) {
      print('Token refresh failed: $e');
      await _clearSession();
    }
  }

  // ========================================
  // 私有方法
  // ========================================

  Future<void> _saveSession(String token, UserInfo? userInfo) async {
    _currentToken = token;
    _currentUser = userInfo;
    await _saveToken(token);
    if (userInfo != null) {
      await _saveUserInfo(userInfo);
    }
  }

  Future<void> _clearSession() async {
    _currentToken = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('easy_auth_token');
    await prefs.remove('easy_auth_user_info');
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('easy_auth_token');
      final userInfoStr = prefs.getString('easy_auth_user_info');

      if (token != null) {
        _currentToken = token;
        if (userInfoStr != null) {
          final userInfoJson = jsonDecode(userInfoStr) as Map<String, dynamic>;
          _currentUser = UserInfo.fromJson(userInfoJson);
        }
      }
    } catch (e) {
      print('Failed to restore session: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('easy_auth_token', token);
  }

  Future<void> _saveUserInfo(UserInfo userInfo) async {
    final prefs = await SharedPreferences.getInstance();
    final userInfoStr = jsonEncode(userInfo.toJson());
    await prefs.setString('easy_auth_user_info', userInfoStr);
  }
}
