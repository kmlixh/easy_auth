/// AnyLogin API路径配置
///
/// 定义所有与 anylogin 后端服务通信的 API 路径
/// anylogin 服务使用 /login 路由组前缀
/// 所有路径必须包含完整的 /login/xxx 格式
class EasyAuthApiPaths {
  // 登录相关接口
  static const String login = '/login/login';
  static const String loginCallback = '/login/loginCallback';
  static const String loginResult = '/login/loginResult';
  static const String logout = '/login/logout';
  static const String getUserInfo = '/login/getUserInfo';
  static const String refreshToken = '/login/refreshToken';

  // 验证码相关接口
  static const String sendSMSCode = '/login/sendSMSCode';
  static const String sendEmailCode = '/login/sendEmailCode';
  static const String verifyCode = '/login/verifyCode';

  // 租户配置接口
  static const String getTenantConfig = '/login/getTenantConfig';
}
