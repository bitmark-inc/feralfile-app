import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/scan_wallet/scan_wallet_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/scan_wallet/scan_wallet_state.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_toggle.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/crypto_view.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/radio_check_box.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectAddressesPage extends StatefulWidget {
  static const String tag = 'select_addresses_page';
  final SelectAddressesPayload payload;

  const SelectAddressesPage({Key? key, required this.payload})
      : super(key: key);

  @override
  State<SelectAddressesPage> createState() => _SelectAddressesPageState();
}

class _SelectAddressesPageState extends State<SelectAddressesPage> {
  final List<String> _importedAddresses = [];

  int index = 0;
  final List<AddressInfo> _addresses = [];
  final List<AddressInfo> _selectedAddresses = [];
  bool _onlyBalance = true;
  bool _addingAddresses = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _callBloc();
      fetchImportedAddresses();
    });
  }

  Future<void> fetchImportedAddresses() async {
    final importedAddresses = await widget.payload.persona.getAddresses();
    setState(() {
      _importedAddresses.addAll(importedAddresses);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: "import_address".tr(),
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: BlocConsumer<ScanWalletBloc, ScanWalletState>(
          listener: (context, scanState) {
        if (scanState.addresses.isNotEmpty && !scanState.isScanning) {
          _addresses.addAll(scanState.addresses);
          _addresses.sort((a, b) {
            if (a.getCryptoType() == b.getCryptoType()) {
              return a.getCryptoType().index - b.getCryptoType().index;
            } else {
              return a.getCryptoType() == CryptoType.ETH ? -1 : 1;
            }
          });
        }
      }, builder: (context, scanState) {
        final scanningNext = _addresses.isNotEmpty && scanState.isScanning;
        final showAddresses = _onlyBalance
            ? _addresses.where((element) => element.hasBalance()).toList()
            : _addresses;
        return Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Padding(
                  padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                  child: Row(
                    children: [
                      Text(
                        "only_show_balance".tr(),
                        style: theme.textTheme.ppMori400Black14,
                      ),
                      const Spacer(),
                      AuToggle(
                        value: _onlyBalance,
                        onToggle: (value) {
                          setState(() {
                            _onlyBalance = value;
                          });
                        },
                      )
                    ],
                  )),
              Expanded(
                child: _addresses.isEmpty && scanState.isScanning
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/images/loading.gif",
                              width: 52,
                              height: 52,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "h_loading...".tr(),
                              style: theme.textTheme.ppMori400White14,
                            )
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 30),
                            ...showAddresses
                                .map((address) => [
                                      _addressOption(
                                          addressInfo: address,
                                          isImported: _importedAddresses
                                              .contains(address.address)),
                                      addDivider(
                                          height: 1, color: AppColor.auGrey),
                                    ])
                                .flattened
                                .toList()
                          ],
                        ),
                      ),
              ),
              Padding(
                padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                child: Column(
                  children: [
                    OutlineButton(
                      onTap: () {
                        _callBloc();
                      },
                      isProcessing: scanningNext,
                      text: "scan_more".tr(),
                      color: AppColor.white,
                      textColor: AppColor.primaryBlack,
                      borderColor: AppColor.primaryBlack,
                    ),
                    const SizedBox(height: 10),
                    PrimaryButton(
                      text: "continue".tr(),
                      isProcessing: _addingAddresses,
                      enabled: _selectedAddresses.isNotEmpty,
                      onTap: () async {
                        setState(() {
                          _addingAddresses = true;
                        });
                        await injector<AccountService>().addAddressPersona(
                            widget.payload.persona, _selectedAddresses);
                        await _doneAdding();
                        setState(() {
                          _addingAddresses = false;
                        });
                      },
                    )
                  ],
                ),
              )
            ],
          ),
        );
      }),
    );
  }

  Future _doneAdding() async {
    if (Platform.isAndroid) {
      final isAndroidEndToEndEncryptionAvailable =
          await injector<AccountService>()
              .isAndroidEndToEndEncryptionAvailable();

      if (!mounted) return;

      if (injector<ConfigurationService>().isDoneOnboarding()) {
        Navigator.of(context).pushReplacementNamed(AppRouter.cloudAndroidPage,
            arguments: isAndroidEndToEndEncryptionAvailable);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.cloudAndroidPage, (route) => false,
            arguments: isAndroidEndToEndEncryptionAvailable);
      }
    } else {
      if (injector<ConfigurationService>().isDoneOnboarding()) {
        Navigator.of(context)
            .pushReplacementNamed(AppRouter.cloudPage, arguments: "nameAlias");
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.cloudPage, (route) => false,
            arguments: "nameAlias");
      }
    }
  }

  Widget _addressOption(
      {required AddressInfo addressInfo, bool isImported = false}) {
    final theme = Theme.of(context);
    final color = isImported ? AppColor.disabledColor : AppColor.primaryBlack;
    final isSelected = _selectedAddresses.contains(addressInfo) || isImported;
    return Padding(
      padding: const EdgeInsets.all(15),
      child: GestureDetector(
        onTap: isImported
            ? null
            : () {
                setState(() {
                  if (isSelected) {
                    _selectedAddresses.remove(addressInfo);
                  } else {
                    _selectedAddresses.add(addressInfo);
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
                  color: isImported
                      ? AppColor.disabledColor
                      : AppColor.primaryBlack),
              const SizedBox(width: 15),
              LogoCrypto(
                cryptoType: addressInfo.getCryptoType(),
                size: 24,
              ),
              const SizedBox(width: 34),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    addressInfo.getCryptoType().source,
                    style: theme.textTheme.ppMori400Black14.copyWith(
                      color: color,
                    ),
                  ),
                  Text(addressInfo.address.maskOnly(5),
                      style: theme.textTheme.ppMori400Black14.copyWith(
                        color: color,
                      ),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
              const Spacer(),
              isImported
                  ? Text("imported_".tr(),
                      style: theme.textTheme.ppMori400Black14.copyWith(
                        color: AppColor.disabledColor,
                      ))
                  : Text(
                      addressInfo.getBalance(),
                      style: theme.textTheme.ppMori400Black14
                          .copyWith(color: color),
                    )
            ],
          ),
        ),
      ),
    );
  }

  void _callBloc() {
    final wallet = widget.payload.persona.wallet();
    context
        .read<ScanWalletBloc>()
        .add(ScanEthereumWalletEvent(wallet: wallet, startIndex: index));

    context
        .read<ScanWalletBloc>()
        .add(ScanTezosWalletEvent(wallet: wallet, startIndex: index));
    index += 5;
  }
}

class SelectAddressesPayload {
  final Persona persona;

  SelectAddressesPayload({required this.persona});
}
