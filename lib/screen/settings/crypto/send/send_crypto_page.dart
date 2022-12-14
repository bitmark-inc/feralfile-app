//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:math';

import 'package:autonomy_flutter/model/currency_exchange.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_state.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_review_page.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/fee_util.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/usdc_amount_formatter.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:libauk_dart/libauk_dart.dart';

class SendCryptoPage extends StatefulWidget {
  static const String tag = 'send_crypto';

  final SendData data;

  const SendCryptoPage({Key? key, required this.data}) : super(key: key);

  @override
  State<SendCryptoPage> createState() => _SendCryptoPageState();
}

class _SendCryptoPageState extends State<SendCryptoPage> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _showAllFeeOption = false;
  bool _initialChangeAddress = false;

  @override
  void initState() {
    super.initState();

    if (widget.data.address != null) {
      _addressController.text = widget.data.address!;
    }

    context.read<SendCryptoBloc>().add(GetBalanceEvent(widget.data.wallet));
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.data.type;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: BlocBuilder<SendCryptoBloc, SendCryptoState>(
          builder: (context, state) {
        return Container(
          margin: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleText(),
                  style: theme.textTheme.headline1,
                ),
                const SizedBox(height: 40.0),
                if (type == CryptoType.USDC) ...[
                  Text("please_verify_usdc_erc20".tr(),
                      style: theme.textTheme.headline5),
                  const SizedBox(height: 8),
                ],
                AuTextField(
                  title: "to".tr(),
                  placeholder: "paste_or_scan_address".tr(),
                  isError: state.isAddressError,
                  controller: _addressController,
                  suffix: IconButton(
                    icon: SvgPicture.asset(state.isScanQR
                        ? "assets/images/iconQr.svg"
                        : "assets/images/iconClose.svg"),
                    onPressed: () async {
                      if (_addressController.text.isNotEmpty) {
                        _addressController.text = "";
                        _initialChangeAddress = true;
                        context
                            .read<SendCryptoBloc>()
                            .add(AddressChangedEvent(""));
                      } else {
                        dynamic address = await Navigator.of(context).pushNamed(
                            ScanQRPage.tag,
                            arguments: type == CryptoType.XTZ
                                ? ScannerItem.XTZ_ADDRESS
                                : ScannerItem.ETH_ADDRESS);
                        if (address != null && address is String) {
                          address = address.replacePrefix("ethereum:", "");
                          _addressController.text = address;
                          if (!mounted) return;
                          _initialChangeAddress = true;
                          context
                              .read<SendCryptoBloc>()
                              .add(AddressChangedEvent(address));
                        }
                      }
                    },
                  ),
                  onChanged: (value) {
                    _initialChangeAddress = true;
                    context
                        .read<SendCryptoBloc>()
                        .add(AddressChangedEvent(_addressController.text));
                  },
                ),
                const SizedBox(height: 16.0),
                AuTextField(
                  title: "send".tr(),
                  placeholder: "0",
                  isError: state.isAmountError,
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  subTitleView: state.maxAllow != null
                      ? GestureDetector(
                          child: Text(
                            _maxAmountText(state),
                            style: ResponsiveLayout.isMobile
                                ? theme.textTheme.atlasGreyUnderline12
                                : theme.textTheme.atlasGreyUnderline14,
                          ),
                          onTap: () {
                            String amountInStr = _maxAmount(state);
                            _amountController.text = amountInStr;
                            context
                                .read<SendCryptoBloc>()
                                .add(AmountChangedEvent(amountInStr));
                          },
                        )
                      : null,
                  suffix: IconButton(
                    icon: SvgPicture.asset(state.isCrypto
                        ? _cryptoIconAsset()
                        : "assets/images/iconUsd.svg"),
                    onPressed: () {
                      if (type == CryptoType.USDC) return;

                      double amount = double.tryParse(
                              _amountController.text.replaceAll(",", ".")) ??
                          0;
                      if (state.isCrypto) {
                        if (type == CryptoType.ETH) {
                          _amountController.text = state.exchangeRate
                              .ethToUsd(BigInt.from(amount * pow(10, 18)));
                        } else if (type == CryptoType.XTZ) {
                          _amountController.text = state.exchangeRate
                              .xtzToUsd((amount * pow(10, 6)).toInt());
                        }
                      } else {
                        if (type == CryptoType.ETH) {
                          _amountController.text =
                              (double.parse(state.exchangeRate.eth) * amount)
                                  .toStringAsFixed(5);
                        } else {
                          _amountController.text =
                              (double.parse(state.exchangeRate.xtz) * amount)
                                  .toStringAsFixed(6);
                        }
                      }

                      context
                          .read<SendCryptoBloc>()
                          .add(CurrencyTypeChangedEvent(!state.isCrypto));
                    },
                  ),
                  onChanged: (value) {
                    context.read<SendCryptoBloc>().add(AmountChangedEvent(
                        _amountController.text.replaceAll(",", ".")));
                  },
                ),
                const SizedBox(height: 16.0),
                gasFeeStatus(state, theme),
                const SizedBox(height: 10.0),
                if (state.feeOptionValue != null) feeTable(state, context),
                const SizedBox(height: 24.0),
                // Expanded(child: SizedBox()),
                Row(
                  children: [
                    Expanded(
                      child: AuFilledButton(
                        text: "review".tr(),
                        onPress: state.isValid
                            ? () async {
                                final payload = SendCryptoPayload(
                                    type,
                                    state.wallet!,
                                    state.address!,
                                    state.amount!,
                                    state.fee!,
                                    state.exchangeRate,
                                    state.feeOption);
                                final txPayload = await Navigator.of(context)
                                    .pushNamed(SendReviewPage.tag,
                                        arguments: payload) as Map?;
                                if (txPayload != null &&
                                    txPayload["hash"] != null &&
                                    txPayload["hash"] is String) {
                                  if (!mounted) return;
                                  Navigator.of(context).pop(txPayload);
                                }
                              }
                            : null,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget gasFeeStatus(SendCryptoState state, ThemeData theme) {
    if (_initialChangeAddress && state.feeOptionValue == null) {
      return Text("gas_fee_calculating".tr(), style: theme.textTheme.headline5);
    }
    if (state.feeOptionValue != null) {
      if (!(state.amount != null && state.amount! > BigInt.zero)) {
        return Text("gas_fee".tr(), style: theme.textTheme.headline5);
      }
      bool isValid = state.isValid &&
          !(widget.data.type == CryptoType.USDC &&
              state.fee != null &&
              state.ethBalance != null &&
              state.fee! > state.ethBalance!);
      if (isValid) {
        return Text("gas_fee".tr(), style: theme.textTheme.headline5);
      } else {
        return Text("gas_fee_insufficient".tr(),
            style: theme.textTheme.headline5?.copyWith(
              color: AppColor.red,
            ));
      }
    }
    return const SizedBox();
  }

  Widget feeTable(SendCryptoState state, BuildContext context) {
    final theme = Theme.of(context);
    final feeOption = state.feeOption;
    if (!_showAllFeeOption) {
      return Row(
        children: [
          Text(feeOption.name, style: theme.textTheme.atlasBlackBold12),
          const Spacer(),
          Text(_gasFee(state), style: theme.textTheme.atlasBlackBold12),
          const SizedBox(width: 56),
          GestureDetector(
            onTap: () {
              setState(() {
                _showAllFeeOption = true;
              });
            },
            child: Text("edit_priority".tr(),
                style: theme.textTheme.linkStyle
                    .copyWith(fontWeight: FontWeight.w400, fontSize: 12)),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          getFeeRow(FeeOption.LOW, state, theme),
          const SizedBox(height: 8),
          getFeeRow(FeeOption.MEDIUM, state, theme),
          const SizedBox(height: 8),
          getFeeRow(FeeOption.HIGH, state, theme),
        ],
      );
    }
  }

  Widget getFeeRow(
      FeeOption feeOption, SendCryptoState state, ThemeData theme) {
    final isSelected = feeOption == state.feeOption;
    final textStyle = isSelected
        ? theme.textTheme.atlasBlackBold12
        : theme.textTheme.atlasBlackNormal12;
    return Row(
      children: [
        Text(feeOption.name, style: textStyle),
        const Spacer(),
        Text(_gasFee(state, feeOption: feeOption), style: textStyle),
        const SizedBox(width: 56),
        GestureDetector(
          onTap: () {
            context
                .read<SendCryptoBloc>()
                .add(FeeOptionChangedEvent(feeOption, state.address ?? ""));
          },
          child: SvgPicture.asset(isSelected
              ? "assets/images/radio_btn_selected.svg"
              : "assets/images/radio_btn_not_selected.svg"),
        ),
      ],
    );
  }

  String _titleText() {
    switch (widget.data.type) {
      case CryptoType.ETH:
        return "send_eth".tr();
      case CryptoType.XTZ:
        return "send_xtz".tr();
      case CryptoType.USDC:
        return "send_usdc".tr();
      default:
        return "";
    }
  }

  String _cryptoIconAsset() {
    switch (widget.data.type) {
      case CryptoType.ETH:
        return "assets/images/iconEth.svg";
      case CryptoType.XTZ:
        return "assets/images/iconXtz.svg";
      default:
        return "assets/images/iconUsdc.svg";
    }
  }

  String _maxAmountText(SendCryptoState state) {
    if (state.maxAllow == null) return "";
    final max = state.maxAllow!;

    String text = "max".tr();

    switch (widget.data.type) {
      case CryptoType.ETH:
        text += state.isCrypto
            ? "${EthAmountFormatter(max).format()} ETH"
            : "${state.exchangeRate.ethToUsd(max)} USD";
        break;
      case CryptoType.XTZ:
        text += state.isCrypto
            ? "${XtzAmountFormatter(max.toInt()).format()} XTZ"
            : "${state.exchangeRate.xtzToUsd(max.toInt())} USD";
        break;
      case CryptoType.USDC:
        text += "${USDCAmountFormatter(max).format()} USDC";
        break;
      default:
        break;
    }
    return text;
  }

  String _maxAmount(SendCryptoState state) {
    if (state.maxAllow == null) return "";
    final max = state.maxAllow!;

    switch (widget.data.type) {
      case CryptoType.ETH:
        return state.isCrypto
            ? EthAmountFormatter(max).format()
            : state.exchangeRate.ethToUsd(max);
      case CryptoType.XTZ:
        return state.isCrypto
            ? XtzAmountFormatter(max.toInt()).format()
            : state.exchangeRate.xtzToUsd(max.toInt());
      case CryptoType.USDC:
        return USDCAmountFormatter(max).format();
      default:
        return "";
    }
  }

  String _gasFee(SendCryptoState state, {FeeOption? feeOption}) {
    if (state.feeOptionValue == null) return widget.data.type.code;
    final fee = state.feeOptionValue!.getFee(feeOption ?? state.feeOption);
    switch (widget.data.type) {
      case CryptoType.ETH:
        return state.isCrypto
            ? "${EthAmountFormatter(fee, digit: 7).format()} ETH"
            : "${state.exchangeRate.ethToUsd(fee)} USD";
      case CryptoType.XTZ:
        return state.isCrypto
            ? "${XtzAmountFormatter(fee.toInt()).format()} XTZ"
            : "${state.exchangeRate.xtzToUsd(fee.toInt())} USD";
      case CryptoType.USDC:
        return "${EthAmountFormatter(fee, digit: 7).format()} ETH (${state.exchangeRate.ethToUsd(fee)} USD)";
      default:
        return "";
    }
  }
}

class SendData {
  final WalletStorage wallet;
  final CryptoType type;
  final String? address;

  SendData(this.wallet, this.type, this.address);
}

class SendCryptoPayload {
  final CryptoType type;
  final WalletStorage wallet;
  final String address;
  final BigInt amount;
  final BigInt fee;
  final CurrencyExchangeRate exchangeRate;
  final FeeOption feeOption;

  SendCryptoPayload(this.type, this.wallet, this.address, this.amount, this.fee,
      this.exchangeRate, this.feeOption);
}
