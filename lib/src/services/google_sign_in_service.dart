import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'web_google_login_service.dart';

/// Google登录服务类
/// 处理不同平台的Google登录逻辑
class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  factory GoogleSignInService() => _instance;
  GoogleSignInService._internal();

  /// 根据平台获取Google Sign-In实例
  GoogleSignIn _getGoogleSignInForPlatform() {
    final platform = getCurrentPlatform();

    print('🔑 Google Sign-In配置 - 平台: $platform');

    // 所有平台都使用Web方式登录，不指定clientId让系统自动处理
    return GoogleSignIn(
      scopes: ['openid'], // 只获取openid
    );
  }

  /// 执行Google登录
  Future<Map<String, dynamic>?> signIn(BuildContext context) async {
    try {
      final platform = getCurrentPlatform();
      print('🔍 Google登录 - 平台: $platform');

      // 所有平台都使用Web方式登录
      if (kIsWeb) {
        // Web平台直接使用GoogleSignIn
        final googleSignIn = _getGoogleSignInForPlatform();
        final GoogleSignInAccount? account = await googleSignIn.signIn();
        if (account == null) {
          print('❌ Google登录被用户取消');
          return null;
        }

        print('✅ Google登录成功: ${account.email}');
        final GoogleSignInAuthentication auth = await account.authentication;

        return {
          'authCode': auth.accessToken,
          'idToken': auth.idToken,
          'email': account.email,
          'displayName': account.displayName,
          'photoUrl': account.photoUrl,
          'platform': platform,
        };
      } else {
        // 非Web平台使用WebView登录服务
        final webService = WebGoogleLoginService();
        final result = await webService.signIn(context);

        if (result == null) {
          print('❌ WebView登录被用户取消或失败');
          return null;
        }

        return result;
      }
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
