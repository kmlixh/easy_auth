import 'package:flutter_test/flutter_test.dart';
import 'package:easy_auth/easy_auth.dart';
import 'package:easy_auth/easy_auth_platform_interface.dart';
import 'package:easy_auth/easy_auth_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEasyAuthPlatform
    with MockPlatformInterfaceMixin
    implements EasyAuthPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final EasyAuthPlatform initialPlatform = EasyAuthPlatform.instance;

  test('$MethodChannelEasyAuth is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelEasyAuth>());
  });

  test('getPlatformVersion', () async {
    EasyAuth easyAuthPlugin = EasyAuth();
    MockEasyAuthPlatform fakePlatform = MockEasyAuthPlatform();
    EasyAuthPlatform.instance = fakePlatform;

    expect(await easyAuthPlugin.getPlatformVersion(), '42');
  });
}
