import 'dart:async';
import 'package:flutter/material.dart';
import '../easy_auth_core.dart';
import '../easy_auth_exception.dart' as auth_exception;
import '../easy_auth_models.dart';

/// 邮箱验证码登录表单组件
class EmailLoginForm extends StatefulWidget {
  /// 登录成功回调
  final Function(LoginResult)? onLoginSuccess;

  /// 登录失败回调
  final Function(dynamic error)? onLoginFailed;

  /// 自定义样式
  final InputDecoration? emailDecoration;
  final InputDecoration? codeDecoration;
  final ButtonStyle? sendButtonStyle;
  final ButtonStyle? loginButtonStyle;

  /// 倒计时秒数
  final int countdownSeconds;

  /// 主题色
  final Color? primaryColor;

  const EmailLoginForm({
    super.key,
    this.onLoginSuccess,
    this.onLoginFailed,
    this.emailDecoration,
    this.codeDecoration,
    this.sendButtonStyle,
    this.loginButtonStyle,
    this.countdownSeconds = 60,
    this.primaryColor,
  });

  @override
  State<EmailLoginForm> createState() => _EmailLoginFormState();
}

class _EmailLoginFormState extends State<EmailLoginForm> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// 发送验证码
  Future<void> _sendCode() async {
    if (_countdown > 0) return;

    // 验证邮箱
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await EasyAuth().sendEmailCode(_emailController.text);

      // 开始倒计时
      setState(() => _countdown = widget.countdownSeconds);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_countdown > 0) {
            _countdown--;
          } else {
            _timer?.cancel();
          }
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('验证码已发送到邮箱'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on auth_exception.VerificationCodeException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      widget.onLoginFailed?.call(e);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败: $e'), backgroundColor: Colors.red),
        );
      }
      widget.onLoginFailed?.call(e);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// 登录
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final result = await EasyAuth().loginWithEmail(
        email: _emailController.text,
        code: _codeController.text,
      );

      if (result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('登录成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
        widget.onLoginSuccess?.call(result);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? '登录失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
        widget.onLoginFailed?.call(result.message);
      }
    } on auth_exception.VerificationCodeException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      widget.onLoginFailed?.call(e);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登录失败: $e'), backgroundColor: Colors.red),
        );
      }
      widget.onLoginFailed?.call(e);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.primaryColor;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 邮箱输入
          TextFormField(
            controller: _emailController,
            decoration:
                widget.emailDecoration ??
                InputDecoration(
                  labelText: '邮箱',
                  hintText: '请输入邮箱地址',
                  prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                  filled: true,
                  fillColor: theme.brightness == Brightness.dark
                      ? Colors.grey[850]
                      : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入邮箱地址';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return '请输入有效的邮箱地址';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // 验证码输入
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _codeController,
                  decoration:
                      widget.codeDecoration ??
                      InputDecoration(
                        labelText: '验证码',
                        hintText: '请输入验证码',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: primaryColor,
                        ),
                        filled: true,
                        fillColor: theme.brightness == Brightness.dark
                            ? Colors.grey[850]
                            : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        counterText: '',
                      ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入验证码';
                    }
                    if (value.length != 6) {
                      return '验证码为6位数字';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                height: 56,
                child: ElevatedButton(
                  onPressed: _countdown > 0 || _loading ? null : _sendCode,
                  style:
                      widget.sendButtonStyle ??
                      ElevatedButton.styleFrom(
                        backgroundColor: primaryColor.withOpacity(0.1),
                        foregroundColor: primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                  child: _countdown > 0
                      ? Text(
                          '$_countdown秒',
                          style: const TextStyle(fontSize: 13),
                        )
                      : const Text('发送验证码', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // 登录按钮
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _login,
              style:
                  widget.loginButtonStyle ??
                  ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    shadowColor: primaryColor.withOpacity(0.3),
                  ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      '登录',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
