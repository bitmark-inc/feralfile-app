//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:math';

import 'package:autonomy_flutter/model/currency_exchange.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_state.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/fee_util.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/usdc_amount_formatter.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:autonomy_flutter/view/au_radio_button.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:libauk_dart/libauk_dart.dart';

class SendCryptoPage extends StatefulWidget {
  final SendData data;

  const SendCryptoPage({required this.data, super.key});

  @override
  State<SendCryptoPage> createState() => _SendCryptoPageState();
}

class _SendCryptoPageState extends State<SendCryptoPage> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _initialChangeAddress = false;
  late FeeOption _selectedPriority;
  final xtzFormatter = XtzAmountFormatter();
  final ethFormatter = EthAmountFormatter();
  final usdcFormatter = USDCAmountFormatter();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _selectedPriority = FeeOption.MEDIUM;

    if (widget.data.address != null) {
      _addressController.text = widget.data.address!;
    }

    context
        .read<SendCryptoBloc>()
        .add(GetBalanceEvent(widget.data.wallet, widget.data.index));
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _unFocus(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.data.type;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: _titleText(),
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: BlocBuilder<SendCryptoBloc, SendCryptoState>(
          builder: (context, state) => GestureDetector(
                behavior: HitTestBehavior.deferToChild,
                onTap: () {
                  _unFocus(context);
                },
                child: Container(
                  padding: ResponsiveLayout.pageEdgeInsetsWithSubmitButton,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              addTitleSpace(),
                              if (type == CryptoType.USDC) ...[
                                Text('please_verify_usdc_erc20'.tr(),
                                    style: theme.textTheme.headlineSmall),
                                const SizedBox(height: 8),
                              ],
                              Text(
                                'to'.tr(),
                                style: theme.textTheme.ppMori400Black14,
                              ),
                              const SizedBox(height: 4),
                              AuTextField(
                                labelSemantics:
                                    'address_send_${widget.data.type.code}',
                                title: '',
                                placeholder: 'paste_or_scan_address'.tr(),
                                isError: state.isAddressError,
                                controller: _addressController,
                                enableSuggestions: false,
                                suffix: IconButton(
                                  icon: Icon(
                                    state.isScanQR ? AuIcon.scan : AuIcon.close,
                                    color: AppColor.secondaryDimGrey,
                                  ),
                                  onPressed: () async {
                                    if (_addressController.text.isNotEmpty) {
                                      _addressController.text = '';
                                      _initialChangeAddress = true;
                                      context
                                          .read<SendCryptoBloc>()
                                          .add(AddressChangedEvent(''));
                                    } else {
                                      dynamic address =
                                          await Navigator.of(context).pushNamed(
                                        AppRouter.scanQRPage,
                                        arguments: ScanQRPagePayload(
                                          scannerItem: type == CryptoType.XTZ
                                              ? ScannerItem.XTZ_ADDRESS
                                              : ScannerItem.ETH_ADDRESS,
                                        ),
                                      );
                                      if (address != null &&
                                          address is String) {
                                        address = address.replacePrefix(
                                            'ethereum:', '');
                                        _addressController.text = address;
                                        if (!mounted) {
                                          return;
                                        }
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
                                  _timer?.cancel();
                                  _timer = Timer(
                                      const Duration(milliseconds: 500), () {
                                    context.read<SendCryptoBloc>().add(
                                        AddressChangedEvent(
                                            _addressController.text));
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'amount'.tr(),
                                    style: theme.textTheme.ppMori400Black14,
                                  ),
                                  if (state.maxAllow != null) ...[
                                    GestureDetector(
                                      child: RichText(
                                        textScaler:
                                            MediaQuery.textScalerOf(context),
                                        text: TextSpan(children: [
                                          TextSpan(
                                              text: '${'max'.tr()} ',
                                              style: theme
                                                  .textTheme.ppMori400Grey14),
                                          TextSpan(
                                              text: _maxAmountText(state),
                                              style: theme
                                                  .textTheme.ppMori400Grey14
                                                  .copyWith(
                                                      decoration: TextDecoration
                                                          .underline))
                                        ]),
                                      ),
                                      onTap: () {
                                        String amountInStr = _maxAmount(state);
                                        _amountController.text = amountInStr;
                                        context.read<SendCryptoBloc>().add(
                                            AmountChangedEvent(amountInStr));
                                      },
                                    )
                                  ]
                                ],
                              ),
                              const SizedBox(height: 4),
                              AuTextField(
                                labelSemantics:
                                    'amount_send_${widget.data.type.code}',
                                title: '',
                                placeholder:
                                    '''0.00 ${state.isCrypto ? widget.data.type.code : 'USD'}''',
                                isError: state.isAmountError,
                                controller: _amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                suffix: IconButton(
                                  icon: SvgPicture.asset(state.isCrypto
                                      ? _cryptoIconAsset()
                                      : 'assets/images/iconUsd.svg'),
                                  onPressed: () {
                                    if (type == CryptoType.USDC) {
                                      return;
                                    }

                                    double amount = double.tryParse(
                                            _amountController.text
                                                .replaceAll(',', '.')) ??
                                        0;
                                    if (amount != 0) {
                                      if (state.isCrypto) {
                                        if (type == CryptoType.ETH) {
                                          _amountController.text = state
                                              .exchangeRate
                                              .ethToUsd(BigInt.from(
                                                  amount * pow(10, 18)));
                                        } else if (type == CryptoType.XTZ) {
                                          _amountController.text = state
                                              .exchangeRate
                                              .xtzToUsd((amount * pow(10, 6))
                                                  .toInt());
                                        }
                                      } else {
                                        if (type == CryptoType.ETH) {
                                          _amountController
                                              .text = (double.parse(
                                                      state.exchangeRate.eth) *
                                                  amount)
                                              .toStringAsFixed(5);
                                        } else {
                                          _amountController
                                              .text = (double.parse(
                                                      state.exchangeRate.xtz) *
                                                  amount)
                                              .toStringAsFixed(6);
                                        }
                                      }
                                    }

                                    context.read<SendCryptoBloc>().add(
                                        CurrencyTypeChangedEvent(
                                            !state.isCrypto));
                                  },
                                ),
                                onChanged: (value) {
                                  _amountController
                                    ..text = _amountController.text
                                        .replaceAll(',', '.')
                                    ..selection = TextSelection.fromPosition(
                                        TextPosition(
                                            offset:
                                                _amountController.text.length));
                                  context.read<SendCryptoBloc>().add(
                                      AmountChangedEvent(
                                          _amountController.text));
                                },
                              ),
                              gasFeeStatus(state, theme),
                              const SizedBox(height: 8),
                              if (state.feeOptionValue != null)
                                feeTable(state, context),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              text: 'review'.tr(),
                              onTap: state.isValid
                                  ? () async {
                                      _unFocus(context);
                                      final payload = SendCryptoPayload(
                                          type,
                                          state.wallet!,
                                          state.index!,
                                          state.address!,
                                          state.amount!,
                                          state.fee!,
                                          state.exchangeRate,
                                          state.feeOption);
                                      final txPayload =
                                          await Navigator.of(context).pushNamed(
                                              AppRouter.sendReviewPage,
                                              arguments: payload) as Map?;
                                      if (txPayload != null &&
                                          txPayload['hash'] != null &&
                                          txPayload['hash'] is String) {
                                        if (!mounted) {
                                          return;
                                        }
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
              )),
    );
  }

  Widget gasFeeStatus(SendCryptoState state, ThemeData theme) {
    if (_initialChangeAddress && state.feeOptionValue == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text('gas_fee_calculating'.tr(),
            style: theme.textTheme.ppMori400Black12),
      );
    }
    if (state.feeOptionValue != null) {
      if (!(state.amount != null && state.amount! > BigInt.zero)) {
        return const SizedBox();
      }
      bool isValid = state.isValid &&
          !(widget.data.type == CryptoType.USDC &&
              state.fee != null &&
              state.ethBalance != null &&
              state.fee! > state.ethBalance!);
      if (!isValid) {
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('gas_fee_insufficient'.tr(),
              style: theme.textTheme.ppMori400Black12.copyWith(
                color: AppColor.red,
              )),
        );
      }
    }
    return const SizedBox();
  }

  Widget _editPriorityView(SendCryptoState state, BuildContext context,
      {required Function() onSave}) {
    final theme = Theme.of(context);
    final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
    return StatefulBuilder(
        builder: (context, setState) => Column(
              children: [
                Padding(
                  padding: padding,
                  child: getFeeRow(FeeOption.LOW, state, theme, setState),
                ),
                addDivider(color: AppColor.white),
                Padding(
                  padding: padding,
                  child: getFeeRow(FeeOption.MEDIUM, state, theme, setState),
                ),
                addDivider(color: AppColor.white),
                Padding(
                  padding: padding,
                  child: getFeeRow(FeeOption.HIGH, state, theme, setState),
                ),
                addDivider(color: AppColor.white),
                const SizedBox(height: 12),
                Padding(
                  padding: padding,
                  child: PrimaryButton(
                    text: 'save_priority'.tr(),
                    onTap: () {
                      onSave();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: padding,
                  child: OutlineButton(
                    text: 'cancel'.tr(),
                    onTap: () {
                      _selectedPriority = state.feeOption;
                      Navigator.of(context).pop();
                    },
                  ),
                )
              ],
            ));
  }

  Widget feeTable(SendCryptoState state, BuildContext context) {
    final theme = Theme.of(context);
    final feeOption = state.feeOption;
    return Row(
      children: [
        Text('gas_fee'.tr(), style: theme.textTheme.ppMori400Black12),
        const SizedBox(width: 8),
        Text(feeOption.name, style: theme.textTheme.ppMori400Black12),
        const Spacer(),
        Text(_gasFee(state), style: theme.textTheme.ppMori400Black12),
        const SizedBox(
          width: 24,
        ),
        GestureDetector(
          onTap: () {
            unawaited(UIHelper.showDialog(
                context,
                'edit_priority'.tr().capitalize(),
                _editPriorityView(state, context, onSave: () {
                  context.read<SendCryptoBloc>().add(FeeOptionChangedEvent(
                      _selectedPriority, state.address ?? ''));
                }),
                backgroundColor: AppColor.auGreyBackground,
                padding: const EdgeInsets.symmetric(vertical: 32),
                paddingTitle: ResponsiveLayout.pageHorizontalEdgeInsets));
            _unFocus(context);
          },
          child: Text('edit_priority'.tr(),
              style: theme.textTheme.linkStyle
                  .copyWith(fontWeight: FontWeight.w400, fontSize: 12)),
        ),
      ],
    );
  }

  Widget getFeeRow(FeeOption feeOption, SendCryptoState state, ThemeData theme,
      StateSetter setState) {
    final textStyle = theme.textTheme.ppMori400White14;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPriority = feeOption;
        });
      },
      child: Container(
        color: Colors.transparent,
        child: Row(
          children: [
            Text(feeOption.name, style: textStyle),
            const Spacer(),
            Text(_gasFee(state, feeOption: feeOption), style: textStyle),
            const SizedBox(width: 56),
            AuRadio(
              onTap: (FeeOption value) {
                setState(() {
                  _selectedPriority = feeOption;
                });
              },
              value: feeOption,
              groupValue: _selectedPriority,
              color: AppColor.white,
            ),
          ],
        ),
      ),
    );
  }

  String _titleText() {
    switch (widget.data.type) {
      case CryptoType.ETH:
        return 'send_eth'.tr();
      case CryptoType.XTZ:
        return 'send_xtz'.tr();
      case CryptoType.USDC:
        return 'send_usdc'.tr();
      default:
        return '';
    }
  }

  String _cryptoIconAsset() {
    switch (widget.data.type) {
      case CryptoType.ETH:
        return 'assets/images/iconEth.svg';
      case CryptoType.XTZ:
        return 'assets/images/tez.svg';
      default:
        return 'assets/images/iconUsdc.svg';
    }
  }

  String _maxAmountText(SendCryptoState state) {
    if (state.maxAllow == null) {
      return '';
    }
    final max = state.maxAllow!;

    String text = '';

    switch (widget.data.type) {
      case CryptoType.ETH:
        text = state.isCrypto
            ? '${ethFormatter.format(max)} ETH'
            : '${state.exchangeRate.ethToUsd(max)} USD';
        break;
      case CryptoType.XTZ:
        text = state.isCrypto
            ? '${xtzFormatter.format(max.toInt())} XTZ'
            : '${state.exchangeRate.xtzToUsd(max.toInt())} USD';
        break;
      case CryptoType.USDC:
        text = '${usdcFormatter.format(max)} USDC';
        break;
      default:
        break;
    }
    return text;
  }

  String _maxAmount(SendCryptoState state) {
    if (state.maxAllow == null) {
      return '';
    }
    final max = state.maxAllow!;

    switch (widget.data.type) {
      case CryptoType.ETH:
        return state.isCrypto
            ? ethFormatter.format(max)
            : state.exchangeRate.ethToUsd(max);
      case CryptoType.XTZ:
        return state.isCrypto
            ? xtzFormatter.format(max.toInt())
            : state.exchangeRate.xtzToUsd(max.toInt());
      case CryptoType.USDC:
        return usdcFormatter.format(max);
      default:
        return '';
    }
  }

  String _gasFee(SendCryptoState state, {FeeOption? feeOption}) {
    if (state.feeOptionValue == null) {
      return widget.data.type.code;
    }
    final ethFormatter = EthAmountFormatter(digit: 7);
    final fee = state.feeOptionValue!.getFee(feeOption ?? state.feeOption);
    switch (widget.data.type) {
      case CryptoType.ETH:
        return state.isCrypto
            ? '''${ethFormatter.format(fee)} ETH (${state.exchangeRate.ethToUsd(fee)} USD)'''
            : '${state.exchangeRate.ethToUsd(fee)} USD';
      case CryptoType.XTZ:
        return state.isCrypto
            ? '''${xtzFormatter.format(fee.toInt())} XTZ (${state.exchangeRate.xtzToUsd(fee.toInt())} USD)'''
            : '${state.exchangeRate.xtzToUsd(fee.toInt())} USD';
      case CryptoType.USDC:
        return '''${ethFormatter.format(fee)} ETH (${state.exchangeRate.ethToUsd(fee)} USD)''';
      default:
        return '';
    }
  }
}

class SendData {
  final WalletStorage wallet;
  final CryptoType type;
  final String? address;
  final int index;

  SendData(this.wallet, this.type, this.address, this.index);
}

class SendCryptoPayload {
  final CryptoType type;
  final WalletStorage wallet;
  final int index;
  final String address;
  final BigInt amount;
  final BigInt fee;
  final CurrencyExchangeRate exchangeRate;
  final FeeOption feeOption;

  SendCryptoPayload(this.type, this.wallet, this.index, this.address,
      this.amount, this.fee, this.exchangeRate, this.feeOption);
}
