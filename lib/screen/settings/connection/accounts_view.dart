//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/autonomy_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';

import 'package:autonomy_flutter/view/account_view.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class AccountsView extends StatefulWidget {
  final bool isInSettingsPage;

  const AccountsView({required this.isInSettingsPage, Key? key})
      : super(key: key);

  @override
  State<AccountsView> createState() => _AccountsViewState();
}

class _AccountsViewState extends State<AccountsView> {
  String? _editingAccountKey;
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<AccountsBloc, AccountsState>(
        listener: (context, state) {
      final accounts = state.accounts;
      if (accounts == null) return;

      // move back to onboarding
      if (accounts.isEmpty) {
        injector<ConfigurationService>().setDoneOnboardingOnce(true);
        injector<ConfigurationService>().setDoneOnboarding(false);
        Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.newAccountPage, (route) => false);
      }
    }, builder: (context, state) {
      final accounts = state.accounts;
      if (accounts == null) return const CupertinoActivityIndicator();
      if (accounts.isEmpty) return const SizedBox();

      if (!widget.isInSettingsPage) {
        return _noEditAccountsListWidget(accounts);
      }
      int index = 0;
      return SlidableAutoCloseBehavior(
        child: Column(
          children: [
            ...accounts.map(
              (account) {
                index++;
                return Column(
                  children: [
                    Slidable(
                      key: UniqueKey(),
                      groupTag: 'accountsView',
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        dragDismissible: false,
                        children: slidableActions(
                            account, account.persona?.defaultAccount == 1),
                      ),
                      child: Column(
                        children: [
                          if (_editingAccountKey == null ||
                              _editingAccountKey != account.key) ...[
                            _viewAccountItem(account),
                          ] else ...[
                            _editAccountItem(account),
                          ],
                        ],
                      ),
                    ),
                    index < accounts.length
                        ? Divider(
                            height: 1.0,
                            thickness: 1.0,
                            color: (_editingAccountKey == null ||
                                    _editingAccountKey != account.key)
                                ? null
                                : theme.colorScheme.primary)
                        : const SizedBox(),
                  ],
                );
              },
            ).toList(),
          ],
        ),
      );
    });
  }

  List<SlidableAction> slidableActions(Account account, bool isDefault) {
    final theme = Theme.of(context);
    var actions = [
      SlidableAction(
        backgroundColor: AppColor.secondarySpanishGrey,
        foregroundColor: theme.colorScheme.secondary,
        icon: CupertinoIcons.pencil,
        onPressed: (_) {
          setState(() {
            _nameController.text = account.name;
            _editingAccountKey = account.key;
          });
        },
      )
    ];

    if (!isDefault) {
      actions.add(SlidableAction(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.secondary,
        icon: CupertinoIcons.delete,
        onPressed: (_) {
          _showDeleteAccountConfirmation(context, account);
        },
      ));
    }
    return actions;
  }

  Widget _noEditAccountsListWidget(List<Account> accounts) {
    int index = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...accounts
            .map((account) => Column(
                  children: [
                    _viewAccountItem(account),
                    index < accounts.length
                        ? addOnlyDivider()
                        : const SizedBox(),
                  ],
                ))
            .toList(),
      ],
    );
  }

  Widget _viewAccountItem(Account account) {
    return accountItem(
      context,
      account,
      onPersonaTap: () => Navigator.of(context).pushNamed(
        AppRouter.personaDetailsPage,
        arguments: account.persona,
      ),
      onConnectionTap: () => Navigator.of(context).pushNamed(
          AppRouter.linkedAccountDetailsPage,
          arguments: account.connections!.first),
    );
  }

  Widget _editAccountItem(Account account) {
    final theme = Theme.of(context);

    return Row(
      children: [
        accountLogo(account),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: theme.textTheme.headline4,
            controller: _nameController,
            onSubmitted: (String value) async {
              final persona = account.persona;
              final connection = account.connections?.first;
              if (persona != null) {
                await injector<AccountService>().namePersona(persona, value);
              } else if (connection != null) {
                await injector<AccountService>()
                    .nameLinkedAccount(connection, value);
              }

              setState(() {
                _editingAccountKey = null;
              });
              if (!mounted) return;
              context.read<AccountsBloc>().add(GetAccountsEvent());
            },
          ),
        ),
      ],
    );
  }

  void _showDeleteAccountConfirmation(
      BuildContext pageContext, Account account) {
    final theme = Theme.of(context);
    var accountName = account.name;
    if (accountName.isEmpty) {
      accountName = account.accountNumber.mask(4);
    }

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
                color: theme.colorScheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delete account',
                        style: theme.primaryTextTheme.headline1),
                    const SizedBox(height: 40),
                    RichText(
                      text: TextSpan(
                        style: theme.primaryTextTheme.bodyText1,
                        children: <TextSpan>[
                          const TextSpan(
                            text:
                                'Are you sure you want to delete the account ',
                          ),
                          TextSpan(
                              text: '“$accountName”',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const TextSpan(
                            text: '?',
                          ),
                          if (account.persona != null) ...[
                            const TextSpan(
                                text:
                                    ' If you haven’t backed up your recovery phrase, you will lose access to your funds.')
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: AuFilledButton(
                            text: "DELETE",
                            onPress: () {
                              Navigator.of(context).pop();
                              _deleteAccount(pageContext, account);
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
                        child: Text("CANCEL",
                            style: theme.primaryTextTheme.button),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }

  void _deleteAccount(BuildContext context, Account account) async {
    final persona = account.persona;
    if (persona != null) {
      await injector<AccountService>().deletePersona(persona);
    }

    final connection = account.connections?.first;

    if (connection != null) {
      await injector<AccountService>().deleteLinkedAccount(connection);
    }

    injector<AutonomyService>().postLinkedAddresses();
  }
}
