import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

/// WebView登录对话框
class WebViewLoginDialog extends StatefulWidget {
  final String loginUrl;
  final Function(Map<String, dynamic>?) onResult;

  const WebViewLoginDialog({
    Key? key,
    required this.loginUrl,
    required this.onResult,
  }) : super(key: key);

  @override
  State<WebViewLoginDialog> createState() => _WebViewLoginDialogState();
}

class _WebViewLoginDialogState extends State<WebViewLoginDialog> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            print('🔍 开始加载: $url');
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            print('✅ 页面加载完成: $url');
          },
          onNavigationRequest: (NavigationRequest request) {
            print('🔍 导航请求: ${request.url}');

            // 检查是否是回调URL
            if (request.url.contains('/user/login/google/callback')) {
              print('✅ 检测到回调URL，开始处理登录结果');
              _handleCallback(request.url);
              return NavigationDecision.prevent;
            }

            // 允许所有其他导航
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ WebView资源错误: ${error.description}');
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.loginUrl));
  }

  void _handleCallback(String url) async {
    try {
      final uri = Uri.parse(url);
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];

      if (code != null) {
        print('✅ 获取到授权码: $code');

        // 调用后端API完成登录
        final loginResult = await _completeLogin(code, state);

        // 关闭对话框并返回结果
        if (mounted) {
          Navigator.of(context).pop();
        }
        widget.onResult(loginResult);
      } else {
        print('❌ 未获取到授权码');
        if (mounted) {
          Navigator.of(context).pop();
        }
        widget.onResult(null);
      }
    } catch (e) {
      print('❌ 处理回调失败: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
      widget.onResult(null);
    }
  }

  /// 调用后端API完成登录
  Future<Map<String, dynamic>?> _completeLogin(
    String code,
    String? state,
  ) async {
    try {
      print('🔄 调用后端API完成登录...');

      final response = await http.post(
        Uri.parse('https://api.janyee.com/user/login/directLogin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tenant_id': 'kiku_app',
          'scene_id': 'app_native',
          'channel_id': 'google',
          'channel_data': {'code': code, 'state': state, 'platform': 'web'},
        }),
      );

      print('📥 后端响应: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 0) {
          print('✅ 后端登录成功');
          return {
            'authCode': code,
            'state': state,
            'platform': 'web',
            'token': data['data']['token'],
            'userInfo': data['data']['user_info'],
          };
        } else {
          print('❌ 后端登录失败: ${data['msg']}');
          return null;
        }
      } else {
        print('❌ 后端请求失败: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ 调用后端API失败: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Google登录',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onResult(null);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // WebView
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
