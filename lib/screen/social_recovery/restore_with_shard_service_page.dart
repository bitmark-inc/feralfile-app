//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/social_recovery/social_recovery_service.dart';
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
  bool _hasPlatformShards = false;
  bool _isSubmissionEnabled = false;

  @override
  void initState() {
    _loadData();
    super.initState();
  }

  void _loadData() async {
    final _hasPlatformShardsResult =
        await injector<SocialRecoveryService>().hasPlatformShards();
    setState(() {
      _hasPlatformShards = _hasPlatformShardsResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
        // margin: pageEdgeInsetsWithSubmitButton,
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Get ShardDeck from Shard Service",
                      style: theme.textTheme.headline1,
                    ),
                    addTitleSpace(),
                    Text(
                      "some description about Shard Service",
                      style: theme.textTheme.bodyText1,
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
                                style: theme.textTheme.caption)),
                      ],
                    )
                  ]),
            ),
          ),
          Column(
            children: [
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
            ],
          ),
          if (_hasPlatformShards) ...[
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pushNamed(AppRouter.restoreWithEmergencyContactPage),
              child: Text(
                "RESTORE WITH EMERGENCY CONTACT",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: "IBMPlexMono"),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
