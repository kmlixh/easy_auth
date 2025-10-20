import 'dart:async';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Apple 原生登录服务（使用 sign_in_with_apple 插件）
class NativeAppleLoginService {
  static final NativeAppleLoginService _instance =
      NativeAppleLoginService._internal();
  factory NativeAppleLoginService() => _instance;
  NativeAppleLoginService._internal();

  /// 调用原生 Apple 登录
  /// 返回形如：{ 'authCode': String?, 'idToken': String? }
  Future<Map<String, dynamic>?> signIn() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [], // 仅获取 code/idToken，不请求姓名邮箱
    );

    return <String, dynamic>{
      'authCode': credential.authorizationCode,
      'idToken': credential.identityToken,
    };
  }
}
