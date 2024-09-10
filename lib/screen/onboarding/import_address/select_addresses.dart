import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_object.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/scan_wallet/scan_wallet_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/scan_wallet/scan_wallet_state.dart';
import 'package:autonomy_flutter/screen/onboarding/import_address/name_address_persona.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_toggle.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/crypto_view.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/radio_check_box.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libauk_dart/libauk_dart.dart';

class SelectAddressesPage extends StatefulWidget {
  final SelectAddressesPayload payload;

  const SelectAddressesPage({required this.payload, super.key});

  @override
  State<SelectAddressesPage> createState() => _SelectAddressesPageState();
}

class _SelectAddressesPageState extends State<SelectAddressesPage> {
  final List<String> _importedAddresses = [];

  int index = 0;
  final List<AddressInfo> _addresses = [];
  final List<AddressInfo> _selectedAddresses = [];
  bool _onlyBalance = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _callBloc();
      unawaited(fetchImportedAddresses());
    });
  }

  Future<void> fetchImportedAddresses() async {
    final importedAddresses = injector<CloudObjects>()
        .addressObject
        .getAddressesByPersona(widget.payload.wallet.uuid);
    setState(() {
      _importedAddresses.addAll(importedAddresses.map((e) => e.address));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: 'import_address'.tr(),
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: BlocConsumer<ScanWalletBloc, ScanWalletState>(
          listener: (context, scanState) {
        if (scanState.addresses.isNotEmpty && !scanState.isScanning) {
          _addresses
            ..addAll(scanState.addresses)
            ..sort((a, b) {
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
                        'only_show_balance'.tr(),
                        style: theme.textTheme.ppMori400Black14,
                      ),
                      const Spacer(),
                      Semantics(
                        label: 'only_show_balance_toggle',
                        child: AuToggle(
                          value: _onlyBalance,
                          onToggle: (value) {
                            setState(() {
                              _onlyBalance = value;
                            });
                          },
                        ),
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
                              'assets/images/loading.gif',
                              width: 52,
                              height: 52,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'h_loading...'.tr(),
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
                      text: 'scan_more'.tr(),
                      color: AppColor.white,
                      textColor: AppColor.primaryBlack,
                      borderColor: AppColor.primaryBlack,
                    ),
                    const SizedBox(height: 10),
                    PrimaryAsyncButton(
                      text: 'continue'.tr(),
                      enabled: _selectedAddresses.isNotEmpty,
                      onTap: () async {
                        await injector<AccountService>().addAddressPersona(
                            widget.payload.wallet.uuid, _selectedAddresses);
                        if (!context.mounted) {
                          return;
                        }
                        unawaited(Navigator.of(context).pushNamed(
                            AppRouter.nameAddressPersonaPage,
                            arguments:
                                NameAddressPersonaPayload(_selectedAddresses)));
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
        child: DecoratedBox(
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
              if (isImported)
                Text('imported_'.tr(),
                    style: theme.textTheme.ppMori400Black14.copyWith(
                      color: AppColor.disabledColor,
                    ))
              else
                Text(
                  addressInfo.getBalance(),
                  style:
                      theme.textTheme.ppMori400Black14.copyWith(color: color),
                )
            ],
          ),
        ),
      ),
    );
  }

  void _callBloc() {
    final wallet = widget.payload.wallet;
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
  final WalletStorage wallet;

  SelectAddressesPayload({required this.wallet});
}
