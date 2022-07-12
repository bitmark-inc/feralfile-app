//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class RestoreWithShardServicePage extends StatefulWidget {
  const RestoreWithShardServicePage({Key? key}) : super(key: key);

  @override
  State<RestoreWithShardServicePage> createState() =>
      _RestoreWithShardServicePageState();
}

class _RestoreWithShardServicePageState
    extends State<RestoreWithShardServicePage> {
  TextEditingController _shardServiceTextController = TextEditingController();
  bool _isSubmissionEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
        margin: pageEdgeInsetsWithSubmitButton,
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Get ShardDeck from Shard Service",
                      style: appTextTheme.headline1,
                    ),
                    addTitleSpace(),
                    Text(
                      "some description about Shard Service",
                      style: appTextTheme.bodyText1,
                    ),
                    SizedBox(height: 40),
                    AuTextField(
                        title: "",
                        placeholder: "Enter Shard Service",
                        controller: _shardServiceTextController,
                        onChanged: (value) async {
                          final isValidURL = await canLaunchUrlString(value);

                          setState(() {
                            _isSubmissionEnabled = isValidURL;
                          });
                        }),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: () {
                              _shardServiceTextController.text =
                                  Environment.autonomyShardService;
                              setState(() {
                                _isSubmissionEnabled = true;
                              });
                            },
                            child: Text('Use Autonomy Service?',
                                style: linkStyle)),
                      ],
                    )
                  ]),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: AuFilledButton(
                  enabled: _isSubmissionEnabled,
                  text: "OPEN".toUpperCase(),
                  onPress: () {
                    if (_isSubmissionEnabled)
                      launch(_shardServiceTextController.text,
                          forceSafariVC: false);
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
