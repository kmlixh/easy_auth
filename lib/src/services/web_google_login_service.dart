import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// Web Google登录服务
/// 使用浏览器窗口进行OAuth登录
class WebGoogleLoginService {
  static final WebGoogleLoginService _instance =
      WebGoogleLoginService._internal();
  factory WebGoogleLoginService() => _instance;
  WebGoogleLoginService._internal();

  /// 启动Web Google登录
  Future<Map<String, dynamic>?> signIn() async {
    if (!kIsWeb) {
      throw Exception('WebGoogleLoginService只能在Web平台使用');
    }

    try {
      print('🌐 启动Web Google登录...');

      // 构建登录URL
      final loginUrl = _buildLoginUrl();

      // 打开新窗口进行登录
      final popup = html.window.open(
        loginUrl,
        'google-login',
        'width=500,height=600,scrollbars=yes,resizable=yes',
      );

      if (popup == null || popup.closed!) {
        throw Exception('无法打开登录窗口，可能被浏览器阻止');
      }

      // 监听窗口关闭和消息
      return await _waitForLoginResult(popup);
    } catch (e) {
      print('❌ Web Google登录失败: $e');
      rethrow;
    }
  }

  /// 构建登录URL
  String _buildLoginUrl() {
    // 使用正确的API路径
    const baseUrl = 'https://api.janyee.com/user/login';
    return '$baseUrl/google';
  }

  /// 等待登录结果
  Future<Map<String, dynamic>?> _waitForLoginResult(html.Window popup) async {
    final completer = Completer<Map<String, dynamic>?>();

    // 监听来自登录窗口的消息
    void handleMessage(html.Event event) {
      final messageEvent = event as html.MessageEvent;
      if (messageEvent.data is Map<String, dynamic>) {
        final data = messageEvent.data as Map<String, dynamic>;
        if (data['type'] == 'GOOGLE_LOGIN_SUCCESS') {
          print('✅ Web Google登录成功');
          html.window.removeEventListener('message', handleMessage);
          completer.complete(data['data']);
        }
      }
    }

    html.window.addEventListener('message', handleMessage);

    // 检查窗口是否关闭
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (popup.closed!) {
        timer.cancel();
        html.window.removeEventListener('message', handleMessage);
        if (!completer.isCompleted) {
          print('❌ 登录窗口被关闭，未完成登录');
          completer.complete(null);
        }
      }
    });

    return completer.future;
  }
}
