package com.example.easy_auth

import android.app.Activity
import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** EasyAuthPlugin */
class EasyAuthPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel
  private var context: Context? = null
  private var activity: Activity? = null
  private var wechatLoginHandler: WechatLoginHandler? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "easy_auth")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "wechatLogin" -> {
        handleWechatLogin(result)
      }
      "appleLogin" -> {
        // Android不支持Apple登录，需要使用网页方式
        result.error(
          "UNSUPPORTED_PLATFORM",
          "Apple Sign In is not available on Android",
          null
        )
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    context = null
  }

  // ========================================
  // Activity生命周期
  // ========================================

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    wechatLoginHandler = WechatLoginHandler(activity!!)
  }

  override fun onDetachedFromActivity() {
    activity = null
    wechatLoginHandler = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  // ========================================
  // 微信登录
  // ========================================

  private fun handleWechatLogin(result: Result) {
    val handler = wechatLoginHandler
    if (handler == null) {
      result.error(
        "NO_ACTIVITY",
        "Activity is not attached",
        null
      )
      return
    }

    // 检查是否集成了微信SDK
    try {
      Class.forName("com.tencent.mm.opensdk.openapi.WXAPIFactory")
    } catch (e: ClassNotFoundException) {
      result.error(
        "SDK_NOT_FOUND",
        "Wechat SDK not found. Please integrate Wechat SDK first.",
        null
      )
      return
    }

    // 检查是否安装了微信App
    if (!handler.isWechatInstalled()) {
      result.error(
        "APP_NOT_INSTALLED",
        "WeChat app is not installed",
        null
      )
      return
    }

    // 调用微信登录
    // 注意：这里需要实际集成微信SDK才能工作
    // 以下是伪代码示例
    /*
    val req = SendAuth.Req()
    req.scope = "snsapi_userinfo"
    req.state = "easy_auth_wechat_login"
    
    val api = handler.getWXAPI()
    if (api.sendReq(req)) {
      WechatLoginManager.pendingResult = result
    } else {
      result.error("SEND_REQUEST_FAILED", "Failed to send WeChat auth request", null)
    }
    */

    result.error(
      "NOT_IMPLEMENTED",
      "WeChat login requires manual SDK integration. Please see documentation.",
      null
    )
  }
}

// ========================================
// 微信登录处理器
// ========================================

class WechatLoginHandler(private val activity: Activity) {
  
  fun isWechatInstalled(): Boolean {
    return try {
      val packageManager = activity.packageManager
      packageManager.getPackageInfo("com.tencent.mm", 0)
      true
    } catch (e: Exception) {
      false
    }
  }
  
  // 获取微信API实例（需要集成微信SDK）
  /*
  fun getWXAPI(): IWXAPI {
    val api = WXAPIFactory.createWXAPI(activity, "YOUR_WECHAT_APP_ID", true)
    api.registerApp("YOUR_WECHAT_APP_ID")
    return api
  }
  */
}

// ========================================
// 微信登录管理器（单例）
// ========================================

object WechatLoginManager {
  var pendingResult: Result? = null
  
  fun handleWechatCallback(code: String?, error: String?) {
    val result = pendingResult ?: return
    
    when {
      error != null -> {
        result.error("WECHAT_AUTH_ERROR", "WeChat auth failed: $error", null)
      }
      code != null -> {
        result.success(code)
      }
      else -> {
        result.error("UNKNOWN_ERROR", "Unknown error in WeChat callback", null)
      }
    }
    
    pendingResult = null
  }
}
