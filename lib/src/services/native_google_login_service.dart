import 'dart:async';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import '../easy_auth_models.dart';

/// Google 原生登录服务（使用 google_sign_in 插件）
class NativeGoogleLoginService {
  static final NativeGoogleLoginService _instance =
      NativeGoogleLoginService._internal();
  factory NativeGoogleLoginService() => _instance;
  NativeGoogleLoginService._internal();

  /// 调用原生 Google 登录
  /// 返回形如：{ 'authCode': String?, 'idToken': String? }
  Future<Map<String, dynamic>?> signIn([TenantConfig? tenantConfig]) async {
    try {
      // 从TenantConfig中获取Google OAuth配置
      String? clientId;
      if (tenantConfig != null) {
        final googleChannel = tenantConfig.supportedChannels
            .where((channel) => channel.channelId == 'google')
            .firstOrNull;

        if (googleChannel?.config != null) {
          if (Platform.isAndroid) {
            clientId = googleChannel!.config!['google_client_id_android'];
          } else if (Platform.isIOS) {
            clientId = googleChannel!.config!['google_client_id_ios'];
          } else if (Platform.isWindows ||
              Platform.isLinux ||
              Platform.isMacOS) {
            clientId = googleChannel!.config!['google_client_id_desktop'];
          }
        }
      }

      // 如果从配置中获取到clientId，使用它；否则抛出错误
      if (clientId == null || clientId.isEmpty) {
        final platform = Platform.isAndroid
            ? 'android'
            : Platform.isIOS
            ? 'ios'
            : Platform.isWindows
            ? 'windows'
            : Platform.isLinux
            ? 'linux'
            : Platform.isMacOS
            ? 'macos'
            : 'desktop';
        throw Exception('Google OAuth配置缺失：未找到${platform}平台的clientId配置');
      } else {
        print('🔑 使用配置的Client ID: $clientId');
      }

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: clientId,
        scopes: ['openid'], // 只获取openid
      );

      print('🔍 开始Google原生登录...');
      final GoogleSignInAccount? account = await googleSignIn.signIn();

      if (account == null) {
        print('❌ 用户取消Google登录');
        return null; // 用户取消登录
      }

      print('✅ Google登录成功: ${account.email}');
      final GoogleSignInAuthentication auth = await account.authentication;

      return <String, dynamic>{
        'authCode': auth.accessToken,
        'idToken': auth.idToken,
      };
    } catch (e) {
      print('❌ Google原生登录失败: $e');
      // 重新抛出错误，让上层处理
      rethrow;
    }
  }
}
