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

  /// Apple 登录（一次性完成）
  /// 原生：仅需要 idToken；部分平台可能同时提供 authCode
  /// 注意：后端原生路径只要求 id_token，web 路径通过 loginWithAppleWeb()
  Future<LoginResult> loginWithApple({
    String? authCode,
    String? idToken,
  }) async {
    print('📤 [loginWithApple] 一次性登录');

    // 构建 channel_data：原生仅需 id_token；如有 code 一并传递（后端原生路径忽略 code）
    final Map<String, dynamic> channelData = {};
    if (idToken != null) channelData['id_token'] = idToken;
    if (authCode != null) channelData['code'] = authCode;

    final response = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.directLogin}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tenant_id': tenantId,
        'scene_id': sceneId,
        'channel_id': 'apple',
        'channel_data': channelData,
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

  /// Apple Web登录（使用回调URL）
  Future<LoginResult> loginWithAppleWeb({
    required String callbackUrl,
    String? platform,
  }) async {
    print('📤 [loginWithAppleWeb] Web登录 - 平台: $platform');
    print('   Callback URL: $callbackUrl');

    final response = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.directLogin}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tenant_id': tenantId,
        'scene_id': sceneId,
        'channel_id': 'apple',
        'channel_data': {
          'callback_url': callbackUrl,
          'platform': platform ?? 'web',
        },
      }),
    );

    print('📥 [loginWithAppleWeb] Status: ${response.statusCode}');
    print('📥 [loginWithAppleWeb] Response: ${response.body}');

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

  /// Google登录（一次性完成，支持多平台）
  /// 需要先通过原生SDK获取authCode
  Future<LoginResult> loginWithGoogle({
    String? authCode,
    String? idToken,
    String? platform,
    String? callbackUrl,
  }) async {
    print('📤 [loginWithGoogle] 一次性登录 - 平台: $platform');

    // 构建channel_data
    Map<String, dynamic> channelData = {};

    if (callbackUrl != null) {
      // 使用callback_url方式
      channelData['callback_url'] = callbackUrl;
      if (platform != null) {
        channelData['platform'] = platform;
      }
    } else {
      // 使用传统方式
      if (authCode != null) {
        channelData['code'] = authCode;
      }
      if (idToken != null) {
        channelData['id_token'] = idToken;
      }
      if (platform != null) {
        channelData['platform'] = platform;
      }
    }

    final response = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.directLogin}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tenant_id': tenantId,
        'scene_id': sceneId,
        'channel_id': 'google',
        'channel_data': channelData,
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

  /// 更新用户信息
  Future<UserInfo> updateUserInfo({
    required String token,
    String? nickname,
    String? avatar,
  }) async {
    final body = <String, dynamic>{};
    if (nickname != null) body['nickname'] = nickname;
    if (avatar != null) body['avatar'] = avatar;

    final response = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.updateUserInfo}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, ...body}),
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

    // 有些后端可能返回纯文本，如 "ok"，容错处理
    if (response.statusCode != 200) {
      _handleResponse(response);
    }
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

  // ==========================================================================
  // 跨渠道账号绑定 / 合并 (对应 userLogin/binding.go)
  // ==========================================================================

  /// 通用绑定调用 — 三态返回 (ok / already_bound / conflict)
  ///
  /// 与 directLogin 共享 channel_id + channel_data 协议;不同点:
  ///   - 必须带当前已登录用户的 token (?token=...)
  ///   - 后端会返 200 (ok / already_bound) 或 409 (conflict)
  ///   - 都解析成 BindResult
  Future<BindResult> bindChannel({
    required String token,
    required String channelId,
    required Map<String, dynamic> channelData,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.bindChannel}?token=${Uri.encodeComponent(token)}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tenant_id': tenantId,
        'scene_id': sceneId,
        'channel_id': channelId,
        'channel_data': channelData,
      }),
    );

    print('📥 [bindChannel] Status: ${response.statusCode}');
    print('📥 [bindChannel] Response: ${response.body}');

    final (status, body) = _rawJsonResponse(response);
    _checkAccountState(status, body); // 401 + account_merged 等特殊错误抛 AccountStateException

    // 200(ok/already_bound) 或 409(conflict),body 直接是 BindChannelV2Result 形态
    if (status == 200 || status == 409) {
      return BindResult.fromJson(body ?? {}, httpStatus: status);
    }
    // 其它都是真错误
    final msg = body?['message'] as String? ?? body?['msg'] as String? ?? response.body;
    return BindError(message: 'HTTP $status: $msg');
  }

  /// 完成冲突合并
  Future<BindResult> resolveBindConflict({
    required String token,
    required String conflictToken,
    required ResolveAction action,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.bindChannelResolve}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'conflict_token': conflictToken,
        'action': action.wire,
      }),
    );

    print('📥 [resolveBindConflict] Status: ${response.statusCode}');
    print('📥 [resolveBindConflict] Response: ${response.body}');

    final (status, body) = _rawJsonResponse(response);
    _checkAccountState(status, body);
    if (status == 200) {
      return BindResult.fromJson(body ?? {}, httpStatus: status);
    }
    final msg = body?['message'] as String? ?? body?['msg'] as String? ?? response.body;
    return BindError(message: 'HTTP $status: $msg');
  }

  /// 7 天内回滚 merge
  Future<void> revertMerge({
    required String token,
    required String mergeId,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl${EasyAuthApiPaths.revertMerge}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'merge_id': mergeId}),
    );
    _handleResponse(response);
  }

  /// 解绑某个渠道(后端会拦截"最后一个登录方式")
  Future<void> unbindChannel({
    required String token,
    required String channelId,
  }) async {
    final response = await _client.post(
      Uri.parse(
        '$baseUrl${EasyAuthApiPaths.unbindChannel}?token=${Uri.encodeComponent(token)}&channel_id=${Uri.encodeComponent(channelId)}',
      ),
      headers: {'Content-Type': 'application/json'},
    );
    _handleResponse(response);
  }

  /// 列当前 user 的绑定渠道(channel_user_id 脱敏)
  Future<List<LinkedChannel>> myChannels(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl${EasyAuthApiPaths.myChannels}?token=${Uri.encodeComponent(token)}'),
      headers: {'Content-Type': 'application/json'},
    );
    final data = _handleResponseAsList(response);
    return data.map((e) => LinkedChannel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// _rawJsonResponse 不抛异常的 HTTP 解析,给 bind/resolve 用 — 它们要区分
  /// 200 / 409 / 401 都是合法语义
  (int, Map<String, dynamic>?) _rawJsonResponse(http.Response response) {
    Map<String, dynamic>? body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      body = null;
    }
    return (response.statusCode, body);
  }

  /// 401 + error_code='account_merged' / 'account_cancelled' / 'user_not_found'
  /// → 抛 AccountStateException (SDK 上层捕获引导用户去切账号 / 重新登录)
  void _checkAccountState(int status, Map<String, dynamic>? body) {
    if (status != 401 || body == null) return;
    final errorCode = body['error_code'] as String?;
    if (errorCode == null || errorCode.isEmpty) return;
    throw AccountStateException(
      errorCode: errorCode,
      mergedInto: body['merged_into'] as String?,
      message: (body['message'] as String?) ?? 'account state invalid',
    );
  }

  /// 复用 _handleResponse 的语义,但 data 字段是 List(myChannels 返回数组)
  List<dynamic> _handleResponseAsList(http.Response response) {
    Map<String, dynamic>? json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      throw EasyAuthException('HTTP ${response.statusCode}: ${response.body}', statusCode: response.statusCode);
    }
    _checkAccountState(response.statusCode, json);
    if (response.statusCode != 200) {
      final msg = json['msg'] as String? ?? response.body;
      throw EasyAuthException(msg, statusCode: response.statusCode);
    }
    final code = json['code'] as int?;
    if (code != 0 && code != 200) {
      throw EasyAuthException(json['msg'] as String? ?? 'unknown', statusCode: code);
    }
    return (json['data'] as List<dynamic>?) ?? [];
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

    // 401 + error_code='account_merged'/'account_cancelled' → 抛专用异常
    // 让上层 SDK 能区分"账号本身失效"和"普通服务器错误"
    _checkAccountState(response.statusCode, json);

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
