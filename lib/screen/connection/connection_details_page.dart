//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/screen/bloc/connections/connections_bloc.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConnectionDetailsPage extends StatelessWidget {
  final ConnectionItem connectionItem;

  const ConnectionDetailsPage({required this.connectionItem, super.key});

  @override
  Widget build(BuildContext context) {
    final connection = connectionItem.representative;
    final theme = Theme.of(context);
    final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: 'connections'.tr(),
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: ResponsiveLayout.pageEdgeInsetsWithSubmitButton
            .copyWith(left: 0, right: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    addTitleSpace(),
                    Padding(
                      padding: padding,
                      child: Row(
                        children: [
                          UIHelper.buildConnectionAppWidget(connection, 64),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(connection.appName,
                                    style: theme.textTheme.displayMedium),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    addDivider(height: 52),
                    Padding(
                      padding: padding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'you_have_permission'.tr(),
                            style: theme.textTheme.ppMori400Black16,
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColor.auLightGrey,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...grantPermissions.map(
                                  (permission) => Row(
                                    children: [
                                      const SizedBox(
                                        width: 12,
                                      ),
                                      Text('•',
                                          style:
                                              theme.textTheme.ppMori400Black14),
                                      const SizedBox(
                                        width: 6,
                                      ),
                                      Text(permission,
                                          style:
                                              theme.textTheme.ppMori400Black14),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: Center(
                child: OutlineButton(
                  color: AppColor.white,
                  textColor: AppColor.primaryBlack,
                  borderColor: AppColor.primaryBlack,
                  text: 'disconnect_and_revoke'.tr(),
                  onTap: () => _showDeleteConnectionConfiguration(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConnectionConfiguration(BuildContext pageContext) {
    final theme = Theme.of(pageContext);
    final connection = connectionItem.representative;

    unawaited(showModalBottomSheet(
      context: pageContext,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
          maxWidth: ResponsiveLayout.isMobile
              ? double.infinity
              : Constants.maxWidthModalTablet),
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Container(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: theme.auGreyBackground,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'revoke_all_rights'.tr(),
                style: theme.primaryTextTheme.ppMori700White24,
              ),
              const SizedBox(height: 40),
              RichText(
                textScaler: MediaQuery.textScalerOf(context),
                text: TextSpan(
                  style: theme.primaryTextTheme.ppMori400White14,
                  children: <TextSpan>[
                    TextSpan(
                      text: '${'sure_revoke'.tr()} ',
                    ),
                    TextSpan(
                        text: 'autonomyL'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                      text: ' ${'from_all_rights_on'.tr()} ',
                    ),
                    TextSpan(
                        text: connection.appName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                      text: '?'.tr(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              PrimaryButton(
                text: 'revoke_all'.tr(),
                onTap: () {
                  pageContext
                      .read<ConnectionsBloc>()
                      .add(DeleteConnectionsEvent(connectionItem));
                  Navigator.of(context).pop();
                  Navigator.of(pageContext).pop();
                },
              ),
              const SizedBox(height: 10),
              OutlineButton(
                onTap: () => Navigator.of(context).pop(),
                text: 'cancel_dialog'.tr(),
              )
            ],
          ),
        ),
      ),
    ));
  }
}
