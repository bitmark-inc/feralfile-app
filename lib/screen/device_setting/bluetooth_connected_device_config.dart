import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/bluetooth_device_status.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/device_setting/device_config.dart';
import 'package:autonomy_flutter/screen/device_setting/enter_wifi_password.dart';
import 'package:autonomy_flutter/screen/device_setting/scan_wifi_network_page.dart';
import 'package:autonomy_flutter/service/bluetooth_notification_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:autonomy_flutter/util/device_realtime_metric_helper.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/now_displaying_manager.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum ScreenOrientation {
  landscape,
  landscapeReverse,
  portrait,
  portraitReverse;

  String get name {
    switch (this) {
      case ScreenOrientation.landscape:
        return 'landscape';
      case ScreenOrientation.landscapeReverse:
        return 'landscapeReverse';
      case ScreenOrientation.portrait:
        return 'portrait';
      case ScreenOrientation.portraitReverse:
        return 'portraitReverse';
    }
  }

  static ScreenOrientation fromString(String value) {
    switch (value) {
      case 'landscape':
      case 'normal':
        return ScreenOrientation.landscape;
      case 'landscapeReverse':
      case 'inverted':
        return ScreenOrientation.landscapeReverse;
      case 'portrait':
      case 'left':
        return ScreenOrientation.portrait;
      case 'portraitReverse':
      case 'right':
        return ScreenOrientation.portraitReverse;
      default:
        throw ArgumentError('Invalid screen orientation: $value');
    }
  }
}

class BluetoothConnectedDeviceConfigPayload {
  BluetoothConnectedDeviceConfigPayload({
    required this.device,
    this.isFromOnboarding = false,
  });

  final FFBluetoothDevice device;

  final bool isFromOnboarding;
}

class BluetoothConnectedDeviceConfig extends StatefulWidget {
  const BluetoothConnectedDeviceConfig({required this.payload, super.key});

  final BluetoothConnectedDeviceConfigPayload payload;

  @override
  State<BluetoothConnectedDeviceConfig> createState() =>
      BluetoothConnectedDeviceConfigState();
}

