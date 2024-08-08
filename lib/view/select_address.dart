import 'dart:async';

import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/account_view.dart';
import 'package:autonomy_flutter/view/crypto_view.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/radio_check_box.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class IRLSelectAddressView extends StatefulWidget {
  final List<WalletAddress> addresses;
  final String? selectButton;
  final int? minimumCryptoBalance;

  const IRLSelectAddressView(
      {required this.addresses,
      super.key,
      this.selectButton,
      this.minimumCryptoBalance});

  @override
  State<IRLSelectAddressView> createState() => _IRLSelectAddressViewState();
}

class _IRLSelectAddressViewState extends State<IRLSelectAddressView> {
  String? _selectedAddress;
  final Map<String, bool> _isViewing = {};

  @override
  Widget build(BuildContext context) {
    final minimumCryptoBalance = widget.minimumCryptoBalance ?? 0;
    return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 325),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: SingleChildScrollView(
                  child: Column(
                children: [
                  if (_isViewing.isEmpty) ...[
                    loadingIndicator(valueColor: AppColor.white),
                  ],
                  if (_noAddressHasEnoughBalance()) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'no_address_has_enough_balance'.tr(),
                        style: Theme.of(context)
                            .textTheme
                            .ppMori400White14
                            .copyWith(color: AppColor.disabledColor),
                      ),
                    ),
                  ] else
                    ...widget.addresses.map((e) => AddressView(
                          key: Key(e.address),
                          address: e,
                          selectedAddress: _selectedAddress,
                          onTap: () {
                            setState(() {
                              _selectedAddress = e.address;
                            });
                          },
                          onDoneLoading: (notShowing) {
                            setState(() {
                              _isViewing[e.address] = !notShowing;
                            });
                          },
                          minimumCryptoBalance: minimumCryptoBalance,
                        ))
                ],
              )),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                      child: Column(
                    children: [
                      PrimaryButton(
                          text: widget.selectButton ?? 'connect'.tr(),
                          enabled: _selectedAddress != null,
                          onTap: () {
                            Navigator.pop(context, _selectedAddress);
                          }),
                      const SizedBox(
                        height: 10,
                      ),
                      OutlineButton(
                          text: 'cancel'.tr(),
                          onTap: () {
                            Navigator.pop(context);
                          })
                    ],
                  )),
                ],
              ),
            )
          ],
        ));
  }

  bool _noAddressHasEnoughBalance() =>
      widget.addresses.every((element) => _isViewing[element.address] == false);
}

class AddressView extends StatefulWidget {
  const AddressView({
    required this.address,
    super.key,
    this.selectedAddress,
    this.onTap,
    this.minimumCryptoBalance = 0,
    this.onDoneLoading,
  });

  final WalletAddress address;
  final String? selectedAddress;
  final Function()? onTap;
  final int minimumCryptoBalance;
  final Function(bool notShowing)? onDoneLoading;

  @override
  State<AddressView> createState() => _AddressViewState();
}

class _AddressViewState extends State<AddressView> {
  Pair<String, String>? _balance;
  bool _didLoad = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadBalance());
  }

  Future<void> _loadBalance() async {
    final cryptoType = CryptoType.fromSource(widget.address.cryptoType);
    _balance = await getAddressBalance(
      widget.address.address,
      cryptoType,
      getNFT: false,
      minimumCryptoBalance: widget.minimumCryptoBalance,
    );
    setState(() {
      _didLoad = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final balances = _balance;
    if (_didLoad) {
      Future.delayed(const Duration(milliseconds: 50), () {
        widget.onDoneLoading
            ?.call(balances == null && widget.minimumCryptoBalance > 0);
      });
    }
    if (balances == null && widget.minimumCryptoBalance > 0) {
      return const SizedBox();
    }
    return _addressView(context, balances ?? Pair('--', '--'));
  }

  Widget _addressView(BuildContext context, Pair<String, String> balances) {
    final theme = Theme.of(context);
    final cryptoType = CryptoType.fromSource(widget.address.cryptoType);
    final isSelected = widget.address.address == widget.selectedAddress;
    final color = isSelected ? AppColor.white : AppColor.disabledColor;
    final name = widget.address.name ?? '';
    final style = theme.textTheme.ppMori400White14.copyWith(color: color);
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 14),
            color: isSelected
                ? const Color.fromRGBO(30, 30, 30, 1)
                : Colors.transparent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LogoCrypto(
                  cryptoType: cryptoType,
                  size: 24,
                ),
                const SizedBox(
                  width: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty
                          ? name
                          : cryptoType == CryptoType.ETH
                              ? 'Ethereum'
                              : 'Tezos',
                      style: style,
                    ),
                    Text(balances.first, style: style),
                  ],
                ),
                const Spacer(),
                Text(widget.address.address.maskOnly(6), style: style),
                const SizedBox(
                  width: 20,
                ),
                AuCheckBox(
                  isChecked: widget.address.address == widget.selectedAddress,
                  color: color,
                ),
              ],
            ),
          ),
          addOnlyDivider(color: AppColor.disabledColor),
        ],
      ),
    );
  }
}

enum SelectAddressType {
  connect,
  purchase,
  receive,
  unknown,
  ;

  String get popUpTitle {
    switch (this) {
      case SelectAddressType.connect:
      case SelectAddressType.purchase:
      case SelectAddressType.receive:
        return 'select_address_to_'.tr(args: [selectButton.toLowerCase()]);
      default:
        return 'select_address_irl'.tr();
    }
  }

  String get selectButton {
    switch (this) {
      case SelectAddressType.connect:
        return 'connect'.tr();
      case SelectAddressType.purchase:
        return 'purchase'.tr();
      case SelectAddressType.receive:
        return 'receive'.tr();
      default:
        return 'select'.tr();
    }
  }

  static SelectAddressType fromString(String value) {
    switch (value) {
      case 'connect':
        return SelectAddressType.connect;
      case 'purchase':
        return SelectAddressType.purchase;
      case 'receive':
        return SelectAddressType.receive;
      default:
        return SelectAddressType.unknown;
    }
  }
}
