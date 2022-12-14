//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../util/style.dart';

class SelectLedgerPage extends StatefulWidget {
  const SelectLedgerPage({Key? key}) : super(key: key);

  @override
  State<SelectLedgerPage> createState() => _SelectLedgerPageState();
}

class _SelectLedgerPageState extends State<SelectLedgerPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: ResponsiveLayout.pageEdgeInsetsNotBottom,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "select_wallet".tr(),
                style: theme.textTheme.headline1,
              ),
              addTitleSpace(),
              _linkLedger("Tezos"),
              addOnlyDivider(),
              _linkLedger("Ethereum"),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  Widget _linkLedger(String blockchain) {
    final theme = Theme.of(context);
    return Column(
      children: [
        TappableForwardRow(
            leftWidget: Row(
              children: [
                SvgPicture.asset("assets/images/iconLedger.svg"),
                const SizedBox(width: 16),
                Text(blockchain, style: theme.textTheme.headline4),
              ],
            ),
            onTap: () => Navigator.of(context).pushNamed(
                AppRouter.linkLedgerWalletPage,
                arguments: blockchain)),
      ],
    );
  }
}
