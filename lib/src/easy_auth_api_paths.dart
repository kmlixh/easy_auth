/// AnyLogin API路径配置
///
/// 定义所有与 anylogin 后端服务通信的 API 路径
/// anylogin 服务部署在 https://auth.janyee.com
/// anylogin 内部使用 /login 路由组
/// 所以最终路径是 /login/xxx
class EasyAuthApiPaths {
  // 新的一次性登录接口（推荐使用）
  static const String directLogin = '/login/directLogin';

  // 旧的多步登录接口（已废弃，保留兼容）
  static const String login = '/login/login';
  static const String loginCallback = '/login/loginCallback';
  static const String loginResult = '/login/loginResult';

  // 用户管理接口
  static const String logout = '/login/logout';
  static const String getUserInfo = '/login/getUserInfo';
  static const String updateUserInfo = '/login/updateUserInfo';
  static const String refreshToken = '/login/refreshToken';

  // 验证码相关接口
  static const String sendSMSCode = '/login/sendSMSCode';
  static const String sendEmailCode = '/login/sendEmailCode';
  static const String verifyCode = '/login/verifyCode';

  // 租户配置接口
  static const String getTenantConfig = '/login/getTenantConfig';

  // 跨渠道账号绑定 / 合并 (对应 userLogin/binding.go)
  static const String myChannels = '/login/myChannels';
  static const String bindChannel = '/login/bindChannel';
  static const String bindChannelResolve = '/login/bindChannelResolve';
  static const String unbindChannel = '/login/unbindChannel';

  // 头像 (PNG 200x200, BYTEA 直存)
  static const String updateAvatar = '/login/updateAvatar';
  // GET /user/avatar/:userId  (公开,带 ETag/Cache-Control)
  static String userAvatar(String userId) => '/user/avatar/$userId';
}
