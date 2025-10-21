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

  /// 调用原生 Google 登录（新版本7.2.0 API）
  /// 返回形如：{ 'authCode': String?, 'idToken': String? }
  Future<Map<String, dynamic>?> signIn([TenantConfig? tenantConfig]) async {
    try {
      // 获取当前平台
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

      print('🔑 Google原生登录配置 - 平台: $platform');

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
      await GoogleSignIn.instance.initialize(
        clientId: clientId,
        serverClientId: serverClientId,
      );

      print('🔍 开始Google原生登录...');
      
      // 使用新版本API进行认证
      if (GoogleSignIn.instance.supportsAuthenticate()) {
        await GoogleSignIn.instance.authenticate();
      } else {
        throw Exception('当前平台不支持Google原生认证');
      }

      // 监听认证事件获取用户信息
      GoogleSignInAccount? currentUser;
      await for (final GoogleSignInAccount? user in GoogleSignIn.instance.onCurrentUserChanged) {
        currentUser = user;
        break;
      }

      if (currentUser == null) {
        print('❌ Google登录失败：未获取到用户信息');
        return null;
      }

      print('✅ Google登录成功: ${currentUser.email}');
      final GoogleSignInAuthentication auth = await currentUser.authentication;

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
