import 'dart:async';
import 'package:flutter/material.dart';
import '../easy_auth_core.dart';
import '../easy_auth_models.dart';
import 'verification_login_form.dart';
import 'enhanced_third_party_login_buttons.dart';

/// EasyAuth 完整登录页面组件
///
/// 直接使用 EasyAuth 已缓存的租户配置，不重复初始化
class EasyAuthLoginPage extends StatefulWidget {
  /// 登录成功回调（可选，不提供则默认关闭页面并返回结果）
  final Function(LoginResult)? onLoginSuccess;

  /// 登录失败回调（可选）
  final Function(dynamic error)? onLoginFailed;

  const EasyAuthLoginPage({super.key, this.onLoginSuccess, this.onLoginFailed});

  @override
  State<EasyAuthLoginPage> createState() => _EasyAuthLoginPageState();
}

class _EasyAuthLoginPageState extends State<EasyAuthLoginPage> {
  bool _submitting = false; // 登录中的遮罩
  Timer? _configCheckTimer;

  @override
  void initState() {
    super.initState();
    // 定期检查配置是否加载完成
    _configCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) {
      if (EasyAuth().tenantConfig != null) {
        timer.cancel();
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _configCheckTimer?.cancel();
    super.dispose();
  }

  /// 处理登录成功
  void _handleLoginSuccess(LoginResult result) {
    if (!mounted) return;
    setState(() => _submitting = false);
    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!(result);
    }
    // 默认：关闭页面并返回结果
    Navigator.of(context).pop<LoginResult>(result);
  }

  /// 处理登录失败
  void _handleLoginFailed(dynamic error) {
    if (!mounted) return;
    setState(() => _submitting = false);
    if (widget.onLoginFailed != null) {
      widget.onLoginFailed!(error);
    }
    // 失败也立即关闭页面并把失败结果抛给外部
    Navigator.of(
      context,
    ).pop<LoginResult>(LoginResult.failure(error?.toString() ?? '登录失败'));
  }

  @override
  Widget build(BuildContext context) {
    final tenantConfig = EasyAuth().tenantConfig;
    final primaryColor = EasyAuth().primaryColor;
    final backgroundColor = EasyAuth().backgroundColor;
    final surfaceColor = EasyAuth().surfaceColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : backgroundColor,
      body: _buildBody(
        tenantConfig,
        primaryColor,
        backgroundColor,
        surfaceColor,
        isDarkMode,
      ),
    );
  }

  Widget _buildBody(
    TenantConfig? tenantConfig,
    Color primaryColor,
    Color backgroundColor,
    Color surfaceColor,
    bool isDarkMode,
  ) {
    // 如果配置为空，显示加载状态
    if (tenantConfig == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '正在加载登录配置...',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // 如果配置为空或没有支持的渠道，显示错误信息
    if (tenantConfig.supportedChannels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDarkMode ? Colors.red[300] : Colors.red[600],
            ),
            const SizedBox(height: 16),
            Text(
              '该租户未配置任何登录方式',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(
                context,
              ).pop<LoginResult>(LoginResult.failure('用户取消登录')),
              child: const Text('返回'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        SafeArea(
          child: Column(
            children: [
              // 顶部关闭按钮
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop<LoginResult>(LoginResult.failure('用户取消登录')),
                      icon: Icon(
                        Icons.close,
                        color: isDarkMode ? Colors.white : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 40), // 占位，让标题居中
                  ],
                ),
              ),

              // 主要内容区域
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),

                      // Logo 和标题
                      _buildHeader(tenantConfig, primaryColor, isDarkMode),

                      const SizedBox(height: 24),

                      // 登录方式
                      _buildLoginMethods(
                        primaryColor,
                        surfaceColor,
                        isDarkMode,
                        tenantConfig,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 登录中的遮罩
        if (_submitting)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
              child: Container(
                color: Colors.black26,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(
    TenantConfig tenantConfig,
    Color primaryColor,
    bool isDarkMode,
  ) {
    return Column(
      children: [
        // Logo
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: tenantConfig.icon != null && tenantConfig.icon!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    tenantConfig.icon!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.school, size: 40, color: primaryColor),
                  ),
                )
              : Icon(Icons.school, size: 40, color: primaryColor),
        ),

        const SizedBox(height: 16),

        // 标题
        Text(
          '登录',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginMethods(
    Color primaryColor,
    Color surfaceColor,
    bool isDarkMode,
    TenantConfig tenantConfig,
  ) {
    final channels = tenantConfig.supportedChannels;

    // 分离验证码登录和第三方登录
    final hasSMS = channels.any((ch) => ch.channelId == 'sms');
    final hasEmail = channels.any((ch) => ch.channelId == 'email');
    final hasWechat = channels.any((ch) => ch.channelId == 'wechat');
    final hasGoogle = channels.any((ch) => ch.channelId == 'google');
    final hasApple = channels.any((ch) => ch.channelId == 'apple');

    final hasVerificationLogin = hasSMS || hasEmail;
    final hasThirdPartyLogin = hasWechat || hasGoogle || hasApple;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 验证码登录（如果支持）
        if (hasVerificationLogin) ...[
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
              ),
            ),
            child: hasSMS && hasEmail
                ? DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF2A2A2A)
                                : Colors.grey[100],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: TabBar(
                            indicatorColor: primaryColor,
                            labelColor: isDarkMode
                                ? Colors.white
                                : Colors.grey[800],
                            unselectedLabelColor: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[500],
                            tabs: const [
                              Tab(text: '短信登录'),
                              Tab(text: '邮箱登录'),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            height: 180,
                            child: TabBarView(
                              children: [
                                SingleChildScrollView(
                                  child: VerificationLoginForm(
                                    type: VerificationType.sms,
                                    onLoginSuccess: _handleLoginSuccess,
                                    onLoginFailed: _handleLoginFailed,
                                    onLoginStart: () =>
                                        setState(() => _submitting = true),
                                    primaryColor: primaryColor,
                                  ),
                                ),
                                SingleChildScrollView(
                                  child: VerificationLoginForm(
                                    type: VerificationType.email,
                                    onLoginSuccess: _handleLoginSuccess,
                                    onLoginFailed: _handleLoginFailed,
                                    onLoginStart: () =>
                                        setState(() => _submitting = true),
                                    primaryColor: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: VerificationLoginForm(
                      type: hasSMS
                          ? VerificationType.sms
                          : VerificationType.email,
                      onLoginSuccess: _handleLoginSuccess,
                      onLoginFailed: _handleLoginFailed,
                      onLoginStart: () => setState(() => _submitting = true),
                      primaryColor: primaryColor,
                    ),
                  ),
          ),
        ],

        // 分隔线
        if (hasVerificationLogin && hasThirdPartyLogin) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '其他登录方式',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // 第三方登录
        if (hasThirdPartyLogin)
          EnhancedThirdPartyLoginButtons(
            showWechat: hasWechat,
            showGoogle: hasGoogle,
            showApple: hasApple,
            onLoginStart: () => setState(() => _submitting = true),
            onLoginSuccess: _handleLoginSuccess,
            onLoginFailed: _handleLoginFailed,
            suppressFeedback: true,
            primaryColor: primaryColor,
          ),
      ],
    );
  }
}
