/// AnyLogin API路径配置
///
/// 定义所有与 anylogin 后端服务通信的 API 路径
/// anylogin 服务部署在 https://api.janyee.com/user/
/// anylogin 内部使用 /login 路由组
/// 所以最终路径是 /user/login/xxx
class EasyAuthApiPaths {
  // 新的一次性登录接口（推荐使用）
  static const String directLogin = '/user/login/directLogin';

  // 旧的多步登录接口（已废弃，保留兼容）
  static const String login = '/user/login/login';
  static const String loginCallback = '/user/login/loginCallback';
  static const String loginResult = '/user/login/loginResult';

  // 用户管理接口
  static const String logout = '/user/login/logout';
  static const String getUserInfo = '/user/login/getUserInfo';
  static const String refreshToken = '/user/login/refreshToken';

  // 验证码相关接口
  static const String sendSMSCode = '/user/login/sendSMSCode';
  static const String sendEmailCode = '/user/login/sendEmailCode';
  static const String verifyCode = '/user/login/verifyCode';

  // 租户配置接口
  static const String getTenantConfig = '/user/login/getTenantConfig';
}
