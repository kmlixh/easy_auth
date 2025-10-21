import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'web_google_login_service.dart';
import '../easy_auth_models.dart';

/// Google登录服务类
/// 处理不同平台的Google登录逻辑（合并原生和WebView登录）
class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  factory GoogleSignInService() => _instance;
  GoogleSignInService._internal();

  /// 执行Google登录（新版本7.2.0 API）
  /// 返回形如：{ 'idToken': String?, 'email': String?, 'displayName': String? }
  Future<Map<String, dynamic>?> signIn(
    BuildContext context, [
    TenantConfig? tenantConfig,
  ]) async {
    try {
      final platform = getCurrentPlatform();
      print('🔍 Google登录 - 平台: $platform');

      // 根据平台选择登录方式
      if (platform == 'android' || platform == 'ios' || platform == 'macos') {
        // Android 和 iOS 使用原生登录
        return await _signInNative(tenantConfig);
      } else {
        // 其他平台使用WebView登录
        return await _signInWebView(context);
      }
    } catch (e) {
      print('❌ Google登录失败: $e');
      rethrow;
    }
  }

  /// 原生登录（Android/iOS）
  Future<Map<String, dynamic>?> _signInNative([
    TenantConfig? tenantConfig,
  ]) async {
    try {
      // 从TenantConfig中获取Google OAuth配置
      String? clientId;
      String? serverClientId;

      if (tenantConfig != null) {
        final googleChannel = tenantConfig.supportedChannels
            .where((channel) => channel.channelId == 'google')
            .firstOrNull;

        if (googleChannel?.config != null) {
          final platform = getCurrentPlatform();
          clientId = googleChannel!.config![platform];
          serverClientId = googleChannel.config!['web'];
        }
      }

      // 检查配置是否有效
      if (clientId == null || clientId.isEmpty) {
        throw Exception(
          'Google OAuth配置缺失：未找到${getCurrentPlatform()}平台的clientId配置',
        );
      }

      print('🔑 使用配置 - clientId: $clientId, serverClientId: $serverClientId');

      // 使用新版本API初始化（Android需要serverClientId）
      await GoogleSignIn.instance.initialize(
        clientId: clientId,
        serverClientId: serverClientId,
      );

      print('🔍 开始Google原生登录...');

      // 使用新版本API进行认证
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw Exception('当前平台不支持Google原生认证');
      }

      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate(scopeHint: const <String>['openid','profile','email']);

      print('✅ Google登录成功: ${googleUser.email}');
      final GoogleSignInAuthentication auth = await googleUser.authentication;

      // 7.2.0 版本只返回 idToken，没有 accessToken
      return <String, dynamic>{
        'idToken': auth.idToken,
        'email': googleUser.email,
        'displayName': googleUser.displayName,
        'photoUrl': googleUser.photoUrl,
        'platform': getCurrentPlatform(),
      };
    } catch (e) {
      print('❌ Google原生登录失败: $e');
      rethrow;
    }
  }

  /// WebView登录（Web/Desktop）
  Future<Map<String, dynamic>?> _signInWebView(BuildContext context) async {
    try {
      final webService = WebGoogleLoginService();
      final result = await webService.signIn(context);

      print('🔍 WebView登录服务返回结果: $result');

      if (result == null) {
        print('❌ WebView登录被用户取消或失败');
        return null;
      }

      return result;
    } catch (e) {
      print('❌ WebView登录失败: $e');
      rethrow;
    }
  }

  /// 登出
  Future<void> signOut([TenantConfig? tenantConfig]) async {
    try {
      // 从TenantConfig中获取Google OAuth配置
      String? clientId;
      String? serverClientId;

      if (tenantConfig != null) {
        final googleChannel = tenantConfig.supportedChannels
            .where((channel) => channel.channelId == 'google')
            .firstOrNull;

        if (googleChannel?.config != null) {
          final platform = getCurrentPlatform();
          clientId = googleChannel!.config![platform];
          serverClientId = googleChannel.config!['web'];
        }
      }

      if (clientId != null && clientId.isNotEmpty) {
        await GoogleSignIn.instance.initialize(
          clientId: clientId,
          serverClientId: serverClientId,
        );
        await GoogleSignIn.instance.signOut();
      }
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
      // 从TenantConfig中获取Google OAuth配置
      String? clientId;
      String? serverClientId;

      if (tenantConfig != null) {
        final googleChannel = tenantConfig.supportedChannels
            .where((channel) => channel.channelId == 'google')
            .firstOrNull;

        if (googleChannel?.config != null) {
          final platform = getCurrentPlatform();
          clientId = googleChannel!.config![platform];
          serverClientId = googleChannel.config!['web'];
        }
      }

      if (clientId != null && clientId.isNotEmpty) {
        await GoogleSignIn.instance.initialize(
          clientId: clientId,
          serverClientId: serverClientId,
        );
        // 7.2.0 版本没有 currentUser 属性，需要通过其他方式检查
        return false; // 暂时返回 false，需要重新实现
      }
      return false;
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
      // 从TenantConfig中获取Google OAuth配置
      String? clientId;
      String? serverClientId;

      if (tenantConfig != null) {
        final googleChannel = tenantConfig.supportedChannels
            .where((channel) => channel.channelId == 'google')
            .firstOrNull;

        if (googleChannel?.config != null) {
          final platform = getCurrentPlatform();
          clientId = googleChannel!.config![platform];
          serverClientId = googleChannel.config!['web'];
        }
      }

      if (clientId != null && clientId.isNotEmpty) {
        await GoogleSignIn.instance.initialize(
          clientId: clientId,
          serverClientId: serverClientId,
        );
        // 7.2.0 版本没有 currentUser 属性，需要通过其他方式获取
        return null; // 暂时返回 null，需要重新实现
      }
      return null;
    } catch (e) {
      print('❌ 获取当前Google用户失败: $e');
      return null;
    }
  }
}
