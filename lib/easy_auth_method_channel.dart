import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'easy_auth_platform_interface.dart';

/// An implementation of [EasyAuthPlatform] that uses method channels.
class MethodChannelEasyAuth extends EasyAuthPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('easy_auth');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
