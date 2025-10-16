import 'package:flutter/material.dart';
import '../easy_auth_core.dart';
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

  /// 主题色
  final Color? primaryColor;

  const EasyAuthLoginPage({
    super.key,
    this.onLoginSuccess,
    this.title = '登录',
    this.logo,
    this.primaryColor,
  });

  @override
  State<EasyAuthLoginPage> createState() => _EasyAuthLoginPageState();
}

class _EasyAuthLoginPageState extends State<EasyAuthLoginPage> {
  int _selectedTabIndex = 0;
  TenantConfig? _tenantConfig;
  bool _loading = true;

  // 验证码登录渠道（短信、邮箱）
  List<SupportedChannel> _verificationChannels = [];

  // 第三方登录渠道（微信、Apple、Google）
  List<SupportedChannel> _thirdPartyChannels = [];

  @override
  void initState() {
    super.initState();
    _loadTenantConfig();
  }

  Future<void> _loadTenantConfig() async {
    try {
      final config = await EasyAuth().apiClient.getTenantConfig();
      setState(() {
        _tenantConfig = config;

        // 分类渠道
        _verificationChannels = config.supportedChannels
            .where((ch) => ch.channelId == 'sms' || ch.channelId == 'email')
            .toList();

        _thirdPartyChannels = config.supportedChannels
            .where((ch) => ch.channelId != 'sms' && ch.channelId != 'email')
            .toList();

        _loading = false;
      });
    } catch (e) {
      print('加载租户配置失败: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  void _handleLoginSuccess(LoginResult result) {
    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!(result);
    } else {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(widget.title),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: theme.textTheme.bodyLarge?.color,
        ),
        body: const Center(child: CircularProgressIndicator()),
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

            // Tab切换（仅当有多个验证码登录方式时显示）
            if (_verificationChannels.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: List.generate(_verificationChannels.length, (
                      index,
                    ) {
                      final isSelected = _selectedTabIndex == index;
                      final channel = _verificationChannels[index];
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
                              color: isSelected
                                  ? primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              channel.channelTitle,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[700]),
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
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
                child: _buildLoginForm(primaryColor),
              ),
            ),

            // 第三方登录
            if (_thirdPartyChannels.isNotEmpty)
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
                            '使用社交账号直接登录',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[600],
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
                      availableChannels: _thirdPartyChannels
                          .map((ch) => ch.channelId)
                          .toList(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(Color primaryColor) {
    if (_verificationChannels.isEmpty) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(32), child: Text('暂无可用的登录方式')),
      );
    }

    final selectedChannel = _verificationChannels[_selectedTabIndex];

    if (selectedChannel.channelId == 'sms') {
      return SMSLoginForm(
        onLoginSuccess: _handleLoginSuccess,
        primaryColor: primaryColor,
      );
    } else if (selectedChannel.channelId == 'email') {
      return EmailLoginForm(
        onLoginSuccess: _handleLoginSuccess,
        primaryColor: primaryColor,
      );
    }

    return const SizedBox.shrink();
  }
}
