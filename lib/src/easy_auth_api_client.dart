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
    final response = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.sendSMSCode}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'tenant_id': tenantId, 'phone_number': phoneNumber}),
    );

    _handleResponse(response);
  }

  /// 发送邮箱验证码
  Future<void> sendEmailCode(String email) async {
    final response = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.sendEmailCode}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'tenant_id': tenantId, 'email': email}),
    );

    _handleResponse(response);
  }

  /// 短信验证码登录
  Future<LoginResult> loginWithSMS({
    required String phoneNumber,
    required String code,
  }) async {
    // 1. 调用login接口
    final loginResponse = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.login}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tenant_id': tenantId,
        'scene_id': sceneId,
        'channel_id': 'sms',
        'channel_data': {'phone': phoneNumber, 'code': code},
      }),
    );

    _handleResponse(loginResponse);

    // 2. 调用loginCallback接口
    final callbackResponse = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.loginCallback}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tenant_id': tenantId,
        'scene_id': sceneId,
        'channel_id': 'sms',
        'channel_data': {'phone': phoneNumber, 'code': code},
      }),
    );

    final callbackData = _handleResponse(callbackResponse);
    final tempToken = callbackData['temp_token'] as String?;

    if (tempToken == null) {
      throw EasyAuthException('No temp_token received');
    }

    // 3. 轮询loginResult获取最终token
    return await _pollLoginResult(tempToken);
  }

  /// 邮箱验证码登录
  Future<LoginResult> loginWithEmail({
    required String email,
    required String code,
  }) async {
    // 1. 调用login接口
    final loginResponse = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.login}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tenant_id': tenantId,
        'scene_id': sceneId,
        'channel_id': 'email',
        'channel_data': {'email': email, 'code': code},
      }),
    );

    _handleResponse(loginResponse);

    // 2. 调用loginCallback接口
    final callbackResponse = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.loginCallback}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tenant_id': tenantId,
        'scene_id': sceneId,
        'channel_id': 'email',
        'channel_data': {'email': email, 'code': code},
      }),
    );

    final callbackData = _handleResponse(callbackResponse);
    final tempToken = callbackData['temp_token'] as String?;

    if (tempToken == null) {
      throw EasyAuthException('No temp_token received');
    }

    // 3. 轮询loginResult获取最终token
    return await _pollLoginResult(tempToken);
  }

  /// 微信登录（需要先通过原生SDK获取authCode）
  Future<LoginResult> loginWithWechat(String authCode) async {
    // 1. 调用login接口
    final loginResponse = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.login}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tenant_id': tenantId,
        'scene_id': sceneId,
        'channel_id': 'wechat',
        'channel_data': {'code': authCode},
      }),
    );

    _handleResponse(loginResponse);

    // 2. 调用loginCallback接口
    final callbackResponse = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.loginCallback}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tenant_id': tenantId,
        'scene_id': sceneId,
        'channel_id': 'wechat',
        'channel_data': {'code': authCode},
      }),
    );

    final callbackData = _handleResponse(callbackResponse);
    final tempToken = callbackData['temp_token'] as String?;

    if (tempToken == null) {
      throw EasyAuthException('No temp_token received');
    }

    // 3. 轮询loginResult获取最终token
    return await _pollLoginResult(tempToken);
  }

  /// Apple ID登录（需要先通过原生SDK获取authCode）
  Future<LoginResult> loginWithApple({
    required String authCode,
    String? idToken,
  }) async {
    // 1. 调用login接口
    final loginResponse = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.login}'),
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

    _handleResponse(loginResponse);

    // 2. 调用loginCallback接口
    final callbackResponse = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.loginCallback}'),
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

    final callbackData = _handleResponse(callbackResponse);
    final tempToken = callbackData['temp_token'] as String?;

    if (tempToken == null) {
      throw EasyAuthException('No temp_token received');
    }

    // 3. 轮询loginResult获取最终token
    return await _pollLoginResult(tempToken);
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

  /// 轮询登录结果
  Future<LoginResult> _pollLoginResult(String tempToken) async {
    const maxAttempts = 30; // 最多尝试30次
    const pollInterval = Duration(seconds: 1); // 每秒轮询一次

    for (var i = 0; i < maxAttempts; i++) {
      await Future.delayed(pollInterval);

      try {
        final response = await _client.get(
          Uri.parse(
            '$baseUrl${EasyAuthApiPaths.loginResult}?temp_token=$tempToken',
          ),
          headers: {'Content-Type': 'application/json'},
        );

        final data = _handleResponse(response);
        final status = data['status'] as String?;

        if (status == 'success') {
          final token = data['token'] as String?;
          final userInfo = data['user_info'] as Map<String, dynamic>?;

          if (token == null) {
            throw EasyAuthException('No token in login result');
          }

          return LoginResult(
            status: LoginStatus.success,
            token: token,
            userInfo: userInfo != null ? UserInfo.fromJson(userInfo) : null,
          );
        } else if (status == 'pending') {
          // 继续轮询
          continue;
        } else if (status == 'failed') {
          final message = data['message'] as String? ?? 'Login failed';
          return LoginResult(status: LoginStatus.failed, message: message);
        }
      } catch (e) {
        // 轮询过程中的错误，继续尝试
        if (i == maxAttempts - 1) {
          rethrow;
        }
      }
    }

    // 超时
    return LoginResult(
      status: LoginStatus.timeout,
      message: 'Login polling timeout',
    );
  }

  /// 获取租户配置
  Future<TenantConfig> getTenantConfig(String tenantId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl${EasyAuthApiPaths.getTenantConfig}?tenant_id=$tenantId'),
      headers: {'Content-Type': 'application/json'},
    );

    final data = _handleResponse(response);
    return TenantConfig.fromJson(data);
  }

  /// 处理HTTP响应
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw EasyAuthException(
        'HTTP ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
      );
    }

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final code = json['code'] as int?;

    if (code != 200) {
      final msg = json['msg'] as String? ?? 'Unknown error';
      throw EasyAuthException(msg, statusCode: code);
    }

    return json['data'] as Map<String, dynamic>? ?? {};
  }

  /// 关闭HTTP客户端
  void close() {
    if (httpClient == null) {
      _client.close();
    }
  }
}
