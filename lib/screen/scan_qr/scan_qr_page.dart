//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart'
    as accounts;
import 'package:autonomy_flutter/screen/bloc/ethereum/ethereum_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/tezos/tezos_bloc.dart';
import 'package:autonomy_flutter/screen/global_receive/receive_page.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service.dart';
import 'package:autonomy_flutter/service/deeplink_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/route_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/header.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:synchronized/synchronized.dart';

// ignore_for_file: constant_identifier_names

enum QRScanTab {
  scan,
  showMyCode,
  ;

  String get routerName {
    switch (this) {
      case scan:
        return AppRouter.scanQRPage;
      case showMyCode:
        return AppRouter.globalReceivePage;
    }
  }

  String get screenName => getPageName(routerName);
}

class ScanQRPage extends StatefulWidget {
  final ScannerItem scannerItem;
  final Function? onHandleFinished;

  const ScanQRPage(
      {super.key,
      this.scannerItem = ScannerItem.GLOBAL,
      this.onHandleFinished});

  @override
  State<ScanQRPage> createState() => ScanQRPageState();
}

class ScanQRPageState extends State<ScanQRPage>
    with RouteAware, TickerProviderStateMixin {
  late TabController _tabController;
  late bool _isGlobal;
  final GlobalKey<QRScanViewState> _qrScanViewKey = GlobalKey();
  final _metricClientService = injector<MetricClientService>();
  late List<Widget> _pages;

  TabController get tabController => _tabController;

  @override
  void initState() {
    super.initState();
    _isGlobal = (widget.scannerItem == ScannerItem.GLOBAL);
    //There is a conflict with lib qr_code_scanner on Android.
    if (Platform.isIOS) {
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack));
    }
    _tabController = TabController(length: _isGlobal ? 2 : 1, vsync: this);
    _tabController.addListener(() {
      setState(() {});
      _addMetricListener(_tabController);
    });
    _pages = [
      QRScanView(
        key: _qrScanViewKey,
        scannerItem: widget.scannerItem,
        onHandleFinished: widget.onHandleFinished,
      ),
      MultiBlocProvider(
        providers: [
          BlocProvider(
              create: (_) => accounts.AccountsBloc(injector(), injector())),
          BlocProvider(
            create: (_) => PersonaBloc(
              injector<CloudDatabase>(),
              injector(),
              injector<AuditService>(),
            ),
          ),
          BlocProvider(create: (_) => EthereumBloc(injector(), injector())),
          BlocProvider(
            create: (_) => TezosBloc(injector(), injector()),
          ),
        ],
        child: GlobalReceivePage(
          onClose: () {
            setState(
              () {
                _tabController.animateTo(QRScanTab.scan.index,
                    duration: const Duration(milliseconds: 300));
                unawaited(resumeCamera());
              },
            );
          },
        ),
      ),
    ];
  }

  void _addMetricListener(TabController controller) {
    if (controller.indexIsChanging) {
      return;
    }
    unawaited(_metricClientService.addEvent(MixpanelEvent.visitPage, data: {
      MixpanelProp.title: QRScanTab.values[controller.previousIndex].screenName,
    }));
    _metricClientService.timerEvent(MixpanelEvent.visitPage);
  }

  Future<void> pauseCamera() async {
    await Future.delayed(const Duration(milliseconds: 100));
    await _qrScanViewKey.currentState?.pauseCamera();
  }

  Future<void> resumeCamera() async {
    if (_tabController.index == QRScanTab.scan.index) {
      await _qrScanViewKey.currentState?.resumeCamera();
    }
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
          appBar: _tabController.index == QRScanTab.scan.index
              ? getDarkEmptyAppBar(Colors.transparent)
              : getLightEmptyAppBar(),
          body: Stack(
            children: <Widget>[
              _content(context),
              if (_tabController.index == QRScanTab.scan.index)
                _header(context),
            ],
          ),
        ),
      );

  Widget _content(BuildContext context) {
    final size1 = MediaQuery.of(context).size.height / 2;
    final qrSize = size1 < 240.0 ? size1 : 240.0;

    double cutPaddingTop = qrSize + 500 - MediaQuery.of(context).size.height;
    if (cutPaddingTop < 0) {
      cutPaddingTop = 0;
    }
    return Column(
      children: [
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: _pages.sublist(0, _tabController.length),
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
          child: HeaderView(
            title: 'scan'.tr(),
            action: _isGlobal
                ? GestureDetector(
                    onTap: () {
                      setState(() {
                        unawaited(pauseCamera());
                        _tabController.animateTo(QRScanTab.showMyCode.index,
                            duration: const Duration(milliseconds: 300));
                      });
                    },
                    child: Text(
                      'show_my_code'.tr(),
                      style: theme.textTheme.ppMori400White14.copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: AppColor.white,
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      if (!_isGlobal) {
                        Navigator.pop(context);
                      }
                    },
                    child: closeIcon(
                      color: AppColor.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  void didPopNext() {
    super.didPopNext();
    if (Platform.isIOS) {
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack));
    }
  }

  @override
  void didPushNext() {
    super.didPushNext();
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values));
    unawaited(pauseCamera());
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values));
    super.dispose();
  }
}

