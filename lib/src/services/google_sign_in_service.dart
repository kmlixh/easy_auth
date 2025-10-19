import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google登录服务类
/// 处理不同平台的Google登录逻辑
/// 注意：Client ID应该从后端API获取，不在此处硬编码
class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  factory GoogleSignInService() => _instance;
  GoogleSignInService._internal();

  /// 根据平台获取Google Sign-In实例
  /// 注意：Client ID应该从后端API获取，这里使用占位符
  GoogleSignIn _getGoogleSignInForPlatform() {
    final platform = getCurrentPlatform();

    // TODO: 从后端API获取Client ID，而不是硬编码
    // 这里应该调用租户配置API获取Google的Client ID配置
    // 然后根据平台选择对应的Client ID

    // 临时使用占位符（实际使用时需要从API获取）
    String clientId = 'PLACEHOLDER_CLIENT_ID';

    print('🔑 Google Sign-In配置 - 平台: $platform, Client ID: $clientId');
    print('⚠️ 警告：当前使用占位符Client ID，需要从后端API获取真实配置');

    return GoogleSignIn(
      clientId: clientId,
      scopes: ['openid', 'profile', 'email'],
    );
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
