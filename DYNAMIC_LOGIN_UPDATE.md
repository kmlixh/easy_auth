# 动态登录渠道功能实现总结

## 📋 功能概述

实现了基于后端配置的动态登录渠道加载功能，登录界面会根据 anylogin 后端返回的可用登录方式自动显示对应的登录选项。

## 🎯 主要功能

### 1. 动态加载登录渠道

- **API 接口**: `GET /login/getTenantConfig?tenant_id=xxx`
- **返回数据**: 租户配置信息，包括可用的登录渠道列表
- **自动适配**: 登录页面根据后端配置自动显示/隐藏登录方式

### 2. 圆形图标按钮设计

模仿现代APP登录界面，第三方登录采用圆形图标样式：

- **尺寸**: 60x60 圆形按钮
- **样式**: 灰色背景 + 彩色图标 + 底部文字
- **间距**: 按钮之间间隔32px
- **适配**: 深色/浅色模式自动切换

### 3. 智能Tab切换

- **动态显示**: 仅当有多个验证码登录方式（短信、邮箱）时才显示Tab
- **单一方式**: 只有一种验证码登录时，直接显示该登录表单，无需Tab
- **样式优化**: 圆角切换器，选中项主题色高亮

## 📦 新增模型类

### SupportedChannel
```dart
class SupportedChannel {
  final String channelId;       // 渠道ID (sms, email, wechat, apple, google)
  final String channelName;     // 渠道名称
  final String channelTitle;    // 渠道标题（显示用）
  final int sortOrder;          // 排序顺序
}
```

### TenantConfig
```dart
class TenantConfig {
  final String tenantId;                        // 租户ID
  final String tenantName;                      // 租户名称
  final String? icon;                           // 租户图标
  final List<SupportedChannel> supportedChannels; // 支持的渠道列表
  final String defaultChannel;                  // 默认渠道
}
```

## 🔧 API 更新

### EasyAuthApiClient

新增方法：
```dart
/// 获取租户配置（可用的登录渠道）
Future<TenantConfig> getTenantConfig() async {
  final response = await _client.get(
    Uri.parse('$baseUrl/login/getTenantConfig?tenant_id=$tenantId'),
    headers: {'Content-Type': 'application/json'},
  );
  
  final data = _handleResponse(response);
  return TenantConfig.fromJson(data);
}
```

## 🎨 UI 组件更新

### 1. EasyAuthLoginPage

**主要变化：**
- 初始化时自动加载租户配置
- 分离验证码登录和第三方登录
- 根据配置动态显示Tab和登录表单
- 加载状态显示优化

**关键代码：**
```dart
Future<void> _loadTenantConfig() async {
  final config = await EasyAuth().apiClient.getTenantConfig();
  
  // 分类渠道
  _verificationChannels = config.supportedChannels
      .where((ch) => ch.channelId == 'sms' || ch.channelId == 'email')
      .toList();
  
  _thirdPartyChannels = config.supportedChannels
      .where((ch) => ch.channelId != 'sms' && ch.channelId != 'email')
      .toList();
}
```

### 2. ThirdPartyLoginButtons

**主要变化：**
- 新增 `availableChannels` 参数，用于控制显示哪些登录方式
- 改为圆形图标按钮布局
- 自动过滤不可用的登录渠道

**使用示例：**
```dart
ThirdPartyLoginButtons(
  onLoginSuccess: _handleLoginSuccess,
  primaryColor: primaryColor,
  availableChannels: ['wechat', 'apple', 'google'], // 从后端获取
)
```

**按钮样式：**
- **圆形容器**: 60x60，灰色背景，彩色边框
- **图标**: 28px（Google为32px），彩色
- **文字**: 12px，灰色，位于图标下方8px处
- **点击效果**: InkWell水波纹效果

## 📱 支持的登录方式

### 验证码登录（Tab切换）
1. **短信登录** (`sms`)
2. **邮箱登录** (`email`)

### 第三方登录（圆形图标）
1. **微信登录** (`wechat`) - 绿色图标
2. **Apple登录** (`apple`) - 黑/白色图标（深色模式自适应）
3. **Google登录** (`google`) - 蓝色图标

## 🔄 工作流程

1. **页面加载**
   - 调用 `getTenantConfig()` 获取租户配置
   - 解析可用的登录渠道列表

2. **渠道分类**
   - 验证码登录：`sms`, `email`
   - 第三方登录：`wechat`, `apple`, `google`

3. **UI渲染**
   - Tab切换器（仅多个验证码方式时显示）
   - 登录表单（根据选中的Tab显示）
   - 第三方登录按钮（圆形图标布局）

4. **登录流程**
   - 用户选择登录方式
   - 调用对应的登录API
   - 返回登录结果

## 🎯 优势

1. **灵活配置**: 后端可随时调整可用的登录方式，前端自动适配
2. **用户体验**: 现代化的圆形图标设计，美观直观
3. **代码简洁**: 统一的配置加载和渲染逻辑
4. **易于扩展**: 新增登录方式只需后端配置，无需修改前端代码

## 📝 使用说明

### 基础使用
```dart
// 初始化 EasyAuth
await EasyAuth().init(
  EasyAuthConfig(
    baseUrl: 'https://api.janyee.com',
    tenantId: 'kiku',
    sceneId: 'app_native',
  ),
);

// 使用登录页面
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EasyAuthLoginPage(
      title: '登录',
      primaryColor: Colors.blue,
      onLoginSuccess: (result) {
        // 登录成功处理
      },
    ),
  ),
);
```

### 自定义样式
```dart
EasyAuthLoginPage(
  title: '欢迎登录',
  logo: Image.asset('assets/logo.png', width: 80),
  primaryColor: Color(0xFF6C5CE7),
  onLoginSuccess: (result) {
    // 处理登录成功
  },
)
```

## 🔧 后端配置

确保 anylogin 后端已配置好 `/login/getTenantConfig` 接口，返回格式：

```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "tenant_id": "kiku",
    "tenant_name": "Kiku日语学习",
    "icon": "https://...",
    "supported_channels": [
      {
        "channel_id": "sms",
        "channel_name": "短信验证码",
        "channel_title": "短信登录",
        "sort_order": 1
      },
      {
        "channel_id": "wechat",
        "channel_name": "微信",
        "channel_title": "微信登录",
        "sort_order": 3
      }
    ],
    "default_channel": "sms"
  }
}
```

## 🐛 注意事项

1. **网络请求**: 首次加载需要网络请求，建议显示加载状态
2. **错误处理**: 配置加载失败时的降级处理
3. **缓存策略**: 可考虑缓存租户配置减少请求
4. **平台适配**: Apple登录在非iOS平台自动隐藏（已实现）

## 📅 更新日期

2025-01-16

## 🔗 相关文件

- `lib/src/easy_auth_models.dart` - 新增模型类
- `lib/src/easy_auth_api_client.dart` - 新增API方法
- `lib/src/widgets/login_page.dart` - 登录页面重构
- `lib/src/widgets/third_party_login_buttons.dart` - 圆形按钮组件


