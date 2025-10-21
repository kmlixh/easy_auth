import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'web_google_login_service.dart';
import '../easy_auth_models.dart';

/// Google登录服务类
/// 处理不同平台的Google登录逻辑
class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  factory GoogleSignInService() => _instance;
  GoogleSignInService._internal();

  /// 初始化Google Sign-In（新版本7.2.0 API）
  Future<void> _initializeGoogleSignIn([TenantConfig? tenantConfig]) async {
    final platform = getCurrentPlatform();
    print('🔑 Google Sign-In配置 - 平台: $platform');

    // 从TenantConfig中获取Google OAuth配置
    String? clientId;
    String? serverClientId;

    if (tenantConfig != null) {
      final googleChannel = tenantConfig.supportedChannels
          .where((channel) => channel.channelId == 'google')
          .firstOrNull;

      if (googleChannel?.config != null) {
        // 根据平台获取对应的客户端ID
        clientId = googleChannel!.config![platform];

        // 所有平台都需要serverClientId（Web客户端ID）
        serverClientId = googleChannel.config!['web'];
      }
    }

    // 检查配置是否有效
    if (clientId == null || clientId.isEmpty) {
      throw Exception('Google OAuth配置缺失：未找到${platform}平台的clientId配置');
    }

    print('🔑 使用配置 - clientId: $clientId, serverClientId: $serverClientId');

    // 使用新版本API初始化
    await GoogleSignInPlatform.instance.init(
      InitParameters(clientId: clientId, serverClientId: serverClientId),
    );
  }

  /// 执行Google登录（新版本7.2.0 API）
  Future<Map<String, dynamic>?> signIn(
    BuildContext context, [
    TenantConfig? tenantConfig,
  ]) async {
    try {
      final platform = getCurrentPlatform();
      print('🔍 Google登录 - 平台: $platform');

      // 先初始化GoogleSignIn
      await _initializeGoogleSignIn(tenantConfig);

      // 使用新版本API进行认证
      if (GoogleSignInPlatform.instance.supportsAuthenticate()) {
        // 支持authenticate方法的平台（Android、iOS）
        await GoogleSignInPlatform.instance.authenticate();
      } else {
        // 其他平台使用WebView登录服务
        final webService = WebGoogleLoginService();
        final result = await webService.signIn(context);

        print('🔍 WebView登录服务返回结果: $result');

        if (result == null) {
          print('❌ WebView登录被用户取消或失败');
          return null;
        }

        return result;
      }

      // 获取当前用户信息
      final GoogleSignInAccount? currentUser =
          GoogleSignInPlatform.instance.currentUser;
      if (currentUser == null) {
        print('❌ Google登录失败：未获取到用户信息');
        return null;
      }

      print('✅ Google登录成功: ${currentUser.email}');

      // 获取认证信息
      final GoogleSignInAuthentication auth = await currentUser.authentication;

      return {
        'authCode': auth.accessToken,
        'idToken': auth.idToken,
        'email': currentUser.email,
        'displayName': currentUser.displayName,
        'photoUrl': currentUser.photoUrl,
        'platform': platform,
      };
    } catch (e) {
      print('❌ Google登录失败: $e');
      rethrow;
    }
  }

  /// 登出
  Future<void> signOut([TenantConfig? tenantConfig]) async {
    try {
      await _initializeGoogleSignIn(tenantConfig);
      await GoogleSignInPlatform.instance.signOut();
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
  Future<bool> isSignedIn([TenantConfig? tenantConfig]) async {
    try {
      await _initializeGoogleSignIn(tenantConfig);
      return GoogleSignInPlatform.instance.currentUser != null;
    } catch (e) {
      print('❌ 检查Google登录状态失败: $e');
      return false;
    }
  }

  /// 获取当前用户
  Future<GoogleSignInAccount?> getCurrentUser([
    TenantConfig? tenantConfig,
  ]) async {
    try {
      await _initializeGoogleSignIn(tenantConfig);
      return GoogleSignInPlatform.instance.currentUser;
    } catch (e) {
      print('❌ 获取当前Google用户失败: $e');
      return null;
    }
  }
}
