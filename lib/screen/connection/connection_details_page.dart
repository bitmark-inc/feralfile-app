//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/bloc/connections/connections_bloc.dart';
import 'package:autonomy_flutter/util/style.dart';

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
    final theme = Theme.of(context);

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
                      style: theme.textTheme.headline1,
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
                                  style: theme.textTheme.headline4),
                              Text(
                                "You have granted permission to:",
                                style: theme.textTheme.bodyText1,
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
                                        style: theme.textTheme.bodyText1),
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
                    style: theme.textTheme.button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConnectionConfiguration(BuildContext context) {
    final theme = Theme.of(context);
    final connection = connectionItem.representative;

    showModalBottomSheet(
        context: context,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            color: Colors.transparent,
            child: ClipPath(
              clipper: AutonomyTopRightRectangleClipper(),
              child: Container(
                color: theme.colorScheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Revoke all rights',
                        style: theme.primaryTextTheme.headline1),
                    const SizedBox(height: 40),
                    RichText(
                      text: TextSpan(
                        style: theme.primaryTextTheme.bodyText1,
                        children: <TextSpan>[
                          const TextSpan(
                            text: 'Are you sure you want to revoke ',
                          ),
                          const TextSpan(
                              text: 'Autonomy',
                              style: TextStyle(fontWeight: FontWeight.bold)),
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
                              context
                                  .read<ConnectionsBloc>()
                                  .add(DeleteConnectionsEvent(connectionItem));
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                            },
                            color: theme.colorScheme.secondary,
                            textStyle: theme.textTheme.button,
                          ),
                        ),
                      ],
                    ),
                    Align(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          "CANCEL",
                          style: theme.primaryTextTheme.button,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }
}
