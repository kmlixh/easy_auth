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

  const EnhancedThirdPartyLoginButtons({
    super.key,
    this.onLoginSuccess,
    this.onLoginFailed,
    this.showWechat = true,
    this.showApple = true,
    this.showGoogle = true,
    this.wechatButtonStyle,
    this.appleButtonStyle,
    this.googleButtonStyle,
  });

  /// 微信登录
  Future<void> _loginWithWechat(BuildContext context) async {
    try {
      print('📱 开始微信登录...');
      final result = await EasyAuth().loginWithWechat();

      if (result.isSuccess) {
        print('✅ 微信登录成功');
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
      print('❌ 微信登录失败: ${e.message}');
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
      print('❌ 微信登录异常: $e');
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
      print('🍎 开始Apple登录...');
      final result = await EasyAuth().loginWithApple();

      if (result.isSuccess) {
        print('✅ Apple登录成功');
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
      print('❌ Apple登录失败: ${e.message}');
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
      print('❌ Apple登录异常: $e');
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
      print('🔍 开始Google登录...');

      // 调用 EasyAuth 的 Google 登录方法
      // 注意：需要在宿主应用中实现 GoogleSignInService
      final result = await EasyAuth().loginWithGoogle();

      if (result.isSuccess) {
        print('✅ Google登录成功');
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
      print('❌ Google登录失败: ${e.message}');
      if (context.mounted) {
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
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black),
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
