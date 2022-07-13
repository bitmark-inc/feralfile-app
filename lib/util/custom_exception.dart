//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/util/constants.dart';

class SystemException implements Exception {
  final String reason;

  SystemException(this.reason);
}

class AlreadyLinkedException implements Exception {
  final Connection connection;
  AlreadyLinkedException(this.connection);
}

class AbortedException implements Exception {}

class RequiredPremiumFeature implements Exception {
  final PremiumFeature feature;

  RequiredPremiumFeature({
    required this.feature,
  });
}

class InvalidDeeplink implements Exception {}

class ExpiredCodeLink implements Exception {}

class FailedFetchBackupVersion implements Exception {}

class SocialRecoveryMissingShard implements Exception {}

class IncorrectFlow implements Exception {}

class RestoreAccountSSKRFailureException implements Exception {}
