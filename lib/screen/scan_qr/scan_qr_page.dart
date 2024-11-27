//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/deeplink_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/display_instruction_view.dart';
import 'package:autonomy_flutter/view/header.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/splitted_banner.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

// ignore_for_file: constant_identifier_names

enum QRScanTab {
  scan,
  ;

  String get routerName {
    switch (this) {
      case scan:
        return AppRouter.scanQRPage;
    }
  }
}

class ScanQRPagePayload {
  const ScanQRPagePayload({
    required this.scannerItem,
    this.onHandleFinished,
  });

  final ScannerItem scannerItem;
  final Function? onHandleFinished;
}

class ScanQRPage extends StatefulWidget {
  const ScanQRPage({required this.payload, super.key});

  final ScanQRPagePayload payload;

  @override
  State<ScanQRPage> createState() => ScanQRPageState();
}

class ScanQRPageState extends State<ScanQRPage>
    with RouteAware, TickerProviderStateMixin {
  final GlobalKey<QRScanViewState> _qrScanViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    //There is a conflict with lib qr_code_scanner on Android.
    if (Platform.isIOS) {
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack));
    }
  }

  Future<void> pauseCamera() async {
    await Future.delayed(const Duration(milliseconds: 100));
    await _qrScanViewKey.currentState?.pauseCamera();
  }

  Future<void> resumeCamera() async {
    await _qrScanViewKey.currentState?.resumeCamera();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        bottom: false,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: AppColor.primaryBlack,
          appBar: getDarkEmptyAppBar(Colors.transparent),
          body: Stack(
            children: <Widget>[
              _content(context),
              _header(context),
            ],
          ),
        ),
      );

  Widget _content(BuildContext context) => Column(
        children: [
          Expanded(
            child: QRScanView(
              key: _qrScanViewKey,
              scannerItem: widget.payload.scannerItem,
              onHandleFinished: widget.payload.onHandleFinished,
            ),
          ),
        ],
      );

  Widget _header(BuildContext context) {
    Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
          child: HeaderView(
            title: 'scan'.tr(),
            action: Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: closeIcon(
                    color: AppColor.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void didPopNext() {
    super.didPopNext();
    unawaited(resumeCamera());
    if (Platform.isIOS) {
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack));
    }
  }

  @override
  void didPushNext() {
    super.didPushNext();
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      ),
    );
    unawaited(pauseCamera());
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      ),
    );
    super.dispose();
  }
}

enum ScannerItem {
  ETH_ADDRESS,
  XTZ_ADDRESS,
  GLOBAL,
  CANVAS;

  List<ScannerInstruction> get instructions {
    switch (this) {
      case ETH_ADDRESS:
      case XTZ_ADDRESS:
        return [];
      case GLOBAL:
        return [
          ScannerInstruction.displayFF,
        ];
      case CANVAS:
        return [
          ScannerInstruction.displayFF,
        ];
    }
  }
}

class ScannerInstruction {
  const ScannerInstruction({
    required this.name,
    required this.detail,
    this.icon,
  });

  final String name;
  final String detail;
  final Widget? icon;

