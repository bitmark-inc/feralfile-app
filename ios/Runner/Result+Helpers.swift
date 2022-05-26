//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import Foundation

extension Result {
    func isSuccess(ifFailure completion: @escaping (Error) -> ()) -> Bool {
        switch self {
        case .success:
            return true

        case let .failure(error):
            completion(error)
            return false
        }
    }

    func get(ifFailure completion: @escaping (Error) -> ()) -> Success? {
        switch self {
        case let .success(value):
            return value

        case let .failure(error):
            completion(error)
            return nil
        }

    }
}
