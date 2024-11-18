//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import UIKit
import Flutter
import LibAuk
import BigInt
import Web3
import KukaiCoreSwift
import Combine
import flutter_downloader
//import Sentry
import Starscream
import IOSSecuritySuite
import Sentry
import Logging
import workmanager

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    var cancelBag = Set<AnyCancellable>()
    var authenticationVC = BiometricAuthenticationViewController()
    var splashScreenVC: SplashViewController? = SplashViewController()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

//         DONT REMOVE, We will bring back the security check
//         DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//             if !Constant.isInhouse() {
//                 if self.checkDebugger() {
//                     self.captureMessage(message: "[Security check] Debugger detected")
//                     self.exitApp()
//                 }
//                 IOSSecuritySuite.denyDebugger()
//             }
//
//            // Check bundle identifier
//             let isSecure = self.checkMainBundleIdentifier()
//
//             if !isSecure {
//                 self.captureMessage(message: "[Security check] Integrity check failed")
//                 self.exitApp()
//             }
//
//             // Check reverse engineering
//             if IOSSecuritySuite.amIReverseEngineered() {
//                 self.captureMessage(message: "[Security check] Reverse engineering tool detected")
//                 self.exitApp()
//             }
//
//             // Check jailbreak
//             if IOSSecuritySuite.amIJailbroken() {
//                 self.captureMessage(message: "[Security check] Jail broken device detected")
//                 self.showAlertAndExit()
//             }
//         }

        LibAuk.create(keyChainGroup: Constant.keychainGroup)
        
        authenticationVC.authenticationCallback = self.authenticationCompleted
        
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let libaukChannel = FlutterMethodChannel(name: "libauk_dart",
                                                 binaryMessenger: controller.binaryMessenger)
        libaukChannel.setMethodCallHandler({(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "createKey":
                LibAukChannelHandler.shared.createKey(call: call, result: result)
            case "importKey":
                LibAukChannelHandler.shared.importKey(call: call, result: result)
            case "calculateFirstEthAddress":
                LibAukChannelHandler.shared.calculateFirstEthAddress(call: call, result: result)
            case "getName":
                LibAukChannelHandler.shared.getName(call: call, result: result)
            case "updateName":
                LibAukChannelHandler.shared.updateName(call: call, result: result)
            case "getAccountDID":
                LibAukChannelHandler.shared.getAccountDID(call: call, result: result)
            case "getAccountDIDSignature":
                LibAukChannelHandler.shared.getAccountDIDSignature(call: call, result: result)
            case "isWalletCreated":
                LibAukChannelHandler.shared.isWalletCreated(call: call, result: result)
            case "getETHAddress":
                LibAukChannelHandler.shared.getETHAddress(call: call, result: result)
            case "ethSignPersonalMessage":
                LibAukChannelHandler.shared.signPersonalMessage(call: call, result: result)
            case "ethSignMessage":
                LibAukChannelHandler.shared.signMessage(call: call, result: result)
            case "getETHAddressWithIndex":
                LibAukChannelHandler.shared.getETHAddressWithIndex(call: call, result: result)
            case "ethSignPersonalMessageWithIndex":
                LibAukChannelHandler.shared.signPersonalMessageWithIndex(call: call, result: result)
            case "ethSignMessageWithIndex":
                LibAukChannelHandler.shared.signMessageWithIndex(call: call, result: result)
            case "exportMnemonicPassphrase":
                LibAukChannelHandler.shared.exportMnemonicPassphrase(call: call, result: result)
            case "exportMnemonicWords":
                LibAukChannelHandler.shared.exportMnemonicWords(call: call, result: result)
            case "ethSignTransaction":
                LibAukChannelHandler.shared.signTransaction(call: call, result: result)
            case "ethSignTransaction1559":
                LibAukChannelHandler.shared.signTransaction1559(call: call, result: result)
            case "ethSignTransactionWithIndex":
                LibAukChannelHandler.shared.signTransactionWithIndex(call: call, result: result)
            case "ethSignTransaction1559WithIndex":
                LibAukChannelHandler.shared.signTransaction1559WithIndex(call: call, result: result)
            case "encryptFile":
                LibAukChannelHandler.shared.encryptFile(call: call, result: result)
            case "decryptFile":
                LibAukChannelHandler.shared.decryptFile(call: call, result: result)
            case "getTezosPublicKey":
                LibAukChannelHandler.shared.getTezosPublicKey(call: call, result: result)
            case "tezosSignMessage":
                LibAukChannelHandler.shared.tezosSign(call: call, result: result)
            case "tezosSignTransaction":
                LibAukChannelHandler.shared.tezosSignTransaction(call: call, result: result)
            case "getTezosPublicKeyWithIndex":
                LibAukChannelHandler.shared.getTezosPublicKeyWithIndex(call: call, result: result)
            case "tezosSignMessageWithIndex":
                LibAukChannelHandler.shared.tezosSignWithIndex(call: call, result: result)
            case "tezosSignTransactionWithIndex":
                LibAukChannelHandler.shared.tezosSignTransactionWithIndex(call: call, result: result)
            case "removeKeys":
                LibAukChannelHandler.shared.removeKeys(call: call, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        })
        
        let localeChannel = FlutterMethodChannel(name: "locale",
                                                    binaryMessenger: controller.binaryMessenger)
        localeChannel.setMethodCallHandler({(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "getMeasurementSystem":
                LocaleHandler.shared.getMeasurementSystem(call: call, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        })

        let keychainChannel = FlutterMethodChannel(name: "keychain",
                                                  binaryMessenger: controller.binaryMessenger)

        keychainChannel.setMethodCallHandler({(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "removeKeychainItems":
                SystemChannelHandler.shared.removeKeychainItems(call: call, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        })

        let secureScreenChannel = FlutterMethodChannel(name: "secure_screen_channel",
                                                   binaryMessenger: controller.binaryMessenger)
        secureScreenChannel.setMethodCallHandler({(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "setSecureFlag":
                SecureChannelHandler.shared.setSecureFlag(call: call, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        })

        let migrationChannel = FlutterMethodChannel(name: "migration_util",
                                                    binaryMessenger: controller.binaryMessenger)
        migrationChannel.setMethodCallHandler({(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "getiOSMigrationData":
                SystemChannelHandler.shared.getiOSMigrationData(call: call, result: result)

            case "cleariOSMigrationData":
                SystemChannelHandler.shared.cleariOSMigrationData(call: call, result: result)

            case "getWalletUUIDsFromKeychain":
                SystemChannelHandler.shared.getWalletUUIDsFromKeychain(call: call, result: result)

            case "getDeviceID":
                SystemChannelHandler.shared.getDeviceUniqueID(call: call, result: result)
                
            case "getPrimaryAddress":
                SystemChannelHandler.shared.getPrimaryAddress(call: call, result: result)
                
            case "setPrimaryAddress":
                SystemChannelHandler.shared.setPrimaryAddress(call: call, result: result)
                
            case "clearPrimaryAddress":
                SystemChannelHandler.shared.clearPrimaryAddress(call: call)

            case "didRegisterPasskey":
                SystemChannelHandler.shared.didRegisterPasskey(call: call, result: result)

            case "setDidRegisterPasskey":
                SystemChannelHandler.shared.setDidRegisterPasskey(call: call, result: result)
            
            case "setJWT":
                SystemChannelHandler.shared.setJWT(call: call, result: result)
                
            case "getJWT":
                SystemChannelHandler.shared.getJWT(call: call, result: result)
            
            case "clearJWT":
                SystemChannelHandler.shared.clearJWT(call: call, result: result)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        })
        
        let beaconChannel = FlutterMethodChannel(name: "tezos_beacon",
                                                    binaryMessenger: controller.binaryMessenger)
        let beaconEventChannel = FlutterEventChannel(name: "tezos_beacon/event", binaryMessenger: controller.binaryMessenger)
        
        beaconChannel.setMethodCallHandler({(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "connect":
                BeaconChannelHandler.shared.connect()
            case "getConnectionURI":
                BeaconChannelHandler.shared.getConnectionURI(call: call, result: result)
            case "getPostMessageConnectionURI":
                BeaconChannelHandler.shared.getPostMessageConnectionURI(call: call, result: result)
            case "addPeer":
                BeaconChannelHandler.shared.addPeer(call: call, result: result)
            case "removePeer":
                BeaconChannelHandler.shared.removePeer(call: call, result: result)
            case "cleanup":
                BeaconChannelHandler.shared.cleanupSessions(call: call, result: result)
            case "response":
                BeaconChannelHandler.shared.response(call: call, result: result)
            case "pause":
                BeaconChannelHandler.shared.pause(call: call, result: result)
            case "resume":
                BeaconChannelHandler.shared.resume(call: call, result: result)

            case "handlePostMessageOpenChannel":
                BeaconChannelHandler.shared.handlePostMessageOpenChannel(call: call, result: result)

            case "handlePostMessageMessage":
                BeaconChannelHandler.shared.handlePostMessageMessage(call: call, result: result)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        })
        beaconEventChannel.setStreamHandler(BeaconChannelHandler.shared)

        let cloudEventChannel = FlutterEventChannel(name: "cloud/event", binaryMessenger: controller.binaryMessenger)
        cloudEventChannel.setStreamHandler(CloudChannelHandler.shared)

        GeneratedPluginRegistrant.register(with: self)
        FlutterDownloaderPlugin.setPluginRegistrantCallback({ registry in
            if (!registry.hasPlugin("FlutterDownloaderPlugin")) {
                FlutterDownloaderPlugin.register(with: registry.registrar(forPlugin: "FlutterDownloaderPlugin")!)
            }
        })

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            if UserDefaults.standard.bool(forKey: "flutter.device_passcode") == true {
                SystemChannelHandler.shared.getJWT { jwtRaw in
                    guard let jwtRaw = jwtRaw else {
                            print("JWT is nil or invalid")
                            return
                        }

                        do {
                            // Decode the JWT and check its expiration
                            if let jwtData = jwtRaw.data(using: .utf8),
                               let json = try JSONSerialization.jsonObject(with: jwtData, options: []) as? [String: Any],
                               let refreshTokenExpiredAtString = json["refresh_expire_at"] as? String,
                               let refreshTokenExpiredAt = ISO8601DateFormatter().date(from: refreshTokenExpiredAtString) {

                                // Check if the token is expired
                                let isExpired = refreshTokenExpiredAt < Date()
                                if isExpired {
                                    print("Token is expired")
                                    return
                                }

                                // If not expired, trigger authentication
                                self?.showAuthenticationOverlay()
                                self?.authenticationVC.authentication()
                            } else {
                                print("Failed to decode JWT or missing required fields")
                            }
                        } catch {
                            print("Error decoding JWT: \(error.localizedDescription)")
                        }
            }
        }
        
        // Register the workmanager
        WorkmanagerPlugin.setPluginRegistrantCallback { registry in
            GeneratedPluginRegistrant.register(with: registry)
        }
        // Register a periodic task with 4 hours frequency. The frequency is in seconds.
        WorkmanagerPlugin.registerPeriodicTask(withIdentifier: "feralfile.workmanager.iOSBackgroundAppRefresh", frequency: NSNumber(value: 4 * 60 * 60))
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        return extensionPointIdentifier != .keyboard
    }

    private func captureMessage(message: String) {
        do {
            SentrySDK.capture(message: message)
        } catch {}
    }


    override func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        logger.info("handle deeplink")
        if url.scheme == "feralfile" {

            handleEmergencyLog(url)
        }
        return super.application(application, open: url, options: options)
    }

    private func handleEmergencyLog(_ url: URL) {
        logger.info("handle feralfile deeplink")

        if url.host == "emergency-logs" {
            logger.info("emergency-logs")
            let token = url.lastPathComponent
            uploadLogFile(uploadURL: Logger.appLogURL,token: token)
        }
    }

    func uploadLogFile(uploadURL: URL , token: String) {
        // Create a URLSession configuration
        logger.info("upload log file")
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)

        let endpoint = Constant.isInhouse() ? "https://support.test.autonomy.io/v1/issues/" : "https://support.autonomy.io/v1/issues/"
        // Create the request body
        guard let url = URL(string: endpoint) else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Set the authorization header
        request.setValue("Emergency \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")


        let fileData = base64EncodedFile(fileURL: uploadURL)

        if (fileData == nil) {
            return
        }
            // Construct the request body
        let requestBody: [String: Any] = [
            "attachments": [
                [
                    "data": fileData,
                    "title": "Emergency log",
                    "path": "",
                    "contentType": ""
                ]
            ],
            "title": "Emergency log",
            "message": "Emergency log",
            "tags": ["emergency", "iOS"]
        ]

            // Convert the request body to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("Failed to encode request body")
            return
        }

            // Set the request body
        request.httpBody = jsonData


            // Create a data task to perform the request
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Upload log Error: \(error)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Upload log Invalid response")
                return
            }

            print("Upload log Response status: \(httpResponse.statusCode)")
            return
        }

        // Start the data task
        task.resume()
    }

    func base64EncodedFile(fileURL: URL) -> String? {
        do {
            // Read file contents as bytes
            let fileData = try Data(contentsOf: fileURL)

            // Encode bytes to Base64
            let base64Data = fileData.base64EncodedData()

            // Convert Base64 data to a string representation
            let base64String = String(data: base64Data, encoding: .utf8)

            return base64String
        } catch {
            // Handle any errors that occur during file reading
            print("Error reading file:", error.localizedDescription)
            return nil
        }
    }

    override func applicationWillEnterForeground(_ application: UIApplication) {
        if UserDefaults.standard.bool(forKey: "flutter.device_passcode") == true {
            authenticationVC.authentication()
        }
        // Remove splash screen when entering foreground
        removeSplashScreen()
    }
    
    override func applicationDidEnterBackground(_ application: UIApplication) {
        if UserDefaults.standard.bool(forKey: "flutter.device_passcode") == true {
            showAuthenticationOverlay()
        }
        // Show splash screen when entering background
        if SecureChannelHandler.shared.shouldShowSplash {
            showSplashScreen()
        }
    }

//     DONT REMOVE, We will bring back the security check
//     func showAlertAndExit() {
//             let alert = UIAlertController(title: "Jailbreak Detected",
//                                           message: "This app cannot run on jailbroken devices.",
//                                           preferredStyle: .alert)
//             alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
//                 // Dismiss the alert and exit the app
//                 self.exitApp()
//             }))
//
//             // Get the root view controller to present the alert
//             if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
//                 rootViewController.present(alert, animated: true, completion: nil)
//
//             }
//
//         }


    private func showSplashScreen() {
        if splashScreenVC == nil {
            splashScreenVC = SplashViewController()
            splashScreenVC?.modalPresentationStyle = .overFullScreen
            window?.rootViewController?.present(splashScreenVC!, animated: false, completion: nil)
        }
    }

    private func removeSplashScreen() {
        if let splashVC = splashScreenVC {
            splashVC.dismiss(animated: false, completion: {
                self.splashScreenVC = nil
            })
        }
    }
    
    func authenticationCompleted(success: Bool) {
        if success {
            hideAuthenticationOverlay()
        }
    }

//        DONT REMOVE, We will bring back the security check
//        Exit app, if security check failed
//        TODO: we are now suspending the app instead of exiting, need to find a way to exit the app
//     private func exitApp() {
//         UIControl().sendAction(#selector(NSXPCConnection.suspend), to: UIApplication.shared, for: nil)
//     }
}

extension AppDelegate {
    func showAuthenticationOverlay() {
        authenticationVC.view.frame = window?.bounds ?? CGRect.zero
        authenticationVC.view.alpha = 1
        window?.addSubview(authenticationVC.view)
        window?.bringSubviewToFront(authenticationVC.view)
    }
    
    func hideAuthenticationOverlay() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.authenticationVC.view.alpha = 0
        } completion: { [weak self] _ in
            self?.authenticationVC.view.removeFromSuperview()
        }
    }

    func checkDebugger() -> Bool {
        return checkExceptionPorts() || checkSignalHandlers() || checkExecutionStates()
    }

    private static let EXC_MASK_ALL = (
        EXC_MASK_BAD_ACCESS | EXC_MASK_BAD_INSTRUCTION | EXC_MASK_ARITHMETIC |
            EXC_MASK_EMULATION | EXC_MASK_SOFTWARE | EXC_MASK_BREAKPOINT |
            EXC_MASK_SYSCALL | EXC_MASK_MACH_SYSCALL | EXC_MASK_RPC_ALERT |
            EXC_MASK_CRASH | EXC_MASK_RESOURCE | EXC_MASK_GUARD |
            EXC_MASK_CORPSE_NOTIFY
    )

    func checkExceptionPorts() -> Bool {
        let typesCnt = Int(EXC_TYPES_COUNT)

        let masks = exception_mask_array_t.allocate(capacity: typesCnt)
        masks.initialize(repeating: exception_mask_t(), count: typesCnt)

        let oldHandlers = exception_handler_array_t.allocate(capacity: typesCnt)
        oldHandlers.initialize(repeating: exception_handler_t(), count: typesCnt)
        let oldBehaviors = exception_behavior_array_t.allocate(capacity: typesCnt)
        oldBehaviors.initialize(repeating: exception_behavior_t(), count: typesCnt)
        let oldFlavors = exception_flavor_array_t.allocate(capacity: typesCnt)
        oldFlavors.initialize(repeating: thread_state_flavor_t(), count: typesCnt)

        defer {
            masks.deallocate()
            oldHandlers.deallocate()
            oldBehaviors.deallocate()
            oldFlavors.deallocate()
        }

        var masksCnt: mach_msg_type_number_t = 0
        let kr = task_get_exception_ports(mach_task_self_, exception_mask_t(Self.EXC_MASK_ALL), masks, &masksCnt, oldHandlers, oldBehaviors, oldFlavors)
        guard kr == KERN_SUCCESS else {
            return false
        }

        let taskExceptionHandlers = UnsafeMutableBufferPointer(start: oldHandlers, count: typesCnt)

        guard taskExceptionHandlers.first(where: { $0 != 0 }) == nil
        else {
            return false
        }

        return true
    }

    private static let availableSignals = [
        SIGHUP, SIGINT, SIGQUIT, SIGILL,
        SIGTRAP, SIGABRT, SIGEMT, SIGFPE,
        SIGKILL, SIGBUS, SIGSEGV, SIGSYS,
        SIGPIPE, SIGALRM, SIGTERM, SIGURG,
        SIGSTOP, SIGTSTP, SIGCONT, SIGCHLD,
        SIGTTIN, SIGTTOU, SIGIO, SIGXCPU,
        SIGXFSZ, SIGVTALRM, SIGPROF, SIGWINCH,
        SIGINFO, SIGUSR1, SIGUSR2,
    ]

    func checkSignalHandlers() -> Bool {
        for signal in Self.availableSignals {
            var oldact = sigaction()
            sigaction(signal, nil, &oldact)
            if oldact.__sigaction_u.__sa_sigaction != nil {
                return false
            }
        }

        return true
    }

    func checkExecutionStates() -> Bool {
        let typesCnt = Int(EXC_TYPES_COUNT)

        let masks = exception_mask_array_t.allocate(capacity: typesCnt)
        masks.initialize(repeating: exception_mask_t(), count: typesCnt)

        let oldHandlers = exception_handler_array_t.allocate(capacity: typesCnt)
        oldHandlers.initialize(repeating: exception_handler_t(), count: typesCnt)
        let oldBehaviors = exception_behavior_array_t.allocate(capacity: typesCnt)
        oldBehaviors.initialize(repeating: exception_behavior_t(), count: typesCnt)
        let oldFlavors = exception_flavor_array_t.allocate(capacity: typesCnt)
        oldFlavors.initialize(repeating: thread_state_flavor_t(), count: typesCnt)

        defer {
            masks.deallocate()
            oldHandlers.deallocate()
            oldBehaviors.deallocate()
            oldFlavors.deallocate()
        }

        var masksCnt: mach_msg_type_number_t = 0
        let kr = task_get_exception_ports(mach_task_self_, exception_mask_t(Self.EXC_MASK_ALL), masks, &masksCnt, oldHandlers, oldBehaviors, oldFlavors)
        guard kr == KERN_SUCCESS else {
            return false
        }

        let taskThreadFlavors = UnsafeMutableBufferPointer(start: oldFlavors, count: typesCnt)

        guard taskThreadFlavors.first(where: { $0 == THREAD_STATE_NONE }) == nil
        else {
            return false
        }

        return true
    }

    // Bundle ID Check
    func checkMainBundleIdentifier() -> Bool {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            return false
        }
        return Constant.secureMainBundleIdentifiers.contains(bundleID)
    }

}
