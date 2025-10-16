# EasyAuth

一个强大、易用的Flutter登录认证插件，配合`anylogin`后端服务实现多渠道统一登录。

## ✨ 特性

- 🔐 **多渠道登录**：支持短信、邮箱、微信、Apple ID等多种登录方式
- 📱 **跨平台支持**：iOS和Android原生支持
- 🔄 **自动Token刷新**：内置Token自动刷新机制
- 💾 **本地会话管理**：自动保存和恢复用户会话
- 🎯 **类型安全**：完整的类型定义和错误处理
- 🚀 **简单易用**：链式API，开箱即用
- 🎨 **预置UI组件**：提供完整的登录页面和可复用组件（**新增**）

## 🚀 快速开始

### 1. 添加依赖

```yaml
dependencies:
  easy_auth:
    path: ../easy_auth  # 或发布到pub.dev后使用版本号
```

### 2. 初始化

```dart
import 'package:easy_auth/easy_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化EasyAuth
  await EasyAuth().init(
    EasyAuthConfig(
      baseUrl: 'https://api.janyee.com',  // anylogin 后端地址（不需要 /user 后缀）
      tenantId: 'your_tenant_id',
      sceneId: 'app_native',
      enableAutoRefresh: true,
    ),
  );
  
  runApp(MyApp());
}
```

### 3. 使用登录功能

#### 方式1: 使用预置UI组件（推荐，快速开始）

```dart
import 'package:easy_auth/easy_auth_ui.dart';

// 使用完整登录页
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => EasyAuthLoginPage(
      title: '登录',
      logo: Image.asset('assets/logo.png'),  // 可选
      showSMSLogin: true,        // 显示短信登录
      showEmailLogin: true,      // 显示邮箱登录
      showThirdPartyLogin: true, // 显示第三方登录
      onLoginSuccess: (result) {
        // 登录成功，跳转到主页
        Navigator.pushReplacementNamed(context, '/home');
      },
    ),
  ),
);

// 或使用单独的表单组件
SMSLoginForm(
  onLoginSuccess: (result) {
    // 登录成功处理
  },
  onLoginFailed: (error) {
    // 登录失败处理
  },
  // 可选：自定义样式
  phoneDecoration: InputDecoration(/* ... */),
  sendButtonStyle: ButtonStyle(/* ... */),
  countdownSeconds: 60,
)

// 邮箱登录表单
EmailLoginForm(
  onLoginSuccess: (result) { /* ... */ },
)

// 第三方登录按钮
ThirdPartyLoginButtons(
  onLoginSuccess: (result) { /* ... */ },
  showWechat: true,
  showApple: true,
)
```

#### 方式2: 使用API手动实现

#### 短信验证码登录

```dart
// 发送验证码
await EasyAuth().sendSMSCode('13800138000');

// 登录
final result = await EasyAuth().loginWithSMS(
  phoneNumber: '13800138000',
  code: '123456',
);

if (result.isSuccess) {
  print('登录成功！');
  print('Token: ${result.token}');
  print('用户信息: ${result.userInfo}');
}
```

#### 邮箱验证码登录

```dart
// 发送验证码
await EasyAuth().sendEmailCode('user@example.com');

// 登录
final result = await EasyAuth().loginWithEmail(
  email: 'user@example.com',
  code: '123456',
);
```

#### 微信登录

```dart
try {
  final result = await EasyAuth().loginWithWechat();
  if (result.isSuccess) {
    print('微信登录成功！');
  }
} catch (e) {
  print('微信登录失败: $e');
}
```

#### Apple ID登录（仅iOS）

```dart
try {
  final result = await EasyAuth().loginWithApple();
  if (result.isSuccess) {
    print('Apple登录成功！');
  }
} catch (e) {
  print('Apple登录失败: $e');
}
```

### 4. 用户信息和Token管理

```dart
// 检查登录状态
if (EasyAuth().isLoggedIn) {
  print('用户已登录');
}

// 获取当前用户
final user = EasyAuth().currentUser;
print('用户ID: ${user?.userId}');
print('昵称: ${user?.nickname}');

// 获取当前Token
final token = EasyAuth().currentToken;

// 刷新Token
final newToken = await EasyAuth().refreshToken();

// 获取用户信息（强制刷新）
final userInfo = await EasyAuth().getUserInfo(forceRefresh: true);

// 登出
await EasyAuth().logout();
```

## 📖 配置说明

### EasyAuthConfig 参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| baseUrl | String | 是 | anylogin后端服务地址 |
| tenantId | String | 是 | 租户ID |
| sceneId | String | 是 | 登录场景ID（如：app_native, web_login） |
| tokenExpiry | Duration | 否 | Token有效期，默认7天 |
| enableAutoRefresh | bool | 否 | 是否启用自动刷新，默认true |

### 登录场景说明

- `app_native`: App原生登录
- `web_login`: 网页登录
- `mini_program`: 小程序登录

## 🔧 高级配置

### 微信登录配置

#### iOS配置

1. 在`Info.plist`中添加：

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>weixin</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>YOUR_WECHAT_APP_ID</string>
    </array>
  </dict>
</array>

<key>LSApplicationQueriesSchemes</key>
<array>
  <string>weixin</string>
  <string>weixinULAPI</string>
</array>
```

2. 集成微信SDK（需手动配置）

#### Android配置

1. 在`AndroidManifest.xml`中添加：

```xml
<application>
  <!-- 微信回调Activity -->
  <activity
    android:name=".wxapi.WXEntryActivity"
    android:exported="true"
    android:launchMode="singleTask" />
</application>
```

2. 集成微信SDK（需手动配置）

### Apple ID登录配置（仅iOS）

在Xcode中启用`Sign in with Apple` Capability。

## 📱 完整示例

查看 [example](example/) 目录获取完整的示例应用。

## 🔗 相关项目

- [anylogin](https://github.com/your-org/anylogin) - 配套的后端登录服务

## 🤝 贡献

欢迎提交Issue和Pull Request！

## 📄 许可证

MIT License

## ⚠️ 注意事项

1. **微信登录**需要在微信开放平台注册应用并获取AppID
2. **Apple ID登录**仅在iOS 13.0+可用
3. 确保`anylogin`后端服务已正确配置和部署
4. 生产环境请使用HTTPS
5. 妥善保管tenantId和相关密钥

## 📚 详细文档

- **[UI组件文档](UI_COMPONENTS.md)** - 预置UI组件完整使用指南
- **[配置指南和注意事项](SETUP_GUIDE.md)** - 必读！包含完整的配置步骤和最佳实践
- [完整示例](example/) - 完整的登录UI和流程演示

## 📞 支持

如有问题，请提交Issue或联系技术支持。
