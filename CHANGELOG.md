## 0.0.2

* fix(oauth): 适配 userLogin OIDC profile claims 字段重命名
  - `/oauth/userinfo` 响应里读 `picture`(OIDC 标准)优先,fallback `avatar`(老服务)
  - `UserInfo.fromJson` 同样兼容 picture / phone_number / sub
  - 现在升不升级 userLogin 服务端,easy_auth 都能正常拿到头像 + sub
* 不需要任何 app 端代码改动,字段映射在 SDK 内部处理

## 0.0.1

* Initial release.
