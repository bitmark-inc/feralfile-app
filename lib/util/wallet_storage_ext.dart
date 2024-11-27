//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// ignore_for_file: implementation_imports

import 'package:autonomy_flutter/model/wallet_address.dart';
import 'package:web3dart/web3dart.dart';

extension StringExtension on WalletAddress {
  Future<String> getETHEip55Address() async {
    return EthereumAddress.fromHex(address).hexEip55;
  }
}

extension StringHelper on String {
  String getETHEip55Address() => EthereumAddress.fromHex(this).hexEip55;
}
