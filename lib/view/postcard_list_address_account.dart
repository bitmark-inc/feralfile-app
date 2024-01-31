import 'dart:convert';

import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/util/account_ext.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/radio_check_box.dart';
import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/extensions/theme_extension/moma_sans.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class PostcardListAccountConnect extends StatefulWidget {
  final List<Account> accounts;
  final Function(Account)? onSelectEth;
  final Function(Account)? onSelectTez;
  final bool isAutoSelect;
  final bool isSeparateHidden;

  PostcardListAccountConnect({
    required this.accounts,
    Key? key,
    this.onSelectEth,
    this.onSelectTez,
    this.isAutoSelect = false,
    this.isSeparateHidden = true,
  }) : super(key: key ?? _keyFromAccount(accounts));

  @override
  State<PostcardListAccountConnect> createState() =>
      _PostcardListAccountConnectState();

  static Key _keyFromAccount(List<Account> accounts) {
    final addresses = accounts.map((e) => e.accountNumber).join();
    final bytes = utf8.encode(addresses);
    return Key(sha256.convert(bytes).toString());
  }
}

class _PostcardListAccountConnectState
    extends State<PostcardListAccountConnect> {
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
        const SizedBox(height: 30),
        if (hiddenAccounts.isNotEmpty) ...[
          GestureDetector(
            onTap: () {
              setState(() {
                showHiddenAddresses = !showHiddenAddresses;
              });
            },
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(
                'hidden_addresses'.tr(),
                style: theme.textTheme.ppMori400Grey14,
              ),
              const SizedBox(width: 8),
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

  List<Widget> _listAddresses(List<Account> accounts) => accounts
      .map((account) => PostcardPersonalConnectItem(
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

class PostcardAddressItem extends StatelessWidget {
  const PostcardAddressItem({
    required this.cryptoType,
    required this.address,
    super.key,
    this.name = '',
    this.ethSelectedAddress,
    this.tezSelectedAddress,
    this.onTap,
    this.isAutoSelect = false,
  });

  final CryptoType cryptoType;
  final String address;
  final String? ethSelectedAddress;
  final String? tezSelectedAddress;
  final bool isAutoSelect;
  final Function()? onTap;
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: AppColor.white,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                children: [
                  Text(
                    name.isNotEmpty
                        ? name
                        : cryptoType == CryptoType.ETH
                            ? 'Ethereum'
                            : cryptoType == CryptoType.XTZ
                                ? 'Tezos'
                                : '',
                    style: theme.textTheme.moMASans700Black16
                        .copyWith(fontSize: 18),
                  ),
                  const Spacer(),
                  Text(
                    address.toIdentityOrMask({}) ?? '',
                    style: theme.textTheme.moMASans400Black16
                        .copyWith(fontSize: 18),
                  ),
                  const SizedBox(
                    width: 40,
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
            ),
            addOnlyDivider(),
          ],
        ),
      ),
    );
  }
}

class PostcardPersonalConnectItem extends StatefulWidget {
  final Account account;
  final String? tezSelectedAddress;
  final String? ethSelectedAddress;

  final Function(Account)? onSelectEth;
  final Function(Account)? onSelectTez;

  final bool isAutoSelect;

  const PostcardPersonalConnectItem({
    required this.account,
    super.key,
    this.tezSelectedAddress,
    this.ethSelectedAddress,
    this.onSelectEth,
    this.onSelectTez,
    this.isAutoSelect = false,
  });

  @override
  State<PostcardPersonalConnectItem> createState() =>
      _PostcardPersonalConnectItemState();
}

class _PostcardPersonalConnectItemState
    extends State<PostcardPersonalConnectItem> {
  @override
  Widget build(BuildContext context) {
    final e = widget.account;
    return Column(
      children: [
        PostcardAddressItem(
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
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}
