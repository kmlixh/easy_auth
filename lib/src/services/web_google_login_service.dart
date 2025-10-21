import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/webview_login_dialog.dart';

/// Web Google登录服务
/// 使用WebView进行OAuth登录
class WebGoogleLoginService {
  static final WebGoogleLoginService _instance =
      WebGoogleLoginService._internal();
  factory WebGoogleLoginService() => _instance;
  WebGoogleLoginService._internal();

  /// 启动Web Google登录
  Future<Map<String, dynamic>?> signIn(BuildContext context) async {
    try {
      print('🌐 启动Web Google登录...');

      // 构建登录URL
      final loginUrl = _buildLoginUrl();
      print('🔗 登录URL: $loginUrl');

      // 使用WebView进行登录
      return await _showWebViewLogin(context, loginUrl);
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

  /// 显示WebView登录页面
  Future<Map<String, dynamic>?> _showWebViewLogin(
    BuildContext context,
    String loginUrl,
  ) async {
    final completer = Completer<Map<String, dynamic>?>();
    bool completed = false;

    // 使用全屏Dialog进行登录
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return WebViewLoginDialog(
          loginUrl: loginUrl,
          channelId: 'google',
          fullScreen: true, // 使用全屏显示
          onResult: (result) {
            if (!completed) {
              completed = true;
              completer.complete(result);
              Navigator.of(dialogContext).pop();
            }
          },
        );
      },
    );

    return completer.future;
  }
}
