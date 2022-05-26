//
//  BiometricAuthentication.swift
//  Runner
//
//  Created by Anh Nguyen on 26/05/2022.
//

import UIKit
import LocalAuthentication

class BiometricAuthenticationViewController: UIViewController {
    
    var authenticationCallback: ((Bool) -> Void)?
    lazy var logoImageView: UIImageView = {
        let img = Bundle.main.icon
        let imgView = UIImageView(image: img)
        imgView.frame.size = CGSize(width: 143, height: 143)
        return imgView
    }()
    lazy var authenticationButton: UIButton = {
        let img = biometricTypeImage()!
        let authenticationButton = UIButton(type: .custom)
        authenticationButton.setImage(biometricTypeImage(), for: .normal)
        authenticationButton.frame.size = img.size
        authenticationButton.addTarget(self, action:#selector(self.authenticationButtonClicked), for: .touchUpInside)
        return authenticationButton
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = .white
        view.addSubview(logoImageView)
        view.addSubview(authenticationButton)
    }
    
    override func viewDidLayoutSubviews() {
        logoImageView.center = CGPoint(x: view.frame.size.width  / 2,
                                       y: view.frame.size.height / 2)
        authenticationButton.center = CGPoint(x: view.frame.size.width  / 2,
                                              y: view.frame.size.height - 80)
        
    }
    
    @objc func authenticationButtonClicked() {
        authentication()
    }
}

extension BiometricAuthenticationViewController {
    
    func biometricTypeImage() -> UIImage? {
        let authContext = LAContext()
        let _ = authContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        switch(authContext.biometryType) {
        case .none:
            return UIImage(named: "auth_passcode")
        case .touchID:
            return UIImage(named: "auth_touchid")
        case .faceID:
            return UIImage(named: "auth_faceid")
        default:
            return UIImage(named: "auth_passcode")
        }
    }
    
    func authentication() {
        let authContext = LAContext()
        authContext.localizedFallbackTitle = "Use Passcode"

        var authError: NSError?
        let reasonString = "Access to the Autonomy app."

        if authContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) {
            authContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reasonString) { [weak self] success, evaluateError in
                DispatchQueue.main.async {
                    self?.authenticationCallback?(success)
                }
            }
        } else {
            let alert = UIAlertController(title: "Authentication error", message: "No device authentication method were found. Please enable FaceID, TouchID or Device Passcode to continue", preferredStyle: .alert)
            self.present(alert, animated: true)
        }
    }
}

extension Bundle {
    public var icon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
            let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        return nil
    }
}
