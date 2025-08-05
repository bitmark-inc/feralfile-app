import 'package:autonomy_flutter/model/error/error.dart';
import 'package:collection/collection.dart';

enum FFBluetoothResponseErrorCode {
  userEnterWrongPassword(1),
  wifiConnectedButNoInternet(2),
  wifiConnectedButCannotReachServer(3),
  // BLE_ERR_CODE_WIFI_REQUIRED
  wifiRequired(4),
  // BLE_ERR_CODE_DEVICE_UPDATING
  deviceUpdating(5),
  // BLE_ERR_CODE_VERSION_CHECK_FAILED
  versionCheckFailed(6),
  unknownError(255);

  const FFBluetoothResponseErrorCode(this.code);

  final int code;
}

class FFBluetoothResponseError implements FFError {
  FFBluetoothResponseError(this.message, {this.title = 'Error'});

  @override
  final String message;
  final String title;

  static FFBluetoothResponseError fromErrorCode(int errorCode) {
    final error = FFBluetoothResponseErrorCode.values
        .firstWhereOrNull((e) => e.code == errorCode);
    switch (error) {
      case FFBluetoothResponseErrorCode.userEnterWrongPassword:
        // user enter wrong password
        return FFBluetoothResponseError(
            title: 'Incorrect Wi-Fi Password',
            'Failed to connect to Wi-Fi. Please check your password and try again.');
      case FFBluetoothResponseErrorCode.wifiConnectedButCannotReachServer:
        return FFBluetoothResponseError(
          title: 'Server Unreachable',
          'Connected to Wi-Fi but cannot reach our server. Please check your internet connection.',
        );
      case FFBluetoothResponseErrorCode.wifiConnectedButNoInternet:
        return FFBluetoothResponseError(
          title: 'No Internet Access',
          'Connected to Wi-Fi but no internet access. Please check your internet connection.',
        );
      case FFBluetoothResponseErrorCode.wifiRequired:
        return FFBluetoothResponseError(
          title: 'Wi-Fi Required',
          'This device requires a Wi-Fi connection to function properly. Please connect to a Wi-Fi network.',
        );
      case FFBluetoothResponseErrorCode.deviceUpdating:
        return DeviceUpdatingError();

      case FFBluetoothResponseErrorCode.versionCheckFailed:
        return DeviceVersionCheckFailedError();
      default:
        return FFBluetoothResponseError(
          title: 'Wi-Fi Connection Error',
          'Unknown error occurred while connecting to Wi-Fi. Error code: $errorCode',
        );
    }
  }

  // toString() {
  @override
  String toString() {
    return message;
  }
}

class DeviceUpdatingError extends FFBluetoothResponseError {
  DeviceUpdatingError()
      : super(
          'The FF1 is currently updating. Please wait for the update to complete and try again.',
          title: 'FF1 is Updating',
        );
}

class DeviceVersionCheckFailedError extends FFBluetoothResponseError {
  DeviceVersionCheckFailedError()
      : super(
          'The FF1 version check failed. Please try again or contact support.',
          title: 'Version Check Failed',
        );
}
