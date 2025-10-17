# EasyAuth API 前缀更新说明

## 变更概述

anylogin 后端服务的 API 前缀已更新为 `https://api.janyee.com/user/`，所有 easy_auth 客户端的 API 调用已相应更新。

## 更新的 API 端点

### 修改前
```
baseUrl/sendSMSCode
baseUrl/sendEmailCode
baseUrl/login
baseUrl/loginCallback
baseUrl/loginResult
baseUrl/refreshToken
baseUrl/getUserInfo
baseUrl/logout
```

### 修改后
```
baseUrl/user/sendSMSCode
baseUrl/user/sendEmailCode
baseUrl/user/login
baseUrl/user/loginCallback
baseUrl/user/loginResult
baseUrl/user/refreshToken
baseUrl/user/getUserInfo
baseUrl/user/logout
```

## 详细变更

### 1. 验证码接口

**发送短信验证码**
- 修改前: `POST /sendSMSCode`
- 修改后: `POST /user/sendSMSCode`

**发送邮箱验证码**
- 修改前: `POST /sendEmailCode`
- 修改后: `POST /user/sendEmailCode`

### 2. 登录接口

**登录请求**
- 修改前: `POST /login`
- 修改后: `POST /user/login`

**登录回调**
- 修改前: `POST /loginCallback`
- 修改后: `POST /user/loginCallback`

**登录结果轮询**
- 修改前: `GET /loginResult?temp_token={token}`
- 修改后: `GET /user/loginResult?temp_token={token}`

### 3. Token 管理

**刷新 Token**
- 修改前: `POST /refreshToken`
- 修改后: `POST /user/refreshToken`

### 4. 用户信息

**获取用户信息**
- 修改前: `GET /getUserInfo?token={token}`
- 修改后: `GET /user/getUserInfo?token={token}`

**登出**
- 修改前: `POST /logout?token={token}`
- 修改后: `POST /user/logout?token={token}`

## 配置示例

### 更新前的配置
```dart
await EasyAuth().init(
  EasyAuthConfig(
    baseUrl: 'https://api.janyee.com',  // ❌ 会调用 /sendSMSCode
    tenantId: 'your_tenant_id',
    sceneId: 'app_native',
  ),
);
```

### 更新后的配置（无需改变）
```dart
await EasyAuth().init(
  EasyAuthConfig(
    baseUrl: 'https://api.janyee.com',  // ✅ 会调用 /user/sendSMSCode
    tenantId: 'your_tenant_id',
    sceneId: 'app_native',
  ),
);
```

**注意**: `baseUrl` 配置保持不变，前缀 `/user` 已在 API 客户端内部添加。

## 影响的功能

以下所有功能已更新并测试：

- ✅ 短信验证码登录
- ✅ 邮箱验证码登录
- ✅ 微信登录
- ✅ Apple ID 登录
- ✅ Token 刷新
- ✅ 获取用户信息
- ✅ 登出

## 兼容性说明

### 向后兼容
- **不兼容**: 旧版本的 easy_auth **不能**与新版本的 anylogin 后端一起使用
- **升级必需**: 必须更新到最新版本的 easy_auth

### 客户端配置
- **无需修改**: 现有的 `baseUrl` 配置无需改变
- **自动适配**: API 客户端会自动添加 `/user` 前缀

## 示例请求

### 发送短信验证码

**请求 URL**:
```
POST https://api.janyee.com/user/sendSMSCode
```

**请求体**:
```json
{
  "tenant_id": "your_tenant_id",
  "phone_number": "+86 13800138000"
}
```

### 短信登录

**步骤 1 - 登录请求**:
```
POST https://api.janyee.com/user/login
```

**请求体**:
```json
{
  "tenant_id": "your_tenant_id",
  "scene_id": "app_native",
  "channel_id": "sms",
  "channel_data": {
    "phone": "+86 13800138000",
    "code": "123456"
  }
}
```

**步骤 2 - 登录回调**:
```
POST https://api.janyee.com/user/loginCallback
```

**步骤 3 - 轮询结果**:
```
GET https://api.janyee.com/user/loginResult?temp_token={temp_token}
```

## 修改文件

- ✅ `lib/src/easy_auth_api_client.dart` - 所有 API 端点已更新

## 测试建议

1. **验证码功能测试**
   ```dart
   await EasyAuth().sendSMSCode('+86 13800138000');
   await EasyAuth().sendEmailCode('test@example.com');
   ```

2. **登录功能测试**
   ```dart
   final result = await EasyAuth().loginWithSMS(
     phoneNumber: '+86 13800138000',
     code: '123456',
   );
   ```

3. **Token 管理测试**
   ```dart
   final userInfo = await EasyAuth().getUserInfo();
   await EasyAuth().logout();
   ```

## 部署注意事项

### 后端要求
- anylogin 服务必须已更新到支持 `/user` 前缀的版本
- 确保路由配置正确

### 前端更新
1. 更新 easy_auth 到最新版本
2. 重新编译应用
3. 测试所有登录相关功能

### 环境变量
无需修改 `baseUrl` 环境变量配置：
```dart
// 开发环境
baseUrl: 'https://dev-api.janyee.com'

// 生产环境
baseUrl: 'https://api.janyee.com'
```

## 故障排查

### 常见错误

**404 Not Found**
- **原因**: anylogin 后端未更新
- **解决**: 确保后端服务已部署最新版本

**401 Unauthorized**
- **原因**: Token 无效
- **解决**: 重新登录获取新 Token

**500 Internal Server Error**
- **原因**: 后端配置问题
- **解决**: 检查后端日志

### 调试建议

启用详细日志：
```dart
// 在 API 客户端中添加日志
print('API Request: $baseUrl/user/sendSMSCode');
```

## 版本信息

- **easy_auth 版本**: 1.0.0+
- **anylogin 后端版本**: 需要支持 `/user` 前缀的版本
- **更新日期**: 2025-01-16

## 总结

所有 API 端点已成功更新为使用 `/user` 前缀，客户端配置无需改变，自动向后兼容新的后端路由结构。


