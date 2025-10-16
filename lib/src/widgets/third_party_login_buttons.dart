import 'package:flutter/material.dart';
import '../easy_auth_core.dart';
import '../easy_auth_exception.dart' as auth_exception;
import '../easy_auth_models.dart';

/// 第三方登录按钮组件
class ThirdPartyLoginButtons extends StatelessWidget {
  /// 登录成功回调
  final Function(LoginResult)? onLoginSuccess;

  /// 登录失败回调
  final Function(dynamic error)? onLoginFailed;

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

  const ThirdPartyLoginButtons({
    super.key,
    this.onLoginSuccess,
    this.onLoginFailed,
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
      final result = await EasyAuth().loginWithWechat();

      if (result.isSuccess) {
        if (context.mounted) {
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
      if (context.mounted) {
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
      if (context.mounted) {
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
      final result = await EasyAuth().loginWithApple();

      if (result.isSuccess) {
        if (context.mounted) {
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
      if (context.mounted) {
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Apple登录失败: $e'), backgroundColor: Colors.red),
        );
      }
      onLoginFailed?.call(e);
    }
  }

  /// Google登录
  Future<void> _loginWithGoogle(BuildContext context) async {
    try {
      final result = await EasyAuth().loginWithGoogle();

      if (result.isSuccess) {
        if (context.mounted) {
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
      if (context.mounted) {
        String message = 'Google登录失败';
        if (e.message.contains('USER_CANCELLED')) {
          message = '用户取消';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
      onLoginFailed?.call(e);
    } catch (e) {
      if (context.mounted) {
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
    final theme = Theme.of(context);
    final buttons = <Widget>[];

    // 微信登录按钮
    if (showWechat) {
      buttons.add(
        _buildLoginButton(
          context: context,
          icon: Icons.wechat,
          label: '微信登录',
          color: const Color(0xFF07C160),
          onPressed: () => _loginWithWechat(context),
          style: wechatButtonStyle,
        ),
      );
    }

    // Apple登录按钮
    if (showApple) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(height: 12));
      }
      buttons.add(
        _buildLoginButton(
          context: context,
          icon: Icons.apple,
          label: 'Apple登录',
          color: theme.brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
          onPressed: () => _loginWithApple(context),
          style: appleButtonStyle,
        ),
      );
    }

    // Google登录按钮
    if (showGoogle) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(height: 12));
      }
      buttons.add(
        _buildLoginButton(
          context: context,
          icon: Icons.g_mobiledata,
          label: 'Google登录',
          color: const Color(0xFF4285F4),
          onPressed: () => _loginWithGoogle(context),
          style: googleButtonStyle,
          iconSize: 32,
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

  Widget _buildLoginButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    ButtonStyle? style,
    double iconSize = 24,
  }) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style:
            style ??
            OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withOpacity(0.3), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
        icon: Icon(icon, size: iconSize),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
