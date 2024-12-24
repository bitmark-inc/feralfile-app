import UIKit
import Flutter
import flutter_downloader

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    FlutterDownloaderPlugin.setPluginRegistrantCallback(registerPlugins)
      
      /*
       Retrieve / Delete Recovery Phrase
       */
      let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
      let walletChannel = FlutterMethodChannel(name: "com.feralfile.wallet", binaryMessenger: controller.binaryMessenger)
      
      walletChannel.setMethodCallHandler({(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
          switch call.method {
          case "exportMnemonicForAllPersonaUUIDs":
              SystemChannelHandler.shared.exportMnemonicForAllPersonaUUIDs(call: call, result: result)
//          case "removeKeys":
//              SystemChannelHandler.shared.removeKeys(call: call, result: result)
          default:
              result(FlutterMethodNotImplemented)
          }
      })
      
      /*
       End Section
       */
      
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

private func registerPlugins(registry: FlutterPluginRegistry) {
    if (!registry.hasPlugin("FlutterDownloaderPlugin")) {
       FlutterDownloaderPlugin.register(with: registry.registrar(forPlugin: "FlutterDownloaderPlugin")!)
    }
}
