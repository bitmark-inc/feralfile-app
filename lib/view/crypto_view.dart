import 'package:autonomy_flutter/screen/bloc/scan_wallet/scan_wallet_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/scan_wallet/scan_wallet_state.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/radio_check_box.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:libauk_dart/libauk_dart.dart';

class AddAddressToWallet extends StatefulWidget {
  final List<AddressInfo> addresses;
  final List<String> importedAddress;
  final bool scanNext;
  final Function(List<AddressInfo> addesses)? onImport;
  final WalletType walletType;
  final WalletStorage wallet;
  final Function? onSkip;

  const AddAddressToWallet(
      {Key? key,
      required this.addresses,
      required this.importedAddress,
      this.scanNext = true,
      this.onImport,
      required this.walletType,
      required this.wallet,
      this.onSkip})
      : super(key: key);

  @override
  State<AddAddressToWallet> createState() => _AddAddressToWalletState();
}

class _AddAddressToWalletState extends State<AddAddressToWallet> {
  List<AddressInfo> addresses = [];
  List<AddressInfo> selectedAddresses = [];
  int index = 0;

  @override
  void initState() {
    super.initState();
    addresses = widget.addresses;
    if (addresses.isEmpty) _callBloc(false);
  }

  @override
  void dispose() {
    addresses = [];
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<ScanWalletBloc, ScanWalletState>(
        listener: (context, scanState) {
      if (scanState.addresses.isNotEmpty && !scanState.isScanning) {
        setState(() {
          addresses = scanState.addresses;
        });
      }
    }, builder: (context, scanState) {
      final scanningNext = addresses.isNotEmpty && scanState.isScanning;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("select_addresses".tr(),
                      style: theme.primaryTextTheme.ppMori700White24),
                  const SizedBox(height: 40),
                  Text(
                    "choose_addresses".tr(),
                    style: theme.textTheme.ppMori400White14,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: addresses.isEmpty && scanState.isScanning
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/images/loading_white_tran.gif",
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
                        children: addresses
                            .map((address) => [
                                  _addressOption(
                                      addressInfo: address,
                                      isImported: widget.importedAddress
                                          .contains(address.address)),
                                  addDivider(height: 1, color: AppColor.white),
                                ])
                            .flattened
                            .toList(),
                      ),
                    ),
            ),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: Column(children: [
                if (widget.scanNext && addresses.isNotEmpty) ...[
                  OutlineButton(
                    enabled: !scanState.isScanning,
                    isProcessing: scanningNext,
                    text: scanningNext
                        ? "scanning_addresses".tr()
                        : "scan_next".tr(),
                    onTap: () {
                      _callBloc(true);
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                PrimaryButton(
                  text: "select".tr(),
                  onTap: selectedAddresses.isNotEmpty
                      ? () {
                          widget.onImport?.call(selectedAddresses);
                          Navigator.pop(context);
                        }
                      : null,
                ),
                if (widget.onSkip != null) ...[
                  const SizedBox(height: 10),
                  OutlineButton(
                    text: "skip".tr(),
                    onTap: () {
                      widget.onSkip?.call();
                    },
                  ),
                ]
              ]),
            )
          ],
        ),
      );
    });
  }

  void _callBloc(bool isAdd) {
    switch (widget.walletType) {
      case WalletType.Ethereum:
        context.read<ScanWalletBloc>().add(ScanEthereumWalletEvent(
            wallet: widget.wallet, startIndex: index, isAdd: isAdd));
        break;
      case WalletType.Tezos:
        context.read<ScanWalletBloc>().add(ScanTezosWalletEvent(
            wallet: widget.wallet, startIndex: index, isAdd: isAdd));
        break;
      default:
        context.read<ScanWalletBloc>().add(ScanEthereumWalletEvent(
            wallet: widget.wallet, startIndex: index, isAdd: isAdd));

        context.read<ScanWalletBloc>().add(ScanTezosWalletEvent(
            wallet: widget.wallet, startIndex: index, isAdd: isAdd));
    }
    index += 5;
  }

  Widget _addressOption(
      {required AddressInfo addressInfo, bool isImported = false}) {
    final theme = Theme.of(context);
    final color = isImported ? AppColor.disabledColor : AppColor.white;
    return Padding(
      padding: const EdgeInsets.all(15),
      child: GestureDetector(
        onTap: isImported
            ? null
            : () {
                setState(() {
                  if (selectedAddresses.contains(addressInfo)) {
                    selectedAddresses.remove(addressInfo);
                  } else {
                    selectedAddresses.add(addressInfo);
                  }
                });
              },
        child: Container(
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Row(
            children: [
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
                    style: theme.textTheme.ppMori400White14.copyWith(
                      color: color,
                    ),
                  ),
                  Text(addressInfo.address.maskOnly(5),
                      style: theme.textTheme.ppMori400White14.copyWith(
                        color: color,
                      ),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
              const Spacer(),
              isImported
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        side: const BorderSide(
                          color: AppColor.disabledColor,
                        ),
                        alignment: Alignment.center,
                      ),
                      onPressed: () {},
                      child: Text(
                        "imported_".tr(),
                        style: theme.textTheme.ppMori400White14.copyWith(
                          color: AppColor.disabledColor,
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Text(
                          addressInfo.getBalance(),
                          style: theme.textTheme.ppMori400White14
                              .copyWith(color: color),
                        ),
                        const SizedBox(width: 20),
                        RadioSelectAddress(
                          isChecked: selectedAddresses.contains(addressInfo),
                          checkColor: AppColor.white,
                          borderColor: AppColor.white,
                        ),
                      ],
                    )
            ],
          ),
        ),
      ),
    );
  }
}

class LogoCrypto extends StatelessWidget {
  final CryptoType? cryptoType;
  final double? size;

  const LogoCrypto({Key? key, this.cryptoType, this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (cryptoType) {
      case CryptoType.ETH:
        return SvgPicture.asset(
          'assets/images/ether.svg',
          width: size,
          height: size,
        );
      case CryptoType.XTZ:
        return SvgPicture.asset(
          "assets/images/tez.svg",
          width: size,
          height: size,
        );
      case CryptoType.USDC:
        return SvgPicture.asset(
          'assets/images/usdc.svg',
          width: size,
          height: size,
        );
      default:
        return Container();
    }
  }
}
