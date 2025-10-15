# EasyAuth UI组件文档

## 📦 组件概览

EasyAuth提供了一套开箱即用的UI组件，帮助你快速构建登录界面。

### 组件列表

| 组件 | 说明 | 推荐场景 |
|------|------|---------|
| `EasyAuthLoginPage` | 完整登录页面 | 需要完整登录流程 |
| `SMSLoginForm` | 短信登录表单 | 单独使用短信登录 |
| `EmailLoginForm` | 邮箱登录表单 | 单独使用邮箱登录 |
| `ThirdPartyLoginButtons` | 第三方登录按钮 | 微信/Apple登录 |

## 🚀 快速开始

### 1. 导入UI组件

```dart
import 'package:easy_auth/easy_auth_ui.dart';
```

### 2. 使用完整登录页

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => EasyAuthLoginPage(
      title: '登录',
      onLoginSuccess: (result) {
        Navigator.pushReplacementNamed(context, '/home');
      },
    ),
  ),
);
```

## 📱 组件详解

### EasyAuthLoginPage - 完整登录页

一个功能完整的登录页面，包含Tab切换、表单验证、第三方登录等。

#### 参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `title` | `String` | `'登录'` | 页面标题 |
| `logo` | `Widget?` | `null` | Logo组件 |
| `showSMSLogin` | `bool` | `true` | 显示短信登录Tab |
| `showEmailLogin` | `bool` | `true` | 显示邮箱登录Tab |
| `showThirdPartyLogin` | `bool` | `true` | 显示第三方登录区域 |
| `onLoginSuccess` | `Function(LoginResult)?` | `null` | 登录成功回调 |

#### 示例

```dart
EasyAuthLoginPage(
  title: '欢迎回来',
  logo: Container(
    width: 100,
    height: 100,
    child: Image.asset('assets/logo.png'),
  ),
  showSMSLogin: true,
  showEmailLogin: false,  // 不显示邮箱登录
  showThirdPartyLogin: true,
  onLoginSuccess: (result) {
    print('登录成功: ${result.userInfo?.username}');
    Navigator.pushReplacementNamed(context, '/home');
  },
)
```

#### 效果

```
┌─────────────────────────┐
│  ← 登录                  │
├─────────────────────────┤
│                         │
│      [Logo图片]         │
│                         │
│  ┌───────────────────┐  │
│  │ 短信登录 | 邮箱登录 │  │
│  ├───────────────────┤  │
│  │  手机号: ________  │  │
│  │  验证码: ____ [发送]│  │
│  │    [登录按钮]      │  │
│  │                   │  │
│  │  ─── 其他登录 ───   │  │
│  │  [微信] [Apple]   │  │
│  └───────────────────┘  │
└─────────────────────────┘
```

---

### SMSLoginForm - 短信登录表单

独立的短信验证码登录表单组件。

#### 参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `onLoginSuccess` | `Function(LoginResult)?` | `null` | 登录成功回调 |
| `onLoginFailed` | `Function(dynamic)?` | `null` | 登录失败回调 |
| `phoneDecoration` | `InputDecoration?` | 默认样式 | 手机号输入框样式 |
| `codeDecoration` | `InputDecoration?` | 默认样式 | 验证码输入框样式 |
| `sendButtonStyle` | `ButtonStyle?` | 默认样式 | 发送按钮样式 |
| `loginButtonStyle` | `ButtonStyle?` | 默认样式 | 登录按钮样式 |
| `countdownSeconds` | `int` | `60` | 倒计时秒数 |

#### 示例1: 基础使用

```dart
SMSLoginForm(
  onLoginSuccess: (result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('登录成功')),
    );
    Navigator.pop(context);
  },
  onLoginFailed: (error) {
    print('登录失败: $error');
  },
)
```

#### 示例2: 自定义样式

```dart
SMSLoginForm(
  // 自定义手机号输入框
  phoneDecoration: InputDecoration(
    labelText: '手机号码',
    hintText: '请输入11位手机号',
    prefixIcon: Icon(Icons.phone_iphone, color: Colors.blue),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    filled: true,
    fillColor: Colors.grey[50],
  ),
  
  // 自定义验证码输入框
  codeDecoration: InputDecoration(
    labelText: '验证码',
    hintText: '6位数字',
    prefixIcon: Icon(Icons.security, color: Colors.blue),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  
  // 自定义发送按钮
  sendButtonStyle: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  
  // 自定义登录按钮
  loginButtonStyle: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    minimumSize: Size(double.infinity, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(25),
    ),
  ),
  
  // 自定义倒计时
  countdownSeconds: 90,
  
  // 回调
  onLoginSuccess: (result) {
    // 处理登录成功
  },
  onLoginFailed: (error) {
    // 处理登录失败
  },
)
```

#### 示例3: 在Dialog中使用

```dart
showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: Text('手机号登录'),
    content: SMSLoginForm(
      onLoginSuccess: (result) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登录成功')),
        );
      },
    ),
  ),
);
```

---

### EmailLoginForm - 邮箱登录表单

独立的邮箱验证码登录表单组件。

#### 参数

与 `SMSLoginForm` 相同，但使用 `emailDecoration` 代替 `phoneDecoration`。

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `onLoginSuccess` | `Function(LoginResult)?` | `null` | 登录成功回调 |
| `onLoginFailed` | `Function(dynamic)?` | `null` | 登录失败回调 |
| `emailDecoration` | `InputDecoration?` | 默认样式 | 邮箱输入框样式 |
| `codeDecoration` | `InputDecoration?` | 默认样式 | 验证码输入框样式 |
| `sendButtonStyle` | `ButtonStyle?` | 默认样式 | 发送按钮样式 |
| `loginButtonStyle` | `ButtonStyle?` | 默认样式 | 登录按钮样式 |
| `countdownSeconds` | `int` | `60` | 倒计时秒数 |

#### 示例

```dart
EmailLoginForm(
  emailDecoration: InputDecoration(
    labelText: '邮箱地址',
    hintText: 'example@domain.com',
    prefixIcon: Icon(Icons.email_outlined),
    border: OutlineInputBorder(),
  ),
  onLoginSuccess: (result) {
    // 登录成功处理
  },
)
```

---

### ThirdPartyLoginButtons - 第三方登录按钮

微信、Apple ID等第三方登录按钮组件。

#### 参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `onLoginSuccess` | `Function(LoginResult)?` | `null` | 登录成功回调 |
| `onLoginFailed` | `Function(dynamic)?` | `null` | 登录失败回调 |
| `showWechat` | `bool` | `true` | 显示微信登录 |
| `showApple` | `bool` | `true` | 显示Apple登录（仅iOS） |
| `wechatButtonStyle` | `ButtonStyle?` | 默认样式 | 微信按钮样式 |
| `appleButtonStyle` | `ButtonStyle?` | 默认样式 | Apple按钮样式 |

#### 示例

```dart
ThirdPartyLoginButtons(
  showWechat: true,
  showApple: Platform.isIOS,  // 仅iOS显示
  onLoginSuccess: (result) {
    print('第三方登录成功');
    Navigator.pushReplacementNamed(context, '/home');
  },
  onLoginFailed: (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('登录失败: $error')),
    );
  },
  wechatButtonStyle: OutlinedButton.styleFrom(
    foregroundColor: Color(0xFF07C160),
    side: BorderSide(color: Color(0xFF07C160), width: 2),
  ),
)
```

## 🎨 自定义主题

### 全局主题

使用Flutter的主题系统全局定制：

```dart
MaterialApp(
  theme: ThemeData(
    primarySwatch: Colors.blue,
    
    // 输入框主题
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    ),
    
    // 按钮主题
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  ),
  home: MyApp(),
)
```

### 单个组件定制

每个组件都支持通过参数定制样式（见上文各组件的参数说明）。

## 🔧 进阶用法

### 1. 组合使用

```dart
class MyLoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              // Logo
              Image.asset('assets/logo.png', height: 100),
              SizedBox(height: 40),
              
              // 短信登录
              SMSLoginForm(
                onLoginSuccess: _handleSuccess,
              ),
              
              SizedBox(height: 20),
              
              // 分隔线
              Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('或'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              
              SizedBox(height: 20),
              
              // 第三方登录
              ThirdPartyLoginButtons(
                onLoginSuccess: _handleSuccess,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _handleSuccess(LoginResult result) {
    Navigator.pushReplacementNamed(context, '/home');
  }
}
```

### 2. 在已有页面中添加登录功能

```dart
// 在设置页面添加绑定手机号功能
class BindPhonePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('绑定手机号')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SMSLoginForm(
          onLoginSuccess: (result) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('绑定成功')),
            );
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
```

### 3. 自定义错误处理

```dart
SMSLoginForm(
  onLoginSuccess: (result) {
    // 成功处理
  },
  onLoginFailed: (error) {
    String message = '登录失败';
    
    if (error is VerificationCodeException) {
      message = error.message;
    } else if (error is NetworkException) {
      message = '网络连接失败，请检查网络设置';
    } else if (error is TimeoutException) {
      message = '请求超时，请重试';
    }
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('登录失败'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('确定'),
          ),
        ],
      ),
    );
  },
)
```

## 📱 响应式设计

组件已做响应式处理，自动适配不同屏幕尺寸：

```dart
// 小屏幕
if (MediaQuery.of(context).size.width < 600) {
  return SMSLoginForm(/* ... */);
}

