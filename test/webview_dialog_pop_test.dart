// 验证 WebViewLoginDialog 关闭按钮只 pop 一次,不会把外层页面也 pop 掉
// (历史 bug:关闭按钮自己 pop + onResult 回调里又 pop → 把外层 EasyAuthLoginPage
//  + 业务方根页面都 pop 掉 → 黑屏)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// 重新实现 WebViewLoginDialog 的"关闭按钮 + Navigator 行为"骨架,不依赖
// InAppWebView (它在测试环境没法 mock,会要求 native plugin),只验证
// 我们关心的导航语义。
class _MockWebViewDialog extends StatefulWidget {
  final void Function(Map<String, dynamic>?) onResult;
  const _MockWebViewDialog({required this.onResult});

  @override
  State<_MockWebViewDialog> createState() => _MockWebViewDialogState();
}

class _MockWebViewDialogState extends State<_MockWebViewDialog> {
  bool _completed = false;

  void _onCloseButton() {
    if (_completed) return;
    _completed = true;
    widget.onResult(null);
  }

  Future<bool> _onWillPop() async {
    if (!_completed) {
      _completed = true;
      widget.onResult(null);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Apple 登录'),
          leading: IconButton(
            key: const Key('close-btn'),
            onPressed: _onCloseButton,
            icon: const Icon(Icons.close),
          ),
        ),
        body: const Center(child: Text('webview body')),
      ),
    );
  }
}

void main() {
  testWidgets('关闭按钮 + onResult 调用方 pop → 只关 dialog,不影响外层页面', (tester) async {
    // 模拟三层栈: 根页面 → 登录页 → WebView dialog
    Map<String, dynamic>? receivedResult;
    bool resultCalled = false;
    int rootBuilds = 0;
    int loginPageBuilds = 0;

    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (rootCtx) {
        rootBuilds++;
        return Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const Key('open-login'),
              onPressed: () {
                Navigator.of(rootCtx).push(MaterialPageRoute(
                  builder: (loginCtx) {
                    loginPageBuilds++;
                    return Scaffold(
                      appBar: AppBar(title: const Text('登录页')),
                      body: Center(
                        child: ElevatedButton(
                          key: const Key('open-webview'),
                          onPressed: () {
                            showDialog(
                              context: loginCtx,
                              barrierDismissible: false,
                              builder: (dialogCtx) => _MockWebViewDialog(
                                onResult: (result) {
                                  receivedResult = result;
                                  resultCalled = true;
                                  // 模拟 WebAppleLoginService:onResult 调用方负责 pop dialog
                                  Navigator.of(dialogCtx).pop();
                                },
                              ),
                            );
                          },
                          child: const Text('打开 WebView'),
                        ),
                      ),
                    );
                  },
                ));
              },
              child: const Text('打开登录页'),
            ),
          ),
        );
      }),
    ));

    // 进登录页
    await tester.tap(find.byKey(const Key('open-login')));
    await tester.pumpAndSettle();
    expect(find.text('登录页'), findsOneWidget);

    // 打开 WebView dialog
    await tester.tap(find.byKey(const Key('open-webview')));
    await tester.pumpAndSettle();
    expect(find.text('Apple 登录'), findsOneWidget);

    // 关闭 WebView
    await tester.tap(find.byKey(const Key('close-btn')));
    await tester.pumpAndSettle();

    // 关键断言:
    expect(resultCalled, isTrue, reason: 'onResult 必须被触发');
    expect(receivedResult, isNull, reason: '关闭按钮 → onResult(null)');
    // 关键:登录页还在,业务方根页面没被误 pop
    expect(find.text('登录页'), findsOneWidget,
        reason: 'WebView 关闭后,外层 EasyAuthLoginPage 不应该被一起 pop');
    expect(find.text('Apple 登录'), findsNothing,
        reason: 'WebView dialog 已关闭');
  });

  testWidgets('Android 返回键关闭 → 也只触发 onResult,不影响外层', (tester) async {
    Map<String, dynamic>? receivedResult;
    bool resultCalled = false;

    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (rootCtx) {
        return Scaffold(
          body: ElevatedButton(
            key: const Key('open-login'),
            onPressed: () {
              Navigator.of(rootCtx).push(MaterialPageRoute(
                builder: (loginCtx) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('登录页')),
                    body: ElevatedButton(
                      key: const Key('open-webview'),
                      onPressed: () {
                        showDialog(
                          context: loginCtx,
                          barrierDismissible: false,
                          builder: (dialogCtx) => _MockWebViewDialog(
                            onResult: (result) {
                              receivedResult = result;
                              resultCalled = true;
                              Navigator.of(dialogCtx).pop();
                            },
                          ),
                        );
                      },
                      child: const Text('open'),
                    ),
                  );
                },
              ));
            },
            child: const Text('open-login'),
          ),
        );
      }),
    ));

    await tester.tap(find.byKey(const Key('open-login')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-webview')));
    await tester.pumpAndSettle();
    expect(find.text('Apple 登录'), findsOneWidget);

    // 模拟系统返回键
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(resultCalled, isTrue, reason: '返回键也必须触发 onResult,不能让 Completer 永远 hang');
    expect(receivedResult, isNull);
    expect(find.text('登录页'), findsOneWidget,
        reason: '返回键关 dialog 后,登录页仍然在');
  });
}
