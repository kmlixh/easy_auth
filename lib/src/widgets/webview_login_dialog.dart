import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:io';

/// WebView登录对话框
class WebViewLoginDialog extends StatefulWidget {
  final String loginUrl;
  final Function(Map<String, dynamic>?) onResult;
  final String? channelId; // 登录渠道ID，用于确定回调URL
  final bool fullScreen; // 是否全屏显示

  const WebViewLoginDialog({
    Key? key,
    required this.loginUrl,
    required this.onResult,
    this.channelId,
    this.fullScreen = false,
  }) : super(key: key);

  @override
  State<WebViewLoginDialog> createState() => _WebViewLoginDialogState();
}

class _WebViewLoginDialogState extends State<WebViewLoginDialog> {
  bool _isLoading = true;
  bool _completed = false; // 防止重复调用onResult

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

  /// 根据平台类型获取合适的User-Agent
  String _getPlatformSpecificUserAgent() {
    if (Platform.isAndroid) {
      // Android平台使用移动端User-Agent，服务器会返回移动端优化页面
      return 'Mozilla/5.0 (Linux; Android 10; SM-G975F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36';
    } else {
      // 其他平台（Web、Windows、Linux等）使用桌面端User-Agent，服务器会返回桌面端页面
      return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Safari/537.36';
    }
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
    // 根据fullScreen参数决定显示方式
    if (widget.fullScreen) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_getTitle()),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          leading: IconButton(
            onPressed: () {
              // 关闭时也避免重复回调
              if (!_completed) {
                _completed = true;
                Navigator.of(context).pop();
                widget.onResult(null);
              } else {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.close),
          ),
        ),
        body: _buildWebView(),
      );
    } else {
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
                        // 关闭时也避免重复回调
                        if (!_completed) {
                          _completed = true;
                          Navigator.of(context).pop();
                          widget.onResult(null);
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // WebView
              Expanded(child: _buildWebView()),
            ],
          ),
        ),
      );
    }
  }

  /// 构建WebView组件
  Widget _buildWebView() {
    final userAgent = _getPlatformSpecificUserAgent();
    print('🔍 使用平台特定User-Agent: $userAgent');

    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.loginUrl)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            userAgent: userAgent,
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
            print('🔍 期望的回调URL: $callbackUrl');
            print('🔍 当前URL: ${url.toString()}');
            print('🔍 URL匹配检查: ${url.toString().startsWith(callbackUrl)}');

            if (url != null && url.toString().startsWith(callbackUrl)) {
              print('✅ 检测到完整回调URL，直接处理登录逻辑');
              // 直接处理回调，不需要等待页面加载完成
              _handleCallback(url.toString());
            } else {
              print('❌ URL不匹配，跳过处理');
            }
          },
          onNavigationResponse: (controller, navigationResponse) async {
            final url = navigationResponse.response?.url;
            print('🔍 导航响应: $url');

            // 检查是否是完整的回调URL（必须以回调URL开头）
            final callbackUrl = _getCallbackUrl();
            print('🔍 [导航响应] 期望的回调URL: $callbackUrl');
            print('🔍 [导航响应] 当前URL: ${url.toString()}');
            print(
              '🔍 [导航响应] URL匹配检查: ${url.toString().startsWith(callbackUrl)}',
            );

            if (url != null && url.toString().startsWith(callbackUrl)) {
              print('✅ [导航响应] 检测到完整回调URL，立即处理登录逻辑');
              // 直接处理（不再延迟，避免组件销毁后触发）
              if (!_completed) {
                _handleCallback(url.toString());
              }
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
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  void _handleCallback(String url) async {
    // 防止重复调用
    if (_completed) {
      print('⚠️ 回调已处理，跳过重复调用');
      return;
    }
    _completed = true;

    try {
      print('🔍 处理回调URL: $url');
      final uri = Uri.parse(url);
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      final error = uri.queryParameters['error'];

      print('🔍 URL参数 - code: $code, state: $state, error: $error');
      print('🔍 所有查询参数: ${uri.queryParameters}');

      // 检查是否有错误
      if (error != null) {
        print('❌ Google OAuth错误: $error');
        widget.onResult(null);
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      if (code != null && code.isNotEmpty) {
        print('✅ 获取到授权码: $code');

        // 直接返回回调URL，让EasyAuth调用后端API
        final result = {'callbackUrl': url, 'platform': 'web'};

        print('🔍 WebView返回回调URL: $result');

        // 返回结果，让调用方处理对话框关闭
        widget.onResult(result);
      } else {
        print('❌ 未获取到授权码，可能是用户取消了登录');
        widget.onResult(null);
      }
    } catch (e) {
      print('❌ 处理回调失败: $e');
      widget.onResult(null);
    }
  }
}
