# EasyAuth 配置指南和注意事项

## ⚠️ 重要注意事项

### 1. 基础配置要求

#### Flutter版本
- **最低要求**: Flutter 3.3.0+
- **Dart SDK**: 3.9.2+
- 建议使用最新稳定版本

#### 依赖包版本
```yaml
dependencies:
  http: ^1.2.0
  shared_preferences: ^2.2.0
```

### 2. anylogin后端服务

#### 必须先部署后端
- EasyAuth **依赖** anylogin后端服务
- 确保后端服务已启动且可访问
- 建议使用HTTPS（生产环境必须）

#### 连接测试
```dart
// 测试后端连接
final response = await http.get(
  Uri.parse('https://your-anylogin-server.com/health'),
);
print(response.body);
// 应返回: {"status":"ok","service":"anylogin"...}
```

### 3. 初始化配置

#### 必须在使用前初始化
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ⚠️ 必须在runApp之前初始化
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

#### 配置参数说明

| 参数 | 类型 | 必填 | 说明 | 示例 |
|------|------|------|------|------|
| baseUrl | String | 是 | anylogin服务地址，**不要**带尾部斜杠 | `https://api.example.com` |
| tenantId | String | 是 | 租户ID，需在anylogin后端配置 | `my_app` |
| sceneId | String | 是 | 登录场景ID | `app_native`, `web_login` |
| tokenExpiry | Duration | 否 | Token有效期（默认7天） | `Duration(days: 7)` |
| enableAutoRefresh | bool | 否 | 是否自动刷新Token（默认true） | `true` |

#### 场景ID说明
- `app_native`: App原生登录（推荐移动端使用）
- `web_login`: 网页登录
- `mini_program`: 小程序登录
- 自定义场景需在后端`login_scenes`表中配置

### 4. 微信登录配置

#### iOS配置

**Step 1: 注册微信开放平台**
1. https://open.weixin.qq.com
2. 创建移动应用
3. 获取AppID

**Step 2: 配置Info.plist**
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
      <!-- ⚠️ 这里填写微信AppID -->
      <string>wx1234567890abcdef</string>
    </array>
  </dict>
</array>

<key>LSApplicationQueriesSchemes</key>
<array>
  <string>weixin</string>
  <string>weixinULAPI</string>
</array>
```

**Step 3: 集成微信SDK（可选，手动配置）**

如需完整功能，需手动集成微信SDK：
```ruby
# ios/Podfile
pod 'WechatOpenSDK'
```

然后在`EasyAuthPlugin.swift`中实现完整的微信登录逻辑。

#### Android配置

**Step 1: 配置AndroidManifest.xml**
```xml
<application>
  <!-- 微信回调Activity -->
  <activity
    android:name=".wxapi.WXEntryActivity"
    android:exported="true"
    android:launchMode="singleTask"
    android:taskAffinity="com.your.package"
    android:theme="@android:style/Theme.Translucent.NoTitleBar" />
</application>

<queries>
  <package android:name="com.tencent.mm" />
</queries>
```

**Step 2: 创建WXEntryActivity**
```kotlin
// android/app/src/main/kotlin/com/your/package/wxapi/WXEntryActivity.kt
package com.your.package.wxapi

import android.app.Activity
import android.os.Bundle
import com.tencent.mm.opensdk.modelbase.BaseReq
import com.tencent.mm.opensdk.modelbase.BaseResp
import com.tencent.mm.opensdk.modelmsg.SendAuth
import com.tencent.mm.opensdk.openapi.IWXAPIEventHandler

class WXEntryActivity : Activity(), IWXAPIEventHandler {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 处理微信回调
        // 将结果通过MethodChannel返回给Flutter
    }
    
    override fun onReq(req: BaseReq?) {}
    
    override fun onResp(resp: BaseResp?) {
        if (resp is SendAuth.Resp) {
            val code = resp.code
            // 调用WechatLoginManager.handleWechatCallback(code, null)
        }
        finish()
    }
}
```

**Step 3: 集成微信SDK（可选）**
```gradle
// android/app/build.gradle
dependencies {
    implementation 'com.tencent.mm.opensdk:wechat-sdk-android:6.8.0'
}
```

#### 使用方法
```dart
try {
  final result = await EasyAuth().loginWithWechat();
  if (result.isSuccess) {
    print('微信登录成功: ${result.token}');
    print('用户信息: ${result.userInfo}');
  }
} on PlatformException catch (e) {
  if (e.code == 'APP_NOT_INSTALLED') {
    print('未安装微信');
  } else if (e.code == 'USER_CANCELLED') {
    print('用户取消');
  }
}
```

### 5. Apple ID登录配置（仅iOS）

#### 系统要求
- **iOS 13.0+**
- Xcode 11+

#### 配置步骤

**Step 1: 在Xcode中启用Capability**
```
1. 打开ios/Runner.xcworkspace
2. 选择Runner target
3. Signing & Capabilities
4. 点击 + Capability
5. 添加 "Sign in with Apple"
```

**Step 2: 配置Apple Developer**
参考anylogin的SETUP_GUIDE.md中的Apple配置部分

**Step 3: 使用**
```dart
try {
  final result = await EasyAuth().loginWithApple();
  if (result.isSuccess) {
    print('Apple登录成功: ${result.token}');
    print('用户信息: ${result.userInfo}');
  }
} on PlatformException catch (e) {
  if (e.code == 'UNAVAILABLE') {
    print('iOS 13.0+ 才支持');
  } else if (e.code == 'USER_CANCELLED') {
    print('用户取消');
  }
}
```

#### Android注意
- Android **不支持** Apple ID原生登录
- 如需支持，使用Web方式（Sign in with Apple JS）

### 6. 短信验证码登录

#### 完整流程
```dart
import 'package:easy_auth/easy_auth.dart';

