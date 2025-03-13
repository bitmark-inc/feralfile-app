//
//  Generated code. Do not modify.
//  source: protos/system_metrics.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class DeviceRealtimeMetrics extends $pb.GeneratedMessage {
  factory DeviceRealtimeMetrics({
    $core.double? cpuUsage,
    $core.double? gpuUsage,
    $core.double? memoryUsage,
    $core.double? cpuTemperature,
    $core.double? gpuTemperature,
    $core.int? screenWidth,
    $core.int? screenHeight,
    $fixnum.Int64? uptimeSeconds,
    $fixnum.Int64? timestamp,
  }) {
    final $result = create();
    if (cpuUsage != null) {
      $result.cpuUsage = cpuUsage;
    }
    if (gpuUsage != null) {
      $result.gpuUsage = gpuUsage;
    }
    if (memoryUsage != null) {
      $result.memoryUsage = memoryUsage;
    }
    if (cpuTemperature != null) {
      $result.cpuTemperature = cpuTemperature;
    }
    if (gpuTemperature != null) {
      $result.gpuTemperature = gpuTemperature;
    }
    if (screenWidth != null) {
      $result.screenWidth = screenWidth;
    }
    if (screenHeight != null) {
      $result.screenHeight = screenHeight;
    }
    if (uptimeSeconds != null) {
      $result.uptimeSeconds = uptimeSeconds;
    }
    if (timestamp != null) {
      $result.timestamp = timestamp;
    }
    return $result;
  }
  DeviceRealtimeMetrics._() : super();
  factory DeviceRealtimeMetrics.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeviceRealtimeMetrics.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeviceRealtimeMetrics', package: const $pb.PackageName(_omitMessageNames ? '' : 'feralfile'), createEmptyInstance: create)
    ..a<$core.double>(1, _omitFieldNames ? '' : 'cpuUsage', $pb.PbFieldType.OD)
    ..a<$core.double>(2, _omitFieldNames ? '' : 'gpuUsage', $pb.PbFieldType.OD)
    ..a<$core.double>(3, _omitFieldNames ? '' : 'memoryUsage', $pb.PbFieldType.OD)
    ..a<$core.double>(4, _omitFieldNames ? '' : 'cpuTemperature', $pb.PbFieldType.OD)
    ..a<$core.double>(5, _omitFieldNames ? '' : 'gpuTemperature', $pb.PbFieldType.OD)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'screenWidth', $pb.PbFieldType.O3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'screenHeight', $pb.PbFieldType.O3)
    ..aInt64(8, _omitFieldNames ? '' : 'uptimeSeconds')
    ..aInt64(9, _omitFieldNames ? '' : 'timestamp')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeviceRealtimeMetrics clone() => DeviceRealtimeMetrics()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeviceRealtimeMetrics copyWith(void Function(DeviceRealtimeMetrics) updates) => super.copyWith((message) => updates(message as DeviceRealtimeMetrics)) as DeviceRealtimeMetrics;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeviceRealtimeMetrics create() => DeviceRealtimeMetrics._();
  DeviceRealtimeMetrics createEmptyInstance() => create();
  static $pb.PbList<DeviceRealtimeMetrics> createRepeated() => $pb.PbList<DeviceRealtimeMetrics>();
  @$core.pragma('dart2js:noInline')
  static DeviceRealtimeMetrics getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeviceRealtimeMetrics>(create);
  static DeviceRealtimeMetrics? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get cpuUsage => $_getN(0);
  @$pb.TagNumber(1)
  set cpuUsage($core.double v) { $_setDouble(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCpuUsage() => $_has(0);
  @$pb.TagNumber(1)
  void clearCpuUsage() => clearField(1);

  @$pb.TagNumber(2)
  $core.double get gpuUsage => $_getN(1);
  @$pb.TagNumber(2)
  set gpuUsage($core.double v) { $_setDouble(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasGpuUsage() => $_has(1);
  @$pb.TagNumber(2)
  void clearGpuUsage() => clearField(2);

  @$pb.TagNumber(3)
  $core.double get memoryUsage => $_getN(2);
  @$pb.TagNumber(3)
  set memoryUsage($core.double v) { $_setDouble(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMemoryUsage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMemoryUsage() => clearField(3);

  @$pb.TagNumber(4)
  $core.double get cpuTemperature => $_getN(3);
  @$pb.TagNumber(4)
  set cpuTemperature($core.double v) { $_setDouble(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasCpuTemperature() => $_has(3);
  @$pb.TagNumber(4)
  void clearCpuTemperature() => clearField(4);

  @$pb.TagNumber(5)
  $core.double get gpuTemperature => $_getN(4);
  @$pb.TagNumber(5)
  set gpuTemperature($core.double v) { $_setDouble(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasGpuTemperature() => $_has(4);
  @$pb.TagNumber(5)
  void clearGpuTemperature() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get screenWidth => $_getIZ(5);
  @$pb.TagNumber(6)
  set screenWidth($core.int v) { $_setSignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasScreenWidth() => $_has(5);
  @$pb.TagNumber(6)
  void clearScreenWidth() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get screenHeight => $_getIZ(6);
  @$pb.TagNumber(7)
  set screenHeight($core.int v) { $_setSignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasScreenHeight() => $_has(6);
  @$pb.TagNumber(7)
  void clearScreenHeight() => clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get uptimeSeconds => $_getI64(7);
  @$pb.TagNumber(8)
  set uptimeSeconds($fixnum.Int64 v) { $_setInt64(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasUptimeSeconds() => $_has(7);
  @$pb.TagNumber(8)
  void clearUptimeSeconds() => clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get timestamp => $_getI64(8);
  @$pb.TagNumber(9)
  set timestamp($fixnum.Int64 v) { $_setInt64(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasTimestamp() => $_has(8);
  @$pb.TagNumber(9)
  void clearTimestamp() => clearField(9);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
