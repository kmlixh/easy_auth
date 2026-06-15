import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_auth/easy_auth.dart';

// ============================================================================
// 集成测试:resolveBindConflict / revertMerge 收到 merge_event 后,
// EasyAuth().onAccountMerge Stream 必须把事件派发出来
//
// 这条链路是消费方 app 业务数据迁移的唯一信号源,断不得。
// ============================================================================

void main() {
  // EasyAuth._internal() 在构造时就 new WechatLoginService(),触发 fluwx
  // 的 MethodChannel 注册 — 测试环境必须先初始化 TestWidgetsFlutterBinding
  // 才能让 setMethodCallHandler 不崩。
  //
  // (这其实暴露 SDK 一个潜在改进点:WechatLoginService 应该 lazy 化,
  //  不用微信登录的应用没必要在 SDK 启动时就加载 fluwx。)
  TestWidgetsFlutterBinding.ensureInitialized();

  // 把 fluwx / google_sign_in / sign_in_with_apple 这些 native MethodChannel
  // 的调用全部 swallow 成 no-op,测试就不会因为缺真机崩。
  setUpAll(() {
    for (final ch in [
      'com.OpenFlutter.fluwx',
      'plugins.flutter.io/google_sign_in',
      'com.aboutyou.dart_packages.sign_in_with_apple',
      'plugins.flutter.io/shared_preferences',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(ch), (call) async => null);
    }
  });

  setUp(() async {
    // 每个 case 前重置 SharedPreferences,避免上次 session 串扰
    SharedPreferences.setMockInitialValues({
      'easy_auth_token': 'fake_token_for_test',
      'easy_auth_user_info': jsonEncode({'user_id': 'current_user'}),
    });
  });

  test('resolveBindConflict 收到 merge_event → onAccountMerge emit', () async {
    // mock 后端返回带 merge_event 的成功响应
    final mockClient = MockClient((req) async {
      expect(req.url.path, '/login/bindChannelResolve');
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      expect(body['action'], 'other_into_me');
      return http.Response(
        jsonEncode({
          'status': 'ok',
          'linked_channels': [],
          'merge_event': {
            'merge_id': 'm-test-1',
            'direction': 'other_into_me',
            'source_user_id': 'other-uid',
            'target_user_id': 'current_user',
            'merged_at': '2026-06-15T10:00:00Z',
            'revert_deadline': '2026-06-22T10:00:00Z',
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await EasyAuth().init(EasyAuthConfig(
      baseUrl: 'http://test',
      tenantId: 'kiku',
      sceneId: 'app_native',
    ));
    // 把 apiClient 换成带 mock httpClient 的实例
    EasyAuth().setApiClientForTesting(EasyAuthApiClient(
      baseUrl: 'http://test',
      tenantId: 'kiku',
      sceneId: 'app_native',
      httpClient: mockClient,
    ));

    // 关键链路:listen → 调 resolveBindConflict → 事件应该被派发
    final received = <MergeEvent>[];
    final sub = EasyAuth().onAccountMerge.listen(received.add);

    final result = await EasyAuth().resolveBindConflict(
      conflictToken: 'ct',
      action: ResolveAction.otherIntoMe,
    );

    // 给 Stream 一拍时间 emit
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(result, isA<BindOk>());
    expect((result as BindOk).mergeEvent, isNotNull);

    expect(received.length, 1, reason: 'onAccountMerge 必须 emit 一次');
    expect(received.first.mergeId, 'm-test-1');
    expect(received.first.direction, MergeDirection.otherIntoMe);
    expect(received.first.fromUserId, 'other-uid');
    expect(received.first.toUserId, 'current_user');

    await sub.cancel();
  });

  test('resolveBindConflict 响应里没 merge_event → onAccountMerge 不 emit', () async {
    // 比如 action=abort 的场景,后端就不带 merge_event
    final mockClient = MockClient((req) async {
      return http.Response(
        jsonEncode({'status': 'ok', 'linked_channels': []}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await EasyAuth().init(EasyAuthConfig(
      baseUrl: 'http://test',
      tenantId: 'kiku',
      sceneId: 'app_native',
    ));
    EasyAuth().setApiClientForTesting(EasyAuthApiClient(
      baseUrl: 'http://test',
      tenantId: 'kiku',
      sceneId: 'app_native',
      httpClient: mockClient,
    ));

    final received = <MergeEvent>[];
    final sub = EasyAuth().onAccountMerge.listen(received.add);

    await EasyAuth().resolveBindConflict(
      conflictToken: 'ct',
      action: ResolveAction.abort,
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(received, isEmpty, reason: '没 merge_event 就不该 emit');
    await sub.cancel();
  });

  test('revertMerge 收到 direction=revert → fromUserId/toUserId 翻转', () async {
    final mockClient = MockClient((req) async {
      expect(req.url.path, '/login/revertMerge');
      return http.Response(
        jsonEncode({
          'code': 0,
          'msg': 'ok',
          'data': {
            'ok': true,
            'merge_event': {
              'merge_id': 'm-test-2',
              'direction': 'revert',
              'source_user_id': 'src',
              'target_user_id': 'tgt',
              'merged_at': '2026-06-15T10:00:00Z',
            },
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await EasyAuth().init(EasyAuthConfig(
      baseUrl: 'http://test',
      tenantId: 'kiku',
      sceneId: 'app_native',
    ));
    EasyAuth().setApiClientForTesting(EasyAuthApiClient(
      baseUrl: 'http://test',
      tenantId: 'kiku',
      sceneId: 'app_native',
      httpClient: mockClient,
    ));

    final received = <MergeEvent>[];
    final sub = EasyAuth().onAccountMerge.listen(received.add);

    final event = await EasyAuth().revertMerge('m-test-2');
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(event, isNotNull);
    expect(event!.direction, MergeDirection.revert);
    // 业务 app 视角:revert 时 from/to 翻转,数据从 target 还回 source
    expect(event.fromUserId, 'tgt');
    expect(event.toUserId, 'src');

    expect(received.length, 1);
    expect(received.first.direction, MergeDirection.revert);

    await sub.cancel();
  });

  test('401 + error_code=account_merged → AccountStateException with mergedInto', () async {
    final mockClient = MockClient((req) async {
      return http.Response(
        jsonEncode({
          'code': 401,
          'message': 'account merged',
          'error_code': 'account_merged',
          'merged_into': 'real-target-uid',
        }),
        401,
        headers: {'content-type': 'application/json'},
      );
    });

    await EasyAuth().init(EasyAuthConfig(
      baseUrl: 'http://test',
      tenantId: 'kiku',
      sceneId: 'app_native',
    ));
    EasyAuth().setApiClientForTesting(EasyAuthApiClient(
      baseUrl: 'http://test',
      tenantId: 'kiku',
      sceneId: 'app_native',
      httpClient: mockClient,
    ));

    AccountStateException? caught;
    try {
      await EasyAuth().myChannels();
    } on AccountStateException catch (e) {
      caught = e;
    }
    expect(caught, isNotNull);
    expect(caught!.isMerged, isTrue);
    expect(caught.mergedInto, 'real-target-uid');
  });
}
