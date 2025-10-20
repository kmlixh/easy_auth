import 'dart:async';
import 'package:flutter/material.dart';
import '../easy_auth_core.dart';
import '../easy_auth_exception.dart' as auth_exception;
import '../easy_auth_models.dart';

/// 验证码登录表单组件（支持短信和邮箱）
class VerificationLoginForm extends StatefulWidget {
  /// 登录类型
  final VerificationType type;

  /// 登录成功回调
  final Function(LoginResult)? onLoginSuccess;

  /// 登录失败回调
  final Function(dynamic error)? onLoginFailed;

  /// 登录开始回调（用于显示遮罩）
  final VoidCallback? onLoginStart;

  /// 自定义样式
  final InputDecoration? inputDecoration;
  final InputDecoration? codeDecoration;
  final ButtonStyle? sendButtonStyle;
  final ButtonStyle? loginButtonStyle;

  /// 倒计时秒数
  final int countdownSeconds;

  /// 主题色
  final Color? primaryColor;

  const VerificationLoginForm({
    super.key,
    required this.type,
    this.onLoginSuccess,
    this.onLoginFailed,
    this.onLoginStart,
    this.inputDecoration,
    this.codeDecoration,
    this.sendButtonStyle,
    this.loginButtonStyle,
    this.countdownSeconds = 60,
    this.primaryColor,
  });

  @override
  State<VerificationLoginForm> createState() => _VerificationLoginFormState();
}

enum VerificationType {
  sms,
  email,
}

class _VerificationLoginFormState extends State<VerificationLoginForm> {
  final _inputController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _inputController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// 发送验证码
  Future<void> _sendCode() async {
    if (_countdown > 0) return;

    final input = _inputController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.type == VerificationType.sms ? '请输入手机号' : '请输入邮箱地址'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 验证格式
    if (widget.type == VerificationType.sms) {
      if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(input)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入有效的手机号'), backgroundColor: Colors.red),
        );
        return;
      }
    } else {
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入有效的邮箱地址'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    setState(() => _loading = true);

    try {
      if (widget.type == VerificationType.sms) {
        print('📱 发送短信验证码: $input');
        await EasyAuth().sendSMSCode(input);
      } else {
        print('📧 发送邮箱验证码: $input');
        await EasyAuth().sendEmailCode(input);
      }

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
          SnackBar(
            content: Text(widget.type == VerificationType.sms ? '验证码已发送' : '验证码已发送到邮箱'),
            duration: const Duration(seconds: 2),
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
    widget.onLoginStart?.call(); // 通知外部显示遮罩

    try {
      final result = widget.type == VerificationType.sms
          ? await EasyAuth().loginWithSms(
              phoneNumber: _inputController.text,
              verificationCode: _codeController.text,
            )
          : await EasyAuth().loginWithEmail(
              email: _inputController.text,
              verificationCode: _codeController.text,
            );

      if (result.isSuccess) {
        widget.onLoginSuccess?.call(result);
      } else {
        widget.onLoginFailed?.call(result.message);
      }
    } on auth_exception.VerificationCodeException catch (e) {
      widget.onLoginFailed?.call(e);
    } catch (e) {
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
    final isSms = widget.type == VerificationType.sms;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 输入框（手机号或邮箱）
          TextFormField(
            controller: _inputController,
            decoration: widget.inputDecoration ??
                InputDecoration(
                  labelText: isSms ? '手机号' : '邮箱',
                  hintText: isSms ? '请输入手机号' : '请输入邮箱地址',
                  prefixIcon: Icon(
                    isSms ? Icons.phone : Icons.email_outlined,
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
                    borderSide: const BorderSide(color: Colors.red, width: 1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
            keyboardType: isSms ? TextInputType.phone : TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return isSms ? '请输入手机号' : '请输入邮箱地址';
              }
              if (isSms) {
                if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
                  return '请输入有效的手机号';
                }
              } else {
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return '请输入有效的邮箱地址';
                }
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // 验证码输入
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _codeController,
                  decoration: widget.codeDecoration ??
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
                          vertical: 12,
                        ),
                        counterText: '',
                      ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入验证码';
                    }
                    if (value.length != 4) {
                      return '验证码为4位数字';
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
                  style: widget.sendButtonStyle ??
                      ElevatedButton.styleFrom(
                        backgroundColor: primaryColor.withValues(alpha: 0.1),
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

          const SizedBox(height: 16),

          // 登录按钮
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _login,
              style: widget.loginButtonStyle ??
                  ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    shadowColor: primaryColor.withValues(alpha: 0.3),
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
