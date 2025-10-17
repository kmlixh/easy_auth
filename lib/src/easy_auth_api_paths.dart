/// AnyLogin API路径配置
///
/// 定义所有与 anylogin 后端服务通信的 API 路径
/// anylogin 服务部署在 https://api.janyee.com/user/
/// anylogin 内部使用 /login 路由组
/// 所以最终路径是 /user/login/xxx
class EasyAuthApiPaths {
  // 登录相关接口
  static const String login = '/user/login/login';
  static const String loginCallback = '/user/login/loginCallback';
  static const String loginResult = '/user/login/loginResult';
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
