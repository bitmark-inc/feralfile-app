//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/bloc/connections/connections_bloc.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConnectionDetailsPage extends StatelessWidget {
  final ConnectionItem connectionItem;
  const ConnectionDetailsPage({Key? key, required this.connectionItem})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final connection = connectionItem.representative;

    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: connectionItem.representative.appName.toUpperCase(),
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: pageEdgeInsetsWithSubmitButton,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Rights",
                      style: appTextTheme.headline1,
                    ),
                    addTitleSpace(),
                    Row(
                      children: [
                        UIHelper.buildConnectionAppWidget(connection, 64),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(connection.appName,
                                  style: appTextTheme.headline4),
                              Text(
                                "You have granted permission to:",
                                style: appTextTheme.bodyText1,
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...grantPermissions
                              .map((permission) => Column(children: [
                                    Text("• $permission",
                                        style: appTextTheme.bodyText1),
                                    const SizedBox(height: 4),
                                  ]))
                              .toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () => _showDeleteConnectionConfiguration(context),
                child: Text('DISCONNECT & REVOKE RIGHTS',
                    style: appTextTheme.button?.copyWith(color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConnectionConfiguration(BuildContext pageContext) {
    final theme = AuThemeManager.get(AppTheme.sheetTheme);
    final connection = connectionItem.representative;

    showModalBottomSheet(
        context: pageContext,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            color: Colors.transparent,
            child: ClipPath(
              clipper: AutonomyTopRightRectangleClipper(),
              child: Container(
                color: theme.backgroundColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Revoke all rights', style: theme.textTheme.headline1),
                    const SizedBox(height: 40),
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyText1,
                        children: <TextSpan>[
                          const TextSpan(
                            text: 'Are you sure you want to revoke ',
                          ),
                          const TextSpan(
                              text: 'Autonomy',
                              style:
                                  TextStyle(fontWeight: FontWeight.bold)),
                          const TextSpan(
                            text: ' from all rights on ',
                          ),
                          TextSpan(
                              text: connection.appName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: AuFilledButton(
                            text: "REVOKE ALL",
                            onPress: () {
                              pageContext
                                  .read<ConnectionsBloc>()
                                  .add(DeleteConnectionsEvent(connectionItem));
                              Navigator.of(context).pop();
                              Navigator.of(pageContext).pop();
                            },
                            color: theme.primaryColor,
                            textStyle: TextStyle(
                                color: theme.backgroundColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                fontFamily: "IBMPlexMono"),
                          ),
                        ),
                      ],
                    ),
                    Align(
                      child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text("CANCEL",
                              style: theme.textTheme.button
                                  ?.copyWith(color: Colors.white))),
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }
}
