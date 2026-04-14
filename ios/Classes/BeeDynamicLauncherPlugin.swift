import Flutter
import UIKit

public class BeeDynamicLauncherPlugin: NSObject, FlutterPlugin {
  private static let channelName = "dev.bee.bee_dynamic_launcher/launcher"
  private var variantIds: [String] = []
  private var primaryVariantId: String = ""

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger())
    let instance = BeeDynamicLauncherPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      guard let args = call.arguments as? [String: Any],
            let ids = args["ids"] as? [String],
            let primary = args["primaryVariantId"] as? String else {
        result(
          FlutterError(
            code: "INVALID_ARGUMENT",
            message: "ids and primaryVariantId required",
            details: nil))
        return
      }
      if ids.isEmpty || primary.isEmpty {
        result(
          FlutterError(
            code: "INVALID_ARGUMENT",
            message: "ids and primaryVariantId required",
            details: nil))
        return
      }
      if !ids.contains(primary) {
        result(
          FlutterError(
            code: "INVALID_ARGUMENT",
            message: "primaryVariantId must be in ids",
            details: nil))
        return
      }
      variantIds = ids
      primaryVariantId = primary
      result(nil)
    case "getAvailableVariants":
      result(variantIds)
    case "getCurrentVariant":
      if variantIds.isEmpty {
        result(nil)
        return
      }
      if UIApplication.shared.supportsAlternateIcons {
        let name = UIApplication.shared.alternateIconName
        result(variantId(fromAlternateIconName: name))
      } else {
        result(primaryVariantId)
      }
    case "applyVariant":
      guard let id = call.arguments as? String else {
        result(
          FlutterError(
            code: "INVALID_ARGUMENT",
            message: "variant id required",
            details: nil))
        return
      }
      if variantIds.isEmpty {
        result(
          FlutterError(
            code: "NOT_INITIALIZED",
            message: "call initialize first",
            details: nil))
        return
      }
      guard variantIds.contains(id) else {
        result(
          FlutterError(
            code: "INVALID_ARGUMENT",
            message: "unknown variant id",
            details: nil))
        return
      }
      let iconName = iosAlternateAssetName(for: id)
      UIApplication.shared.setAlternateIconName(iconName) { error in
        if let error = error {
          result(
            FlutterError(
              code: "APPLY_FAILED",
              message: error.localizedDescription,
              details: nil))
        } else {
          result(nil)
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func iosAlternateAssetName(for id: String) -> String? {
    if id == primaryVariantId {
      return nil
    }
    let suffix = pascalCaseForLauncherId(id)
    return "AppIcon\(suffix)"
  }

  private func pascalCaseForLauncherId(_ id: String) -> String {
    if id.isEmpty {
      return id
    }
    return id.split(separator: "_").map { segment in
      let s = String(segment)
      guard let first = s.first else { return "" }
      return String(first).uppercased() + s.dropFirst().lowercased()
    }.joined()
  }

  private func variantId(fromAlternateIconName name: String?) -> String {
    guard let name = name else {
      return primaryVariantId
    }
    for id in variantIds {
      if let alt = iosAlternateAssetName(for: id), alt == name {
        return id
      }
    }
    return primaryVariantId
  }
}
