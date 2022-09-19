//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/social_recovery/shard_deck.dart';
import 'package:autonomy_flutter/service/social_recovery/social_recovery_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:autonomy_flutter/main.dart';

class SocialRecoveryHelpingsPage extends StatefulWidget {
  const SocialRecoveryHelpingsPage({Key? key}) : super(key: key);

  @override
  State<SocialRecoveryHelpingsPage> createState() =>
      _SocialRecoveryHelpingsPageState();
}

class _SocialRecoveryHelpingsPageState extends State<SocialRecoveryHelpingsPage>
    with RouteAware, WidgetsBindingObserver {
  List<ContactDeck>? _contactDecks;

  @override
  void initState() {
    fetchContactDecks();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    fetchContactDecks();
    super.didPopNext();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    injector<SocialRecoveryService>().cleanTempSecretFile();
    super.dispose();
  }

  Future fetchContactDecks() async {
    var contactDecks =
        (await injector<SocialRecoveryService>().getContactDecks());

    contactDecks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    setState(() {
      _contactDecks = contactDecks;
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
        margin: ResponsiveLayout.pageEdgeInsets,
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "People you’re helping",
                      style: theme.textTheme.headline2,
                    ),
                    addTitleSpace(),
                    Text(
                      "Autonomy helps you safely store recovery codes for friends who have chosen you as their personal collaborator. ",
                      style: theme.textTheme.bodyText1,
                    ),
                    const SizedBox(height: 40),
                    Text(
                      "RECOVERY CODES",
                      style: theme.textTheme.headline4,
                    ),
                    _helpingsListWidget(),
                  ]),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: AuFilledButton(
                  text: "ADD FRIEND’S RECOVERY CODE".toUpperCase(),
                  onPress: () => Navigator.of(context)
                      .pushNamed(AppRouter.storeContactDeckPage),
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _helpingsListWidget() {
    if (_contactDecks == null) return loadingIndicator();

    int index = 0;
    return Column(children: [
      ..._contactDecks!.map((account) {
        final contactDeck = _contactDecks![index];
        index++;
        return Column(children: [
          _contactDeckWidget(contactDeck),
          index < _contactDecks!.length ? addOnlyDivider() : const SizedBox(),
        ]);
      }),
    ]);
  }

  Widget _contactDeckWidget(ContactDeck contactDeck) {
    return TappableForwardRow(
        leftWidget: Row(
          children: [
            Text(contactDeck.name, style: Theme.of(context).textTheme.headline4),
          ],
        ),
        onTap: () async {
          final secretFile = await injector<SocialRecoveryService>()
              .storeDataInTempSecretFile(jsonEncode(contactDeck.deck));

          await Share.shareFiles([secretFile]);
        });
  }
}
