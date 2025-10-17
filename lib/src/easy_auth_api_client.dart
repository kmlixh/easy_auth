import 'dart:convert';
import 'package:http/http.dart' as http;
import 'easy_auth_models.dart';
import 'easy_auth_exception.dart';
import 'easy_auth_api_paths.dart';

/// EasyAuth API客户端
/// 负责与anylogin后端服务通信
class EasyAuthApiClient {
  final String baseUrl;
  final String tenantId;
  final String sceneId;
  final http.Client? httpClient;

  EasyAuthApiClient({
    required this.baseUrl,
    required this.tenantId,
    required this.sceneId,
    this.httpClient,
  });

  http.Client get _client => httpClient ?? http.Client();

  /// 发送短信验证码
  Future<void> sendSMSCode(String phoneNumber) async {
    print('📤 [sendSMSCode] URL: $baseUrl${EasyAuthApiPaths.sendSMSCode}');
    print('📤 [sendSMSCode] TenantID: $tenantId');
    print('📤 [sendSMSCode] Phone: $phoneNumber');

    final response = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.sendSMSCode}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'tenant_id': tenantId, 'phone': phoneNumber}),
    );

    print('📥 [sendSMSCode] Status: ${response.statusCode}');
    print('📥 [sendSMSCode] Response: ${response.body}');

    _handleResponse(response);
  }

  /// 发送邮箱验证码
  Future<void> sendEmailCode(String email) async {
    print('📤 [sendEmailCode] URL: $baseUrl${EasyAuthApiPaths.sendEmailCode}');
    print('📤 [sendEmailCode] TenantID: $tenantId');
    print('📤 [sendEmailCode] Email: $email');

    final response = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.sendEmailCode}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'tenant_id': tenantId, 'email': email}),
    );

    print('📥 [sendEmailCode] Status: ${response.statusCode}');
    print('📥 [sendEmailCode] Response: ${response.body}');

    _handleResponse(response);
  }

  /// 短信验证码登录（一次性完成）
  Future<LoginResult> loginWithSMS({
    required String phoneNumber,
    required String code,
  }) async {
    print('📤 [loginWithSMS] 一次性登录');
    print('   Phone: $phoneNumber');

    final response = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.directLogin}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tenant_id': tenantId,
        'scene_id': sceneId,
        'channel_id': 'sms',
        'channel_data': {'phone': phoneNumber, 'code': code},
      }),
    );

    print('📥 [loginWithSMS] Status: ${response.statusCode}');
    print('📥 [loginWithSMS] Response: ${response.body}');

    final data = _handleResponse(response);

    final token = data['token'] as String?;
    final userInfo = data['user_info'] as Map<String, dynamic>?;

    if (token == null) {
      throw EasyAuthException('No token received');
    }

    return LoginResult(
      status: LoginStatus.success,
      token: token,
      userInfo: userInfo != null ? UserInfo.fromJson(userInfo) : null,
    );
  }

  /// 邮箱验证码登录（一次性完成）
  Future<LoginResult> loginWithEmail({
    required String email,
    required String code,
  }) async {
    print('📤 [loginWithEmail] 一次性登录');
    print('   Email: $email');

    final response = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.directLogin}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tenant_id': tenantId,
        'scene_id': sceneId,
        'channel_id': 'email',
        'channel_data': {'email': email, 'code': code},
      }),
    );

    print('📥 [loginWithEmail] Status: ${response.statusCode}');
    print('📥 [loginWithEmail] Response: ${response.body}');

    final data = _handleResponse(response);

    final token = data['token'] as String?;
    final userInfo = data['user_info'] as Map<String, dynamic>?;

    if (token == null) {
      throw EasyAuthException('No token received');
    }

    return LoginResult(
      status: LoginStatus.success,
      token: token,
      userInfo: userInfo != null ? UserInfo.fromJson(userInfo) : null,
    );
  }

  /// 微信登录（一次性完成）
  /// 需要先通过原生SDK获取authCode
  Future<LoginResult> loginWithWechat(String authCode) async {
    print('📤 [loginWithWechat] 一次性登录');
    print('   AuthCode: ${authCode.substring(0, 10)}...');

    final response = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.directLogin}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tenant_id': tenantId,
        'scene_id': sceneId,
        'channel_id': 'wechat',
        'channel_data': {'code': authCode},
      }),
    );

    print('📥 [loginWithWechat] Status: ${response.statusCode}');
    print('📥 [loginWithWechat] Response: ${response.body}');

    final data = _handleResponse(response);

    final token = data['token'] as String?;
    final userInfo = data['user_info'] as Map<String, dynamic>?;

    if (token == null) {
      throw EasyAuthException('No token received');
    }

    return LoginResult(
      status: LoginStatus.success,
      token: token,
      userInfo: userInfo != null ? UserInfo.fromJson(userInfo) : null,
    );
  }

  /// Apple ID登录（一次性完成）
  /// 需要先通过原生SDK获取authCode和idToken
  Future<LoginResult> loginWithApple({
    required String authCode,
    String? idToken,
  }) async {
    print('📤 [loginWithApple] 一次性登录');

    final response = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.directLogin}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tenant_id': tenantId,
        'scene_id': sceneId,
        'channel_id': 'apple',
        'channel_data': {
          'code': authCode,
          if (idToken != null) 'id_token': idToken,
        },
      }),
    );

    print('📥 [loginWithApple] Status: ${response.statusCode}');
    print('📥 [loginWithApple] Response: ${response.body}');

    final data = _handleResponse(response);

    final token = data['token'] as String?;
    final userInfo = data['user_info'] as Map<String, dynamic>?;

    if (token == null) {
      throw EasyAuthException('No token received');
    }

    return LoginResult(
      status: LoginStatus.success,
      token: token,
      userInfo: userInfo != null ? UserInfo.fromJson(userInfo) : null,
    );
  }

  /// Google登录（一次性完成）
  /// 需要先通过原生SDK获取authCode
  Future<LoginResult> loginWithGoogle({
    required String authCode,
    String? idToken,
  }) async {
    print('📤 [loginWithGoogle] 一次性登录');

    final response = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.directLogin}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tenant_id': tenantId,
        'scene_id': sceneId,
        'channel_id': 'google',
        'channel_data': {
          'code': authCode,
          if (idToken != null) 'id_token': idToken,
        },
      }),
    );

    print('📥 [loginWithGoogle] Status: ${response.statusCode}');
    print('📥 [loginWithGoogle] Response: ${response.body}');

    final data = _handleResponse(response);

    final token = data['token'] as String?;
    final userInfo = data['user_info'] as Map<String, dynamic>?;

    if (token == null) {
      throw EasyAuthException('No token received');
    }

    return LoginResult(
      status: LoginStatus.success,
      token: token,
      userInfo: userInfo != null ? UserInfo.fromJson(userInfo) : null,
    );
  }

  /// 刷新Token
  Future<String> refreshToken(String token) async {
    final response = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.refreshToken}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token}),
    );

    final data = _handleResponse(response);
    return data['token'] as String;
  }

  /// 获取用户信息
  Future<UserInfo> getUserInfo(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl${EasyAuthApiPaths.getUserInfo}?token=$token'),
      headers: {'Content-Type': 'application/json'},
    );

    final data = _handleResponse(response);
    return UserInfo.fromJson(data);
  }

  /// 登出
  Future<void> logout(String token) async {
    final response = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.logout}?token=$token'),
      headers: {'Content-Type': 'application/json'},
    );

    _handleResponse(response);
  }

  /// 获取租户配置（可用的登录渠道）
  Future<TenantConfig> getTenantConfig() async {
    final url =
        '$baseUrl${EasyAuthApiPaths.getTenantConfig}?tenant_id=$tenantId';
    print('🌐 [getTenantConfig] URL: $url');
    print('🌐 [getTenantConfig] TenantID: $tenantId');

    final response = await _client.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    print('🌐 [getTenantConfig] Status: ${response.statusCode}');
    print('🌐 [getTenantConfig] Response: ${response.body}');

    final data = _handleResponse(response);
    return TenantConfig.fromJson(data);
  }

  /// 处理HTTP响应
  Map<String, dynamic> _handleResponse(http.Response response) {
    // 尝试解析JSON响应
    Map<String, dynamic>? json;
    try {
      json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      // 如果不是JSON格式，使用原始body
      if (response.statusCode != 200) {
        throw EasyAuthException(
          'HTTP ${response.statusCode}: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    }

    // 如果HTTP状态码不是200，尝试从JSON中提取错误信息
    if (response.statusCode != 200) {
      final msg = json?['msg'] as String? ?? response.body;
      throw EasyAuthException(msg, statusCode: response.statusCode);
    }

    // HTTP 200，检查业务code
    final code = json?['code'] as int?;

    // 兼容 code: 0 和 code: 200 两种成功响应
    if (code != 0 && code != 200) {
      final msg = json?['msg'] as String? ?? 'Unknown error';
      throw EasyAuthException(msg, statusCode: code);
    }

    return json?['data'] as Map<String, dynamic>? ?? {};
  }

  /// 关闭HTTP客户端
  void close() {
    if (httpClient == null) {
      _client.close();
    }
  }
}
