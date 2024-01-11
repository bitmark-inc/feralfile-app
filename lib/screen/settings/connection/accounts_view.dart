//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/linked_wallet_detail_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/autonomy_service.dart';
import 'package:autonomy_flutter/util/account_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/account_view.dart';
import 'package:autonomy_flutter/view/crypto_view.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AccountsView extends StatefulWidget {
  final bool isInSettingsPage;

  const AccountsView({required this.isInSettingsPage, super.key});

  @override
  State<AccountsView> createState() => _AccountsViewState();
}

class _AccountsViewState extends State<AccountsView> {
  String? _editingAccountKey;
  final TextEditingController _nameController = TextEditingController();
  final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<AccountsBloc, AccountsState>(
        listener: (context, state) {
      final accounts = state.accounts;
      if (accounts == null) {
        return;
      }
    }, builder: (context, state) {
      final accounts = state.accounts;
      if (accounts == null) {
        return const Center(child: CupertinoActivityIndicator());
      }
      if (accounts.isEmpty) {
        return const SizedBox();
      }

      if (!widget.isInSettingsPage) {
        return _noEditAccountsListWidget(accounts);
      }
      return SlidableAutoCloseBehavior(
        child: Column(
          children: [
            ...accounts.map(
              (account) => Column(
                children: [
                  Padding(
                    padding: padding,
                    child: Slidable(
                      groupTag: 'accountsView',
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        dragDismissible: false,
                        children: slidableActions(account),
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
                  ),
                  Divider(
                      height: 1,
                      thickness: 1,
                      color: (_editingAccountKey == null ||
                              _editingAccountKey != account.key)
                          ? null
                          : theme.colorScheme.primary)
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  List<CustomSlidableAction> slidableActions(Account account) {
    final theme = Theme.of(context);
    final isHidden = account.isHidden;
    var actions = [
      CustomSlidableAction(
        backgroundColor: AppColor.secondarySpanishGrey,
        foregroundColor: theme.colorScheme.secondary,
        child: Semantics(
          label: '${account.key}_hide',
          child: SvgPicture.asset(
              isHidden ? 'assets/images/unhide.svg' : 'assets/images/hide.svg'),
        ),
        onPressed: (_) {
          account.setViewAccount(!isHidden);
          context.read<AccountsBloc>().add(GetAccountsEvent());
        },
      ),
      CustomSlidableAction(
        backgroundColor: AppColor.auGreyBackground,
        foregroundColor: theme.colorScheme.secondary,
        child: Semantics(
            label: '${account.name}_edit',
            child: SvgPicture.asset(
              'assets/images/rename_icon.svg',
              colorFilter: ColorFilter.mode(
                  theme.colorScheme.secondary, BlendMode.srcIn),
            )),
        onPressed: (_) {
          setState(() {
            _nameController.text = account.name;
            _editingAccountKey = account.key;
          });
        },
      ),
      CustomSlidableAction(
        backgroundColor: Colors.red,
        foregroundColor: theme.colorScheme.secondary,
        child: Semantics(
            label: '${account.name}_delete',
            child: SvgPicture.asset('assets/images/trash.svg')),
        onPressed: (_) {
          _showDeleteAccountConfirmation(context, account);
        },
      )
    ];
    return actions;
  }

  Widget _noEditAccountsListWidget(List<Account> accounts) {
    int index = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...accounts.map((account) => Column(
              children: [
                Padding(
                  padding: padding,
                  child: _viewAccountItem(account),
                ),
                if (index < accounts.length)
                  addOnlyDivider()
                else
                  const SizedBox(),
              ],
            )),
      ],
    );
  }

  Widget _viewAccountItem(Account account) => accountItem(
        context,
        account,
        onPersonaTap: () {
          if (account.persona != null && account.walletAddress != null) {
            unawaited(Navigator.of(context).pushNamed(
                AppRouter.walletDetailsPage,
                arguments: WalletDetailsPayload(
                    type: CryptoType.fromSource(
                        account.walletAddress!.cryptoType),
                    walletAddress: account.walletAddress!,
                    persona: account.persona!)));
          }
        },
        onConnectionTap: () {
          final connection = account.connections?.first;
          if (connection != null) {
            final payload = LinkedWalletDetailsPayload(
              connection: connection,
              type: account.cryptoType,
              personaName: account.name,
            );
            unawaited(Navigator.of(context).pushNamed(
                AppRouter.linkedWalletDetailsPage,
                arguments: payload));
          }
        },
      );

  Widget _editAccountItem(Account account) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          LogoCrypto(
            cryptoType: account.cryptoType,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Semantics(
              label: '${account.name}_editing',
              child: TextField(
                autocorrect: false,
                autofocus: true,
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: theme.textTheme.ppMori700Black16,
                controller: _nameController,
                onSubmitted: (String value) async {
                  if (value.isEmpty) {
                    return;
                  }
                  final walletAddress = account.walletAddress;
                  final connection = account.connections?.first;
                  if (walletAddress != null) {
                    final newWalletAddress =
                        walletAddress.copyWith(name: value);
                    await injector<AccountService>()
                        .updateAddressPersona(newWalletAddress);
                  } else if (connection != null) {
                    await injector<AccountService>()
                        .nameLinkedAccount(connection, value);
                  }

                  setState(() {
                    _editingAccountKey = null;
                  });
                  if (!mounted) {
                    return;
                  }
                  context.read<AccountsBloc>().add(GetAccountsEvent());
                },
              ),
            ),
          ),
        ],
      ),
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
        constraints: BoxConstraints(
          maxWidth: ResponsiveLayout.isMobile
              ? double.infinity
              : Constants.maxWidthModalTablet,
        ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (account.walletAddress != null)
                          ? 'delete_account'.tr()
                          : 'remove_account'.tr(),
                      style: theme.primaryTextTheme.ppMori700White24,
                    ),
                    const SizedBox(height: 40),
                    RichText(
                      text: TextSpan(
                        style: theme.primaryTextTheme.ppMori400White14,
                        children: <TextSpan>[
                          TextSpan(
                            text: (account.walletAddress != null)
                                ? 'sure_delete_account'.tr()
                                : 'sure_remove_account'.tr(),
                            //'Are you sure you want to delete the account ',
                          ),
                          TextSpan(
                              text: '“$accountName”',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const TextSpan(
                            text: '?',
                          ),
                          if (account.walletAddress != null) ...[
                            TextSpan(text: 'not_back_up_yet'.tr())
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    PrimaryButton(
                      text: (account.walletAddress != null)
                          ? 'delete_dialog'.tr()
                          : 'remove'.tr(),
                      onTap: () {
                        Navigator.of(context).pop();
                        unawaited(_deleteAccount(pageContext, account));
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
            ));
  }

  Future<void> _deleteAccount(BuildContext context, Account account) async {
    final walletAddress = account.walletAddress;
    if (walletAddress != null && account.persona != null) {
      await injector<AccountService>()
          .deleteAddressPersona(account.persona!, account.walletAddress!);
    }

    final connection = account.connections?.first;

    if (connection != null) {
      await injector<AccountService>().deleteLinkedAccount(connection);
    }

    unawaited(injector<AutonomyService>().postLinkedAddresses());
  }
}
