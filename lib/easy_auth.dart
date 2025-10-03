
import 'easy_auth_platform_interface.dart';

class EasyAuth {
  Future<String?> getPlatformVersion() {
    return EasyAuthPlatform.instance.getPlatformVersion();
  }
}
