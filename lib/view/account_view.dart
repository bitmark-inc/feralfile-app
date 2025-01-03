//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/model/wallet_address.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/ether_amount_ext.dart';
import 'package:autonomy_flutter/util/int_ext.dart';
import 'package:autonomy_flutter/view/crypto_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nft_collection/database/dao/dao.dart';

Widget accountItem(
  BuildContext context,
  WalletAddress address, {
  FutureOr<void> Function()? onTap,
}) {
  final theme = Theme.of(context);
  // ignore: discarded_futures
  final balance = getAddressBalance(address.key, address.cryptoType);
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    LogoCrypto(cryptoType: address.cryptoType, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        address.name,
                        style: theme.textTheme.ppMori700Black16,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (address.isHidden) ...[
                const SizedBox(width: 10),
                SvgPicture.asset(
                  'assets/images/hide.svg',
                  colorFilter: ColorFilter.mode(
                    theme.colorScheme.surface,
                    BlendMode.srcIn,
                  ),
                ),
              ],
              const SizedBox(width: 20),
              SvgPicture.asset('assets/images/iconForward.svg'),
            ],
          ),
          const SizedBox(height: 10),
          FutureBuilder<Pair<String, String>?>(
            future: balance,
            builder: (context, snapshot) {
              final balances = snapshot.data ?? Pair('--', '--');
              final style = theme.textTheme.ppMori400Grey14;
              return Row(
                children: [
                  Text(balances.first, style: style),
                  const SizedBox(width: 20),
                  Text(balances.second, style: style),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  address.address,
                  style: theme.textTheme.ppMori400Black14,
                  key: const Key('fullAccount_address'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Future<Pair<String, String>?> getAddressBalance(
  String address,
  CryptoType cryptoType,
) async {
  final tokenDao = injector<TokenDao>();
  final tokens = await tokenDao.findTokenIDsOwnersOwn([address]);
  final nftBalance =
      "${tokens.length} ${tokens.length == 1 ? 'nft'.tr() : 'nfts'.tr()}";
  switch (cryptoType) {
    case CryptoType.ETH:
      final etherAmount = await injector<EthereumService>().getBalance(address);
      return Pair(etherAmount.toEthStringValue, nftBalance);
    case CryptoType.XTZ:
      final tezosAmount = await injector<TezosService>().getBalance(address);
      return Pair(tezosAmount.toXTZStringValue, nftBalance);
    case CryptoType.USDC:
    case CryptoType.UNKNOWN:
      return Pair('', '');
  }
}
