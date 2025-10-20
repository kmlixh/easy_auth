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

  /// 可用的登录渠道ID列表（从后端获取）
  final List<String>? availableChannels;

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
    this.availableChannels,
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
    // 防连点：全局节流
    // 使用库级别的静态标志（简易防抖）
    if (_AppleLoginGuard.inProgress) return;
    _AppleLoginGuard.inProgress = true;
    try {
      // 平台选择与回退由 EasyAuth 内部统一处理
      final result = await _performAppleLogin(context);

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
    } finally {
      _AppleLoginGuard.inProgress = false;
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
      final result = await EasyAuth().loginWithGoogle(context);

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
    final iconButtons = <Widget>[];

    // 判断是否可用
    bool isChannelAvailable(String channelId) {
      if (availableChannels == null) return true;
      return availableChannels!.contains(channelId);
    }

    // 微信登录按钮
    if (showWechat && isChannelAvailable('wechat')) {
      iconButtons.add(
        _buildIconButton(
          context: context,
          icon: Icons.wechat,
          label: '微信',
          color: const Color(0xFF07C160),
          onPressed: () => _loginWithWechat(context),
        ),
      );
    }

    // Apple登录按钮
    if (showApple && isChannelAvailable('apple')) {
      iconButtons.add(
        _buildIconButton(
          context: context,
          icon: Icons.apple,
          label: 'Apple',
          color: theme.brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
          onPressed: () => _loginWithApple(context),
        ),
      );
    }

    // Google登录按钮
    if (showGoogle && isChannelAvailable('google')) {
      iconButtons.add(
        _buildIconButton(
          context: context,
          icon: Icons.g_mobiledata,
          label: 'Google',
          color: const Color(0xFF4285F4),
          onPressed: () => _loginWithGoogle(context),
          iconSize: 32,
        ),
      );
    }

    if (iconButtons.isEmpty) {
      return const SizedBox.shrink();
    }

    // 使用圆形图标按钮布局
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _intersperse(iconButtons, const SizedBox(width: 32)).toList(),
    );
  }

  List<Widget> _intersperse(List<Widget> list, Widget separator) {
    if (list.isEmpty) return list;
    final result = <Widget>[];
    for (var i = 0; i < list.length; i++) {
      result.add(list[i]);
      if (i < list.length - 1) {
        result.add(separator);
      }
    }
    return result;
  }

  Widget _buildIconButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    double iconSize = 28,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.grey[850] : Colors.grey[100],
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(30),
              child: Center(
                child: Icon(icon, size: iconSize, color: color),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

/// Apple 登录节流保护（避免多次点击同时触发）
class _AppleLoginGuard {
  static bool inProgress = false;
}
