import 'package:flutter/material.dart';
import '../easy_auth_core.dart';
import '../easy_auth_exception.dart' as auth_exception;
import '../easy_auth_models.dart';

/// 增强的第三方登录按钮组件（包含 Google 登录）
class EnhancedThirdPartyLoginButtons extends StatelessWidget {
  /// 登录成功回调
  final Function(LoginResult)? onLoginSuccess;

  /// 登录失败回调
  final Function(dynamic error)? onLoginFailed;

  /// 登录开始回调（用于显示加载遮罩）
  final VoidCallback? onLoginStart;

  /// 是否抑制内部反馈（不弹SnackBar，由外部处理提示）
  final bool suppressFeedback;

  /// 显示微信登录按钮
  final bool showWechat;

  /// 显示Apple登录按钮（仅iOS）
  final bool showApple;

  /// 显示Google登录按钮
  final bool showGoogle;

  /// 按钮样式
  final ButtonStyle? wechatButtonStyle;
  final ButtonStyle? appleButtonStyle;
  final ButtonStyle? googleButtonStyle;

  /// 主题色
  final Color? primaryColor;

  const EnhancedThirdPartyLoginButtons({
    super.key,
    this.onLoginSuccess,
    this.onLoginFailed,
    this.onLoginStart,
    this.suppressFeedback = false,
    this.showWechat = true,
    this.showApple = true,
    this.showGoogle = true,
    this.wechatButtonStyle,
    this.appleButtonStyle,
    this.googleButtonStyle,
    this.primaryColor,
  });

  /// 微信登录
  Future<void> _loginWithWechat(BuildContext context) async {
    try {
      onLoginStart?.call();
      print('📱 开始微信登录...');
      final result = await EasyAuth().loginWithWechat();

      if (result.isSuccess) {
        print('✅ 微信登录成功');
        if (!suppressFeedback && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('微信登录成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
        onLoginSuccess?.call(result);
      }
    } on auth_exception.PlatformException catch (e) {
      print('❌ 微信登录失败: ${e.message}');
      if (!suppressFeedback && context.mounted) {
        String message = '微信登录失败';
        if (e.message.contains('APP_NOT_INSTALLED')) {
          message = '未安装微信';
        } else if (e.message.contains('USER_CANCELLED')) {
          message = '用户取消';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
      onLoginFailed?.call(e);
    } catch (e) {
      print('❌ 微信登录异常: $e');
      if (!suppressFeedback && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('微信登录失败: $e'), backgroundColor: Colors.red),
        );
      }
      onLoginFailed?.call(e);
    }
  }

  /// Apple登录
  Future<void> _loginWithApple(BuildContext context) async {
    try {
      onLoginStart?.call();
      print('🍎 开始Apple登录...');
      // 检测平台，决定使用原生登录还是Web登录
      final result = await _performAppleLogin(context);

      if (result.isSuccess) {
        print('✅ Apple登录成功');
        if (!suppressFeedback && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Apple登录成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
        onLoginSuccess?.call(result);
      }
    } on auth_exception.PlatformException catch (e) {
      print('❌ Apple登录失败: ${e.message}');
      if (!suppressFeedback && context.mounted) {
        String message = 'Apple登录失败';
        if (e.message.contains('UNAVAILABLE')) {
          message = '需要iOS 13.0+';
        } else if (e.message.contains('USER_CANCELLED')) {
          message = '用户取消';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
      onLoginFailed?.call(e);
    } catch (e) {
      print('❌ Apple登录异常: $e');
      if (!suppressFeedback && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Apple登录失败: $e'), backgroundColor: Colors.red),
        );
      }
      onLoginFailed?.call(e);
    }
  }

  /// 执行Apple登录（自动选择登录方式）
  Future<LoginResult> _performAppleLogin(BuildContext context) async {
    // 调用 EasyAuth 内部Apple登录，避免在登录页面里再次打开登录页面
    return await EasyAuth().loginWithApple(context);
  }

  /// Google登录
  Future<void> _loginWithGoogle(BuildContext context) async {
    try {
      onLoginStart?.call();
      print('🔍 开始Google登录...');

      // 调用 EasyAuth 的 Google 登录方法
      // 注意：需要在宿主应用中实现 GoogleSignInService
      final result = await EasyAuth().loginWithGoogle(context);

      if (result.isSuccess) {
        print('✅ Google登录成功');
        if (!suppressFeedback && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google登录成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
        onLoginSuccess?.call(result);
      }
    } on auth_exception.PlatformException catch (e) {
      print('❌ Google登录失败: ${e.message}');
      if (!suppressFeedback && context.mounted) {
        String message = 'Google登录失败';
        if (e.message.contains('UNAVAILABLE')) {
          message = 'Google服务不可用';
        } else if (e.message.contains('USER_CANCELLED')) {
          message = '用户取消';
        } else if (e.message.contains('SIGN_IN_FAILED')) {
          message = '登录失败，请重试';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
      onLoginFailed?.call(e);
    } catch (e) {
      print('❌ Google登录异常: $e');
      if (!suppressFeedback && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google登录失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      onLoginFailed?.call(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final buttons = <Widget>[];

    // 微信登录按钮
    if (showWechat) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _loginWithWechat(context),
            style:
                wechatButtonStyle ??
                OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF07C160),
                  side: const BorderSide(color: Color(0xFF07C160)),
                  backgroundColor: isDarkMode
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                ),
            icon: const Icon(Icons.wechat, size: 24),
            label: const Text('微信登录'),
          ),
        ),
      );
    }

    // Google登录按钮
    if (showGoogle) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(height: 12));
      }
      buttons.add(
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _loginWithGoogle(context),
            style:
                googleButtonStyle ??
                OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4285F4),
                  side: const BorderSide(color: Color(0xFF4285F4)),
                  backgroundColor: isDarkMode
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                ),
            icon: const Icon(Icons.g_mobiledata, size: 32),
            label: const Text('Google登录'),
          ),
        ),
      );
    }

    // Apple登录按钮（所有平台）
    if (showApple) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(height: 12));
      }
      buttons.add(
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _loginWithApple(context),
            style:
                appleButtonStyle ??
                OutlinedButton.styleFrom(
                  foregroundColor: isDarkMode ? Colors.white : Colors.black,
                  side: BorderSide(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  backgroundColor: isDarkMode
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                ),
            icon: const Icon(Icons.apple, size: 24),
            label: const Text('Apple登录'),
          ),
        ),
      );
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: buttons,
    );
  }
}
