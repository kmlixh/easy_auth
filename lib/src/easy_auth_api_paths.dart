/// AnyLogin API路径配置
///
/// 定义所有与 anylogin 后端服务通信的 API 路径
/// anylogin 服务使用 /login 路由组前缀
class EasyAuthApiPaths {
  // 登录相关接口
  static const String login = '/login';
  static const String loginCallback = '/loginCallback';
  static const String loginResult = '/loginResult';
  static const String logout = '/logout';
  static const String getUserInfo = '/getUserInfo';
  static const String refreshToken = '/refreshToken';

  // 验证码相关接口
  static const String sendSMSCode = '/sendSMSCode';
  static const String sendEmailCode = '/sendEmailCode';
  static const String verifyCode = '/verifyCode';
}
