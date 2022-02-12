import 'dart:math';

import 'package:autonomy_flutter/model/currency_exchange.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_state.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send_review_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_page.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/xtz_amount_formatter.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SendCryptoPage extends StatefulWidget {
  static const String tag = 'send_crypto';

  final SendData data;

  const SendCryptoPage({Key? key, required this.data}) : super(key: key);

  @override
  State<SendCryptoPage> createState() => _SendCryptoPageState();
}

class _SendCryptoPageState extends State<SendCryptoPage> {
  TextEditingController _addressController = TextEditingController();
  TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.data.address != null) {
      _addressController.text = widget.data.address!;
    }

    context.read<SendCryptoBloc>().add(GetBalanceEvent());
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.data.type;

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
          margin: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Send ${type == CryptoType.ETH ? "ETH" : "XTZ"}",
                style: appTextTheme.headline1,
              ),
              SizedBox(height: 40.0),
              AuTextField(
                title: "To",
                placeholder: "Paste or scan address",
                isError: state.isAddressError,
                controller: _addressController,
                suffix: IconButton(
                  icon: SvgPicture.asset(state.isScanQR
                      ? "assets/images/iconQr.svg"
                      : "assets/images/iconClose.svg"),
                  onPressed: () async {
                    if (_addressController.text.isNotEmpty) {
                      _addressController.text = "";
                      context
                          .read<SendCryptoBloc>()
                          .add(AddressChangedEvent(""));
                    } else {
                      dynamic address = await Navigator.of(context).pushNamed(
                          ScanQRPage.tag,
                          arguments: type == CryptoType.ETH
                              ? ScannerItem.ETH_ADDRESS
                              : ScannerItem.XTZ_ADDRESS);
                      print(address);
                      if (address != null && address is String) {
                        _addressController.text = address;
                        context
                            .read<SendCryptoBloc>()
                            .add(AddressChangedEvent(address));
                      }
                    }
                  },
                ),
                onChanged: (value) {
                  context
                      .read<SendCryptoBloc>()
                      .add(AddressChangedEvent(_addressController.text));
                },
              ),
              SizedBox(height: 16.0),
              AuTextField(
                title: "Send",
                placeholder: "0",
                isError: state.isAmountError,
                controller: _amountController,
                keyboardType: TextInputType.number,
                subTitleView: state.maxAllow != null
                    ? GestureDetector(
                        child: Text(
                          _maxAmountText(state),
                          style: TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                              fontFamily: "AtlasGrotesk",
                              color: AppColorTheme.secondaryHeaderColor,
                              fontWeight: FontWeight.w300),
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
                      ? "assets/images/iconEth.svg"
                      : "assets/images/iconUsd.svg"),
                  onPressed: () {
                    double amount =
                        double.tryParse(_amountController.text) ?? 0;
                    if (state.isCrypto) {
                      if (type == CryptoType.ETH) {
                        _amountController.text = state.exchangeRate
                            .ethToUsd(BigInt.from(amount * pow(10, 18)));
                      } else {
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
                  context
                      .read<SendCryptoBloc>()
                      .add(AmountChangedEvent(_amountController.text));
                },
              ),
              SizedBox(height: 8.0),
              Text(_gasFee(state),
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontFamily: "AtlasGrotesk")),
              SizedBox(height: 24.0),
              // Expanded(child: SizedBox()),
              Row(
                children: [
                  Expanded(
                    child: AuFilledButton(
                      text: "Review",
                      onPress: state.isValid
                          ? () async {
                              final payload = SendCryptoPayload(
                                  type,
                                  state.address!,
                                  state.amount!,
                                  state.fee!,
                                  state.exchangeRate);
                              final txHash = await Navigator.of(context)
                                  .pushNamed(SendReviewPage.tag,
                                      arguments: payload);
                              if (txHash != null && txHash is String) {
                                Navigator.of(context).pop();
                              }
                            }
                          : null,
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      }),
    );
  }

  String _maxAmountText(SendCryptoState state) {
    if (state.maxAllow == null) return "";
    final max = state.maxAllow!;

    String text = "Max: ";

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
    }
  }

  String _gasFee(SendCryptoState state) {
    if (state.fee == null) return "";
    final fee = state.fee!;

    String text = "Gas fee: ";

    switch (widget.data.type) {
      case CryptoType.ETH:
        text += state.isCrypto
            ? "${EthAmountFormatter(fee).format()} ETH"
            : "${state.exchangeRate.ethToUsd(fee)} USD";
        break;
      case CryptoType.XTZ:
        text += state.isCrypto
            ? "${XtzAmountFormatter(fee.toInt()).format()} XTZ"
            : "${state.exchangeRate.xtzToUsd(fee.toInt())} USD";
        break;
    }
    return text;
  }
}

class SendData {
  final CryptoType type;
  final String? address;

  SendData(this.type, this.address);
}

class SendCryptoPayload {
  final CryptoType type;
  final String address;
  final BigInt amount;
  final BigInt fee;
  final CurrencyExchangeRate exchangeRate;

  SendCryptoPayload(
      this.type, this.address, this.amount, this.fee, this.exchangeRate);
}