class BluetoothConnectedDeviceConfigState
    extends State<BluetoothConnectedDeviceConfig>
    with
        RouteAware,
        WidgetsBindingObserver,
        AfterLayoutMixin<BluetoothConnectedDeviceConfig> {
  BluetoothDeviceStatus? status;
  Timer? _connectionStatusTimer;
  bool _isBLEDeviceConnected = false;

  Timer? _pullingDeviceInfoTimer;
  NotificationCallback? cb;

  // Add performance metrics tracking
  final List<FlSpot> _cpuPoints = [];
  final List<FlSpot> _memoryPoints = [];
  final List<FlSpot> _gpuPoints = [];
  Timer? _metricsUpdateTimer;

  final int _maxDataPoints = 20;

  // Add temperature metrics tracking
  final List<FlSpot> _cpuTempPoints = [];
  final List<FlSpot> _gpuTempPoints = [];

  // Add FPS metrics tracking
  final List<FlSpot> _fpsPoints = [];

  StreamSubscription<DeviceRealtimeMetrics>? _metricsStreamSubscription;

  bool _isShowingQRCode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final device = widget.payload.device;

    status = BluetoothDeviceManager().bluetoothDeviceStatus.value;
    BluetoothDeviceManager()
        .bluetoothDeviceStatus
        .addListener(_bluetoothDeviceStatusListener);

    BluetoothDeviceManager().fetchBluetoothDeviceStatus(device);

    injector<CanvasDeviceBloc>().add(CanvasDeviceGetStatusEvent(device));

    // Start polling connection status
    _startBluetoothConnectionStatusPolling();

    // Enable metrics streaming when the screen opens
    _enableMetricsStreaming();
  }

  void _startBluetoothConnectionStatusPolling() {
    // Check initial connection status
    _updateBluetoothConnectionStatus();

    // Set up timer to poll every second
    _connectionStatusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateBluetoothConnectionStatus();
    });
  }

  void _updateBluetoothConnectionStatus() {
    final ffDevice = widget.payload.device;
    final isConnected = injector<CanvasDeviceBloc>()
        .state
        .activeDevices
        .any((device) => device.deviceId == ffDevice.deviceId);

    if (_isBLEDeviceConnected != isConnected) {
      setState(() {
        _isBLEDeviceConnected = isConnected;
      });
    }
    if (isConnected) {
      _pullingDeviceInfo();
    } else {
      _cancelPullingDeviceInfo();
    }
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _pullingDeviceInfo();
    _listenForCanvasCastRequestReply();
  }

  void _listenForCanvasCastRequestReply() {
    cb = (data) async {
      log.info(' Received data: $data');
      _pullingDeviceInfo();
    };
    BluetoothNotificationService().subscribe(wifiConnectionTopic, cb!);
  }

  void _pullingDeviceInfo() {
    final device = widget.payload.device;
    if (!_isBLEDeviceConnected) {
      log.info(
        '[BluetoothConnectedDeviceConfig] '
        '_pullingDeviceInfo: Device is not connected',
      );
      return;
    }
    _pullingDeviceInfoTimer?.cancel();
    _pullingDeviceInfoTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
      final deviceStatus =
          await BluetoothDeviceManager().fetchBluetoothDeviceStatus(device);
      if (deviceStatus != null) {
        timer.cancel();
      }
    });
  }

  void _cancelPullingDeviceInfo() {
    _pullingDeviceInfoTimer?.cancel();
  }

  void _bluetoothDeviceStatusListener() {
    final status = BluetoothDeviceManager().bluetoothDeviceStatus.value;
    if (mounted) {
      setState(() {
        this.status = status;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _connectionStatusTimer?.cancel();
    _metricsUpdateTimer?.cancel();
    _metricsStreamSubscription?.cancel();
    BluetoothDeviceManager()
        .bluetoothDeviceStatus
        .removeListener(_bluetoothDeviceStatusListener);
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);

    // Disable metrics streaming when leaving the screen
    _stopMetricsStreaming();

    if (cb != null) {
      BluetoothNotificationService().unsubscribe(wifiConnectionTopic, cb!);
    }
    _cancelPullingDeviceInfo();

    super.dispose();
  }

  @override
  void didPushNext() {
    // Called when another route has been pushed on top of this one
    super.didPushNext();
    // Disable metrics streaming when navigating away
    _stopMetricsStreaming();
  }

  @override
  void didPopNext() {
    // Called when coming back to this route
    super.didPopNext();
    // Re-enable metrics streaming when returning to this screen
    // _enableMetricsStreaming();

    BluetoothDeviceManager().fetchBluetoothDeviceStatus(widget.payload.device);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          injector<NavigationService>().goBack();
        },
        title: 'configure_device'.tr(),
        isWhite: false,
        actions: [
          if (_isBLEDeviceConnected)
            GestureDetector(
              onTap: () {
                UIHelper.showCenterDialog(
                  context,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Power Off',
                        style: Theme.of(context).textTheme.ppMori700White16,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Are you sure you want to power off the device?',
                        style: Theme.of(context).textTheme.ppMori400White14,
                      ),
                      const SizedBox(height: 36),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryAsyncButton(
                              text: 'cancel'.tr(),
                              textColor: AppColor.white,
                              color: Colors.transparent,
                              borderColor: AppColor.white,
                              onTap: () {
                                injector<NavigationService>().goBack();
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: PrimaryAsyncButton(
                              text: 'OK',
                              textColor: AppColor.white,
                              borderColor: AppColor.white,
                              color: Colors.transparent,
                              onTap: () async {
                                final device = widget.payload.device;
                                await injector<CanvasClientServiceV2>()
                                    .safeShutdown(device);
                                injector<NavigationService>().goBack();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              child: const Icon(
                Icons.power_settings_new,
                size: 24,
              ),
            ),
        ],
      ),
      backgroundColor: AppColor.primaryBlack,
      body: SafeArea(child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    return Stack(
      children: [
        _deviceConfig(context),
        if (widget.payload.isFromOnboarding)
          Positioned(
            bottom: 15,
            left: 0,
            right: 0,
            child: PrimaryAsyncButton(
              onTap: () async {
                Navigator.of(context).pop();
                unawaited(NowDisplayingManager().updateDisplayingNow());
              },
              text: 'finish'.tr(),
              color: AppColor.white,
            ),
          ),
      ],
    );
  }

  Widget _deviceConfig(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.paddingOf(context).top + 32,
            ),
          ),
          if (widget.payload.isFromOnboarding &&
              !(status?.isConnectedToWifi ?? false)) ...[
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 20,
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waiting for Portal to connect to the internet',
                    style: Theme.of(context).textTheme.ppMori400White14,
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 20,
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: _displayOrientation(context),
            ),
          ),
          const SliverToBoxAdapter(
            child: Divider(
              color: AppColor.auGreyBackground,
              thickness: 1,
              height: 40,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: _canvasSetting(context),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 20,
            ),
          ),
          const SliverToBoxAdapter(
            child: Divider(
              color: AppColor.auGreyBackground,
              thickness: 1,
              height: 1,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: _wifiConfig(context),
            ),
          ),
          const SliverToBoxAdapter(
            child: Divider(
              color: AppColor.auGreyBackground,
              thickness: 1,
              height: 1,
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 20,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: _deviceInfo(context),
            ),
          ),

          // Add performance monitoring section
          const SliverToBoxAdapter(
            child: Divider(
              color: AppColor.auGreyBackground,
              thickness: 1,
              height: 40,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: _performanceMonitoring(context),
            ),
          ),

          // Temperature monitoring section
          const SliverToBoxAdapter(
            child: Divider(
              color: AppColor.auGreyBackground,
              thickness: 1,
              height: 40,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: _temperatureMonitoring(context),
            ),
          ),

          const SliverToBoxAdapter(
            child: Divider(
              color: AppColor.auGreyBackground,
              thickness: 1,
              height: 40,
            ),
          ),
          // FPS monitoring section
          SliverToBoxAdapter(
            child: Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: _fpsMonitoring(context),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(
              height: 80,
            ),
          ),
        ],
      ),
    );
  }

  Widget _displayOrientationPreview(ScreenOrientation? screenOrientation) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.auGreyBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      height: 200,
      child: Center(
        child: _displayOrientationPreviewImage(
          screenOrientation,
        ),
      ),
    );
  }

  Widget _displayOrientationPreviewImage(ScreenOrientation? screenOrientation) {
    if (screenOrientation == null) {
      return const SizedBox.shrink();
    }
    switch (screenOrientation) {
      case ScreenOrientation.landscape:
        return SvgPicture.asset('assets/images/landscape.svg', width: 150);
      case ScreenOrientation.landscapeReverse:
        return RotatedBox(
          quarterTurns: 2,
          child: SvgPicture.asset(
            'assets/images/landscape.svg',
            width: 150,
          ),
        );
      case ScreenOrientation.portrait:
        return SvgPicture.asset(
          'assets/images/portrait.svg',
          height: 150,
        );
      case ScreenOrientation.portraitReverse:
        return RotatedBox(
          quarterTurns: 2,
          child: SvgPicture.asset(
            'assets/images/portrait.svg',
            height: 150,
          ),
        );
    }
  }

  Widget _displayOrientation(BuildContext context) {
    final blDevice = widget.payload.device;
    return BlocBuilder<CanvasDeviceBloc, CanvasDeviceState>(
      bloc: injector<CanvasDeviceBloc>(),
      buildWhen: (previous, current) {
        return previous.deviceDisplaySettingOf(blDevice)?.screenOrientation !=
            current.deviceDisplaySettingOf(blDevice)?.screenOrientation;
      },
      builder: (context, state) {
        final deviceState = state.statusOf(blDevice);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'display_orientation'.tr(),
              style: Theme.of(context).textTheme.ppMori400White14,
            ),
            const SizedBox(height: 16),
            _displayOrientationPreview(
              deviceState?.deviceSettings?.screenOrientation,
            ),
            const SizedBox(height: 16),
            PrimaryAsyncButton(
              text: 'rotate'.tr(),
              color: AppColor.white,
              enabled: deviceState != null,
              onTap: () => injector<CanvasDeviceBloc>().add(
                CanvasDeviceRotateEvent(
                  blDevice,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _canvasSetting(BuildContext context) {
    final blDevice = widget.payload.device;
    return BlocBuilder<CanvasDeviceBloc, CanvasDeviceState>(
      bloc: injector<CanvasDeviceBloc>(),
      buildWhen: (previous, current) {
        return previous.statusOf(blDevice)?.deviceSettings?.scaling !=
            current.statusOf(blDevice)?.deviceSettings?.scaling;
      },
      builder: (context, state) {
        final deviceState = state.statusOf(blDevice);
        final artFramingIndex =
            (deviceState?.deviceSettings?.scaling == ArtFraming.cropToFill)
                ? 1
                : 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'canvas'.tr(),
              style: Theme.of(context).textTheme.ppMori400White14,
            ),
            const SizedBox(height: 30),
            SelectDeviceConfigView(
              selectedIndex: artFramingIndex,
              isEnable: deviceState != null,
              items: [
                DeviceConfigItem(
                  title: 'fit'.tr(),
                  icon: Image.asset(
                    'assets/images/fit.png',
                    width: 100,
                    height: 100,
                  ),
                  onSelected: () async {
                    final completer = Completer<void>();
                    injector<CanvasDeviceBloc>().add(
                      CanvasDeviceUpdateArtFramingEvent(
                        blDevice,
                        ArtFraming.fitToScreen,
                        completer.completeError,
                        completer.complete,
                      ),
                    );
                    await completer.future;
                  },
                ),
                DeviceConfigItem(
                  title: 'fill'.tr(),
                  icon: Image.asset(
                    'assets/images/fill.png',
                    width: 100,
                    height: 100,
                  ),
                  onSelected: () async {
                    final completer = Completer<void>();
                    injector<CanvasDeviceBloc>().add(
                      CanvasDeviceUpdateArtFramingEvent(
                        blDevice,
                        ArtFraming.cropToFill,
                        completer.completeError,
                        completer.complete,
                      ),
                    );
                    await completer.future;
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _wifiConfig(BuildContext context) {
    final isEnabled = _isBLEDeviceConnected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TappableForwardRow(
          leftWidget: Row(
            children: [
              Text(
                'configure_wifi'.tr(),
                style: Theme.of(context).textTheme.ppMori400White14.copyWith(
                      color:
                          isEnabled ? AppColor.white : AppColor.disabledColor,
                    ),
              ),
            ],
          ),
          forwardIcon: SvgPicture.asset(
            'assets/images/iconForward.svg',
            colorFilter: ColorFilter.mode(
              isEnabled ? AppColor.white : AppColor.disabledColor,
              BlendMode.srcIn,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          onTap: isEnabled
              ? () {
                  injector<NavigationService>().navigateTo(
                    AppRouter.scanWifiNetworkPage,
                    arguments: ScanWifiNetworkPagePayload(
                      widget.payload.device,
                      onWifiSelected,
                    ),
                  );
                }
              : null,
        ),
      ],
    );
  }

  FutureOr<void> onWifiSelected(WifiPoint accessPoint) {
    final blDevice = widget.payload.device;
    log.info('onWifiSelected: $accessPoint');
    final payload = SendWifiCredentialsPagePayload(
      wifiAccessPoint: accessPoint,
      device: blDevice,
      onSubmitted: (FFBluetoothDevice device) {
        injector<NavigationService>()
            .popUntil(AppRouter.bluetoothConnectedDeviceConfig);
      },
    );
    injector<NavigationService>()
        .navigateTo(AppRouter.sendWifiCredentialPage, arguments: payload);
  }

  Widget _deviceInfoItem(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.ppMori400Grey14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }

  Widget _deviceInfo(BuildContext context) {
    final version = status?.installedVersion;
    final installedVersion = status?.installedVersion ?? version;
    final latestVersion = status?.latestVersion;
    final isUpToDate =
        installedVersion == latestVersion || latestVersion == null;
    final theme = Theme.of(context);
    final device = widget.payload.device;
    final deviceId = device.name;
    final ipAddress = status?.ipAddress;
    final connectedWifi = status?.connectedWifi;
    final isNetworkConnected = status?.isConnectedToWifi ?? false;

    final divider = addDivider(
      height: 16,
      color: AppColor.primaryBlack,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Device Information',
                style: theme.textTheme.ppMori400White14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Connection Status
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColor.auGreyBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // connection status
              _deviceInfoItem(
                context,
                title: 'Connection Status:',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color:
                            _isBLEDeviceConnected ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isBLEDeviceConnected
                            ? 'Connected'
                            : 'Device not connected',
                        style: theme.textTheme.ppMori400White14,
                      ),
                    ),
                  ],
                ),
              ),
              divider,

              // Device Id

              _deviceInfoItem(
                context,
                title: 'Device ID:',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Text(
                        deviceId,
                        style: theme.textTheme.ppMori400White14.copyWith(
                          color: _isBLEDeviceConnected
                              ? AppColor.white
                              : AppColor.disabledColor,
                        ),
                      ),
                    ),
                    _copyButton(
                      context,
                      deviceId,
                    ),
                  ],
                ),
              ),
              divider,
              // software version
              _deviceInfoItem(
                context,
                title: 'Software Version',
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.ppMori400White14.copyWith(
                      color: _isBLEDeviceConnected
                          ? AppColor.white
                          : AppColor.disabledColor,
                    ),
                    children: [
                      TextSpan(
                        text: installedVersion ?? '-',
                      ),
                      if (isUpToDate)
                        const TextSpan(
                          text: ' - Up to date',
                          style: TextStyle(color: AppColor.disabledColor),
                        )
                      else
                        const TextSpan(
                          text: ' - Update available',
                          style: TextStyle(
                            color: AppColor.disabledColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              divider,
              //IP Address
              if (ipAddress != null && ipAddress.isNotEmpty) ...[
                _deviceInfoItem(
                  context,
                  title: 'IP Address:',
                  child: Text(
                    ipAddress,
                    style: theme.textTheme.ppMori400White14.copyWith(
                      color: _isBLEDeviceConnected
                          ? AppColor.white
                          : AppColor.disabledColor,
                    ),
                  ),
                ),
                divider,
              ],

              // WiFi Network
              // Check if the device is connected to WiFi
              // If not connected, show "Not connected" message
              // If connected, show the connected WiFi name
              if (status != null) ...[
                _deviceInfoItem(
                  context,
                  title: 'Device Wifi Network',
                  child: Text(
                    isNetworkConnected ? connectedWifi ?? '-' : '-',
                    style: theme.textTheme.ppMori400White14.copyWith(
                      color: _isBLEDeviceConnected
                          ? AppColor.white
                          : AppColor.disabledColor,
                    ),
                  ),
                ),
              ],
              if (_isBLEDeviceConnected) ...[
                const SizedBox(height: 16),
                PrimaryAsyncButton(
                  text: _isShowingQRCode
                      ? 'Hide QR Code'
                      : 'Show Pairing QR Code',
                  color: AppColor.white,
                  onTap: () async {
                    final device = widget.payload.device;
                    await injector<CanvasClientServiceV2>()
                        .showPairingQRCode(device, !_isShowingQRCode);
                    setState(() {
                      _isShowingQRCode = !_isShowingQRCode;
                    });
                  },
                ),
              ],

              // Update Button
              if (_isBLEDeviceConnected && !isUpToDate) ...[
                const SizedBox(height: 16),
                PrimaryAsyncButton(
                  text: 'Update to latest version v.$latestVersion',
                  color: AppColor.white,
                  onTap: () async {
                    final device = widget.payload.device;
                    await injector<CanvasClientServiceV2>()
                        .updateToLatestVersion(device);
                  },
                ),
              ],
            ],
          ),
        ),

        // Update Button
        if (!isUpToDate) ...[
          const SizedBox(height: 16),
          PrimaryAsyncButton(
            text: 'Update to latest version v.$latestVersion',
            color: AppColor.white,
            onTap: () async {
              final device = widget.payload.device;
              await injector<CanvasClientServiceV2>()
                  .updateToLatestVersion(device);
            },
          ),
        ],
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _copyButton(BuildContext context, String deviceId) {
    return GestureDetector(
      onTap: () {
        showSimpleNotificationToast(
          key: const Key('deviceID'),
          content: 'Device Id copied to clipboard',
        );
        unawaited(
          Clipboard.setData(ClipboardData(text: deviceId)),
        );
      },
      child: SvgPicture.asset(
        'assets/images/copy.svg',
        height: 16,
        width: 16,
        colorFilter: const ColorFilter.mode(
          AppColor.white,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  // // Enable metrics streaming from the device
  Future<void> _enableMetricsStreaming() async {
    try {
      final device = widget.payload.device;
      log.info('Enabling metrics streaming for device: ${device.name}');
      DeviceRealtimeMetricHelper().startRealtimeMetrics(device: device);

      // Subscribe to the metrics stream
      await _metricsStreamSubscription
          ?.cancel(); // Cancel any existing subscription
      _metricsStreamSubscription = DeviceRealtimeMetricHelper()
          .deviceRealtimeMetricsStream
          .listen(_updateMetricsFromStream);
    } catch (e) {
      log.warning('Failed to enable metrics streaming: $e');
    }
  }

  // // Disable metrics streaming from the device
  Future<void> _stopMetricsStreaming() async {
    try {
      // Cancel the stream subscription
      await _metricsStreamSubscription?.cancel();
      _metricsStreamSubscription = null;

      final device = widget.payload.device;
      log.info('Disabling metrics streaming for device: ${device.name}');
      DeviceRealtimeMetricHelper().stopRealtimeMetrics();
    } catch (e) {
      log.warning('Failed to disable metrics streaming: $e');
    }
  }

  void _updateMetricsFromStream(DeviceRealtimeMetrics metrics) {
    if (!mounted) return;

    setState(() {
      // Add new performance data points
      final timestamp = metrics.timestamp.toDouble();
      if (metrics.cpu?.cpuUsage != null) {
        _cpuPoints.add(FlSpot(timestamp, metrics.cpu!.cpuUsage!));
      }
      if (metrics.memory?.memoryUsage != null) {
        _memoryPoints.add(FlSpot(timestamp, metrics.memory!.memoryUsage!));
      }
      if (metrics.gpu?.gpuUsage != null) {
        _gpuPoints.add(FlSpot(timestamp, metrics.gpu!.gpuUsage!));
      }
      if (metrics.cpu?.currentTemperature != null) {
        _cpuTempPoints.add(FlSpot(timestamp, metrics.cpu!.currentTemperature!));
      }
      if (metrics.gpu?.currentTemperature != null) {
        _gpuTempPoints.add(FlSpot(timestamp, metrics.gpu!.currentTemperature!));
      }

      if (metrics.screen?.refreshRate != null) {
        _fpsPoints.add(FlSpot(timestamp, metrics.screen!.refreshRate!));
      }

      // Remove old points if we exceed the limit
      while (_cpuPoints.length > _maxDataPoints) {
        _cpuPoints.removeAt(0);
        _memoryPoints.removeAt(0);
        _gpuPoints.removeAt(0);
        _cpuTempPoints.removeAt(0);
        _gpuTempPoints.removeAt(0);
      }
    });
  }

  Widget _performanceMonitoring(BuildContext context) {
    final theme = Theme.of(context);

    // Define colors for each metric
    const cpuColor = Colors.blue;
    const memoryColor = Colors.green;
    const gpuColor = Colors.red;

    // Get the latest values from the points arrays
    final cpuValue = _cpuPoints.isNotEmpty ? _cpuPoints.last.y : null;
    final memoryValue = _memoryPoints.isNotEmpty ? _memoryPoints.last.y : null;
    final gpuValue = _gpuPoints.isNotEmpty ? _gpuPoints.last.y : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Monitoring',
          style: theme.textTheme.ppMori400White14,
        ),
        const SizedBox(height: 16),

        // Current values display
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColor.auGreyBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metricDisplay('CPU', cpuValue, '%', cpuColor),
              _metricDisplay('Memory', memoryValue, '%', memoryColor),
              _metricDisplay('GPU', gpuValue, '%', gpuColor),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Performance chart
        if (_cpuPoints.length > 1)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColor.auGreyBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(16),
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                // Percentage values 0-100
                minX: _cpuPoints.first.x,
                maxX: _cpuPoints.last.x,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: AppColor.feralFileMediumGrey,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  _createLineData(_cpuPoints, cpuColor, 'CPU'),
                  _createLineData(_memoryPoints, memoryColor, 'Memory'),
                  _createLineData(_gpuPoints, gpuColor, 'GPU'),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: theme.textTheme.ppMori400White12,
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      reservedSize: 30,
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchCallback:
                      (FlTouchEvent event, LineTouchResponse? touchResponse) {
                    if (event is FlTapDownEvent) {
                      HapticFeedback.lightImpact();
                    }
                  },
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(12),
                    tooltipMargin: 8,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      // Sort spots by barIndex to ensure consistent order
                      final sortedSpots =
                          List<LineBarSpot>.from(touchedBarSpots)
                            ..sort((a, b) => a.barIndex.compareTo(b.barIndex));

                      // Get timestamp from the first spot (all spots have the same timestamp)
                      final timestamp = sortedSpots.isNotEmpty
                          ? '\nTime: ${_formatTimestamp(sortedSpots.first.x)}'
                          : '';

                      return sortedSpots.asMap().entries.map((entry) {
                        final index = entry.key;
                        final barSpot = entry.value;

                        final metric = barSpot.barIndex == 0
                            ? 'CPU'
                            : barSpot.barIndex == 1
                                ? 'Memory'
                                : 'GPU';
                        final color = barSpot.barIndex == 0
                            ? cpuColor
                            : barSpot.barIndex == 1
                                ? memoryColor
                                : gpuColor;

                        return LineTooltipItem(
                          '$metric: ${barSpot.y.toStringAsFixed(1)}%',
                          TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          children: index == sortedSpots.length - 1
                              ? [
                                  TextSpan(
                                    text: timestamp,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.normal,
                                      fontSize: 10,
                                    ),
                                  ),
                                ]
                              : null,
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _temperatureMonitoring(BuildContext context) {
    final theme = Theme.of(context);

    // Define colors for each metric
    const cpuTempColor = Colors.blue;
    const gpuTempColor = Colors.red;

    // Get the latest values from the points arrays
    final cpuTempValue =
        _cpuTempPoints.isNotEmpty ? _cpuTempPoints.last.y : null;
    final gpuTempValue =
        _gpuTempPoints.isNotEmpty ? _gpuTempPoints.last.y : null;

    // Convert to Fahrenheit if needed
    final cpuTempDisplayValue = cpuTempValue;
    final gpuTempDisplayValue = gpuTempValue;

    // Temperature unit
    const tempUnit = '°C';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Temperature Monitoring',
          style: theme.textTheme.ppMori400White14,
        ),
        const SizedBox(height: 16),

        // Current values display
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColor.auGreyBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metricDisplay(
                'CPU Temp',
                cpuTempDisplayValue,
                tempUnit,
                cpuTempColor,
              ),
              _metricDisplay(
                'GPU Temp',
                gpuTempDisplayValue,
                tempUnit,
                gpuTempColor,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Temperature chart
        if (_cpuTempPoints.length > 1)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColor.auGreyBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(16),
            child: LineChart(
              LineChartData(
                minY: 30,
                // 30°C = 86°F
                maxY: 80,
                // 100°C = 212°F
                minX: _cpuTempPoints.first.x,
                maxX: _cpuTempPoints.last.x,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: AppColor.feralFileMediumGrey,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  _createLineData(
                    _cpuTempPoints,
                    cpuTempColor,
                    'CPU Temp',
                  ),
                  _createLineData(
                    _gpuTempPoints,
                    gpuTempColor,
                    'GPU Temp',
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 20, // ~20°C = 36°F interval
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}$tempUnit',
                          style: theme.textTheme.ppMori400White12,
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                ),
                lineTouchData: LineTouchData(
                  touchCallback:
                      (FlTouchEvent event, LineTouchResponse? touchResponse) {
                    if (event is FlTapDownEvent) {
                      HapticFeedback.lightImpact();
                    }
                  },
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(12),
                    tooltipMargin: 8,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      // Sort spots by barIndex to ensure consistent order
                      final sortedSpots =
                          List<LineBarSpot>.from(touchedBarSpots)
                            ..sort((a, b) => a.barIndex.compareTo(b.barIndex));

                      // Get timestamp from the first spot (all spots have the same timestamp)
                      final timestamp = sortedSpots.isNotEmpty
                          ? '\nTime: ${_formatTimestamp(sortedSpots.first.x)}'
                          : '';

                      return sortedSpots.asMap().entries.map((entry) {
                        final index = entry.key;
                        final barSpot = entry.value;

                        final metric =
                            barSpot.barIndex == 0 ? 'CPU Temp' : 'GPU Temp';
                        final color =
                            barSpot.barIndex == 0 ? cpuTempColor : gpuTempColor;
                        final value = barSpot.y;

                        return LineTooltipItem(
                          '$metric: ${value.toStringAsFixed(1)}$tempUnit',
                          TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          children: index == sortedSpots.length - 1
                              ? [
                                  TextSpan(
                                    text: timestamp,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.normal,
                                      fontSize: 10,
                                    ),
                                  ),
                                ]
                              : null,
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // FPS monitoring
  Widget _fpsMonitoring(BuildContext context) {
    final theme = Theme.of(context);
    final fpsValue = _fpsPoints.isNotEmpty ? _fpsPoints.last.y : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Screen Monitoring',
          style: theme.textTheme.ppMori400White14,
        ),
        const SizedBox(height: 16),
        // Current FPS value display
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColor.auGreyBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _metricDisplay('Refresh Rate', fpsValue, 'Hz', Colors.yellow),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricDisplay(String label, double? value, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.ppMori400Grey14,
        ),
        const SizedBox(height: 4),
        Text(
          '${value?.toStringAsFixed(1) ?? '--'} $unit',
          style: Theme.of(context).textTheme.ppMori400White14.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  LineChartBarData _createLineData(
    List<FlSpot> points,
    Color color,
    String label,
  ) {
    return LineChartBarData(
      spots: points,
      dotData: const FlDotData(
        show: false,
      ),
      color: color,
      barWidth: 3,
      isCurved: true,
      belowBarData: BarAreaData(
        show: true,
        color: color.withAlpha(40),
      ),
    );
  }

  // Helper method to format timestamp for tooltip display
  String _formatTimestamp(double timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }
}
