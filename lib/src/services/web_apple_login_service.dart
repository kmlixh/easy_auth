import 'dart:async';
import 'package:flutter/material.dart';
import '../easy_auth_core.dart';
import '../widgets/webview_login_dialog.dart';

/// Web Apple登录服务
/// 使用WebView进行OAuth登录
class WebAppleLoginService {
  static final WebAppleLoginService _instance =
      WebAppleLoginService._internal();
  factory WebAppleLoginService() => _instance;
  WebAppleLoginService._internal();

  /// 启动Web Apple登录
  Future<Map<String, dynamic>?> signIn(BuildContext context) async {
    try {
      print('🍎 启动Web Apple登录...');

      // 构建登录URL
      final loginUrl = _buildLoginUrl();
      print('🔗 登录URL: $loginUrl');

      // 使用WebView进行登录
      return await _showWebViewLogin(context, loginUrl);
    } catch (e) {
      print('❌ Web Apple登录失败: $e');
      rethrow;
    }
  }

  /// 构建登录URL
  ///
  /// **必须带 tenant_id 参数**。不带的话 AnyLogin 后端会 fallback 到默认 tenant
  /// (kiku),用 kiku 的 Apple Service ID 起步 OAuth,但 callback 后又按
  /// SDK 持有的 tenant 去 exchange token → client_id mismatch。
  String _buildLoginUrl() {
    final cfg = EasyAuth().config;
    final baseUrl = cfg.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final tenantId = Uri.encodeQueryComponent(cfg.tenantId);
    return '$baseUrl/login/apple?tenant_id=$tenantId';
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
          channelId: 'apple',
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
