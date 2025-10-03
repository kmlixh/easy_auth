#include "include/easy_auth/easy_auth_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "easy_auth_plugin.h"

void EasyAuthPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  easy_auth::EasyAuthPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