// 1. 发送验证码
await EasyAuth().sendSMSCode('13800138000');
// 用户会收到短信验证码

// 2. 用户输入验证码后，调用登录
try {
  final result = await EasyAuth().loginWithSMS(
    phoneNumber: '13800138000',
    code: '123456',  // 用户输入的验证码
  );
  
  if (result.isSuccess) {
    // 登录成功
    print('Token: ${result.token}');
    print('用户: ${EasyAuth().currentUser}');
    
    // 保存登录状态（自动完成）
    // 跳转到主页面
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage()),
    );
  } else {
    // 登录失败
    print('登录失败: ${result.message}');
  }
} on VerificationCodeException catch (e) {
  print('验证码错误: ${e.message}');
} on AuthenticationException catch (e) {
  print('登录失败: ${e.message}');
}
```

#### 验证码限制
- **发送间隔**: 60秒（后端限制）
- **有效期**: 5分钟
- **每日次数**: 10次
- **验证失败**: 5次后验证码失效

#### 错误处理
```dart
try {
  await EasyAuth().sendSMSCode(phoneNumber);
} on VerificationCodeException catch (e) {
  if (e.message.contains('频繁')) {
    // 60秒内不能重复发送
    showDialog(context, '请稍后再试');
  } else if (e.message.contains('上限')) {
    // 今日发送次数已达上限
    showDialog(context, '今日发送次数已用完');
  }
}
```

### 7. 邮箱验证码登录

#### 使用方法
```dart
// 发送验证码
await EasyAuth().sendEmailCode('user@example.com');

// 登录
final result = await EasyAuth().loginWithEmail(
  email: 'user@example.com',
  code: '123456',
);
```

#### 注意事项
- 邮件可能进入垃圾箱
- 发送限制与短信相同
- 建议提示用户检查垃圾邮件

### 8. Token和会话管理

#### 自动会话恢复
```dart
// App启动时自动检查
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyAuth().init(config);
  
  // 自动从SharedPreferences恢复会话
  if (EasyAuth().isLoggedIn) {
    print('用户已登录: ${EasyAuth().currentUser}');
    // 直接进入主页
  } else {
    // 显示登录页
  }
  
  runApp(MyApp());
}
```

#### Token自动刷新
```dart
// 启用后自动在后台刷新（每6天刷新一次）
EasyAuthConfig(
  enableAutoRefresh: true, // 默认true
  tokenExpiry: Duration(days: 7), // Token有效期
)

