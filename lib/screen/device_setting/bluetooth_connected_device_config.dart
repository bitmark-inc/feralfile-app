import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/generated/protos/system_metrics.pb.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/bluetooth_device_status.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/device_setting/device_config.dart';
import 'package:autonomy_flutter/screen/device_setting/enter_wifi_password.dart';
import 'package:autonomy_flutter/screen/device_setting/scan_wifi_network_page.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BluetoothConnectedDeviceConfig extends StatefulWidget {
  const BluetoothConnectedDeviceConfig({super.key, required this.device});

  final BluetoothDevice device;

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

  // Add performance metrics tracking
  final List<FlSpot> _cpuPoints = [];
  final List<FlSpot> _memoryPoints = [];
  final List<FlSpot> _gpuPoints = [];
  Timer? _metricsUpdateTimer;
  final int _maxDataPoints = 20;

  // Add temperature metrics tracking
  final List<FlSpot> _cpuTempPoints = [];
  final List<FlSpot> _gpuTempPoints = [];

  StreamSubscription<DeviceRealtimeMetrics>? _metricsStreamSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    status = injector<FFBluetoothService>().bluetoothDeviceStatus.value;
    injector<FFBluetoothService>()
        .bluetoothDeviceStatus
        .addListener(_statusListener);

    injector<FFBluetoothService>().fetchBluetoothDeviceStatus(widget.device);

    // Start polling connection status
    _startConnectionStatusPolling();

    // Enable metrics streaming when the screen opens
    _enableMetricsStreaming();

    // Start updating performance chart
    _startPerformanceMetricsUpdates();
  }

  void _startConnectionStatusPolling() {
    // Check initial connection status
    _updateConnectionStatus();

    // Set up timer to poll every second
    _connectionStatusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateConnectionStatus();
    });
  }

  void _updateConnectionStatus() {
    final ffDevice = widget.device.toFFBluetoothDevice();
    final isConnected = ffDevice.isConnected;

    if (_isBLEDeviceConnected != isConnected) {
      setState(() {
        _isBLEDeviceConnected = isConnected;
      });
    }
  }

  @override
  void afterFirstLayout(BuildContext context) {}

  void _statusListener() {
    final status = injector<FFBluetoothService>().bluetoothDeviceStatus.value;
    setState(() {
      this.status = status;
    });
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
    injector<FFBluetoothService>()
        .bluetoothDeviceStatus
        .removeListener(_statusListener);
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);

    // Disable metrics streaming when leaving the screen
    _disableMetricsStreaming();

    super.dispose();
  }

  @override
  void didPushNext() {
    // Called when another route has been pushed on top of this one
    super.didPushNext();
    // Disable metrics streaming when navigating away
    _disableMetricsStreaming();
  }

  @override
  void didPopNext() {
    // Called when coming back to this route
    super.didPopNext();
    // Re-enable metrics streaming when returning to this screen
    _enableMetricsStreaming();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(context, onBack: () {
        injector<NavigationService>().goBack();
      }, title: 'configure_device'.tr(), isWhite: false),
      backgroundColor: AppColor.primaryBlack,
      body: SafeArea(child: _body(context)),
    );
  }

  Widget _emptyView(BuildContext context) {
    return Center(
      child: Text(
        'no_device_connected'.tr(),
        style: Theme.of(context).textTheme.ppMori400White14,
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (widget.device == null) {
      return _emptyView(context);
    }
    return _deviceConfig(context);
  }

  Widget _deviceConfig(BuildContext context) {
    final theme = Theme.of(context);
    final device = widget.device!;
    return Padding(
      padding: EdgeInsets.zero,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.paddingOf(context).top + 32,
            ),
          ),
          if (kDebugMode)
            SliverToBoxAdapter(
              child: Padding(
                padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                child: Text(
                  'Device: ${device.advName} - ${device.remoteId.str}',
                  style: theme.textTheme.ppMori400White14,
                ),
              ),
            ),
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
          SliverToBoxAdapter(
            child: const SizedBox(
              height: 20,
            ),
          ),
          SliverToBoxAdapter(
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
          SliverToBoxAdapter(
            child: Divider(
              color: AppColor.auGreyBackground,
              thickness: 1,
              height: 1,
            ),
          ),
          SliverToBoxAdapter(
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
          SliverToBoxAdapter(
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
          SliverToBoxAdapter(
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
            child: SizedBox(
              height: 80,
            ),
          ),
        ],
      ),
    );
  }

  Widget _displayOrientationPreview() {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.auGreyBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      height: 200,
      child: Center(
        child: _displayOrientationPreviewImage(),
      ),
    );
  }

  Widget _displayOrientationPreviewImage() {
    if (status == null) {
      return const SizedBox.shrink();
    }
    final screenRotation = status!.screenRotation;
    switch (screenRotation) {
      case ScreenOrientation.landscape:
        return SvgPicture.asset('assets/images/landscape.svg', width: 150);
      case ScreenOrientation.landscapeReverse:
        return SvgPicture.asset(
          'assets/images/landscape.svg',
          width: 150,
        );
      case ScreenOrientation.portrait:
        return SvgPicture.asset(
          'assets/images/portrait.svg',
          height: 150,
        );
      case ScreenOrientation.portraitReverse:
        return SvgPicture.asset(
          'assets/images/portrait.svg',
          height: 150,
        );
    }
  }

  Widget _displayOrientation(BuildContext context) {
    final blDevice = widget.device!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'display_orientation'.tr(),
          style: Theme.of(context).textTheme.ppMori400White14,
        ),
        const SizedBox(height: 16),
        _displayOrientationPreview(),
        const SizedBox(height: 16),
        PrimaryAsyncButton(
          text: 'rotate'.tr(),
          color: AppColor.white,
          onTap: () async {
            final device = blDevice.toFFBluetoothDevice();
            await injector<CanvasClientServiceV2>().rotateCanvas(device);
            // update orientation
          },
        )
      ],
    );
  }

  Widget _canvasSetting(BuildContext context) {
    final blDevice = widget.device!;
    final defaultArtFramingIndex =
        (status?.artFraming == ArtFraming.cropToFill) ? 1 : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'canvas'.tr(),
          style: Theme.of(context).textTheme.ppMori400White14,
        ),
        const SizedBox(height: 30),
        SelectDeviceConfigView(selectedIndex: defaultArtFramingIndex, items: [
          DeviceConfigItem(
            title: 'fit'.tr(),
            icon: Image.asset('assets/images/fit.png', width: 100, height: 100),
            onSelected: () {
              final device = blDevice.toFFBluetoothDevice();
              injector<CanvasClientServiceV2>()
                  .updateArtFraming(device, ArtFraming.fitToScreen);
            },
          ),
          DeviceConfigItem(
            title: 'fill'.tr(),
            icon: Image.asset(
              'assets/images/fill.png',
              width: 100,
              height: 100,
            ),
            onSelected: () {
              final device = blDevice.toFFBluetoothDevice();
              injector<CanvasClientServiceV2>()
                  .updateArtFraming(device, ArtFraming.cropToFill);
            },
          ),
        ])
      ],
    );
  }

  Widget _wifiConfig(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TappableForwardRow(
          leftWidget: Row(
            children: [
              Text(
                'configure_wifi'.tr(),
                style: Theme.of(context).textTheme.ppMori400White14,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          onTap: () {
            injector<NavigationService>().navigateTo(
                AppRouter.scanWifiNetworkPage,
                arguments: ScanWifiNetworkPagePayload(
                    widget.device.toFFBluetoothDevice(), onWifiSelected));
          },
        ),
      ],
    );
  }

  FutureOr<void> onWifiSelected(WifiPoint accessPoint) {
    final blDevice = widget.device;
    log.info('onWifiSelected: $accessPoint');
    final payload = SendWifiCredentialsPagePayload(
        wifiAccessPoint: accessPoint,
        device: blDevice,
        onSubmitted: () {
          injector<NavigationService>()
              .popUntil(AppRouter.bluetoothConnectedDeviceConfig);
        });
    injector<NavigationService>()
        .navigateTo(AppRouter.sendWifiCredentialPage, arguments: payload);
  }

  Widget _deviceInfo(BuildContext context) {
    final version = status?.version;
    final installedVersion = status?.installedVersion ?? version;
    final latestVersion = status?.latestVersion;
    final isUpToDate =
        installedVersion == latestVersion || latestVersion == null;
    final theme = Theme.of(context);
    final deviceId = widget.device?.advName ?? 'Unknown';
    final ipAddress = status?.ipAddress ?? 'Not connected to WiFi';
    final connectedWifi = status?.connectedWifi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Device Information',
          style: theme.textTheme.ppMori400White14,
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
              // Connection Status
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _isBLEDeviceConnected ? Colors.green : Colors.red,
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
                  _isBLEDeviceConnected
                      ? const SizedBox()
                      : InkWell(
                          onTap: () async {
                            final device = widget.device.toFFBluetoothDevice();
                            await injector<FFBluetoothService>()
                                .connectToDevice(device);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColor.feralFileMediumGrey,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Connect',
                              style: theme.textTheme.ppMori400White12,
                            ),
                          ),
                        ),
                ],
              ),

              const SizedBox(height: 16),

              // Device ID
              Text(
                'Device ID:',
                style: theme.textTheme.ppMori400Grey14,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      deviceId,
                      style: theme.textTheme.ppMori400White14,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: deviceId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Device ID copied to clipboard'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColor.feralFileMediumGrey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Copy',
                        style: theme.textTheme.ppMori400White12,
                      ),
                    ),
                  ),
                ],
              ),

              // Version Information
              if (installedVersion != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Software Version:',
                  style: theme.textTheme.ppMori400Grey14,
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: installedVersion,
                        style: theme.textTheme.ppMori400White14,
                      ),
                      if (isUpToDate)
                        TextSpan(
                          text: ' - Up to date',
                          style: theme.textTheme.ppMori400Grey14,
                        )
                      else
                        TextSpan(
                          text: ' - Update available',
                          style: theme.textTheme.ppMori400Grey14,
                        ),
                    ],
                  ),
                ),
              ],

              // IP Address
              if (ipAddress != null) ...[
                const SizedBox(height: 16),
                Text(
                  'IP Address:',
                  style: theme.textTheme.ppMori400Grey14,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ipAddress,
                        style: theme.textTheme.ppMori400White14,
                      ),
                    ),
                    if (status?.isConnectedToWifi == true)
                      InkWell(
                        onTap: () {
                          final url = 'http://$ipAddress:8080/logs.html';
                          injector<NavigationService>().openUrl(Uri.parse(url));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColor.feralFileLightBlue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'View device logs',
                            style: theme.textTheme.ppMori400White12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],

              // Connected WiFi
              if (connectedWifi != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Device WiFi Network:',
                  style: theme.textTheme.ppMori400Grey14,
                ),
                const SizedBox(height: 4),
                Text(
                  connectedWifi,
                  style: theme.textTheme.ppMori400White14,
                ),
              ],
            ],
          ),
        ),

        // Update Button
        if (!isUpToDate && latestVersion != null) ...[
          const SizedBox(height: 16),
          PrimaryAsyncButton(
            text: 'Update to latest version v.$latestVersion',
            color: AppColor.white,
            onTap: () async {
              final device = widget.device!.toFFBluetoothDevice();
              await injector<CanvasClientServiceV2>()
                  .updateToLatestVersion(device);
            },
          ),
        ],
        const SizedBox(height: 30),
      ],
    );
  }

  // Enable metrics streaming from the device
  Future<void> _enableMetricsStreaming() async {
    try {
      final device = widget.device.toFFBluetoothDevice();
      log.info('Enabling metrics streaming for device: ${device.name}');
      await injector<CanvasClientServiceV2>().enableMetricsStreaming(device);

      // Subscribe to the metrics stream
      _metricsStreamSubscription?.cancel(); // Cancel any existing subscription
      _metricsStreamSubscription = injector<FFBluetoothService>()
          .deviceRealtimeMetricsStream
          .listen(_updateMetricsFromStream);
    } catch (e) {
      log.warning('Failed to enable metrics streaming: $e');
    }
  }

  // Disable metrics streaming from the device
  Future<void> _disableMetricsStreaming() async {
    try {
      // Cancel the stream subscription
      _metricsStreamSubscription?.cancel();
      _metricsStreamSubscription = null;

      final device = widget.device.toFFBluetoothDevice();
      log.info('Disabling metrics streaming for device: ${device.name}');
      await injector<CanvasClientServiceV2>().disableMetricsStreaming(device);
    } catch (e) {
      log.warning('Failed to disable metrics streaming: $e');
    }
  }

  void _startPerformanceMetricsUpdates() {
    // We don't need this anymore as we're using the stream directly
    // _metricsUpdateTimer = Timer.periodic(...);
  }

  void _updateMetricsFromStream(DeviceRealtimeMetrics metrics) {
    if (!mounted) return;

    setState(() {
      // Add new performance data points
      _cpuPoints.add(FlSpot(metrics.timestamp.toDouble(), metrics.cpuUsage));
      _memoryPoints
          .add(FlSpot(metrics.timestamp.toDouble(), metrics.memoryUsage));
      _gpuPoints
          .add(FlSpot(metrics.timestamp.toDouble(), metrics.gpuUsage / 10));

      // Add new temperature data points
      _cpuTempPoints
          .add(FlSpot(metrics.timestamp.toDouble(), metrics.cpuTemperature));
      _gpuTempPoints
          .add(FlSpot(metrics.timestamp.toDouble(), metrics.gpuTemperature));

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
                  )),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
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
    final locale = Localizations.localeOf(context);
    final usesFahrenheit = locale.countryCode == 'US';

    // Define colors for each metric
    const cpuTempColor = Colors.blue;
    const gpuTempColor = Colors.red;

    // Get the latest values from the points arrays
    final cpuTempValue =
        _cpuTempPoints.isNotEmpty ? _cpuTempPoints.last.y : null;
    final gpuTempValue =
        _gpuTempPoints.isNotEmpty ? _gpuTempPoints.last.y : null;

    // Convert to Fahrenheit if needed
    final cpuTempDisplayValue = cpuTempValue != null && usesFahrenheit
        ? _celsiusToFahrenheit(cpuTempValue)
        : cpuTempValue;
    final gpuTempDisplayValue = gpuTempValue != null && usesFahrenheit
        ? _celsiusToFahrenheit(gpuTempValue)
        : gpuTempValue;

    // Temperature unit
    final tempUnit = usesFahrenheit ? '°F' : '°C';

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
                  'CPU Temp', cpuTempDisplayValue, tempUnit, cpuTempColor),
              _metricDisplay(
                  'GPU Temp', gpuTempDisplayValue, tempUnit, gpuTempColor),
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
                minY: usesFahrenheit ? 104 : 40,
                // 40°C = 104°F
                maxY: usesFahrenheit ? 212 : 100,
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
                      usesFahrenheit
                          ? _cpuTempPoints
                              .map((spot) =>
                                  FlSpot(spot.x, _celsiusToFahrenheit(spot.y)))
                              .toList()
                          : _cpuTempPoints,
                      cpuTempColor,
                      'CPU Temp'),
                  _createLineData(
                      usesFahrenheit
                          ? _gpuTempPoints
                              .map((spot) =>
                                  FlSpot(spot.x, _celsiusToFahrenheit(spot.y)))
                              .toList()
                          : _gpuTempPoints,
                      gpuTempColor,
                      'GPU Temp'),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval:
                          usesFahrenheit ? 36 : 20, // ~20°C = 36°F interval
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
                  enabled: true,
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
                        final value = usesFahrenheit
                            ? _celsiusToFahrenheit(barSpot.y)
                            : barSpot.y;

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

  // Helper method to convert Celsius to Fahrenheit
  double _celsiusToFahrenheit(double celsius) {
    return (celsius * 9 / 5) + 32;
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
      List<FlSpot> points, Color color, String label) {
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
