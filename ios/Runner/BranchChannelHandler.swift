//
//  BranchChannelHandler.swift
//  Runner
//
//  Created by Ho Hien on 12/09/2022.
//

import Foundation
import Branch

class BranchChannelHandler: NSObject {

    static let shared = BranchChannelHandler()
    private var branchInstance = Branch.getInstance()

}

extension BranchChannelHandler: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        branchInstance.initSession { (params, error) in
            events([
                "eventName": "observeDeeplinkParams",
                "params": params as Any
            ])
       }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
}