// 手动刷新
try {
  final newToken = await EasyAuth().refreshToken();
  print('Token已刷新: $newToken');
} on TokenExpiredException catch (e) {
  // Token已过期，需要重新登录
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => LoginPage()),
  );
}
```

#### 登出
```dart
await EasyAuth().logout();
// 自动清除：
// - SharedPreferences中的token和用户信息
// - 内存中的会话数据
// - 后端的登录状态（调用/logout接口）
```

### 9. 错误处理

#### 异常类型

| 异常类型 | 说明 | 常见原因 |
|---------|------|----------|
| `ConfigurationException` | 配置错误 | 未初始化、参数错误 |
| `NetworkException` | 网络错误 | 无网络、服务器不可达 |
| `AuthenticationException` | 认证失败 | 密码错误、Token过期 |
| `VerificationCodeException` | 验证码错误 | 验证码错误、已过期 |
| `TokenExpiredException` | Token过期 | 需要重新登录 |
| `PlatformException` | 平台错误 | 原生SDK调用失败 |

#### 统一错误处理
```dart
Future<void> handleLogin() async {
  try {
    final result = await EasyAuth().loginWithSMS(...);
    // 处理成功
  } on TokenExpiredException catch (e) {
    // Token过期，跳转登录页
    Navigator.pushReplacement(context, LoginPage());
  } on VerificationCodeException catch (e) {
    // 验证码错误
    showSnackBar('验证码错误');
  } on NetworkException catch (e) {
    // 网络错误
    showSnackBar('网络连接失败');
  } on AuthenticationException catch (e) {
    // 其他认证错误
    showSnackBar('登录失败: ${e.message}');
  } catch (e) {
    // 未知错误
    showSnackBar('未知错误: $e');
  }
}
```

### 10. 最佳实践

#### 登录流程UI示例
```dart
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _loading = false;
  int _countdown = 0;
  Timer? _timer;

  // 发送验证码
  Future<void> _sendCode() async {
    if (_countdown > 0) return;
    
    setState(() => _loading = true);
    try {
      await EasyAuth().sendSMSCode(_phoneController.text);
      
      // 开始倒计时
      setState(() => _countdown = 60);
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          if (_countdown > 0) {
            _countdown--;
          } else {
            _timer?.cancel();
          }
        });
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('验证码已发送')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // 登录
  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final result = await EasyAuth().loginWithSMS(
        phoneNumber: _phoneController.text,
        code: _codeController.text,
      );
      
      if (result.isSuccess) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登录失败: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: '手机号'),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    decoration: InputDecoration(labelText: '验证码'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _countdown > 0 || _loading ? null : _sendCode,
                  child: Text(_countdown > 0 ? '$_countdown秒' : '发送'),
                ),
              ],
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading 
                  ? CircularProgressIndicator()
                  : Text('登录'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 11. 测试建议

#### 单元测试
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_auth/easy_auth.dart';

void main() {
  test('EasyAuth初始化测试', () async {
    await EasyAuth().init(EasyAuthConfig(
      baseUrl: 'https://test-server.com',
      tenantId: 'test',
      sceneId: 'app_native',
    ));
    
    expect(EasyAuth().config.tenantId, 'test');
  });
}
```

#### 集成测试
- 使用真实后端服务测试
- 测试各种登录方式
- 测试错误处理
- 测试Token刷新

### 12. 性能优化

#### 减少不必要的API调用
```dart
// ❌ 不好的做法：频繁调用getUserInfo
final user = await EasyAuth().getUserInfo(forceRefresh: true);

// ✅ 好的做法：使用缓存
final user = EasyAuth().currentUser; // 从内存获取
// 或
final user = await EasyAuth().getUserInfo(); // 使用缓存，仅在需要时刷新
```

#### 异步初始化
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 异步初始化，不阻塞UI
  EasyAuth().init(config).then((_) {
    // 初始化完成后的处理
  });
  
  runApp(MyApp());
}
```

### 13. 安全建议

#### 不要在客户端存储敏感信息
```dart
// ❌ 不要这样做
final password = '123456';
await EasyAuth().loginWithPassword(password); // 没有这个方法！

// ✅ 使用验证码或第三方登录
await EasyAuth().loginWithSMS(...);
```

#### HTTPS强制
```dart
// 生产环境必须使用HTTPS
EasyAuthConfig(
  baseUrl: 'https://your-server.com', // 注意是https
  ...
)
```

#### Token安全
- Token存储在SharedPreferences（加密存储）
- 不要将Token暴露给第三方
- Token过期后自动清除

### 14. 常见问题

#### Q: 如何检查用户是否登录？
```dart
if (EasyAuth().isLoggedIn) {
  // 已登录
} else {
  // 未登录
}
```

#### Q: 如何获取当前用户信息？
```dart
final user = EasyAuth().currentUser;
if (user != null) {
  print('用户ID: ${user.userId}');
  print('昵称: ${user.nickname}');
}
```

#### Q: Token过期怎么办？
```dart
// 方式1: 自动刷新（推荐）
EasyAuthConfig(enableAutoRefresh: true)

// 方式2: 手动刷新
try {
  await EasyAuth().refreshToken();
} on TokenExpiredException {
  // 需要重新登录
  Navigator.pushReplacement(context, LoginPage());
}
```

#### Q: 如何支持多个登录方式？
```dart
// 短信登录
ElevatedButton(
  onPressed: () => _loginWithSMS(),
  child: Text('短信登录'),
)

// 微信登录
ElevatedButton(
  onPressed: () => EasyAuth().loginWithWechat(),
  child: Text('微信登录'),
)

// Apple登录
if (Platform.isIOS) {
  ElevatedButton(
    onPressed: () => EasyAuth().loginWithApple(),
    child: Text('Apple登录'),
  )
}
```

### 15. 技术支持

- **示例代码**: 查看 `example/` 目录
- **后端文档**: 查看 `anylogin/README.md`
- **Issue**: 提交GitHub Issue

---

**最后更新**: 2025-10-14  
**适用版本**: v0.0.1+