// 大屏幕（平板）
return Container(
  width: 400,
  child: SMSLoginForm(/* ... */),
);
```

## 🌍 国际化

### 1. 覆盖文本

所有文本都可以通过 `decoration` 参数自定义：

```dart
SMSLoginForm(
  phoneDecoration: InputDecoration(
    labelText: 'Phone Number',  // 英文
    hintText: 'Enter your phone number',
  ),
  codeDecoration: InputDecoration(
    labelText: 'Verification Code',
    hintText: 'Enter 6-digit code',
  ),
)
```

### 2. 使用intl包

```dart
import 'package:intl/intl.dart';

SMSLoginForm(
  phoneDecoration: InputDecoration(
    labelText: AppLocalizations.of(context).phoneNumber,
    hintText: AppLocalizations.of(context).phoneHint,
  ),
)
```

## 🐛 常见问题

### Q1: 组件显示不完整？
A: 确保父容器有足够空间，或包裹在 `SingleChildScrollView` 中：

```dart
SingleChildScrollView(
  child: SMSLoginForm(/* ... */),
)
```

### Q2: 倒计时不准确？
A: 倒计时基于客户端时间，确保设备时间正确。

### Q3: 第三方登录按钮不显示？
A: Apple登录仅在iOS上显示，Android不支持。

### Q4: 如何禁用某个登录方式？
A: 使用对应的 `show*` 参数：

```dart
EasyAuthLoginPage(
  showSMSLogin: true,
  showEmailLogin: false,  // 不显示邮箱登录
  showThirdPartyLogin: false,  // 不显示第三方登录
)
```

## 💡 最佳实践

1. **使用预置组件快速开发**，需要定制时再自己实现UI
2. **统一错误处理**，为用户提供友好提示
3. **合理设置倒计时**，避免频繁发送验证码
4. **测试各种场景**：成功、失败、网络异常等
5. **遵循平台设计规范**：iOS使用Cupertino风格，Android使用Material风格

## 📚 相关文档

- [EasyAuth核心API](README.md)
- [配置指南](SETUP_GUIDE.md)
- [完整使用示例](LOGIN_UI_GUIDE.md)

## 🎉 完成！

现在你已经掌握了EasyAuth UI组件的使用方法，开始构建你的登录界面吧！


