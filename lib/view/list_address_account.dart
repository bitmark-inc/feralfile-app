import 'dart:convert';

import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/util/account_ext.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/account_view.dart';
import 'package:autonomy_flutter/view/crypto_view.dart';
import 'package:autonomy_flutter/view/radio_check_box.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ListAccountConnect extends StatefulWidget {
  final List<Account> accounts;
  final Function(Account)? onSelectEth;
  final Function(Account)? onSelectTez;
  final bool isAutoSelect;
  final bool isSeparateHidden;

  ListAccountConnect({
    Key? key,
    required this.accounts,
    this.onSelectEth,
    this.onSelectTez,
    this.isAutoSelect = false,
    this.isSeparateHidden = true,
  }) : super(key: key ?? _keyFromAccount(accounts));

  @override
  State<ListAccountConnect> createState() => _ListAccountConnectState();

  static Key _keyFromAccount(List<Account> accounts) {
    final addresses = accounts.map((e) => e.accountNumber).join();
    final bytes = utf8.encode(addresses);
    return Key(sha256.convert(bytes).toString());
  }
}

class _ListAccountConnectState extends State<ListAccountConnect> {
  final List<Account> showedAccounts = [];
  final List<Account> hiddenAccounts = [];
  String? tezSelectedAddress;
  String? ethSelectedAddress;
  bool showHiddenAddresses = true;

  @override
  void initState() {
    if (widget.isSeparateHidden) {
      for (var e in widget.accounts) {
        e.isHidden ? hiddenAccounts.add(e) : showedAccounts.add(e);
      }
    } else {
      showedAccounts.addAll(widget.accounts);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._listAddresses(showedAccounts),
        const SizedBox(height: 30.0),
        if (hiddenAccounts.isNotEmpty) ...[
          GestureDetector(
            onTap: () {
              setState(() {
                showHiddenAddresses = !showHiddenAddresses;
              });
            },
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(
                "hidden_addresses".tr(),
                style: theme.textTheme.ppMori400Grey14,
              ),
              const SizedBox(width: 8.0),
              RotatedBox(
                quarterTurns: showHiddenAddresses ? -1 : 1,
                child: const Icon(
                  AuIcon.chevron_Sm,
                  size: 12,
                  color: AppColor.auGrey,
                ),
              )
            ]),
          ),
          if (showHiddenAddresses) ..._listAddresses(hiddenAccounts),
        ]
      ],
    );
  }

  List<Widget> _listAddresses(List<Account> accounts) {
    return accounts
        .map((account) => PersonalConnectItem(
              account: account,
              ethSelectedAddress: ethSelectedAddress,
              tezSelectedAddress: tezSelectedAddress,
              onSelectEth: (value) {
                widget.onSelectEth?.call(value);
                setState(() {
                  ethSelectedAddress = value.accountNumber;
                });
              },
              onSelectTez: (value) {
                widget.onSelectTez?.call(value);
                setState(() {
                  tezSelectedAddress = value.accountNumber;
                });
              },
              isAutoSelect: widget.isAutoSelect,
            ))
        .toList();
  }
}

class AddressItem extends StatelessWidget {
  const AddressItem({
    Key? key,
    required this.cryptoType,
    required this.address,
    this.name = "",
    this.ethSelectedAddress,
    this.tezSelectedAddress,
    this.onTap,
    this.isAutoSelect = false,
    this.isViewOnly = false,
  }) : super(key: key);

  final CryptoType cryptoType;
  final String address;
  final String? ethSelectedAddress;
  final String? tezSelectedAddress;
  final bool isAutoSelect;
  final Function()? onTap;
  final String name;
  final bool isViewOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: AppColor.white,
        padding: ResponsiveLayout.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LogoCrypto(
                  cryptoType: cryptoType,
                  size: 24,
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                    name.isNotEmpty
                        ? name
                        : cryptoType == CryptoType.ETH
                            ? 'Ethereum'
                            : cryptoType == CryptoType.XTZ
                                ? 'Tezos'
                                : '',
                    style: theme.textTheme.ppMori700Black14,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                if (isViewOnly) ...[
                  viewOnlyLabel(context),
                  const SizedBox(
                    width: 20,
                  ),
                ],
                Text(
                  address.toIdentityOrMask({}) ?? '',
                  style: theme.textTheme.ibmBlackNormal14,
                ),
                const SizedBox(
                  width: 20,
                ),
                Visibility(
                  visible: !isAutoSelect,
                  child: AuCheckBox(
                    isChecked: address == ethSelectedAddress ||
                        address == tezSelectedAddress,
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PersonalConnectItem extends StatefulWidget {
  final Account account;
  final String? tezSelectedAddress;
  final String? ethSelectedAddress;

  final Function(Account)? onSelectEth;
  final Function(Account)? onSelectTez;

  final bool isAutoSelect;

  const PersonalConnectItem({
    Key? key,
    required this.account,
    this.tezSelectedAddress,
    this.ethSelectedAddress,
    this.onSelectEth,
    this.onSelectTez,
    this.isAutoSelect = false,
  }) : super(key: key);

  @override
  State<PersonalConnectItem> createState() => _PersonalConnectItemState();
}

class _PersonalConnectItemState extends State<PersonalConnectItem> {
  @override
  Widget build(BuildContext context) {
    final e = widget.account;
    return Column(
      children: [
        AddressItem(
          onTap: () {
            if (e.isEth) {
              widget.onSelectEth?.call(e);
            }
            if (e.isTez) {
              widget.onSelectTez?.call(e);
            }
          },
          name: e.name,
          isAutoSelect: widget.isAutoSelect,
          address: e.accountNumber,
          cryptoType: e.isEth ? CryptoType.ETH : CryptoType.XTZ,
          ethSelectedAddress: widget.ethSelectedAddress,
          tezSelectedAddress: widget.tezSelectedAddress,
          isViewOnly: e.isViewOnly,
        ),
        addOnlyDivider(),
      ],
    );
  }
}
