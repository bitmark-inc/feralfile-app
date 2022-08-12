//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/settings/crypto/receive_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/tezos_transaction_list_view.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_state.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/view/au_outlined_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:autonomy_theme/autonomy_theme.dart';

class WalletDetailPage extends StatefulWidget {
  final WalletDetailsPayload payload;

  const WalletDetailPage({Key? key, required this.payload}) : super(key: key);

  @override
  State<WalletDetailPage> createState() => _WalletDetailPageState();
}

class _WalletDetailPageState extends State<WalletDetailPage> {
  @override
  Widget build(BuildContext context) {
    context.read<WalletDetailBloc>().add(
        WalletDetailBalanceEvent(widget.payload.type, widget.payload.wallet));
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: BlocConsumer<WalletDetailBloc, WalletDetailState>(
          listener: (context, state) async {},
          builder: (context, state) {
            return Container(
              margin: EdgeInsets.only(
                  top: 16.0,
                  left: 16.0,
                  right: 16.0,
                  bottom: MediaQuery.of(context).padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16.0),
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          state.balance.isNotEmpty
                              ? state.balance
                              : "-- ${widget.payload.type == CryptoType.ETH ? "ETH" : "XTZ"}",
                          style: theme.textTheme.ibmBlackBold24,
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          state.balanceInUSD.isNotEmpty
                              ? state.balanceInUSD
                              : "-- USD",
                          style: theme.textTheme.subtitle1,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: widget.payload.type == CryptoType.XTZ
                        ? TezosTXListView(address: state.address)
                        : Container(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AuOutlinedButton(
                          text: "Send",
                          onPress: () {
                            Navigator.of(context).pushNamed(SendCryptoPage.tag,
                                arguments: SendData(widget.payload.wallet,
                                    widget.payload.type, null));
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 16.0,
                      ),
                      Expanded(
                        child: AuOutlinedButton(
                          text: "Receive",
                          onPress: () {
                            if (state.address.isNotEmpty) {
                              Navigator.of(context).pushNamed(ReceivePage.tag,
                                  arguments: WalletPayload(
                                      widget.payload.type, state.address));
                            }
                          },
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          }),
    );
  }
}

class WalletDetailsPayload {
  final CryptoType type;
  final WalletStorage wallet;

  WalletDetailsPayload({
    required this.type,
    required this.wallet,
  });
}
