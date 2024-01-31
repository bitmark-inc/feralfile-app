import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/crypto_view.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/radio_check_box.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class SelectAddressView extends StatefulWidget {
  final List<WalletAddress> addresses;
  final String? selectButton;

  const SelectAddressView(
      {required this.addresses, super.key, this.selectButton});

  @override
  State<SelectAddressView> createState() => _SelectAddressViewState();
}

class _SelectAddressViewState extends State<SelectAddressView> {
  String? _selectedAddress;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 325),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: SingleChildScrollView(
                child: Column(
              children: widget.addresses
                  .map((e) => AddressView(
                        address: e,
                        selectedAddress: _selectedAddress,
                        onTap: () {
                          setState(() {
                            _selectedAddress = e.address;
                          });
                        },
                      ))
                  .toList(),
            )),
          ),
          Row(
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
                        Navigator.pop(context, null);
                      })
                ],
              )),
            ],
          )
        ],
      ));
}

class AddressView extends StatelessWidget {
  const AddressView({
    required this.address,
    super.key,
    this.selectedAddress,
    this.onTap,
  });

  final WalletAddress address;
  final String? selectedAddress;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cryptoType = CryptoType.fromSource(address.cryptoType);
    final color = address.address == selectedAddress
        ? AppColor.white
        : AppColor.disabledColor;
    final name = address.name ?? '';
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            color: Colors.transparent,
            child: Row(
              children: [
                LogoCrypto(
                  cryptoType: cryptoType,
                  size: 24,
                ),
                const SizedBox(
                  width: 10,
                ),
                Text(
                  name.isNotEmpty
                      ? name
                      : cryptoType == CryptoType.ETH
                          ? 'Ethereum'
                          : 'Tezos',
                  style:
                      theme.textTheme.ppMori400White14.copyWith(color: color),
                ),
                const Spacer(),
                Text(
                  address.address.maskOnly(6),
                  style:
                      theme.textTheme.ppMori400White14.copyWith(color: color),
                ),
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
