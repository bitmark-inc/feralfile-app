//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
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
import 'package:autonomy_flutter/view/display_instruction_view.dart';
import 'package:autonomy_flutter/view/header.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/splitted_banner.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

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
    _metricClientService
      ..addEvent(MixpanelEvent.visitPage, data: {
        MixpanelProp.title:
            QRScanTab.values[controller.previousIndex].screenName,
      })
      ..timerEvent(MixpanelEvent.visitPage);
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

  Widget _content(BuildContext context) => Column(
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
                    child: Container(
                      color: Colors.yellow,
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                      child: Text(
                        'show_my_code'.tr(),
                        style: theme.textTheme.ppMori400White14.copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: AppColor.white,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: Colors.yellow,
                    child: IconButton(
                        onPressed: () {
                          if (!_isGlobal) {
                            Navigator.pop(context);
                          }
                        },
                        icon: closeIcon(
                          color: AppColor.white,
                        )),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  void didPopNext() {
    super.didPopNext();
    // for global camera, it's already handled in HomeNavigationPage.didPopNext
    if (!_isGlobal) {
      unawaited(resumeCamera());
    }
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
  GLOBAL,
  CANVAS;

  List<ScannerInstruction> get instructions {
    switch (this) {
      case WALLET_CONNECT:
      case BEACON_CONNECT:
        return [ScannerInstruction.web3Connect];
      case ETH_ADDRESS:
      case XTZ_ADDRESS:
        return [];
      case GLOBAL:
        return [
          ScannerInstruction.web3Connect,
          ScannerInstruction.signTransaction,
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
  final String name;
  final String detail;
  final Widget? icon;

  const ScannerInstruction({
    required this.name,
    required this.detail,
    this.icon,
  });

  static ScannerInstruction web3Connect = ScannerInstruction(
    name: 'apps'.tr(),
    detail: 'such_as_openSea'.tr(),
  );

  static ScannerInstruction signTransaction = ScannerInstruction(
    name: 'sign_transaction'.tr(),
    detail: 'after_connecting'.tr(),
  );

  static ScannerInstruction displayFF = ScannerInstruction(
    name: 'display_with_ff'.tr(),
    detail: 'on_tv_or_desktop'.tr(),
    icon: Container(
      color: Colors.yellow,
      child: IconButton(
          onPressed: () {
            final context =
                injector<NavigationService>().navigatorKey.currentContext!;
            UIHelper.showDialog(
                context, 'display'.tr(), const DisplayInstructionView(),
                isDismissible: true, withCloseIcon: true);
          },
          icon: SvgPicture.asset('assets/images/info_white.svg')),
    ),
  );
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
  Timer? _timer;

  static const _qrSize = 260.0;
  static const double _topPadding = 144;

  late bool _shouldPop;

  @override
  void initState() {
    super.initState();
    _shouldPop = !(widget.scannerItem == ScannerItem.GLOBAL ||

        /// handle canvas deeplink will pop the screen,
        /// therefore no need to pop here
        widget.scannerItem == ScannerItem.CANVAS);
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
    double cutOutBottomOffset =
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
          )
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
                )
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
            SvgPicture.asset('assets/images/iconController.svg',
                colorFilter: const ColorFilter.mode(
                  AppColor.white,
                  BlendMode.srcIn,
                )),
            const SizedBox(width: 20),
            Text(
              'allow_camera_permission'.tr(),
              style: theme.textTheme.ppMori400White14,
            )
          ],
        ),
        bodyWidget: Text(
          'allow_camera_permission_desc'.tr(),
          style: theme.textTheme.ppMori400White14,
        ));
  }

  Widget _instructionView(BuildContext context) {
    if (widget.scannerItem.instructions.isEmpty) {
      return const SizedBox();
    }
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 44),
        child: SplittedBanner(
            headerWidget: _instructionHeader(context),
            bodyWidget:
                _instructionBody(context, widget.scannerItem.instructions)));
  }

  Widget _instructionHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SvgPicture.asset(
          'assets/images/icon_scan.svg',
        ),
        const SizedBox(width: 20),
        RichText(
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
      ],
    );
  }

  Widget _instructionBody(
      BuildContext context, List<ScannerInstruction> instructions) {
    final theme = Theme.of(context);
    return Column(
      children: instructions
          .map(
            (instruction) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instruction.name,
                        style: theme.textTheme.ppMori700White14,
                      ),
                      Text(
                        instruction.detail,
                        style: theme.textTheme.ppMori400Grey14,
                      )
                    ],
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
          case ScannerItem.CANVAS:

          /// handled with deeplink
          case ScannerItem.WALLET_CONNECT:
            if (code.startsWith('wc:')) {
              await _handleAutonomyConnect(code);
            } else {
              _handleError(code);
            }

          case ScannerItem.BEACON_CONNECT:
            if (code.startsWith('tezos://')) {
              await _handleBeaconConnect(code);
            } else {
              _handleError(code);
            }

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
            if (code.startsWith('wc:')) {
              await _handleAutonomyConnect(code);
            } else if (code.startsWith('tezos:')) {
              await _handleBeaconConnect(code);
            } else {
              _handleError(code);
            }
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
