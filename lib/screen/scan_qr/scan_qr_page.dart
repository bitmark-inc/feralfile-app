//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/feralfile/feralfile_bloc.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class ScanQRPage extends StatefulWidget {
  static const String tag = AppRouter.scanQRPage;

  final ScannerItem scannerItem;

  const ScanQRPage({Key? key, this.scannerItem = ScannerItem.GLOBAL})
      : super(key: key);

  @override
  _ScanQRPageState createState() => _ScanQRPageState();
}

class _ScanQRPageState extends State<ScanQRPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late QRViewController controller;
  var isScanDataError = false;
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    //There is a conflict with lib qr_code_scanner on Android.
    if (Platform.isIOS) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    }
    checkPermission();
  }

  Future checkPermission() async {
    await Permission.camera.request();
    final status = await Permission.camera.status;

    if (status.isPermanentlyDenied) {
      openAppSettings();
    } else {
      if (Platform.isAndroid) {
        Future.delayed(Duration(seconds: 1), () {
          controller.resumeCamera();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrSize = MediaQuery.of(context).size.width - 90;

    var cutPaddingTop = qrSize + 430 - MediaQuery.of(context).size.height;
    if (cutPaddingTop < 0) cutPaddingTop = 0;

    return BlocListener<FeralfileBloc, FeralFileState>(
      listener: (context, state) {
        final event = state.event;
        if (event == null) return;

        if (event is LinkAccountSuccess) {
          Navigator.of(context).pop();
        } else if (event is AlreadyLinkedError) {
          showErrorDiablog(
              context,
              ErrorEvent(
                  null,
                  "Already linked",
                  "You’ve already linked this account to Autonomy.",
                  ErrorItemState.seeAccount), defaultAction: () {
            Navigator.of(context).pushReplacementNamed(
                AppRouter.linkedAccountDetailsPage,
                arguments: event.connection);
          }, cancelAction: () {
            controller.resumeCamera();
          });
        } else if (event is NotFFLoggedIn) {
          _handleError("feralfile-api:qrcode-with-feralfile-format");
          controller.resumeCamera();
        }
      },
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            Container(
              child: QRView(
                key: qrKey,
                overlay: QrScannerOverlayShape(
                  borderColor: isScanDataError ? Colors.red : Colors.white,
                  cutOutSize: qrSize,
                  borderWidth: 8,
                  // borderRadius: 20,
                  // borderLength: qrSize / 2,
                  cutOutBottomOffset: cutPaddingTop,
                ),
                onQRViewCreated: _onQRViewCreated,
              ),
            ),
            GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 55, 15, 15),
                  child: closeIcon(color: Colors.white),
                )),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  0,
                  MediaQuery.of(context).size.height / 2 +
                      qrSize / 2 +
                      32 -
                      cutPaddingTop,
                  0,
                  0),
              child: Center(child: _instructionView()),
            ),
            if (_isLoading) ...[
              Center(
                child:
                    CupertinoActivityIndicator(color: Colors.black, radius: 16),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _instructionView() {
    switch (widget.scannerItem) {
      case ScannerItem.WALLET_CONNECT:
      case ScannerItem.BEACON_CONNECT:
      case ScannerItem.FERALFILE_TOKEN:
      case ScannerItem.GLOBAL:
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Scan QR code to connect to".toUpperCase(),
              style: appTextTheme.button?.copyWith(color: Colors.white),
            ),
            SizedBox(height: 24),
            Text(
              "Marketplaces",
              style: appTextTheme.headline4
                  ?.copyWith(color: Colors.white, fontSize: 12),
            ),
            Text('Such as OpenSea or objkt.com',
                style: appTextTheme.bodyText1
                    ?.copyWith(color: Colors.white, fontSize: 12)),
            SizedBox(height: 16),
            Text(
              "Wallets",
              style: appTextTheme.headline4
                  ?.copyWith(color: Colors.white, fontSize: 12),
            ),
            Text('Such as MetaMask',
                style: appTextTheme.bodyText1
                    ?.copyWith(color: Colors.white, fontSize: 12)),
            SizedBox(height: 16),
            Text(
              "Autonomy",
              style: appTextTheme.headline4
                  ?.copyWith(color: Colors.white, fontSize: 12),
            ),
            Text('on TV or desktop',
                style: appTextTheme.bodyText1
                    ?.copyWith(color: Colors.white, fontSize: 12)),
          ],
        );

      case ScannerItem.ETH_ADDRESS:
      case ScannerItem.XTZ_ADDRESS:
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "SCAN QR CODE",
              style: appTextTheme.button?.copyWith(color: Colors.white),
            ),
          ],
        );
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (scanData.code == null) return;

      final code = scanData.code!;

      switch (widget.scannerItem) {
        case ScannerItem.WALLET_CONNECT:
          if (code.startsWith("wc:") == true) {
            _handleWalletConnect(code);
          } else {
            _handleError(code);
          }
          break;

        case ScannerItem.BEACON_CONNECT:
          if (code.startsWith("tezos://") == true) {
            _handleBeaconConnect(code);
          } else {
            _handleError(code);
          }
          break;

        case ScannerItem.FERALFILE_TOKEN:
          if (code.startsWith(FF_TOKEN_DEEPLINK_PREFIX)) {
            controller.dispose();
            Navigator.pop(context, code);
          } else {
            _handleError(code);
          }
          break;

        case ScannerItem.ETH_ADDRESS:
        case ScannerItem.XTZ_ADDRESS:
          controller.dispose();
          Navigator.pop(context, code);
          break;
        case ScannerItem.GLOBAL:
          if (code.startsWith("wc:") == true) {
            _handleWalletConnect(code);
          } else if (code.startsWith("tezos:") == true) {
            _handleBeaconConnect(code);
          } else if (code.startsWith(FF_TOKEN_DEEPLINK_PREFIX) == true) {
            _handleFeralFileToken(code);
            /* TODO: Remove or support for multiple wallets
          } else if (code.startsWith("tz1")) {
            Navigator.of(context).popAndPushNamed(SendCryptoPage.tag,
                arguments: SendData(CryptoType.XTZ, code));
          } else {
            try {
              final _ = EthereumAddress.fromHex(code);
              Navigator.of(context).popAndPushNamed(SendCryptoPage.tag,
                  arguments: SendData(CryptoType.ETH, code));
            } catch (err) {
              log(err.toString());
            }
            */
          } else {
            _handleError(code);
          }
          break;
      }
    });
  }

  void _handleError(String data) {
    setState(() {
      isScanDataError = true;
    });

    log.info("[Scanner][start] scan ${widget.scannerItem}");
    log.info(
        "[Scanner][incorrectScanItem] item: ${data.substring(0, data.length ~/ 2)}");
  }

  void _handleWalletConnect(String code) {
    controller.dispose();
    injector<WalletConnectService>().connect(code);
    Navigator.of(context).pop();
  }

  void _handleBeaconConnect(String code) {
    controller.dispose();
    injector<TezosBeaconService>().addPeer(code);
    Navigator.of(context).pop();
  }

  void _handleFeralFileToken(String code) async {
    setState(() {
      _isLoading = true;
    });
    controller.pauseCamera();
    try {
      final connection = await injector<FeralFileService>().linkFF(
          code.replacePrefix(FF_TOKEN_DEEPLINK_PREFIX, ""),
          delayLink: false);
      injector<NavigationService>().popUntilHomeOrSettings();
      UIHelper.showFFAccountLinked(context, connection.name);
    } catch (_) {
      Navigator.of(context).pop();
      rethrow;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }
}

enum ScannerItem {
  WALLET_CONNECT,
  BEACON_CONNECT,
  ETH_ADDRESS,
  XTZ_ADDRESS,
  FERALFILE_TOKEN,
  GLOBAL
}
