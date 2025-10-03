import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'easy_auth_method_channel.dart';

abstract class EasyAuthPlatform extends PlatformInterface {
  /// Constructs a EasyAuthPlatform.
  EasyAuthPlatform() : super(token: _token);

  static final Object _token = Object();

  static EasyAuthPlatform _instance = MethodChannelEasyAuth();

  /// The default instance of [EasyAuthPlatform] to use.
  ///
  /// Defaults to [MethodChannelEasyAuth].
  static EasyAuthPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [EasyAuthPlatform] when
  /// they register themselves.
  static set instance(EasyAuthPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
