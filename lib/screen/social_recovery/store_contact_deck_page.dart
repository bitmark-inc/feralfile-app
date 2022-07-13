//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/social_recovery/shard_deck.dart';
import 'package:autonomy_flutter/service/social_recovery/social_recovery_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

class StoreContactDeckPage extends StatefulWidget {
  const StoreContactDeckPage({Key? key}) : super(key: key);

  @override
  State<StoreContactDeckPage> createState() => _StoreContactDeckPageState();
}

class _StoreContactDeckPageState extends State<StoreContactDeckPage> {
  TextEditingController _nameTextController = TextEditingController();
  TextEditingController _deckTextController = TextEditingController();
  bool _isError = false;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Add Helping Contact",
                        style: appTextTheme.headline1,
                      ),
                      addTitleSpace(),
                      AuTextField(
                        title: "",
                        placeholder: "Enter owner name",
                        controller: _nameTextController,
                        keyboardType: TextInputType.name,
                        onChanged: (_) => _refreshSubmissionEnaled(),
                      ),
                      SizedBox(height: 15),
                      Container(
                        height: 120,
                        child: Column(
                          children: [
                            AuTextField(
                              title: "",
                              placeholder: "Enter contact deck",
                              keyboardType: TextInputType.multiline,
                              expanded: true,
                              maxLines: null,
                              hintMaxLines: 2,
                              controller: _deckTextController,
                              isError: _isError,
                              onChanged: (_) => _refreshSubmissionEnaled(),
                            ),
                          ],
                        ),
                      ),
                    ]),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    enabled: _isSubmissionEnabled,
                    text: "ADD".toUpperCase(),
                    onPress: () => storeContactDeck(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _refreshSubmissionEnaled() {
    setState(() {
      _isSubmissionEnabled = _deckTextController.text.isNotEmpty &&
          _nameTextController.text.isNotEmpty;
    });
  }

  void storeContactDeck() async {
    late ShardDeck shardDeck;
    try {
      shardDeck = ShardDeck.fromJson(jsonDecode(_deckTextController.text));
    } catch (_) {
      setState(() {
        _isError = true;
      });
    }

    final contactDeck = ContactDeck(
      uuid: Uuid().v4(),
      name: _nameTextController.text,
      deck: shardDeck,
      createdAt: DateTime.now(),
    );

    await injector<SocialRecoveryService>().storeContactDeck(contactDeck);

    Navigator.of(context).pop();
  }
}
