import 'dart:async';
import 'package:flutter/material.dart';
import '../easy_auth_core.dart';
import '../easy_auth_exception.dart' as auth_exception;
import '../easy_auth_models.dart';

/// 短信验证码登录表单组件
class SMSLoginForm extends StatefulWidget {
  /// 登录成功回调
  final Function(LoginResult)? onLoginSuccess;

  /// 登录失败回调
  final Function(dynamic error)? onLoginFailed;

  /// 自定义样式
  final InputDecoration? phoneDecoration;
  final InputDecoration? codeDecoration;
  final ButtonStyle? sendButtonStyle;
  final ButtonStyle? loginButtonStyle;

  /// 倒计时秒数
  final int countdownSeconds;

  const SMSLoginForm({
    super.key,
    this.onLoginSuccess,
    this.onLoginFailed,
    this.phoneDecoration,
    this.codeDecoration,
    this.sendButtonStyle,
    this.loginButtonStyle,
    this.countdownSeconds = 60,
  });

  @override
  State<SMSLoginForm> createState() => _SMSLoginFormState();
}

class _SMSLoginFormState extends State<SMSLoginForm> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// 发送验证码
  Future<void> _sendCode() async {
    if (_countdown > 0) return;

    // 验证手机号
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await EasyAuth().sendSMSCode(_phoneController.text);

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
            content: Text('验证码已发送'),
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
      final result = await EasyAuth().loginWithSMS(
        phoneNumber: _phoneController.text,
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 手机号输入
          TextFormField(
            controller: _phoneController,
            decoration:
                widget.phoneDecoration ??
                const InputDecoration(
                  labelText: '手机号',
                  hintText: '请输入手机号',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入手机号';
              }
              if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
                return '请输入有效的手机号';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // 验证码输入
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _codeController,
                  decoration:
                      widget.codeDecoration ??
                      const InputDecoration(
                        labelText: '验证码',
                        hintText: '请输入验证码',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
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
                width: 120,
                height: 48,
                child: ElevatedButton(
                  onPressed: _countdown > 0 || _loading ? null : _sendCode,
                  style: widget.sendButtonStyle,
                  child: _countdown > 0
                      ? Text('$_countdown秒')
                      : const Text('发送验证码'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 登录按钮
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _login,
              style: widget.loginButtonStyle,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('登录', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
