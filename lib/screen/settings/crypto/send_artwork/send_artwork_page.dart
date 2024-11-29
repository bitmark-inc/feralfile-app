//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_review_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_artwork/send_artwork_state.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/fee_util.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/au_radio_button.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:url_launcher/url_launcher.dart';

class SendArtworkPage extends StatefulWidget {
  final SendArtworkPayload payload;

  const SendArtworkPage({required this.payload, super.key});

  @override
  State<SendArtworkPage> createState() => _SendArtworkPageState();
}

class _SendArtworkPageState extends State<SendArtworkPage> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final feeWidgetKey = GlobalKey();
  final xtzFormatter = XtzAmountFormatter();

  late int index;
  bool _initialChangeAddress = false;
  final _focusNode = FocusNode();
  late FeeOption _selectedPriority;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    index = widget.payload.index;
    context
        .read<SendArtworkBloc>()
        .add(GetBalanceEvent(widget.payload.wallet, index));
    _selectedPriority = context.read<SendArtworkBloc>().state.feeOption;

    context.read<SendArtworkBloc>().add(QuantityUpdateEvent(
        quantity: 1, maxQuantity: widget.payload.ownedQuantity, index: index));
    if (widget.payload.ownedQuantity == 1) {
      _quantityController.text = '1';
    }
    if (widget.payload.asset.artistName != null) {
      context
          .read<IdentityBloc>()
          .add(GetIdentityEvent([widget.payload.asset.artistName!]));
    }

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _onQuantityUpdated();
      }
    });
  }

  int get _quantity => int.tryParse(_quantityController.text) ?? 0;

  void _onQuantityUpdated() {
    context.read<SendArtworkBloc>().add(QuantityUpdateEvent(
        quantity: _quantity,
        maxQuantity: widget.payload.ownedQuantity,
        index: index));
  }

  void _unfocus() {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  Widget _quantityInputField(
          {required int maxQuantity, required bool hasError}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuTextField(
            labelSemantics: 'quantity_send_artwork',
            title: '',
            placeholder:
                'enter_a_number_'.tr(args: ['1', maxQuantity.toString()]),
            controller: _quantityController,
            isError: hasError,
            keyboardType: TextInputType.number,
            onChanged: (value) => _onQuantityUpdated(),
            onSubmit: (value) => _onQuantityUpdated(),
          ),
        ],
      );

  @override
  void dispose() {
    _focusNode.dispose();
    _quantityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asset = widget.payload.asset;
    final maxQuantity = widget.payload.ownedQuantity;
    final divider = addDivider(height: 20);
    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: 'send_artwork'.tr(),
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Stack(
        children: [
          BlocConsumer<SendArtworkBloc, SendArtworkState>(
              listener: (context, state) {
                if (state.fee != null && feeWidgetKey.currentContext != null) {
                  unawaited(
                      Scrollable.ensureVisible(feeWidgetKey.currentContext!));
                }
                if (state.fee != null &&
                    state.balance != null &&
                    state.fee! > state.balance! + BigInt.from(10)) {
                  unawaited(UIHelper.showMessageAction(
                    context,
                    'transaction_failed'.tr(),
                    'dont_enough_money'.tr(),
                  ));
                }
              },
              builder: (context, state) => GestureDetector(
                    behavior: HitTestBehavior.deferToChild,
                    onTap: () {
                      _unfocus();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(
                        top: 16,
                        left: 16,
                        right: 16,
                        bottom: 40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  _artworkView(context),
                                  const SizedBox(height: 20),
                                  _item(
                                      context: context,
                                      title: 'token'.tr(),
                                      content: polishSource(asset.source ?? ''),
                                      tapLink: asset.assetURL),
                                  divider,
                                  _item(
                                    context: context,
                                    title: 'contract'.tr(),
                                    content: asset.blockchain.capitalize(),
                                    tapLink: asset.getBlockchainUrl(),
                                  ),
                                  divider,
                                  _item(
                                      context: context,
                                      title: 'minted'.tr(),
                                      content: asset.mintedAt != null
                                          ? localTimeString(asset.mintedAt!)
                                          : ''),
                                  divider,
                                  if (widget.payload.asset.fungible) ...[
                                    _item(
                                        context: context,
                                        title: 'owned_tokens'.tr(),
                                        content: '$maxQuantity'),
                                    divider,
                                    const SizedBox(height: 16),
                                    Text(
                                      'quantity_to_send'.tr(),
                                      style: theme.textTheme.ppMori400Black14,
                                    ),
                                    const SizedBox(height: 8),
                                    _quantityInputField(
                                        maxQuantity: maxQuantity,
                                        hasError: state.isQuantityError),
                                    if (state.isQuantityError) ...[
                                      const SizedBox(height: 8),
                                      if (_quantity < 1)
                                        Text(
                                          '${'minimum_1'.tr()} ',
                                          style: theme
                                              .textTheme.ppMori400Black12
                                              .copyWith(color: AppColor.red),
                                        ),
                                      if (_quantity > maxQuantity)
                                        Text(
                                          'maximum_'.tr(
                                              args: [maxQuantity.toString()]),
                                          style: theme
                                              .textTheme.ppMori400Black12
                                              .copyWith(color: AppColor.red),
                                        ),
                                    ]
                                  ],
                                  const SizedBox(height: 16),
                                  Text(
                                    'to'.tr(),
                                    style: theme.textTheme.ppMori400Black14,
                                  ),
                                  const SizedBox(height: 8),
                                  AuTextField(
                                    labelSemantics: 'to_address_send_artwork',
                                    title: '',
                                    placeholder: 'paste_or_scan_address'.tr(),
                                    controller: _addressController,
                                    isError: state.isAddressError,
                                    enableSuggestions: false,
                                    suffix: IconButton(
                                      icon: Icon(
                                        state.isScanQR
                                            ? AuIcon.scan
                                            : AuIcon.close,
                                        color: AppColor.secondaryDimGrey,
                                      ),
                                      onPressed: () async {
                                        if (_addressController
                                            .text.isNotEmpty) {
                                          _addressController.text = '';
                                          context.read<SendArtworkBloc>().add(
                                              AddressChangedEvent('', index));
                                          _initialChangeAddress = true;
                                        } else {
                                          dynamic address =
                                              await Navigator.of(context)
                                                  .pushNamed(
                                            AppRouter.scanQRPage,
                                            arguments: ScanQRPagePayload(
                                              scannerItem:
                                                  asset.blockchain == 'ethereum'
                                                      ? ScannerItem.ETH_ADDRESS
                                                      : ScannerItem.XTZ_ADDRESS,
                                            ),
                                          );
                                          if (address != null &&
                                              address is String) {
                                            address = address.replacePrefix(
                                                'ethereum:', '');
                                            _addressController.text = address;
                                            if (!context.mounted) {
                                              return;
                                            }
                                            context.read<SendArtworkBloc>().add(
                                                AddressChangedEvent(
                                                    address, index));
                                            _initialChangeAddress = true;
                                          }
                                        }
                                      },
                                    ),
                                    onSubmit: (value) {
                                      if (value != state.address) {
                                        context.read<SendArtworkBloc>().add(
                                              AddressChangedEvent(
                                                  _addressController.text,
                                                  index),
                                            );
                                        _initialChangeAddress = true;
                                      }
                                    },
                                    onChanged: (value) {
                                      _initialChangeAddress = true;
                                      _timer?.cancel();
                                      _timer = Timer(
                                          const Duration(milliseconds: 500),
                                          () {
                                        context.read<SendArtworkBloc>().add(
                                              AddressChangedEvent(
                                                  _addressController.text,
                                                  index),
                                            );
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Visibility(
                                      visible: state.isAddressError,
                                      child: Text(
                                        'error_invalid_address'.tr(),
                                        style: theme.textTheme.ppMori400Black12
                                            .copyWith(color: AppColor.red),
                                      )),
                                  Visibility(
                                    visible: !state.isAddressError,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        gasFeeStatus(state, theme),
                                        const SizedBox(height: 8),
                                        if (state.feeOptionValue != null)
                                          feeTable(state, context),
                                        const SizedBox(height: 24),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _reviewButton(asset, state)
                        ],
                      ),
                    ),
                  )),
        ],
      ),
    );
  }

  Widget _reviewButton(AssetToken asset, SendArtworkState state) => Row(
        children: [
          Expanded(
            child: PrimaryButton(
              text: 'review'.tr(),
              onTap: state.isValid
                  ? () async {
                      _unfocus();
                      final payload = await Navigator.of(context).pushNamed(
                          AppRouter.sendArtworkReviewPage,
                          arguments: SendArtworkReviewPayload(
                              asset,
                              widget.payload.wallet,
                              widget.payload.index,
                              state.address!,
                              state.fee!,
                              state.exchangeRate,
                              widget.payload.ownedQuantity,
                              state.quantity,
                              state.feeOption,
                              state.feeOptionValue!)) as Map?;
                      if (payload != null &&
                          payload['hash'] != null &&
                          payload['hash'] is String) {
                        if (!mounted) {
                          return;
                        }
                        Navigator.of(context).pop(payload);
                      }
                    }
                  : null,
            ),
          ),
        ],
      );

  Widget _item({
    required BuildContext context,
    required String title,
    required String content,
    String? tapLink,
    double width = 120,
    bool forceSafariVC = true,
  }) {
    final theme = Theme.of(context);
    Function()? onValueTap;

    if (tapLink != null) {
      final uri = Uri.parse(tapLink);
      onValueTap = () => unawaited(launchUrl(uri,
          mode: forceSafariVC
              ? LaunchMode.externalApplication
              : LaunchMode.platformDefault));
    }
    return Row(
      children: [
        SizedBox(
          width: width,
          child: Text(
            title,
            style: theme.textTheme.ppMori400Grey14,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: onValueTap,
          child: Text(
            content,
            style: theme.textTheme.ppMori400Black14.copyWith(
              decoration:
                  (onValueTap != null) ? TextDecoration.underline : null,
              decorationColor: AppColor.primaryBlack,
            ),
          ),
        )
      ],
    );
  }

  Widget gasFeeStatus(SendArtworkState state, ThemeData theme) {
    if (_initialChangeAddress && state.feeOptionValue == null) {
      return Text('gas_fee_calculating'.tr(),
          style: theme.textTheme.ppMori400Black12);
    }
    if (state.feeOptionValue != null && state.balance != null) {
      bool isValid = state.balance! >
          state.feeOptionValue!.getFee(state.feeOption) + BigInt.from(10);
      if (!isValid) {
        return Text(
          'gas_fee_insufficient'.tr(),
          textAlign: TextAlign.start,
          style: theme.textTheme.ppMori400Black12.copyWith(color: AppColor.red),
        );
      }
    }
    return const SizedBox();
  }

  Widget feeTable(SendArtworkState state, BuildContext context) {
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
                context
                    .read<SendArtworkBloc>()
                    .add(FeeOptionChangedEvent(_selectedPriority));
              }),
              backgroundColor: AppColor.auGreyBackground,
              padding: const EdgeInsets.symmetric(vertical: 32),
              paddingTitle: ResponsiveLayout.pageHorizontalEdgeInsets,
            ));
          },
          child: Text('edit_priority'.tr(),
              style: theme.textTheme.linkStyle
                  .copyWith(fontWeight: FontWeight.w400, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _editPriorityView(SendArtworkState state, BuildContext context,
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

  Widget getFeeRow(FeeOption feeOption, SendArtworkState state, ThemeData theme,
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

  String _gasFee(SendArtworkState state, {FeeOption? feeOption}) {
    final type = widget.payload.asset.blockchain == 'ethereum'
        ? CryptoType.ETH
        : CryptoType.XTZ;
    if (state.feeOptionValue == null) {
      return type.code;
    }
    final ethFormatter = EthAmountFormatter(digit: 7);
    final fee = state.feeOptionValue!.getFee(feeOption ?? state.feeOption);
    switch (type) {
      case CryptoType.ETH:
        return '${ethFormatter.format(fee)} ETH '
            '(${state.exchangeRate.ethToUsd(fee)} USD)';
      case CryptoType.XTZ:
        return '${xtzFormatter.format(fee.toInt())} XTZ '
            '(${state.exchangeRate.xtzToUsd(fee.toInt())} USD)';
      default:
        return '';
    }
  }

  Widget _artworkView(BuildContext context) {
    final title = widget.payload.asset.displayTitle;
    final theme = Theme.of(context);
    final asset = widget.payload.asset;

    final identityState = context.watch<IdentityBloc>().state;
    final artistName =
        asset.artistName?.toIdentityOrMask(identityState.identityMap);
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5), color: AppColor.primaryBlack),
      child: Row(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: tokenGalleryThumbnailWidget(
              context,
              CompactedAssetToken.fromAssetToken(widget.payload.asset),
              500,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? '',
                  style: theme.textTheme.ppMori400White16,
                ),
                const SizedBox(height: 8),
                RichText(
                  textScaler: MediaQuery.textScalerOf(context),
                  text: TextSpan(
                    style: theme.textTheme.ppMori400White14,
                    children: [
                      TextSpan(text: 'by'.tr(args: [artistName ?? ''])),
                    ],
                  ),
                ),
                if (asset.maxEdition == -1) ...[
                  const SizedBox(height: 8),
                  Text(
                    asset.editionName ?? '',
                    style: theme.textTheme.ppMori400Grey14,
                  ),
                ]
              ],
            ),
          )
        ],
      ),
    );
  }
}

class SendArtworkPayload {
  final AssetToken asset;
  final WalletStorage wallet;
  final int index;
  final int ownedQuantity;

  SendArtworkPayload(this.asset, this.wallet, this.index, this.ownedQuantity);
}
