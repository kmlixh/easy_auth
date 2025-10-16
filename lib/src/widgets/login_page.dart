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

  /// 主题色
  final Color? primaryColor;

  const EasyAuthLoginPage({
    super.key,
    this.onLoginSuccess,
    this.title = '登录',
    this.logo,
    this.showSMSLogin = true,
    this.showEmailLogin = true,
    this.showThirdPartyLogin = true,
    this.primaryColor,
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
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.primaryColor;
    
    final tabs = <Widget>[];
    final tabViews = <Widget>[];

    if (widget.showSMSLogin) {
      tabs.add(const Tab(text: '短信登录'));
      tabViews.add(
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: SMSLoginForm(
            onLoginSuccess: _handleLoginSuccess,
            primaryColor: primaryColor,
          ),
        ),
      );
    }

    if (widget.showEmailLogin) {
      tabs.add(const Tab(text: '邮箱登录'));
      tabViews.add(
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: EmailLoginForm(
            onLoginSuccess: _handleLoginSuccess,
            primaryColor: primaryColor,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.textTheme.bodyLarge?.color,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Logo区域
            if (widget.logo != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: widget.logo,
              ),

            // Tab切换
            if (tabs.length > 1)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  tabs: tabs,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: primaryColor,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: theme.textTheme.bodyMedium?.color,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                ),
              ),

            const SizedBox(height: 16),

            // 登录表单
            Expanded(
              child: tabViews.isNotEmpty
                  ? TabBarView(controller: _tabController, children: tabViews)
                  : const Center(child: Text('请配置至少一种登录方式')),
            ),

            // 第三方登录
            if (widget.showThirdPartyLogin)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: theme.dividerColor.withOpacity(0.3),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '其他登录方式',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.6),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: theme.dividerColor.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ThirdPartyLoginButtons(
                      onLoginSuccess: _handleLoginSuccess,
                      primaryColor: primaryColor,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