enum ScannerItem {
  WALLET_CONNECT,
  BEACON_CONNECT,
  ETH_ADDRESS,
  XTZ_ADDRESS,
  CANVAS_DEVICE,
  GLOBAL
}

class QRScanView extends StatefulWidget {
  final ScannerItem scannerItem;
  final Function? onHandleFinished;

  const QRScanView(
      {required this.scannerItem, super.key, this.onHandleFinished});

  @override
  State<QRScanView> createState() => QRScanViewState();
}

class QRScanViewState extends State<QRScanView>
    with RouteAware, AutomaticKeepAliveClientMixin<QRScanView> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late QRViewController controller;
  bool isScanDataError = false;
  bool _isLoading = false;
  bool? _cameraPermission;
  String? currentCode;
  final metricClient = injector<MetricClientService>();
  final _navigationService = injector<NavigationService>();
  late Lock _lock;
  Timer? _timer;

  late bool _shouldPop;

  @override
  void initState() {
    super.initState();
    _shouldPop = !(widget.scannerItem == ScannerItem.GLOBAL);
    unawaited(_checkPermission());
    _lock = Lock();
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
    unawaited(Future.delayed(const Duration(milliseconds: 300)).then((_) {
      pauseCamera();
    }));
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  Future<void> resumeCamera() async {
    await controller.resumeCamera();
  }

  Future<void> pauseCamera() async {
    await controller.pauseCamera();
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
          _timer = Timer(const Duration(seconds: 1), () {
            resumeCamera();
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final size1 = MediaQuery.of(context).size.height / 2;
    final qrSize = size1 < 240.0 ? size1 : 240.0;

    var cutPaddingTop = qrSize + 500 - MediaQuery.of(context).size.height;
    if (cutPaddingTop < 0) {
      cutPaddingTop = 0;
    }
    final theme = Theme.of(context);
    return Stack(
      children: [
        if (_cameraPermission == false)
          _noPermissionView(context)
        else ...[
          _qrView(context),
          Padding(
            padding: EdgeInsets.fromLTRB(
              0,
              MediaQuery.of(context).size.height / 2 +
                  qrSize / 2 -
                  cutPaddingTop,
              0,
              15,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _instructionView(context),
                ],
              ),
            ),
          )
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
    final size1 = MediaQuery.of(context).size.height / 2;
    final qrSize = size1 < 240.0 ? size1 : 240.0;

    var cutPaddingTop = qrSize + 500 - MediaQuery.of(context).size.height;
    if (cutPaddingTop < 0) {
      cutPaddingTop = 0;
    }
    final cutOutBottomOffset = 80 + cutPaddingTop;
    return Stack(
      children: [
        QRView(
          key: qrKey,
          overlay: QrScannerOverlayShape(
            borderColor:
                isScanDataError ? AppColor.red : theme.colorScheme.secondary,
            overlayColor: _cameraPermission == true
                ? const Color.fromRGBO(0, 0, 0, 0.6)
                : const Color.fromRGBO(0, 0, 0, 1),
            cutOutSize: qrSize,
            borderWidth: 8,
            borderRadius: 40,
            cutOutBottomOffset: cutOutBottomOffset,
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
            left: (MediaQuery.of(context).size.width - qrSize) / 2,
            top: (MediaQuery.of(context).size.height - qrSize) / 2 -
                cutOutBottomOffset,
            child: SizedBox(
              height: qrSize,
              width: qrSize,
              child: Center(
                child: Text(
                  'invalid_qr_code'.tr(),
                  style: theme.textTheme.ppMori700Black14
                      .copyWith(color: AppColor.red),
                ),
              ),
            ),
          )
      ],
    );
  }

  Widget _noPermissionView(BuildContext context) {
    final size1 = MediaQuery.of(context).size.height / 2;
    final qrSize = size1 < 240.0 ? size1 : 240.0;

    var cutPaddingTop = qrSize + 500 - MediaQuery.of(context).size.height;
    if (cutPaddingTop < 0) {
      cutPaddingTop = 0;
    }
    final cutOutBottomOffset = 80 + cutPaddingTop;
    return Stack(
      children: [
        _qrView(context),
        Padding(
          padding: EdgeInsets.fromLTRB(
            0,
            MediaQuery.of(context).size.height / 2 +
                qrSize / 2 -
                cutOutBottomOffset +
                32,
            0,
            120,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _instructionViewNoPermission(context),
                Padding(
                  padding: const EdgeInsets.all(8),
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
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _instructionViewNoPermission(BuildContext context) {
    final theme = Theme.of(context);
    final size1 = MediaQuery.of(context).size.height / 2;
    final qrSize = size1 < 240.0 ? size1 : 240.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      width: qrSize,
      child: Text(
        'please_ensure'.tr(),
        style: theme.textTheme.ppMori400White14,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _instructionView(BuildContext context) {
    final theme = Theme.of(context);

    switch (widget.scannerItem) {
      case ScannerItem.WALLET_CONNECT:
      case ScannerItem.BEACON_CONNECT:
      case ScannerItem.GLOBAL:
        return Padding(
          padding: const EdgeInsets.all(15),
          child: Container(
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(5),
            ),
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'scan_qr_to'.tr(),
                  style: theme.textTheme.ppMori700White14,
                ),
                Divider(
                  color: theme.colorScheme.secondary,
                  height: 30,
                ),
                RichText(
                  text: TextSpan(
                    text: 'apps'.tr(),
                    children: [
                      TextSpan(
                        text: ' ',
                        style: theme.textTheme.ppMori400Grey14,
                      ),
                      TextSpan(
                        text: 'such_as_openSea'.tr(),
                        style: theme.textTheme.ppMori400Grey14,
                      ),
                    ],
                    style: theme.textTheme.ppMori400White14,
                  ),
                ),
                const SizedBox(height: 15),
                RichText(
                  text: TextSpan(
                    text: 'autonomy_canvas'.tr(),
                    children: [
                      TextSpan(
                        text: ' ',
                        style: theme.textTheme.ppMori400Grey14,
                      ),
                      TextSpan(
                        text: 'on_tv_or_desktop'.tr(),
                        style: theme.textTheme.ppMori400Grey14,
                      ),
                    ],
                    style: theme.textTheme.ppMori400White14,
                  ),
                ),
              ],
            ),
          ),
        );

      case ScannerItem.ETH_ADDRESS:
      case ScannerItem.XTZ_ADDRESS:
        return Column(
          children: [
            Text('scan_qr'.tr(), style: theme.primaryTextTheme.labelLarge),
          ],
        );
      case ScannerItem.CANVAS_DEVICE:
        return const SizedBox();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (_isLoading) {
        return;
      }
      if (scanData.code == null) {
        return;
      }
      if (scanData.code == currentCode && isScanDataError) {
        return;
      }
      currentCode = scanData.code;
      String code = scanData.code!;

      if (DEEP_LINKS.any((prefix) => code.startsWith(prefix))) {
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
          onFinished: () {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              unawaited(resumeCamera());
            }
            widget.onHandleFinished?.call();
          },
        );
        return;
      } else {
        switch (widget.scannerItem) {
          case ScannerItem.WALLET_CONNECT:
            if (code.startsWith('wc:')) {
              await _handleAutonomyConnect(code);
            } else {
              _handleError(code);
            }
            break;

          case ScannerItem.BEACON_CONNECT:
            if (code.startsWith('tezos://')) {
              await _handleBeaconConnect(code);
            } else {
              _handleError(code);
            }
            break;

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
            break;
          case ScannerItem.GLOBAL:
            if (code.startsWith('wc:')) {
              await _handleAutonomyConnect(code);
            } else if (code.startsWith('tezos:')) {
              await _handleBeaconConnect(code);
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
            } else if (_isCanvasQrCode(code)) {
              unawaited(_lock.synchronized(() async {
                await _handleCanvasQrCode(code);
              }));
            } else {
              _handleError(code);
            }
            break;
          case ScannerItem.CANVAS_DEVICE:
            if (_isCanvasQrCode(code)) {
              unawaited(_lock.synchronized(() => _handleCanvasQrCode(code)));
            } else {
              _handleError(code);
            }
            break;
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

  bool _isCanvasQrCode(String code) {
    try {
      CanvasDevice.fromJson(jsonDecode(code));
      return true;
    } catch (err) {
      return false;
    }
  }

  Future<bool> _handleCanvasQrCode(String code) async {
    log.info('Canvas device scanned: $code');
    setState(() {
      _isLoading = true;
    });
    await pauseCamera();
    if (!mounted) {
      return false;
    }
    try {
      final device = CanvasDevice.fromJson(jsonDecode(code));
      final canvasClient = injector<CanvasClientService>();
      final result = await canvasClient.connectToDevice(device);
      if (result) {
        device.isConnecting = true;
      }
      if (!mounted) {
        return false;
      }
      if (_shouldPop) {
        Navigator.pop(context, device);
      }
      return result;
    } catch (e) {
      if (mounted) {
        if (_shouldPop) {
          Navigator.pop(context);
        }
        if (e.toString().contains('DEADLINE_EXCEEDED') || true) {
          await UIHelper.showInfoDialog(
              _navigationService.navigatorKey.currentContext!,
              'failed_to_connect'.tr(),
              'canvas_ip_fail'.tr(),
              closeButton: 'close'.tr());
        }
      }
    }
    return false;
  }

  void _handleError(String data) {
    setState(() {
      isScanDataError = true;
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          isScanDataError = false;
        });
      }
    });

    log
      ..info('[Scanner][start] scan ${widget.scannerItem}')
      ..info('[Scanner][incorrectScanItem] item: '
          '${data.substring(0, data.length ~/ 2)}');
  }

  Future<void> _handleAutonomyConnect(String code) async {
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
    await Future.delayed(const Duration(seconds: 1));

    await injector<Wc2Service>().connect(code);
  }

  Future<void> _handleBeaconConnect(String code) async {
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
    await Future.delayed(const Duration(seconds: 1));

    await Future.wait([
      injector<TezosBeaconService>().addPeer(code),
      injector<NavigationService>().showContactingDialog()
    ]);
  }

  @override
  bool get wantKeepAlive => true;
}
