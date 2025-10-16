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

class _EasyAuthLoginPageState extends State<EasyAuthLoginPage> {
  int _selectedTabIndex = 0;

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
    final isDark = theme.brightness == Brightness.dark;
    
    final tabs = <String>[];
    final tabViews = <Widget>[];

    if (widget.showSMSLogin) {
      tabs.add('短信登录');
      tabViews.add(
        SMSLoginForm(
          onLoginSuccess: _handleLoginSuccess,
          primaryColor: primaryColor,
        ),
      );
    }

    if (widget.showEmailLogin) {
      tabs.add('邮箱登录');
      tabViews.add(
        EmailLoginForm(
          onLoginSuccess: _handleLoginSuccess,
          primaryColor: primaryColor,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: List.generate(tabs.length, (index) {
                      final isSelected = _selectedTabIndex == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTabIndex = index;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              tabs[index],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.grey[400] : Colors.grey[700]),
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

            // 登录表单
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: tabViews.isNotEmpty
                    ? tabViews[_selectedTabIndex]
                    : const Center(child: Text('请配置至少一种登录方式')),
              ),
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
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[500] : Colors.grey[600],
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
