import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google登录服务类
/// 处理不同平台的Google登录逻辑
class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  factory GoogleSignInService() => _instance;
  GoogleSignInService._internal();

  // 存储从服务器获取的Google配置
  Map<String, String>? _googleConfig;

  /// 设置Google配置（从服务器获取）
  void setGoogleConfig(Map<String, String> config) {
    _googleConfig = config;
    print('🔑 Google配置已设置: $config');
  }

  /// 根据平台获取Google Sign-In实例
  GoogleSignIn _getGoogleSignInForPlatform() {
    final platform = getCurrentPlatform();

    print('🔑 Google Sign-In配置 - 平台: $platform');

    // 所有平台都使用Web方式登录
    String clientId = _getClientIdForPlatform('web');
    print('🔑 使用Web Client ID: $clientId');

    return GoogleSignIn(
      clientId: clientId,
      scopes: ['openid'], // 只获取openid
    );
  }

  /// 根据平台获取对应的Client ID
  String _getClientIdForPlatform(String platform) {
    if (_googleConfig == null) {
      throw Exception('Google配置未初始化，请先调用setGoogleConfig()');
    }

    // 根据平台选择对应的Client ID
    switch (platform) {
      case 'android':
        return _googleConfig!['android'] ?? '';
      case 'ios':
        return _googleConfig!['ios'] ?? '';
      case 'web':
        return _googleConfig!['web'] ?? '';
      case 'macos':
      case 'windows':
      case 'linux':
      case 'desktop':
        return _googleConfig!['desktop'] ?? '';
      default:
        // 默认使用桌面端配置
        return _googleConfig!['desktop'] ?? '';
    }
  }

  /// 执行Google登录
  Future<Map<String, dynamic>?> signIn() async {
    try {
      final googleSignIn = _getGoogleSignInForPlatform();
      final platform = getCurrentPlatform();

      print('🔍 Google登录 - 平台: $platform');

      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        print('❌ Google登录被用户取消');
        return null;
      }

      print('✅ Google登录成功: ${account.email}');

      // 获取认证信息
      final GoogleSignInAuthentication auth = await account.authentication;

      return {
        'authCode': auth.accessToken, // 注意：这里实际是accessToken，不是authCode
        'idToken': auth.idToken,
        'email': account.email,
        'displayName': account.displayName,
        'photoUrl': account.photoUrl,
        'platform': platform,
      };
    } catch (e) {
      print('❌ Google登录失败: $e');
      rethrow;
    }
  }

  /// 登出
  Future<void> signOut() async {
    try {
      final googleSignIn = _getGoogleSignInForPlatform();
      await googleSignIn.signOut();
      print('✅ Google登出成功');
    } catch (e) {
      print('❌ Google登出失败: $e');
      rethrow;
    }
  }

  /// 获取当前平台
  String getCurrentPlatform() {
    if (kIsWeb) {
      return 'web';
    } else if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isMacOS) {
      return 'macos';
    } else if (Platform.isWindows) {
      return 'windows';
    } else if (Platform.isLinux) {
      return 'linux';
    } else {
      return 'desktop';
    }
  }

  /// 检查是否已登录
  Future<bool> isSignedIn() async {
    try {
      final googleSignIn = _getGoogleSignInForPlatform();
      return await googleSignIn.isSignedIn();
    } catch (e) {
      print('❌ 检查Google登录状态失败: $e');
      return false;
    }
  }

  /// 获取当前用户
  Future<GoogleSignInAccount?> getCurrentUser() async {
    try {
      final googleSignIn = _getGoogleSignInForPlatform();
      return await googleSignIn.signInSilently();
    } catch (e) {
      print('❌ 获取当前Google用户失败: $e');
      return null;
    }
  }
}