  static ScannerInstruction displayFF = ScannerInstruction(
    name: 'display_with_ff'.tr(),
    detail: 'on_tv_or_desktop'.tr(),
    icon: IconButton(
      onPressed: () {
        final context =
            injector<NavigationService>().navigatorKey.currentContext!;
        UIHelper.showDialog(
          context,
          'display_art'.tr(),
          Column(
            children: [
              DisplayInstructionView(
                onScanQRTap: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
          isDismissible: true,
          withCloseIcon: true,
        );
      },
      constraints: const BoxConstraints(
        maxWidth: 44,
        maxHeight: 44,
        minWidth: 44,
        minHeight: 44,
      ),
      icon: SvgPicture.asset('assets/images/info_white.svg'),
    ),
  );
}

class QRScanView extends StatefulWidget {
  const QRScanView({
    required this.scannerItem,
    super.key,
    this.onHandleFinished,
  });

  final ScannerItem scannerItem;
  final Function? onHandleFinished;

  @override
  State<QRScanView> createState() => QRScanViewState();
}

class QRScanViewState extends State<QRScanView>
    with RouteAware, AutomaticKeepAliveClientMixin<QRScanView> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;
  bool isScanDataError = false;
  bool _isLoading = false;
  bool? _cameraPermission;
  String? currentCode;
  final metricClient = injector<MetricClientService>();
  Timer? _timer;

  static const _qrSize = 260.0;
  static const double _topPadding = 144;

  late bool _shouldPop;

  @override
  void initState() {
    super.initState();
    _shouldPop = true;
    unawaited(_checkPermission());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    super.didPopNext();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void didPushNext() {
    super.didPushNext();
    unawaited(
      Future.delayed(const Duration(milliseconds: 300)).then((_) {
        pauseCamera();
      }),
    );
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> resumeCamera() async {
    await _controller?.resumeCamera();
  }

  Future<void> pauseCamera() async {
    await _controller?.pauseCamera();
  }

  Future _checkPermission() async {
    await Permission.camera.request();
    final status = await Permission.camera.status;

    if (status.isPermanentlyDenied || status.isDenied) {
      if (_cameraPermission != false) {
        setState(() {
          _cameraPermission = false;
        });
      }
    } else {
      if (_cameraPermission != true) {
        setState(() {
          _cameraPermission = true;
        });
        if (Platform.isAndroid) {
          _timer?.cancel();
          _timer = Timer(const Duration(seconds: 1), resumeCamera);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    return Stack(
      children: [
        if (_cameraPermission == false)
          _noPermissionView(context)
        else ...[
          _qrView(context),
          Padding(
            padding:
                const EdgeInsets.fromLTRB(0, _qrSize + _topPadding + 30, 0, 15),
            child: _instructionView(context),
          ),
        ],
        if (_isLoading) ...[
          Center(
            child: CupertinoActivityIndicator(
              color: theme.colorScheme.primary,
              radius: 16,
            ),
          ),
        ],
      ],
    );
  }

  Widget _qrView(BuildContext context) {
    final theme = Theme.of(context);
    var cutOutBottomOffset =
        MediaQuery.of(context).size.height / 2 - (_qrSize / 2 + _topPadding);
    if (cutOutBottomOffset < 0) {
      cutOutBottomOffset = 0;
    }
    return Stack(
      children: [
        QRView(
          key: qrKey,
          overlay: QrScannerOverlayShape(
            borderLength: _qrSize / 2,
            borderColor:
                isScanDataError ? Colors.red : theme.colorScheme.secondary,
            overlayColor: const Color.fromRGBO(196, 196, 196, 0.6),
            cutOutSize: _qrSize,
            borderWidth: 2,
            cutOutBottomOffset: cutOutBottomOffset,
            borderRadius: 40,
          ),
          onQRViewCreated: _onQRViewCreated,
          onPermissionSet: (ctrl, p) {
            setState(() {
              _cameraPermission = ctrl.hasPermissions;
            });
          },
        ),
        if (isScanDataError)
          Positioned(
            left: (MediaQuery.of(context).size.width - _qrSize) / 2,
            top: _topPadding,
            child: SizedBox(
              height: _qrSize,
              width: _qrSize,
              child: Center(
                child: Text(
                  'invalid_qr_code'.tr(),
                  style: theme.textTheme.ppMori700Black14
                      .copyWith(color: Colors.red),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _noPermissionView(BuildContext context) => Stack(
        children: [
          _qrView(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              44,
              _qrSize + _topPadding + 30,
              44,
              120,
            ),
            child: Column(
              children: [
                _instructionViewNoPermission(context),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: PrimaryButton(
                    text: 'open_setting'.tr(
                      namedArgs: {
                        'device': Platform.isAndroid ? 'Device' : 'iOS',
                      },
                    ),
                    onTap: () async {
                      await openAppSettings();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _instructionViewNoPermission(BuildContext context) {
    final theme = Theme.of(context);
    return SplittedBanner(
      headerWidget: Row(
        children: [
          SvgPicture.asset(
            'assets/images/iconController.svg',
            colorFilter: const ColorFilter.mode(
              AppColor.white,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 20),
          Text(
            'allow_camera_permission'.tr(),
            style: theme.textTheme.ppMori400White14,
          ),
        ],
      ),
      bodyWidget: Text(
        'allow_camera_permission_desc'.tr(),
        style: theme.textTheme.ppMori400White14,
      ),
    );
  }

  Widget _instructionView(BuildContext context) {
    if (widget.scannerItem.instructions.isEmpty) {
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 44),
      child: SingleChildScrollView(
        child: SplittedBanner(
          headerWidget: _instructionHeader(context),
          bodyWidget:
              _instructionBody(context, widget.scannerItem.instructions),
        ),
      ),
    );
  }

  Widget _instructionHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SvgPicture.asset(
          'assets/images/icon_scan.svg',
        ),
        const SizedBox(width: 20),
        Expanded(
          child: RichText(
            textScaler: MediaQuery.textScalerOf(context),
            text: TextSpan(
              text: 'scan_qr_code'.tr(),
              children: [
                TextSpan(
                  text: ' ',
                  style: theme.textTheme.ppMori400Grey14,
                ),
                TextSpan(
                  text: 'in_order_to'.tr(),
                  style: theme.textTheme.ppMori400Grey14,
                ),
              ],
              style: theme.textTheme.ppMori400White14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _instructionBody(
    BuildContext context,
    List<ScannerInstruction> instructions,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: instructions
          .map(
            (instruction) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          instruction.name,
                          style: theme.textTheme.ppMori700White14,
                        ),
                        Text(
                          instruction.detail,
                          style: theme.textTheme.ppMori400Grey14,
                        ),
                      ],
                    ),
                  ),
                  instruction.icon ?? const SizedBox(),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    // Dispose of the previous controller if it exists
    _controller?.dispose();

    _controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (_isLoading) {
        return;
      }
      if (scanData.code == currentCode && isScanDataError) {
        return;
      }
      currentCode = scanData.code;
      final code = scanData.code;

      if (DEEP_LINKS.any(code.startsWith)) {
        setState(() {
          _isLoading = true;
        });
        await pauseCamera();
        if (!mounted) {
          return;
        }
        if (_shouldPop) {
          Navigator.pop(context);
        }

        injector<DeeplinkService>().handleDeeplink(
          code,
          delay: const Duration(seconds: 1),
          // ignore: avoid_annotating_with_dynamic
          onFinished: (dynamic object) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              unawaited(resumeCamera());
            }
            widget.onHandleFinished?.call(object);
          },
        );
        return;
      } else {
        switch (widget.scannerItem) {
          case ScannerItem.CANVAS:
          // dont need to do anything here,
          // it has been processed in the branch deeplink
          /// handled with deeplink

          case ScannerItem.ETH_ADDRESS:
          case ScannerItem.XTZ_ADDRESS:
            setState(() {
              _isLoading = true;
            });
            await pauseCamera();
            if (!mounted) {
              return;
            }
            if (_shouldPop) {
              Navigator.pop(context, code);
            }
            await Future.delayed(const Duration(milliseconds: 300));
          case ScannerItem.GLOBAL:
        }
        if (mounted) {
          await resumeCamera();
          setState(() {
            _isLoading = false;
          });
        }
        if (!isScanDataError) {
          widget.onHandleFinished?.call();
        }
      }
    });
  }

  @override
  bool get wantKeepAlive => true;
}
