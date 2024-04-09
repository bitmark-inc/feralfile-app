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

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    var cancelBag = Set<AnyCancellable>()
    var authenticationVC = BiometricAuthenticationViewController()
    var splashScreenVC: SplashViewController? = SplashViewController()
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if IOSSecuritySuite.amIJailbroken() {
                // If jailbreak is detected, notify the user and terminate the app
                self.showAlertAndExit()
            }
        }
        
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
                self?.showAuthenticationOverlay()
                self?.authenticationVC.authentication()
            }
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        return extensionPointIdentifier != .keyboard
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
    
    func showAlertAndExit() {
            let alert = UIAlertController(title: "Jailbreak Detected",
                                          message: "This app cannot run on jailbroken devices.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                // Dismiss the alert and exit the app
                exit(0)
            }))
            
            // Get the root view controller to present the alert
            if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
                rootViewController.present(alert, animated: true, completion: nil)
                
            }
        
        }
    
    
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
}
