//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/tezos_transaction_list_view.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:autonomy_flutter/screen/settings/crypto/receive_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_state.dart';
import 'package:autonomy_flutter/view/au_outlined_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';

class WalletDetailPage extends StatelessWidget {
  final WalletDetailsPayload payload;

  WalletDetailPage({Key? key, required this.payload}) : super(key: key);

  var addressFuture = Completer<String>();

  @override
  Widget build(BuildContext context) {
    context
        .read<WalletDetailBloc>()
        .add(WalletDetailBalanceEvent(payload.type, payload.wallet));

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: BlocConsumer<WalletDetailBloc, WalletDetailState>(
          listener: (context, state) async {
        addressFuture.complete(state.address);
      }, builder: (context, state) {
        return Container(
          margin: EdgeInsets.only(
              top: 16.0,
              left: 16.0,
              right: 16.0,
              bottom: MediaQuery.of(context).padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 16.0),
              Container(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.balance.isNotEmpty
                          ? state.balance
                          : "-- ${payload.type == CryptoType.ETH ? "ETH" : "XTZ"}",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          fontFamily: "IBMPlexMono"),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      state.balanceInUSD.isNotEmpty
                          ? state.balanceInUSD
                          : "-- USD",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          fontFamily: "IBMPlexMono"),
                    )
                  ],
                ),
              ),
              SizedBox(height: 10),
              Expanded(child: TezosTXListView(address: addressFuture.future)),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AuOutlinedButton(
                      text: "Send",
                      onPress: () {
                        Navigator.of(context).pushNamed(SendCryptoPage.tag,
                            arguments:
                                SendData(payload.wallet, payload.type, null));
                      },
                    ),
                  ),
                  SizedBox(
                    width: 16.0,
                  ),
                  Expanded(
                    child: AuOutlinedButton(
                      text: "Receive",
                      onPress: () {
                        if (state.address.isNotEmpty) {
                          Navigator.of(context).pushNamed(ReceivePage.tag,
                              arguments:
                                  WalletPayload(payload.type, state.address));
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
