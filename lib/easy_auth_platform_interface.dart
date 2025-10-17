/// EasyAuth平台接口
/// 这是一个纯Flutter包，不需要原生代码
abstract class EasyAuthPlatform {
  /// 获取平台版本
  Future<String?> getPlatformVersion() async {
    return 'Flutter ${await _getFlutterVersion()}';
  }

  /// 获取Flutter版本
  Future<String> _getFlutterVersion() async {
    // 这里可以返回Flutter版本信息
    return '3.x.x';
  }
}
