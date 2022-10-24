//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/tzkt_operation.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher_string.dart';

const _nanoTEZFactor = 1000000;

class TezosTXDetailPage extends StatelessWidget {
  final String currentAddress;
  final TZKTTransactionInterface tx;
  final bool isBackHome;

  const TezosTXDetailPage({
    Key? key,
    required this.currentAddress,
    required this.tx,
    this.isBackHome = false,
  }) : super(key: key);

  factory TezosTXDetailPage.fromPayload({
    Key? key,
    required Map<String, dynamic> payload,
  }) =>
      TezosTXDetailPage(
          currentAddress: payload["current_address"], tx: payload["tx"], isBackHome: payload["isBackHome"],);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final DateFormat formatter = dateFormatterYMDHM;
    double safeAreaBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: getBackAppBar(context, onBack: () => isBackHome
          ? Navigator.of(context).pushNamed(AppRouter.homePage)
          : Navigator.of(context).pop()),
      body: Container(
        margin: EdgeInsets.only(
            top: 16.0, left: 16.0, right: 16.0, bottom: safeAreaBottom + 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tx.transactionTitleDetail(currentAddress),
                style: theme.textTheme.headline1),
            const SizedBox(height: 27),
            if (tx.isSendNFT(currentAddress) ||
                tx.isReceiveNFT(currentAddress)) ...[
              listViewNFT(context, tx, formatter)
            ] else ...[
              listViewNonNFT(context, tx, formatter)
            ],
            if (tx is TZKTOperation) ...[
              AuFilledButton(
                text: "share".tr(),
                onPress: () => Share.share(_txURL(tx as TZKTOperation)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget listViewNFT(
      BuildContext context, TZKTTransactionInterface tx, DateFormat formatter) {
    TZKTTokenTransfer? tx_;
    bool hasFee = true;
    String amount = "";
    if (tx is TZKTTokenTransfer) {
      hasFee = false;
      tx_ = tx;
    } else {
      tx_ = (tx as TZKTOperation).tokenTransfer;
      amount = _totalAmount(tx, currentAddress);
    }
    return Expanded(
      child: ListView(
        children: [
          tx_!.isSendNFT(currentAddress)
              ? _transactionInfo(context, "to".tr(), tx_.to?.address)
              : _transactionInfo(context, "from".tr(), tx_.from?.address),
          _transactionInfo(context, "contract".tr(),
              tx_.token?.contract?.alias ?? tx_.token?.contract?.address),
          _transactionInfo(context, "status".tr(), tx_.transactionStatus()),
          _transactionInfo(context, "date".tr(),
              formatter.format(tx_.getTimeStamp()).toUpperCase()),
          _transactionInfo(context, "token_id".tr(), tx_.token?.tokenId),
          _transactionInfo(context, "token_amount".tr(), tx_.amount),
          if (hasFee) ...[
            _transactionInfo(context, "gas_fee2".tr(), amount),
          ],
          if (tx is TZKTOperation) ...[
            _viewOnTZKT(context, tx),
          ],
        ],
      ),
    );
  }

  Widget listViewNonNFT(
      BuildContext context, TZKTTransactionInterface tx, DateFormat formatter) {
    TZKTOperation? tx_;
    if (tx is TZKTOperation) {
      tx_ = tx;
    } else {
      return const Text("");
    }
    return Expanded(
      child: ListView(
        children: [
          if (tx_.parameter != null) ...[
            _transactionInfo(context, "call".tr(), tx_.parameter?.entrypoint),
            _transactionInfo(context, "contract".tr(),
                tx_.target?.alias ?? tx_.target?.address)
          ] else if (tx_.type == "transaction") ...[
            tx_.sender?.address == currentAddress
                ? _transactionInfo(context, "to".tr(), tx_.target?.address)
                : _transactionInfo(context, "from".tr(), tx_.sender?.address),
          ],
          _transactionInfo(context, "status".tr(), tx.transactionStatus()),
          _transactionInfo(context, "date".tr(),
              formatter.format(tx.getTimeStamp()).toUpperCase()),
          if (tx_.type == "transaction")
            _transactionInfo(context, "amount".tr(), _transactionAmount(tx_)),
          if (tx_.sender?.address == currentAddress) ...[
            _transactionInfo(context, "gas_fee2".tr(), _gasFee(tx_)),
            _transactionInfo(context, "total_amount".tr(),
                _totalAmount(tx_, currentAddress)),
          ],
          _viewOnTZKT(context, tx_),
        ],
      ),
    );
  }

  Widget _transactionInfo(BuildContext context, String title, String? detail) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 16,
            runSpacing: 16,
            runAlignment: WrapAlignment.center,
            children: [
              Text(title, style: theme.textTheme.headline4),
              if (detail != null)
                Text(
                  detail,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.subtitle1
                      ?.copyWith(color: AppColor.secondaryDimGrey),
                ),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }

  String _txURL(TZKTOperation tx) {
    return "https://tzkt.io/${tx.hash}";
  }

  Widget _viewOnTZKT(BuildContext context, TZKTOperation tx) {
    final theme = Theme.of(context);
    final customLinkStyle = theme.textTheme.linkStyle.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14.0,
                  color: theme.colorScheme.primary,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: "powered_by_tzkt".tr(),
                    style: customLinkStyle,
                  ),
                ],
              ),
            ),
            SvgPicture.asset("assets/images/external_link.svg"),
          ],
        ),
      ),
      onTap: () => launchUrlString(_txURL(tx)),
    );
  }

  String _transactionAmount(TZKTOperation tx) {
    return "${(tx.amount ?? 0) / _nanoTEZFactor} XTZ";
  }

  String _gasFee(TZKTOperation tx) {
    return "${(tx.bakerFee + (tx.storageFee ?? 0) + (tx.allocationFee ?? 0)) / _nanoTEZFactor} XTZ";
  }

  String _totalAmount(TZKTOperation tx, String? currentAddress) {
    return "${tx.totalAmount(currentAddress)} (${((tx.quote.usd * (tx.getTotalAmount(currentAddress)) / _nanoTEZFactor)).toStringAsPrecision(2)} USD)";
  }
}
