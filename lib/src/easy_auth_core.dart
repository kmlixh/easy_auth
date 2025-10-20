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
import 'widgets/easy_auth_login_page.dart';

/// EasyAuth核心类 - 纯Flutter包
/// 提供统一的登录、登出、Token管理功能
class EasyAuth {
  EasyAuthConfig? _config;
  EasyAuthApiClient? _apiClient;
  UserInfo? _currentUser;
  String? _currentToken;
  TenantConfig? _tenantConfig; // 缓存租户配置（含可用登录方式）

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
      final config = await apiClient.getTenantConfig();
      _tenantConfig = config; // 缓存一次，供UI直接读取
      // Google登录现在使用Web方式，不需要设置配置
    } catch (e) {
      print('⚠️ 加载租户配置失败: $e');
    }
  }

  /// 已加载的租户配置（包含 supportedChannels）。需先 init()。
  TenantConfig? get tenantConfig => _tenantConfig;

  /// 当前主题色
  Color get primaryColor => _config?.primaryColor ?? Colors.pink[300]!;

  /// 当前背景色
  Color get backgroundColor => _config?.backgroundColor ?? Colors.white;

  /// 当前表面色
  Color get surfaceColor => _config?.surfaceColor ?? Colors.grey[50]!;

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

  /// 检测是否为Web平台
  bool _isWebPlatform() {
    return kIsWeb;
  }

  // 已移除对外的统一 login() 方法，改为全屏 LoginPage

  /// Apple登录（内部API，供组件使用）
  Future<LoginResult> loginWithApple([BuildContext? context]) async {
    try {
      print('🍎 启动Apple登录...');
      return await _performAppleLogin(context);
    } catch (e, stackTrace) {
      throw auth_exception.AuthenticationException(
        'Apple login failed: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 跳转到登录页面（对外暴露的统一入口）
  Future<LoginResult> showLoginPage(BuildContext context) async {
    return await Navigator.of(context).push<LoginResult>(
          MaterialPageRoute(
            builder: (context) => const EasyAuthLoginPage(),
            fullscreenDialog: true,
          ),
        ) ??
        LoginResult.failure('用户取消登录');
  }

  /// 智能处理登录状态（已登录显示用户信息，未登录显示登录页面）
  Future<void> handleAuthState({
    required BuildContext context,
    Function(LoginResult)? onLoginSuccess,
    Function(String)? onLoginError,
    Function(UserInfo)? onUserInfoShown,
  }) async {
    if (isLoggedIn) {
      // 已登录：显示用户信息
      print('🔐 用户已登录，显示用户信息');
      _showUserInfoDialog(context, onUserInfoShown);
    } else {
      // 未登录：显示登录页面
      print('🔐 用户未登录，启动登录');
      try {
        final result = await showLoginPage(context);
        if (result.isSuccess) {
          if (onLoginSuccess != null) {
            onLoginSuccess(result);
          }
        } else {
          if (onLoginError != null) {
            onLoginError(result.message ?? '登录失败');
          }
        }
      } catch (e) {
        if (onLoginError != null) {
          onLoginError(e.toString());
        }
      }
    }
  }

  /// 显示用户信息编辑页面
  void showEditUserInfo(BuildContext context) {
    if (!isLoggedIn) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先登录')));
      return;
    }

    final user = currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('用户信息获取失败')));
      return;
    }

    _showEditUserInfoDialog(context, user);
  }

  /// 显示用户信息对话框
  void _showUserInfoDialog(
    BuildContext context,
    Function(UserInfo)? onUserInfoShown,
  ) {
    final user = currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('用户信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('昵称: ${user.nickname ?? user.username ?? 'Kiku用户'}'),
            const SizedBox(height: 8),
            Text('邮箱: ${user.email ?? '未设置'}'),
            const SizedBox(height: 8),
            Text('手机: ${user.phone ?? '未设置'}'),
            const SizedBox(height: 8),
            Text('用户ID: ${user.userId}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 显示编辑用户信息页面
              _showEditUserInfoDialog(context, user);
            },
            child: const Text('编辑'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 退出登录
              logout()
                  .then((_) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('已退出登录')));
                  })
                  .catchError((error) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('退出登录失败: $error')));
                  });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('退出登录'),
          ),
        ],
      ),
    );

    if (onUserInfoShown != null) {
      onUserInfoShown(user);
    }
  }

  /// 显示编辑用户信息对话框
  void _showEditUserInfoDialog(BuildContext context, UserInfo user) {
    final nicknameController = TextEditingController(text: user.nickname ?? '');
    final avatarController = TextEditingController(text: user.avatar ?? '');
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('编辑用户信息'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 昵称输入框
                TextField(
                  controller: nicknameController,
                  decoration: const InputDecoration(
                    labelText: '昵称',
                    hintText: '请输入昵称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // 头像URL输入框
                TextField(
                  controller: avatarController,
                  decoration: const InputDecoration(
                    labelText: '头像URL',
                    hintText: '请输入头像链接',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // 当前头像预览
                if (user.avatar != null && user.avatar!.isNotEmpty)
                  Column(
                    children: [
                      const Text(
                        '当前头像:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(user.avatar!),
                        onBackgroundImageError: (exception, stackTrace) {
                          // 头像加载失败时显示默认图标
                        },
                        child: user.avatar == null || user.avatar!.isEmpty
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() {
                        isLoading = true;
                      });

                      try {
                        // 调用更新用户信息API
                        await updateUserInfo(
                          nickname: nicknameController.text.trim().isEmpty
                              ? null
                              : nicknameController.text.trim(),
                          avatar: avatarController.text.trim().isEmpty
                              ? null
                              : avatarController.text.trim(),
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('用户信息更新成功')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('更新失败: $e')));
                        }
                      } finally {
                        if (context.mounted) {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  /// 执行Apple登录（统一内部方法）
  Future<LoginResult> _performAppleLogin([BuildContext? context]) async {
    // 规则：
    // 1) Web 平台 => WebView 登录
    // 2) 非 Web 平台但未设置原生回调 => WebView 登录
    // 3) 仅当设置了原生回调才走原生登录
    final shouldUseWeb = _isWebPlatform() || _appleLoginCallback == null;

    if (shouldUseWeb) {
      if (context == null) {
        throw auth_exception.PlatformException(
          'WebView login requires BuildContext',
          platform: 'web',
        );
      }
      return await _loginWithAppleWeb(context);
    }

    return await _loginWithAppleNative();
  }

  /// Apple原生登录（私有方法）
  Future<LoginResult> _loginWithAppleNative() async {
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
  }

  /// Apple Web登录（私有方法）
  Future<LoginResult> _loginWithAppleWeb(BuildContext context) async {
    final webAppleService = WebAppleLoginService();
    final result = await webAppleService.signIn(context);

    if (result == null) {
      throw auth_exception.PlatformException(
        'User cancelled',
        platform: 'apple',
      );
    }

    // 检查是否是WebView回调结果
    if (result.containsKey('callbackUrl')) {
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
      final loginResult = await apiClient.loginWithApple(
        authCode: result['authCode'] ?? '',
        idToken: result['idToken'],
      );

      if (loginResult.isSuccess && loginResult.token != null) {
        await _saveSession(loginResult.token!, loginResult.userInfo);
      }

      return loginResult;
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

  /// 更新用户信息
  Future<UserInfo> updateUserInfo({String? nickname, String? avatar}) async {
    if (_currentToken == null) {
      throw auth_exception.AuthenticationException('User not logged in');
    }

    try {
      final updatedUser = await apiClient.updateUserInfo(
        token: _currentToken!,
        nickname: nickname,
        avatar: avatar,
      );

      // 更新本地用户信息
      _currentUser = updatedUser;
      await _saveUserInfo(updatedUser);

      return updatedUser;
    } catch (e, stackTrace) {
      throw auth_exception.AuthenticationException(
        'Failed to update user info: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
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
