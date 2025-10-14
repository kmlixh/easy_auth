import Flutter
import UIKit
import AuthenticationServices

public class EasyAuthPlugin: NSObject, FlutterPlugin {
  private var channel: FlutterMethodChannel?
  private var appleLoginDelegate: AppleLoginDelegate?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "easy_auth", binaryMessenger: registrar.messenger())
    let instance = EasyAuthPlugin()
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
      
    case "appleLogin":
      handleAppleLogin(result: result)
      
    case "wechatLogin":
      handleWechatLogin(result: result)
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  // ========================================
  // Apple ID 登录
  // ========================================
  
  private func handleAppleLogin(result: @escaping FlutterResult) {
    if #available(iOS 13.0, *) {
      let appleIDProvider = ASAuthorizationAppleIDProvider()
      let request = appleIDProvider.createRequest()
      request.requestedScopes = [.fullName, .email]
      
      let authorizationController = ASAuthorizationController(authorizationRequests: [request])
      appleLoginDelegate = AppleLoginDelegate(result: result)
      authorizationController.delegate = appleLoginDelegate
      authorizationController.presentationContextProvider = appleLoginDelegate
      authorizationController.performRequests()
    } else {
      result(FlutterError(
        code: "UNAVAILABLE",
        message: "Apple Sign In is only available on iOS 13.0 or later",
        details: nil
      ))
    }
  }
  
  // ========================================
  // 微信登录
  // ========================================
  
  private func handleWechatLogin(result: @escaping FlutterResult) {
    // 检查是否集成了微信SDK
    guard let wechatClass = NSClassFromString("WXApi") else {
      result(FlutterError(
        code: "SDK_NOT_FOUND",
        message: "Wechat SDK not found. Please integrate WeChat SDK first.",
        details: nil
      ))
      return
    }
    
    // 检查是否安装了微信App
    let wechatInstalled = checkWechatInstalled()
    if !wechatInstalled {
      result(FlutterError(
        code: "APP_NOT_INSTALLED",
        message: "WeChat app is not installed",
        details: nil
      ))
      return
    }
    
    // 调用微信登录
    // 注意：这里需要实际集成微信SDK才能工作
    // 以下是伪代码示例
    /*
    let req = SendAuthReq()
    req.scope = "snsapi_userinfo"
    req.state = "easy_auth_wechat_login"
    WXApi.send(req)
    
    // 保存result回调，在AppDelegate中微信回调时使用
    WechatLoginManager.shared.pendingResult = result
    */
    
    result(FlutterError(
      code: "NOT_IMPLEMENTED",
      message: "WeChat login requires manual SDK integration. Please see documentation.",
      details: nil
    ))
  }
  
  private func checkWechatInstalled() -> Bool {
    if let url = URL(string: "weixin://") {
      return UIApplication.shared.canOpenURL(url)
    }
    return false
  }
}

// ========================================
// Apple登录代理
// ========================================

@available(iOS 13.0, *)
class AppleLoginDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
  
  private let result: FlutterResult
  
  init(result: @escaping FlutterResult) {
    self.result = result
  }
  
  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    return UIApplication.shared.keyWindow!
  }
  
  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
      // 获取授权码
      guard let authorizationCode = appleIDCredential.authorizationCode,
            let authCodeString = String(data: authorizationCode, encoding: .utf8) else {
        result(FlutterError(
          code: "AUTH_CODE_ERROR",
          message: "Failed to get authorization code",
          details: nil
        ))
        return
      }
      
      // 获取ID Token（可选）
      var idTokenString: String? = nil
      if let identityToken = appleIDCredential.identityToken {
        idTokenString = String(data: identityToken, encoding: .utf8)
      }
      
      // 返回结果
      var resultDict: [String: Any] = [
        "authCode": authCodeString,
        "user": appleIDCredential.user
      ]
      
      if let idToken = idTokenString {
        resultDict["idToken"] = idToken
      }
      
      if let fullName = appleIDCredential.fullName {
        var nameDict: [String: String] = [:]
        if let givenName = fullName.givenName {
          nameDict["givenName"] = givenName
        }
        if let familyName = fullName.familyName {
          nameDict["familyName"] = familyName
        }
        if !nameDict.isEmpty {
          resultDict["fullName"] = nameDict
        }
      }
      
      if let email = appleIDCredential.email {
        resultDict["email"] = email
      }
      
      result(resultDict)
    } else {
      result(FlutterError(
        code: "INVALID_CREDENTIAL",
        message: "Invalid Apple ID credential",
        details: nil
      ))
    }
  }
  
  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    let authError = error as NSError
    
    // 用户取消
    if authError.code == 1001 {
      result(FlutterError(
        code: "USER_CANCELLED",
        message: "User cancelled Apple Sign In",
        details: nil
      ))
      return
    }
    
    // 其他错误
    result(FlutterError(
      code: "AUTH_ERROR",
      message: "Apple Sign In failed: \(error.localizedDescription)",
      details: error.localizedDescription
    ))
  }
}

// ========================================
// 微信登录管理器（单例）
// ========================================

class WechatLoginManager {
  static let shared = WechatLoginManager()
  var pendingResult: FlutterResult?
  
  private init() {}
  
  func handleWechatCallback(code: String?, error: Error?) {
    guard let result = pendingResult else { return }
    
    if let error = error {
      result(FlutterError(
        code: "WECHAT_AUTH_ERROR",
        message: "WeChat auth failed: \(error.localizedDescription)",
        details: nil
      ))
    } else if let code = code {
      result(code)
    } else {
      result(FlutterError(
        code: "UNKNOWN_ERROR",
        message: "Unknown error in WeChat callback",
        details: nil
      ))
    }
    
    pendingResult = nil
  }
}
