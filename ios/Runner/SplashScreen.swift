//
//  SplashScreen.swift
//  Runner
//
//  Created by Nguyen Phuoc Sang on 25/03/2024.
//

import Foundation

class SplashViewController: UIViewController {
    
    lazy var logoImageView: UIImageView = {
        let img: UIImage?
        let imgView: UIImageView
    #if prod
        img = UIImage(named: "LaunchImage")
        imgView = UIImageView(image: img)
        imgView.frame.size = CGSize(width: 143, height: 143)
    #else
        img = UIImage(named: "InhouseLaunchImage")
        imgView = UIImageView(image: img)
         imgView.frame.size = CGSize(width: 143, height: 143)
    #endif
        return imgView
    }()
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = .white
        view.addSubview(logoImageView)
    }
    
    override func viewDidLayoutSubviews() {
        logoImageView.center = CGPoint(x: view.frame.size.width  / 2,
                                       y: view.frame.size.height / 2)
        
    }
}
