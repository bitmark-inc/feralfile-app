//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/global_receive/receive_detail_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:autonomy_theme/autonomy_theme.dart';

Widget accountWithConnectionItem(
    BuildContext context, CategorizedAccounts categorizedAccounts) {
  final theme = Theme.of(context);

  switch (categorizedAccounts.className) {
    case 'Persona':
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 24,
              height: 24,
              child: Image.asset("assets/images/autonomyIcon.png")),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(categorizedAccounts.category,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headline4),
                const SizedBox(height: 8),
                ...categorizedAccounts.accounts
                    .map((a) => Container(
                        child: _blockchainAddressView(context, a,
                            onTap: () => Navigator.of(context).pushNamed(
                                GlobalReceiveDetailPage.tag,
                                arguments: a))))
                    .toList(),
              ],
            ),
          ),
        ],
      );
    case 'Connection':
      final connection = categorizedAccounts.accounts.first.connections?.first;
      if (connection == null) return const SizedBox();

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              alignment: Alignment.topCenter, child: _appLogo(connection)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          connection.name.isNotEmpty
                              ? connection.name
                              : "unnamed".tr(),
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headline4),
                      _linkedBox(context),
                    ]),
                const SizedBox(height: 8),
                ...categorizedAccounts.accounts
                    .map((a) => Container(
                        child: _blockchainAddressView(context, a,
                            onTap: () => Navigator.of(context).pushNamed(
                                GlobalReceiveDetailPage.tag,
                                arguments: a))))
                    .toList(),
              ],
            ),
          ),
        ],
      );

    default:
      return const SizedBox();
  }
}

Widget accountItem(BuildContext context, Account account,
    {Function()? onPersonaTap, Function()? onConnectionTap}) {
  final theme = Theme.of(context);
  final persona = account.persona;
  if (persona != null) {
    final isHideGalleryEnabled =
        injector<AccountService>().isPersonaHiddenInGallery(persona.uuid);
    return TappableForwardRow(
      leftWidget: Row(
        children: [
          accountLogo(account),
          const SizedBox(width: 16),
          Text(
            account.name.isNotEmpty
                ? account.name.maskIfNeeded()
                : account.accountNumber.mask(4),
            style: theme.textTheme.headline4,
          ),
        ],
      ),
      rightWidget: Visibility(
        visible: isHideGalleryEnabled,
        child: Icon(
          Icons.visibility_off_outlined,
          color: theme.colorScheme.surface,
        ),
      ),
      onTap: onPersonaTap,
    );
  }

  final connection = account.connections?.first;

  if (connection != null) {
    final isHideGalleryEnabled = injector<AccountService>()
        .isLinkedAccountHiddenInGallery(connection.hiddenGalleryKey);
    return TappableForwardRow(
      leftWidget: Row(
        children: [
          accountLogo(account),
          const SizedBox(width: 16),
          Text(
            connection.name.isNotEmpty
                ? connection.name.maskIfNeeded()
                : connection.accountNumber.mask(4),
            style: theme.textTheme.headline4,
          ),
        ],
      ),
      rightWidget: Row(
        children: [
          Visibility(
            visible: isHideGalleryEnabled,
            child: Icon(
              Icons.visibility_off_outlined,
              color: theme.colorScheme.surface,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          _linkedBox(context),
        ],
      ),
      onTap: onConnectionTap,
    );
  }

  return const SizedBox();
}

Widget _blockchainAddressView(
  BuildContext context,
  Account account, {
  Function()? onTap,
}) {
  final theme = Theme.of(context);
  return TappableForwardRow(
    padding: const EdgeInsets.symmetric(vertical: 7),
    leftWidget: Row(
      children: [
        _blockchainLogo(account.blockchain),
        const SizedBox(width: 8),
        Text(
          _blockchainName(account.blockchain),
          style: theme.textTheme.headline5,
        ),
        const SizedBox(width: 8),
        Text(
          account.accountNumber.mask(4),
          style: ResponsiveLayout.isMobile
              ? theme.textTheme.ibmBlackNormal14
              : theme.textTheme.ibmBlackNormal16,
        ),
      ],
    ),
    onTap: onTap,
  );
}

Widget _blockchainLogo(String? blockchain) {
  switch (blockchain) {
    case "Bitmark":
      return SvgPicture.asset('assets/images/iconBitmark.svg');
    case "Ethereum":
    case "walletConnect":
    case "walletBrowserConnect":
      return SvgPicture.asset('assets/images/iconEth.svg');
    case "Tezos":
    case "walletBeacon":
      return SvgPicture.asset('assets/images/iconXtz.svg');
    default:
      return const SizedBox();
  }
}

String _blockchainName(String? blockchain) {
  switch (blockchain) {
    case "Bitmark":
      return "bitmark".tr();
    case "Ethereum":
    case "walletConnect":
      return "ethereum".tr();
    case "Tezos":
    case "walletBeacon":
      return "tezos".tr();
    default:
      return "";
  }
}

Widget accountLogo(Account account) {
  if (account.persona != null) {
    return SizedBox(
        width: 24,
        height: 24,
        child: Image.asset("assets/images/autonomyIcon.png"));
  }

  final connection = account.connections?.first;
  if (connection != null) {
    return _appLogo(connection);
  }

  return const SizedBox(
    width: 24,
  );
}

Widget _appLogo(Connection connection) {
  switch (connection.connectionType) {
    case 'feralFileToken':
    case 'feralFileWeb3':
      return SvgPicture.asset("assets/images/feralfileAppIcon.svg");

    case 'ledger':
      return SvgPicture.asset("assets/images/iconLedger.svg");

    case 'walletConnect':
      final walletName =
          connection.wcConnectedSession?.sessionStore.remotePeerMeta.name;

      switch (walletName) {
        case "MetaMask":
          return Image.asset("assets/images/metamask-alternative.png");
        case "Trust Wallet":
          return Image.asset("assets/images/trust-alternative.png");
        default:
          return Image.asset("assets/images/walletconnect-alternative.png");
      }

    case 'walletBeacon':
      final walletName = connection.walletBeaconConnection?.peer.name;
      switch (walletName) {
        case "Kukai Wallet":
          return Image.asset("assets/images/kukai_wallet.png");
        case "Temple - Tezos Wallet":
        case "Temple - Tezos Wallet (ex. Thanos)":
          return Image.asset("assets/images/temple_wallet.png");
        default:
          return Image.asset("assets/images/tezos_wallet.png");
      }

    case 'walletBrowserConnect':
      final walletName = connection.data;
      switch (walletName) {
        case "MetaMask":
          return Image.asset("assets/images/metamask-alternative.png");
        default:
          return const SizedBox(
            width: 24,
          );
      }

    default:
      return const SizedBox(
        width: 24,
      );
  }
}

Widget _linkedBox(BuildContext context) {
  final theme = Theme.of(context);
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
    decoration: BoxDecoration(
        border: Border.all(
      color: theme.colorScheme.surface,
    )),
    child: Text(
      "linked".tr(),
      style: ResponsiveLayout.isMobile
          ? theme.textTheme.ibmGreyNormal12
          : theme.textTheme.ibmGreyNormal14,
    ),
  );
}
