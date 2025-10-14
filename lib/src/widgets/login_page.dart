import 'package:flutter/material.dart';
import '../easy_auth_models.dart';
import 'sms_login_form.dart';
import 'email_login_form.dart';
import 'third_party_login_buttons.dart';

/// 预置完整登录页面
class EasyAuthLoginPage extends StatefulWidget {
  /// 登录成功回调（可选，不提供则默认pop）
  final Function(LoginResult)? onLoginSuccess;

  /// 标题
  final String title;

  /// Logo
  final Widget? logo;

  /// 显示短信登录
  final bool showSMSLogin;

  /// 显示邮箱登录
  final bool showEmailLogin;

  /// 显示第三方登录
  final bool showThirdPartyLogin;

  const EasyAuthLoginPage({
    super.key,
    this.onLoginSuccess,
    this.title = '登录',
    this.logo,
    this.showSMSLogin = true,
    this.showEmailLogin = true,
    this.showThirdPartyLogin = true,
  });

  @override
  State<EasyAuthLoginPage> createState() => _EasyAuthLoginPageState();
}

class _EasyAuthLoginPageState extends State<EasyAuthLoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final tabCount =
        (widget.showSMSLogin ? 1 : 0) + (widget.showEmailLogin ? 1 : 0);
    _tabController = TabController(
      length: tabCount > 0 ? tabCount : 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleLoginSuccess(LoginResult result) {
    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!(result);
    } else {
      // 默认行为：关闭登录页
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[];
    final tabViews = <Widget>[];

    if (widget.showSMSLogin) {
      tabs.add(const Tab(text: '短信登录'));
      tabViews.add(
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SMSLoginForm(onLoginSuccess: _handleLoginSuccess),
        ),
      );
    }

    if (widget.showEmailLogin) {
      tabs.add(const Tab(text: '邮箱登录'));
      tabViews.add(
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: EmailLoginForm(onLoginSuccess: _handleLoginSuccess),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
        bottom: tabs.isNotEmpty
            ? TabBar(controller: _tabController, tabs: tabs)
            : null,
      ),
      body: Column(
        children: [
          // Logo区域
          if (widget.logo != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: widget.logo,
            ),

          // 登录表单
          Expanded(
            child: tabViews.isNotEmpty
                ? TabBarView(controller: _tabController, children: tabViews)
                : const Center(child: Text('请配置至少一种登录方式')),
          ),

          // 第三方登录
          if (widget.showThirdPartyLogin)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '其他登录方式',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ThirdPartyLoginButtons(onLoginSuccess: _handleLoginSuccess),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
