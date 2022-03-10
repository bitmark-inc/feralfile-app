import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libauk_dart/libauk_dart.dart';

import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/screen/settings/crypto/receive_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_state.dart';
import 'package:autonomy_flutter/view/au_outlined_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';

class WalletDetailPage extends StatelessWidget {
  final WalletDetailsPayload payload;

  const WalletDetailPage({Key? key, required this.payload}) : super(key: key);

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
      body: BlocBuilder<WalletDetailBloc, WalletDetailState>(
          builder: (context, state) {
        return Container(
          margin: EdgeInsets.only(
              top: 16.0,
              left: 16.0,
              right: 16.0,
              bottom: MediaQuery.of(context).padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Expanded(child: SizedBox()),
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

enum CryptoType {
  ETH,
  XTZ,
  BITMARK,
}
