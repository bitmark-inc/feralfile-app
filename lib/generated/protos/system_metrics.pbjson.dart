//
//  Generated code. Do not modify.
//  source: protos/system_metrics.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use deviceRealtimeMetricsDescriptor instead')
const DeviceRealtimeMetrics$json = {
  '1': 'DeviceRealtimeMetrics',
  '2': [
    {'1': 'cpu_usage', '3': 1, '4': 1, '5': 1, '10': 'cpuUsage'},
    {'1': 'gpu_usage', '3': 2, '4': 1, '5': 1, '10': 'gpuUsage'},
    {'1': 'memory_usage', '3': 3, '4': 1, '5': 1, '10': 'memoryUsage'},
    {'1': 'cpu_temperature', '3': 4, '4': 1, '5': 1, '10': 'cpuTemperature'},
    {'1': 'gpu_temperature', '3': 5, '4': 1, '5': 1, '10': 'gpuTemperature'},
    {'1': 'screen_width', '3': 6, '4': 1, '5': 5, '10': 'screenWidth'},
    {'1': 'screen_height', '3': 7, '4': 1, '5': 5, '10': 'screenHeight'},
    {'1': 'uptime_seconds', '3': 8, '4': 1, '5': 3, '10': 'uptimeSeconds'},
    {'1': 'timestamp', '3': 9, '4': 1, '5': 3, '10': 'timestamp'},
  ],
};

/// Descriptor for `DeviceRealtimeMetrics`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deviceRealtimeMetricsDescriptor = $convert.base64Decode(
    'ChVEZXZpY2VSZWFsdGltZU1ldHJpY3MSGwoJY3B1X3VzYWdlGAEgASgBUghjcHVVc2FnZRIbCg'
    'lncHVfdXNhZ2UYAiABKAFSCGdwdVVzYWdlEiEKDG1lbW9yeV91c2FnZRgDIAEoAVILbWVtb3J5'
    'VXNhZ2USJwoPY3B1X3RlbXBlcmF0dXJlGAQgASgBUg5jcHVUZW1wZXJhdHVyZRInCg9ncHVfdG'
    'VtcGVyYXR1cmUYBSABKAFSDmdwdVRlbXBlcmF0dXJlEiEKDHNjcmVlbl93aWR0aBgGIAEoBVIL'
    'c2NyZWVuV2lkdGgSIwoNc2NyZWVuX2hlaWdodBgHIAEoBVIMc2NyZWVuSGVpZ2h0EiUKDnVwdG'
    'ltZV9zZWNvbmRzGAggASgDUg11cHRpbWVTZWNvbmRzEhwKCXRpbWVzdGFtcBgJIAEoA1IJdGlt'
    'ZXN0YW1w');

