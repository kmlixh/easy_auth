import 'dart:async';
import 'package:fluwx/fluwx.dart';
import '../easy_auth_exception.dart';
import '../easy_auth_models.dart';

/// 微信登录服务
class WechatLoginService {
  final Fluwx _fluwx = Fluwx();
  bool _isInitialized = false;

  /// 初始化
  Future<void> init(String appId) async {
    if (_isInitialized) return;
    try {
      await _fluwx.registerApi(appId: appId, doOnIOS: true, doOnAndroid: true);
      _isInitialized = true;
    } catch (e) {
      print('⚠️ Failed to register WeChat API: $e');
    }
  }

  /// 检查微信是否安装
  Future<bool> isWeChatInstalled() async {
    return await _fluwx.isWeChatInstalled;
  }

  /// 发起微信登录
  /// 返回 auth code
  Future<String?> login() async {
    if (!_isInitialized) {
      throw PlatformException('WeChat SDK not initialized', platform: 'wechat');
    }

    final isInstalled = await isWeChatInstalled();
    if (!isInstalled) {
      throw PlatformException(
        'WeChat not installed',
        platform: 'wechat',
        code: 'APP_NOT_INSTALLED',
      );
    }

    final completer = Completer<String?>();

    // 监听响应
    final subscription = _fluwx.weChatResponseEventHandler.listen((response) {
      if (response is WeChatAuthResponse) {
        if (response.errCode == 0) {
          // 成功
          if (!completer.isCompleted) {
            completer.complete(response.code);
          }
        } else if (response.errCode == -2) {
          // 用户取消
          if (!completer.isCompleted) {
            completer.completeError(
              PlatformException(
                'User cancelled',
                platform: 'wechat',
                code: 'USER_CANCELLED',
              ),
            );
          }
        } else {
          // 其他错误
          if (!completer.isCompleted) {
            completer.completeError(
              PlatformException(
                'WeChat auth failed: ${response.errStr} (code: ${response.errCode})',
                platform: 'wechat',
                code: 'AUTH_FAILED',
              ),
            );
          }
        }
      }
    });

    try {
      // 发送请求
      final sent = await _fluwx.sendWeChatAuth(
        scope: "snsapi_userinfo",
        state: "easy_auth_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (!sent) {
        throw PlatformException(
          'Failed to send WeChat auth request',
          platform: 'wechat',
        );
      }

      // 等待结果
      // 设置超时，避免一直等待
      return await completer.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          throw PlatformException(
            'WeChat login timeout',
            platform: 'wechat',
            code: 'TIMEOUT',
          );
        },
      );
    } finally {
      subscription.cancel();
    }
  }
}
