//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

//
//  CloudKitManager.swift
//  Runner
//
//  Created by Thuyên Trương on 01/03/2022.
//

import CloudKit
import Combine

protocol CloudKitManagerProtocol {
    func observeAccountStatus() -> AnyPublisher<CKAccountStatus?, Never>
}

class CloudKitManager: CloudKitManagerProtocol {

    // MARK: - Properties
    fileprivate let container = CKContainer.default()
    fileprivate let accountStatusSubject = CurrentValueSubject<CKAccountStatus?, Never>(nil)

    // MARK: - Initialization
    init() {
        // Request Account Status
        requestAccountStatus()

        // Setup Notification Handling
        setupNotificationHandling()
    }

}

extension CloudKitManager {

    func observeAccountStatus() -> AnyPublisher<CKAccountStatus?, Never> {
        accountStatusSubject.eraseToAnyPublisher()
    }
}

// MARK: - Helper Methods
fileprivate extension CloudKitManager {
    func requestAccountStatus() {
        container.accountStatus { [unowned self] (accountStatus, error) in
            if let error = error {
                print("[Critical][CloudKitManager] Error: \(error)")
            }

            DispatchQueue.main.async { [weak self] in
                self?.accountStatusSubject.send(accountStatus)
            }
        }
    }

    func setupNotificationHandling() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(accountDidChange(_:)), name: Notification.Name.CKAccountChanged, object: nil)
    }

    @objc private func accountDidChange(_ notification: Notification) {
        // Request Account Status
        DispatchQueue.main.async { self.requestAccountStatus() }
    }
}
