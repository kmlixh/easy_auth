// 用 *真实* 的 anylogin /login/getTenantConfig 响应字符串
// 喂给 SDK 的解析链路,验证:
//   1. _handleResponse 不会因 code/data 任意字段错抛异常
//   2. TenantConfig.fromJson 把所有渠道都解析出来
//   3. getTenantConfig() 最终返回的 TenantConfig 不会让 LoginPage 显示
//      "未配置任何登录方式" 错误页 (supportedChannels 非空)
//
// 真实响应抓自 `curl https://auth.janyee.com/login/getTenantConfig?tenant_id=kiku_app`

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:easy_auth/easy_auth.dart';

const realResponse = r'''{"code":0,"data":{"tenant_id":"kiku_app","tenant_name":"Kiku","icon":"https://res.janyee.com/kiku/kiku_logo.png","supported_channels":[{"channel_id":"sms","channel_name":"sms","channel_title":"短信验证码","logo":"https://res.janyee.com/kiku/icons/sms.png","sort_order":1},{"channel_id":"email","channel_name":"email","channel_title":"邮箱验证码","logo":"https://res.janyee.com/kiku/icons/email.png","sort_order":2},{"channel_id":"wechat","channel_name":"wechat","channel_title":"微信登录","logo":"https://res.janyee.com/kiku/icons/wechat.png","sort_order":3},{"channel_id":"google","channel_name":"google","channel_title":"Google登录","logo":"https://res.janyee.com/kiku/icons/google.png","sort_order":4,"config":{"android":"abc.apps.googleusercontent.com","desktop":"abc.apps.googleusercontent.com","ios":"abc.apps.googleusercontent.com","web":"abc.apps.googleusercontent.com"}},{"channel_id":"apple","channel_name":"apple","channel_title":"Apple ID登录","logo":"https://res.janyee.com/kiku/icons/apple.png","sort_order":5}],"default_channel":"sms"},"msg":"success"}''';

void main() {
  test('用真实响应字符串调 getTenantConfig() → 不抛 + 5 个渠道全在', () async {
    final mock = MockClient((req) async {
      expect(req.url.path, '/login/getTenantConfig');
      expect(req.url.queryParameters['tenant_id'], 'kiku_app');
      return http.Response(
        realResponse,
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final api = EasyAuthApiClient(
      baseUrl: 'https://auth.janyee.com',
      tenantId: 'kiku_app',
      sceneId: 'app_native',
      httpClient: mock,
    );

    final cfg = await api.getTenantConfig();

    expect(cfg.tenantId, 'kiku_app');
    expect(cfg.tenantName, 'Kiku');
    expect(cfg.supportedChannels.length, 5,
        reason: 'sms / email / wechat / google / apple 五个');
    expect(cfg.supportedChannels.map((c) => c.channelId).toList(),
        ['sms', 'email', 'wechat', 'google', 'apple']);
    expect(cfg.defaultChannel, 'sms');
  });

  test('baseUrl 末尾 / → 不会拼出 // 的脏 URL', () async {
    String? capturedPath;
    final mock = MockClient((req) async {
      capturedPath = req.url.path;
      return http.Response(realResponse, 200,
          headers: {'content-type': 'application/json'});
    });
    final api = EasyAuthApiClient(
      baseUrl: 'https://auth.janyee.com/', // 末尾故意带斜杠
      tenantId: 'kiku_app',
      sceneId: 'app_native',
      httpClient: mock,
    );
    await api.getTenantConfig();
    expect(capturedPath, isNot(contains('//')),
        reason: 'baseUrl 末尾斜杠 + path 开头斜杠 = // 双斜杠,后端 404');
  });

  test('错误 baseUrl(/user 前缀) + 后端 404 → 抛清晰异常', () async {
    final mock = MockClient((req) async {
      // 模拟后端 404
      return http.Response('Cannot GET /user/login/getTenantConfig', 404);
    });
    final api = EasyAuthApiClient(
      baseUrl: 'https://api.janyee.com/user', // 文档曾经胡编的错误 baseUrl
      tenantId: 'kiku_app',
      sceneId: 'app_native',
      httpClient: mock,
    );
    EasyAuthException? caught;
    try {
      await api.getTenantConfig();
    } on EasyAuthException catch (e) {
      caught = e;
    }
    expect(caught, isNotNull, reason: '404 必须抛 EasyAuthException,不能静默返空');
    expect(caught!.statusCode, 404);
  });

  test('后端返回 code 字段缺失 → 也能正确处理(不该把没有 code 当错)', () async {
    // 防御性测试:如果后端有天改了响应不包 code 字段,直接 {data:{...}},
    // SDK 不应该把它当业务错(code != 0 && code != 200 throw)
    const noCodeResp =
        '{"data":{"tenant_id":"x","tenant_name":"X","supported_channels":[]}}';
    final mock = MockClient((req) async => http.Response(noCodeResp, 200));
    final api = EasyAuthApiClient(
      baseUrl: 'https://auth.janyee.com',
      tenantId: 'x',
      sceneId: 'app_native',
      httpClient: mock,
    );
    EasyAuthException? caught;
    try {
      await api.getTenantConfig();
    } on EasyAuthException catch (e) {
      caught = e;
    }
    if (caught != null) {
      // 这就是 bug:_handleResponse 把缺 code 当业务错抛了
      fail('缺 code 字段时不应该抛异常:${caught.message}');
    }
  });
}
