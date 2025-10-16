import 'package:flutter/material.dart';
import '../easy_auth_core.dart';
import '../easy_auth_models.dart';
import '../easy_auth_exception.dart' as auth_exception;
import 'sms_login_form.dart';
import 'email_login_form.dart';
import 'enhanced_third_party_login_buttons.dart';

/// EasyAuth 完整登录页面组件
///
/// 根据租户配置自动显示支持的登录方式
/// 只需传入 baseUrl 和 tenantId，其他配置自动从后端获取
class EasyAuthLoginPage extends StatefulWidget {
  /// API基础URL（必传）
  final String baseUrl;

  /// 租户ID（必传）
  final String tenantId;

  /// 登录场景ID（可选，默认 "app_native"）
  final String sceneId;

  /// 登录成功回调
  final Function(LoginResult)? onLoginSuccess;

  /// 登录失败回调
  final Function(dynamic error)? onLoginFailed;

  /// 页面标题
  final String? title;

  /// Logo
  final Widget? logo;

  /// 主题色
  final Color? primaryColor;

  const EasyAuthLoginPage({
    super.key,
    required this.baseUrl,
    required this.tenantId,
    this.sceneId = 'app_native',
    this.onLoginSuccess,
    this.onLoginFailed,
    this.title,
    this.logo,
    this.primaryColor,
  });

  @override
  State<EasyAuthLoginPage> createState() => _EasyAuthLoginPageState();
}

class _EasyAuthLoginPageState extends State<EasyAuthLoginPage> {
  bool _loading = true;
  String? _error;
  TenantConfig? _tenantConfig;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  /// 初始化认证并获取租户配置
  Future<void> _initializeAuth() async {
    try {
      print('🔧 初始化 EasyAuth...');
      print('   BaseURL: ${widget.baseUrl}');
      print('   TenantID: ${widget.tenantId}');
      print('   SceneID: ${widget.sceneId}');

      // 1. 初始化 EasyAuth
      await EasyAuth().init(
        EasyAuthConfig(
          baseUrl: widget.baseUrl,
          tenantId: widget.tenantId,
          sceneId: widget.sceneId,
          enableAutoRefresh: true,
        ),
      );

      // 2. 获取租户配置
      print('📡 获取租户配置...');
      final config = await EasyAuth().apiClient.getTenantConfig(
        widget.tenantId,
      );

      print('✅ 租户配置加载成功');
      print('   租户名称: ${config.tenantName}');
      print(
        '   支持的渠道: ${config.supportedChannels.map((e) => e.channelId).join(", ")}',
      );

      setState(() {
        _tenantConfig = config;
        _loading = false;
      });
    } catch (e, stack) {
      print('❌ 初始化失败: $e');
      print('   Stack: $stack');
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? Colors.pink[300]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? '登录'),
        backgroundColor: primaryColor,
      ),
      body: _buildBody(primaryColor),
    );
  }

  Widget _buildBody(Color primaryColor) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载登录配置...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _initializeAuth();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (_tenantConfig == null || _tenantConfig!.supportedChannels.isEmpty) {
      return const Center(child: Text('该租户未配置任何登录方式'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo
          widget.logo ??
              Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.school, size: 60, color: primaryColor),
              ),

          const SizedBox(height: 20),

          // 租户名称
          Text(
            _tenantConfig!.tenantName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 32),

          // 渲染支持的登录方式
          _buildLoginMethods(primaryColor),
        ],
      ),
    );
  }

  Widget _buildLoginMethods(Color primaryColor) {
    final channels = _tenantConfig!.supportedChannels;

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
          if (hasSMS && hasEmail)
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: '短信登录'),
                      Tab(text: '邮箱登录'),
                    ],
                  ),
                  SizedBox(
                    height: 280,
                    child: TabBarView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: SMSLoginForm(
                            onLoginSuccess: widget.onLoginSuccess,
                            onLoginFailed: widget.onLoginFailed,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: EmailLoginForm(
                            onLoginSuccess: widget.onLoginSuccess,
                            onLoginFailed: widget.onLoginFailed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (hasSMS)
            SMSLoginForm(
              onLoginSuccess: widget.onLoginSuccess,
              onLoginFailed: widget.onLoginFailed,
            )
          else if (hasEmail)
            EmailLoginForm(
              onLoginSuccess: widget.onLoginSuccess,
              onLoginFailed: widget.onLoginFailed,
            ),
        ],

        // 分隔线
        if (hasVerificationLogin && hasThirdPartyLogin) ...[
          const SizedBox(height: 24),
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
          const SizedBox(height: 24),
        ],

        // 第三方登录
        if (hasThirdPartyLogin)
          EnhancedThirdPartyLoginButtons(
            showWechat: hasWechat,
            showGoogle: hasGoogle,
            showApple: hasApple,
            onLoginSuccess: widget.onLoginSuccess,
            onLoginFailed: widget.onLoginFailed,
          ),
      ],
    );
  }
}
