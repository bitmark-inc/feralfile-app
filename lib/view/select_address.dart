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

class AddressView extends StatelessWidget {
  const AddressView(
      {required this.address,
      super.key,
      this.selectedAddress,
      this.onTap,
      this.minimumCryptoBalance = 0,
      this.onDoneLoading});

  final WalletAddress address;
  final String? selectedAddress;
  final Function()? onTap;
  final int minimumCryptoBalance;
  final Function(bool notShowing)? onDoneLoading;

  @override
  Widget build(BuildContext context) {
    final cryptoType = CryptoType.fromSource(address.cryptoType);
    final balance =
        // ignore: discarded_futures
        getAddressBalance(address.address, cryptoType,
            getNFT: false, minimumCryptoBalance: minimumCryptoBalance);
    return FutureBuilder<Pair<String, String>?>(
        future: balance,
        builder: (context, snapshot) {
          final balances = snapshot.data;
          if (snapshot.connectionState == ConnectionState.done) {
            onDoneLoading?.call(balances == null && minimumCryptoBalance > 0);
          }
          if (balances == null && minimumCryptoBalance > 0) {
            return const SizedBox();
          }
          return _addressView(context, balances ?? Pair('--', '--'));
        });
  }

  Widget _addressView(BuildContext context, Pair<String, String> balances) {
    final theme = Theme.of(context);
    final cryptoType = CryptoType.fromSource(address.cryptoType);
    final isSelected = address.address == selectedAddress;
    final color = isSelected ? AppColor.white : AppColor.disabledColor;
    final name = address.name ?? '';
    final style = theme.textTheme.ppMori400White14.copyWith(color: color);
    return GestureDetector(
      onTap: onTap,
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
                Text(address.address.maskOnly(6), style: style),
                const SizedBox(
                  width: 20,
                ),
                AuCheckBox(
                  isChecked: address.address == selectedAddress,
                  color: color,
                )
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
