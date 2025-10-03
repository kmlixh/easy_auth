#ifndef FLUTTER_PLUGIN_EASY_AUTH_PLUGIN_H_
#define FLUTTER_PLUGIN_EASY_AUTH_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace easy_auth {

class EasyAuthPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  EasyAuthPlugin();

  virtual ~EasyAuthPlugin();

  // Disallow copy and assign.
  EasyAuthPlugin(const EasyAuthPlugin&) = delete;
  EasyAuthPlugin& operator=(const EasyAuthPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace easy_auth

#endif  // FLUTTER_PLUGIN_EASY_AUTH_PLUGIN_H_
