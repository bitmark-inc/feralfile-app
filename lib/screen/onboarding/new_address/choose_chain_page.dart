import 'package:autonomy_flutter/screen/onboarding/new_address/address_alias.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/crypto_view.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/radio_check_box.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ChooseChainPage extends StatefulWidget {
  static const String tag = 'choose_chain_page';

  const ChooseChainPage({Key? key}) : super(key: key);

  @override
  State<ChooseChainPage> createState() => _ChooseChainPageState();
}

class _ChooseChainPageState extends State<ChooseChainPage> {
  bool _ethSelected = false;
  bool _tezosSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(context,
          title: "choose_a_chain".tr().capitalize(),
          onBack: () => Navigator.of(context).pop()),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _addressOption(context,
                        cryptoType: CryptoType.ETH, isSelected: _ethSelected),
                    _addressOption(context,
                        cryptoType: CryptoType.XTZ, isSelected: _tezosSelected),
                  ],
                ),
              ),
            ),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: PrimaryButton(
                text: "continue".tr(),
                enabled: _ethSelected || _tezosSelected,
                onTap: () {
                  final walletType = WalletType.getWallet(
                      eth: _ethSelected, tezos: _tezosSelected);
                  if (walletType != null) {
                    Navigator.of(context).pushNamed(AddressAlias.tag,
                        arguments: AddressAliasPayload(walletType));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addressOption(BuildContext context,
      {required CryptoType cryptoType, required bool isSelected}) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(15),
          child: GestureDetector(
            onTap: () {
              setState(() {
                switch (cryptoType) {
                  case CryptoType.ETH:
                    _ethSelected = !_ethSelected;
                    break;
                  case CryptoType.XTZ:
                    _tezosSelected = !_tezosSelected;
                    break;
                  default:
                    break;
                }
              });
            },
            child: Container(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuCheckBox(
                    isChecked: isSelected,
                  ),
                  const SizedBox(width: 15),
                  LogoCrypto(
                    cryptoType: cryptoType,
                    size: 24,
                  ),
                  const SizedBox(width: 34),
                  Text(
                    cryptoType.source,
                    style: theme.textTheme.ppMori400Black14,
                  ),
                ],
              ),
            ),
          ),
        ),
        addOnlyDivider(),
      ],
    );
  }
}
