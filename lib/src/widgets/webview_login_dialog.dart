import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// WebView登录对话框
class WebViewLoginDialog extends StatefulWidget {
  final String loginUrl;
  final Function(Map<String, dynamic>?) onResult;
  final String? channelId; // 登录渠道ID，用于确定回调URL

  const WebViewLoginDialog({
    Key? key,
    required this.loginUrl,
    required this.onResult,
    this.channelId,
  }) : super(key: key);

  @override
  State<WebViewLoginDialog> createState() => _WebViewLoginDialogState();
}

class _WebViewLoginDialogState extends State<WebViewLoginDialog> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
  }

  /// 获取回调URL
  String _getCallbackUrl() {
    final channelId = widget.channelId ?? 'google'; // 默认为google
    if (channelId == 'apple') {
      return 'https://api.janyee.com/user/apple/callback';
    }
    return 'https://api.janyee.com/user/login/$channelId/callback';
  }

  /// 获取标题
  String _getTitle() {
    final channelId = widget.channelId ?? 'google';
    switch (channelId) {
      case 'apple':
        return 'Apple 登录';
      case 'google':
        return 'Google 登录';
      default:
        return '$channelId 登录';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _getTitle(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onResult(null);
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // WebView
            Expanded(
              child: Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(widget.loginUrl)),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      userAgent:
                          'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1',
                      allowsInlineMediaPlayback: true,
                      mediaPlaybackRequiresUserGesture: false,
                    ),
                    onLoadStart: (controller, url) {
                      setState(() {
                        _isLoading = true;
                      });
                      print('🔍 开始加载: $url');
                    },
                    onLoadStop: (controller, url) {
                      setState(() {
                        _isLoading = false;
                      });
                      print('✅ 页面加载完成: $url');

                      // 检查是否是完整的回调URL（必须以回调URL开头）
                      final callbackUrl = _getCallbackUrl();
                      if (url != null &&
                          url.toString().startsWith(callbackUrl)) {
                        print('✅ 检测到完整回调URL，直接处理登录逻辑');
                        // 直接处理回调，不需要等待页面加载完成
                        _handleCallback(url.toString());
                      }
                    },
                    onNavigationResponse:
                        (controller, navigationResponse) async {
                          final url = navigationResponse.response?.url;
                          print('🔍 导航响应: $url');

                          // 检查是否是完整的回调URL（必须以回调URL开头）
                          final callbackUrl = _getCallbackUrl();
                          if (url != null &&
                              url.toString().startsWith(callbackUrl)) {
                            print('✅ 检测到完整回调URL，立即处理登录逻辑');
                            // 立即处理回调，不等待页面加载
                            Future.delayed(
                              const Duration(milliseconds: 100),
                              () {
                                _handleCallback(url.toString());
                              },
                            );
                            return NavigationResponseAction.ALLOW;
                          }

                          // 允许所有其他导航
                          return NavigationResponseAction.ALLOW;
                        },
                    onReceivedError: (controller, request, error) {
                      print('❌ WebView错误: ${error.description}');
                      setState(() {
                        _isLoading = false;
                      });
                    },
                  ),
                  // 加载指示器
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

  void _handleCallback(String url) async {
    try {
      print('🔍 处理回调URL: $url');
      final uri = Uri.parse(url);
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      final error = uri.queryParameters['error'];

      print('🔍 URL参数 - code: $code, state: $state, error: $error');

      // 检查是否有错误
      if (error != null) {
        print('❌ Google OAuth错误: $error');
        if (mounted) {
          Navigator.of(context).pop();
        }
        widget.onResult(null);
        return;
      }

      if (code != null && code.isNotEmpty) {
        print('✅ 获取到授权码: $code');

        // 直接返回回调URL，让EasyAuth调用后端API
        final result = {'callbackUrl': url, 'platform': 'web'};

        print('🔍 WebView返回回调URL: $result');

        // 关闭对话框并返回结果
        if (mounted) {
          Navigator.of(context).pop();
        }
        widget.onResult(result);
      } else {
        print('❌ 未获取到授权码，可能是用户取消了登录');
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
}
