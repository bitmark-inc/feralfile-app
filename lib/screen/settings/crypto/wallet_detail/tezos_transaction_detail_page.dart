//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/tzkt_operation.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
        currentAddress: payload["current_address"],
        tx: payload["tx"],
        isBackHome: payload["isBackHome"] ?? false,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final DateFormat formatter = dateFormatterYMDHM;
    final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
    return Scaffold(
      appBar: getBackAppBar(context,
          title: dateFormatterYMD.format(tx.getTimeStamp()).toUpperCase(),
          onBack: () => isBackHome
              ? Navigator.of(context).pushNamed(AppRouter.homePage)
              : Navigator.of(context).pop()),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          addTitleSpace(),
          Padding(
            padding: padding,
            child: Text(tx.transactionTitleDetail(currentAddress),
                style: theme.textTheme.ppMori400Black16),
          ),
          const SizedBox(height: 48),
          addOnlyDivider(),
          if (tx.isSendNFT(currentAddress) ||
              tx.isReceiveNFT(currentAddress)) ...[
            listViewNFT(context, tx, formatter)
          ] else ...[
            listViewNonNFT(context, tx, formatter)
          ],
          if (tx is TZKTOperation) ...[
            GestureDetector(
              onTap: () => launchUrlString(_txURL(tx as TZKTOperation)),
              child: Container(
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.fromLTRB(0, 17, 0, 20),
                color: AppColor.secondaryDimGreyBackground,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("powered_by_tzkt".tr(),
                        style: theme.textTheme.ppMori400Black14),
                    const SizedBox(
                      width: 8,
                    ),
                    SvgPicture.asset("assets/images/external_link.svg"),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget listViewNFT(
      BuildContext context, TZKTTransactionInterface tx, DateFormat formatter) {
    TZKTTokenTransfer? tx_;
    TZKTOperation? txO;
    bool hasFee = true;
    if (tx is TZKTTokenTransfer) {
      hasFee = false;
      tx_ = tx;
    } else {
      txO = tx as TZKTOperation;
      tx_ = tx.tokenTransfer;
    }

    return Expanded(
      child: ListView(
        children: [
          tx_!.isSendNFT(currentAddress)
              ? _transactionInfo(context, "to".tr(), tx_.to?.address)
              : _transactionInfo(context, "from".tr(), tx_.from?.address),
          addOnlyDivider(),
          _transactionInfo(context, "contract".tr(),
              tx_.token?.contract?.alias ?? tx_.token?.contract?.address),
          addOnlyDivider(),
          _transactionInfo(context, "status".tr(), tx_.transactionStatus()),
          addOnlyDivider(),
          _transactionInfo(context, "date".tr(),
              formatter.format(tx_.getTimeStamp()).toUpperCase()),
          addOnlyDivider(),
          _transactionInfo(context, "token_id".tr(), tx_.token?.tokenId),
          addOnlyDivider(),
          _transactionInfo(context, "token_amount".tr(), tx_.amount),
          addOnlyDivider(),
          if (hasFee) ...[
            if (tx.isBoughtNFT(currentAddress)) ...[
              _transactionInfo(
                  context, "amount".tr(), _transactionAmount(txO!)),
              addOnlyDivider(),
            ],
            _transactionInfo(context, "gas_fee2".tr(), _gasFee(txO!)),
            if (tx.isBoughtNFT(currentAddress)) ...[
              addOnlyDivider(),
              _transactionInfoCustom(context, "total_amount".tr(),
                  _totalAmountWidget(context, txO, currentAddress)),
            ]
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
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (tx_.parameter != null) ...[
            _transactionInfo(context, "call".tr(), tx_.parameter?.entrypoint),
            addOnlyDivider(),
            _transactionInfo(context, "contract".tr(),
                tx_.target?.alias ?? tx_.target?.address)
          ] else if (tx_.type == "transaction") ...[
            tx_.sender?.address == currentAddress
                ? _transactionInfo(context, "to".tr(), tx_.target?.address)
                : _transactionInfo(context, "from".tr(), tx_.sender?.address),
          ],
          addOnlyDivider(),
          _transactionInfo(context, "status".tr(), tx.transactionStatus()),
          addOnlyDivider(),
          _transactionInfo(context, "date".tr(),
              formatter.format(tx.getTimeStamp()).toUpperCase()),
          addOnlyDivider(),
          if (tx_.type == "transaction")
            _transactionInfo(context, "amount".tr(), _transactionAmount(tx_)),
          addOnlyDivider(),
          if (tx_.sender?.address == currentAddress) ...[
            _transactionInfo(context, "gas_fee2".tr(), _gasFee(tx_)),
            addOnlyDivider(),
            _transactionInfoCustom(context, "total_amount".tr(),
                _totalAmountWidget(context, tx_, currentAddress)),
            addOnlyDivider(),
          ],
        ],
      ),
    );
  }

  Widget _transactionInfo(BuildContext context, String title, String? detail) {
    final theme = Theme.of(context);
    final padding = ResponsiveLayout.pageEdgeInsets;

    return Padding(
      padding: padding.copyWith(top: 16, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Text(title, style: theme.textTheme.ppMori400Grey14),
          ),
          if (detail != null)
            Flexible(
              child: Text(
                detail,
                textAlign: TextAlign.right,
                style: theme.textTheme.ppMori400Black14,
                maxLines: 5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _transactionInfoCustom(
      BuildContext context, String title, Widget? rightWidget) {
    final theme = Theme.of(context);
    final padding = ResponsiveLayout.pageEdgeInsets;

    return Padding(
      padding: padding.copyWith(top: 16, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Text(title, style: theme.textTheme.ppMori400Grey14),
          ),
          if (rightWidget != null)
            Flexible(
              child: rightWidget,
            ),
        ],
      ),
    );
  }

  String _txURL(TZKTOperation tx) {
    return "https://tzkt.io/${tx.hash}";
  }

  String _transactionAmount(TZKTOperation tx) {
    return "${(tx.amount ?? 0) / _nanoTEZFactor} XTZ";
  }

  String _gasFee(TZKTOperation tx) {
    return "${(tx.bakerFee + (tx.storageFee ?? 0) + (tx.allocationFee ?? 0)) / _nanoTEZFactor} XTZ";
  }

  Widget _totalAmountWidget(
      BuildContext context, TZKTOperation tx, String? currentAddress) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          tx.totalXTZAmount(currentAddress),
          textAlign: TextAlign.right,
          style: theme.textTheme.ppMori400Black14,
        ),
        Text(
          '${((tx.quote.usd * (tx.getTotalAmount(currentAddress)) / _nanoTEZFactor)).toStringAsPrecision(2)} USD',
          textAlign: TextAlign.right,
          style: theme.textTheme.ppMori400Grey14,
        )
      ],
    );
  }
}
