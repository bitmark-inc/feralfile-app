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
import 'package:autonomy_flutter/screen/settings/connection/accounts_view.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

Widget accountWithConnectionItem(BuildContext context,
    CategorizedAccounts categorizedAccounts) {
  final theme = Theme.of(context);

  switch (categorizedAccounts.className) {
    case 'Persona':
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 24,
              height: 24,
              child: Image.asset("assets/images/moma_logo.png")),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(categorizedAccounts.category,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                ...categorizedAccounts.accounts
                    .map((a) =>
                    Container(
                        child: _blockchainAddressView(context,
                            GlobalReceivePayload(address: a.accountNumber,
                                blockchain: a.blockchain!,
                                account: a),
                            onTap: () =>
                                Navigator.of(context).pushNamed(
                                    GlobalReceiveDetailPage.tag,
                                    arguments: GlobalReceivePayload(address: a
                                        .accountNumber, blockchain: a
                                        .blockchain!, account: a)))))
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
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                            connection.name.isNotEmpty
                                ? connection.name
                                : "unnamed".tr(),
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineMedium),
                      ),
                      linkedBox(context),
                    ]),
                const SizedBox(height: 8),
                ...categorizedAccounts.accounts
                    .map((a) =>
                    Container(
                        child: _blockchainAddressView(context, GlobalReceivePayload(address: a.accountNumber, blockchain: a.blockchain!, account: a),
                            onTap: () =>
                                Navigator.of(context).pushNamed(
                                    GlobalReceiveDetailPage.tag,
                                    arguments: GlobalReceivePayload(address: a.accountNumber, blockchain: a.blockchain!, account: a)))))
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
    final getDidKey = persona.wallet().getAccountDID();
    final isHideGalleryEnabled =
    injector<AccountService>().isPersonaHiddenInGallery(persona.uuid);
    return TappableForwardRow(
      leftWidget: Row(
        children: [
          accountLogo(context, account),
          const SizedBox(width: 32),
          FutureBuilder<String>(
            future: getDidKey,
            builder: (context, snapshot) {
              final name =
              account.name.isNotEmpty ? account.name : snapshot.data ?? '';
              return Expanded(
                child: Text(
                  name.replaceFirst('did:key:', ''),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.ppMori400Black14,
                ),
              );
            },
          ),
        ],
      ),
      rightWidget: Row(
        children: [
          context.widget is AccountsView
              ? Visibility(
            visible: isHideGalleryEnabled,
            child: Icon(
              Icons.visibility_off_outlined,
              color: theme.colorScheme.surface,
            ),
          )
              : const SizedBox(),
          const SizedBox(width: 8),
        ],
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
          accountLogo(context, account),
          const SizedBox(width: 32),
          Expanded(
            child: Text(
              connection.name.isNotEmpty
                  ? connection.name.maskIfNeeded()
                  : connection.accountNumber,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.ppMori400Black14,
            ),
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
          linkedBox(context),
          const SizedBox(width: 8),
        ],
      ),
      onTap: onConnectionTap,
    );
  }

  return const SizedBox();
}

Widget _blockchainAddressView(BuildContext context,
    GlobalReceivePayload receiver, {
      Function()? onTap,
    }) {
  final theme = Theme.of(context);
  return TappableForwardRow(
    padding: const EdgeInsets.symmetric(vertical: 7),
    leftWidget: Row(
      children: [
        _blockchainLogo(receiver.blockchain),
        const SizedBox(width: 8),
        Text(
          _blockchainName(receiver.blockchain),
          style: theme.textTheme.atlasBlackBold12,
        ),
        const SizedBox(width: 8),
        Text(
          receiver.address.mask(4),
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

Widget accountLogo(BuildContext context, Account account, {double size = 29}) {
  if (account.persona != null) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
              padding: const EdgeInsets.fromLTRB(0, 4, 4, 0),
              alignment: Alignment.centerLeft,
              child: Image.asset("assets/images/moma_logo.png")),
        ],
      ),
    );
  }

  final connection = account.connections?.first;
  if (connection != null) {
    return SizedBox(width: 29, height: 29, child: _appLogo(connection));
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

Widget linkedBox(BuildContext context) {
  final theme = Theme.of(context);
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
    decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
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
