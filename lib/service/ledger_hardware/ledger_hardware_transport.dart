import 'dart:convert';
import 'dart:typed_data';

import 'package:autonomy_flutter/util/endian_int_ext.dart';
import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue/flutter_blue.dart';

class SWCode {
  static int OK = 0x9000;
  static int INS_NOT_SUPPORTED = 0x6D00;
  static int WRONG_P1_P2 = 0x6B00;
  static int INCORRECT_P1_P2 = 0x6A86;
  static int RECONNECT = 0x6FAA;
  static int INVALID_STATUS = 0x6700;
  static int REJECTED = 0x6985;
  static int INVALID_PKG = 0x6982;
  static int ABORT = 0x0000;
}

class LedgerHardwareWallet {
  final String name;
  final BluetoothDevice device;
  bool isConnected = false;
  BluetoothCharacteristic? writeCharacteristic;
  BluetoothCharacteristic? writeCMDCharacteristic;
  BluetoothCharacteristic? notifyCharacteristic;
  List<String> errors = List.empty();
  int _currentCounter = 0;

  LedgerHardwareWallet(this.name, this.device);

  static const int _TAG_APDU = 0x05;
  static const int _MTU = 128;

  List<int> _wrapCommandAPDU(
      {required int channel,
      required List<int> command,
      int packetSize = _MTU,
      bool hasChannel = false}) {
    if (packetSize < 3) {
      throw "InvalidParameter";
    }
    List<int> buffer = List.empty();

    int sequenceIdx = 0;
    int offset = 0;
    int headerSize = hasChannel ? 7 : 5;
    int size = command.length;
    buffer += hasChannel ? [channel >> 8, channel] : [];
    buffer += [_TAG_APDU, sequenceIdx >> 8, sequenceIdx];
    sequenceIdx += 1;
    buffer += [size >> 8, size];
    int blockSize = command.length > packetSize - headerSize
        ? packetSize - headerSize
        : size;
    buffer += command.sublist(offset, offset + blockSize);
    offset += blockSize;

    while (offset != size) {
      buffer += hasChannel ? [channel >> 8, channel] : [];
      buffer += [_TAG_APDU, sequenceIdx >> 8, sequenceIdx];
      sequenceIdx += 1;
      blockSize = (size - offset > packetSize - headerSize + 2
          ? packetSize - headerSize + 2
          : size - offset);
      buffer += command.sublist(offset, offset + blockSize);
      offset += blockSize;
    }

    if (buffer.length % packetSize != 0) {
      final len = packetSize - buffer.length % packetSize;
      final pad = List<int>.filled(len, 0);
      buffer += pad;
    }
    return buffer;
  }

  List<int> _unwrapResponseAPDU(
      int channel, List<int> data, int packetSize, bool hasChannel) {
    List<int> buffer = List.empty();
    int offset = 0;
    int sequenceIdx = 0;
    int headerSize = hasChannel ? 7 : 5;
    if (data.length < headerSize) {
      throw "LedgerError.IOError";
    }

    if (hasChannel) {
      if (data[0] != channel >> 8 || data[1] != channel & 0xff) {
        throw "LedgerError.IOError";
      }
      offset += 2;
    }

    if (data[offset] != _TAG_APDU) {
      throw "LedgerError.IOError";
    }
    if (data[offset + 1] != 0x00) {
      throw "LedgerError.IOError";
    }
    if (data[offset + 2] != 0x00) {
      throw "LedgerError.IOError";
    }
    var responseLength = (data[offset + 3] & 0xff) << 8;
    responseLength |= data[offset + 4] & 0xff;
    offset += 5;
    if (data.length < headerSize + responseLength) {
      throw "LedgerError.IOError";
    }
    int blockSize = responseLength > packetSize - headerSize
        ? packetSize - headerSize
        : responseLength;
    buffer += data.sublist(offset, offset + blockSize);
    offset += blockSize;

    while (buffer.length != responseLength) {
      sequenceIdx += 1;
      if (offset == data.length) {
        throw "LedgerError.IOError";
      }
      if (hasChannel) {
        if (data[offset] != channel >> 8 ||
            data[offset + 1] != channel & 0xff) {
          throw "LedgerError.IOError";
        }
        offset += 2;
      }
      if (data[offset] != _TAG_APDU) {
        throw "LedgerError.IOError";
      }
      if (data[offset + 1] != sequenceIdx >> 8) {
        throw "LedgerError.IOError";
      }
      if (data[offset + 2] != sequenceIdx & 0xff) {
        throw "LedgerError.IOError";
      }
      offset += 3;
      blockSize = (responseLength - buffer.length > packetSize - headerSize + 2
          ? packetSize - headerSize + 2
          : responseLength - buffer.length);
      if (blockSize > data.length - offset) {
        throw "LedgerError.IOError";
      }
      buffer += data.sublist(offset, offset + blockSize);
      offset += blockSize;
    }
    return buffer;
  }

  Future<void> _send(List<int> data) async {
    if (writeCharacteristic == null) {
      throw ("writeCharacteristic is null");
    }
    print("=> Before wrapping: " + hex.encode(data));
    final buf = _wrapCommandAPDU(
      channel: 0,
      command: data,
      packetSize: _MTU,
      hasChannel: false,
    );
    print("=> After wrapping: " + hex.encode(buf));

    await writeCharacteristic!.write(buf);
  }

  Future<List<int>> _response(List<int> data) async {
    print("<= Before unwrap: " + hex.encode(data));
    final res = _unwrapResponseAPDU(0, data, data.length, false);
    print("<= After unwrap" + hex.encode(res));
    final command = res.sublist(0, res.length - 2);
    final lastSW = (res[res.length - 2] << 8) + res[res.length - 1];
    if (lastSW != SWCode.OK) {
      throw "Response not ok";
    }
    return command;
  }

  Future<List<int>> _exchange(List<int> data) async {
    await _send(data);
    if (notifyCharacteristic == null) {
      throw ("notifyCharacteristic is null");
    }
    final result = await notifyCharacteristic!.read();
    _currentCounter++;
    return await _response(result);
  }

  Future<List<int>> exchangeADPU(ADPU adpu) async {
    var buffer = List<int>.from([adpu.cla, adpu.ins, adpu.p1, adpu.p2]);
    if (adpu.payload != null) {
      buffer += [adpu.payload!.length] + adpu.payload!;
    }

    return await _exchange(buffer);
  }
}

/// Class defines ISO/IEC 7816-4 command APDU
class ADPU {
  int cla;
  int ins;
  int p1;
  int p2;
  List<int>? payload;

  ADPU(
      {required this.cla,
      required this.ins,
      required this.p1,
      required this.p2,
      this.payload});
}

String getLabelFromCode(int code) {
  String labelResponse = '';
  switch (code) {
    case 0x6d00:
      labelResponse = 'Invalid parameter received';
      break;
    case 0x670A:
      labelResponse = 'Lc is 0x00 whereas an application name is required';
      break;
    case 0x6807:
      labelResponse = 'The requested application is not present';
      break;
    case 0x6985:
      labelResponse = 'Cancel the operation';
      break;
    case 0x9000:
      labelResponse = 'Success of the operation';
      break;
    case 0x0000:
      labelResponse = 'Success of the operation';
      break;
    default:
      labelResponse = 'Other error';
  }
  return labelResponse;
}

class LedgerTransportResult {
  int statusWord;
  Uint8List data;
  LedgerTransportResult({required this.statusWord, required this.data});
}

class LedgerCommand {
  static const int CLA_BOLOS = 0xE0;
  static const int INS_GET_VERSION = 0x01;
  static const int INS_RUN_APP = 0xD8;
  static const int INS_QUIT_APP = 0xA7;
  static const int CLA_COMMON_SDK = 0xB0;
  static const int INS_GET_FIRMWARE_VERSION = 0xc4;
  static const int INS_GET_APP_NAME_AND_VERSION = 0x01;
  static const int INS_GET_WALLET_PUBLIC_KEY = 0x40;
  static const int INS_SIGN_MESSAGE = 0x4e;
  static const int INS_HASH_INPUT_START = 0x44;
  static const int INS_HASH_SIGN = 0x48;
  static const int INS_HASH_INPUT_FINALIZE_FULL = 0x4a;
  static const int INS_EXIT = 0xA7;

  static Future<Map<String, dynamic>> version(
      LedgerHardwareWallet ledger) async {
    final adpu = ADPU(cla: CLA_BOLOS, ins: INS_GET_VERSION, p1: 0, p2: 0);
    final buffer = await ledger.exchangeADPU(adpu);
    final targetID = buffer.sublist(0, 4);
    final versionSize = buffer[4];
    final version = utf8.decode(buffer.sublist(5, 5 + versionSize));
    final flagSize = buffer[5 + versionSize];
    final osFlags = buffer.sublist(6 + versionSize, 6 + versionSize + flagSize);
    final mcuSize = buffer[6 + versionSize + flagSize];
    final mcuVersion = utf8.decode(buffer.sublist(
        7 + versionSize + flagSize, 7 + versionSize + flagSize + mcuSize));
    return {
      "targetID": targetID,
      "version": version,
      "osFlags": osFlags,
      "mcuVersion": mcuVersion
    };
  }

  static Future<Map<String, dynamic>> application(
      LedgerHardwareWallet ledger) async {
    const APP_DETAILS_FORMAT_VERSION = 1;
    final adpu = ADPU(
        cla: CLA_COMMON_SDK, ins: INS_GET_APP_NAME_AND_VERSION, p1: 0, p2: 0);
    final buffer = await ledger.exchangeADPU(adpu);
    if (buffer[0] != APP_DETAILS_FORMAT_VERSION) {
      throw SWCode.INVALID_STATUS;
    }
    final nameLength = buffer[1] & 0xff;
    final name = utf8.decode(buffer.sublist(2, nameLength + 2));
    final offset = nameLength + 2;
    final versionLength = buffer[offset] & 0xff;
    final version =
        utf8.decode(buffer.sublist(offset + 1, offset + versionLength + 1));
    return {"name": name, "version": version};
  }

  static List<int> pathToData(List<int> paths) {
    if (paths.length == 0) {
      return [0];
    } else if (paths.length > 10) {
      throw "GaError.GenericError";
    }
    var buffer = List<int>.empty(growable: true);

    for (int p in paths) {
      buffer += p.uint32BE();
    }
    return buffer;
  }

  static Future<Map<String, dynamic>> pubKey(
      LedgerHardwareWallet ledger, List<int> paths) async {
    final pathData = pathToData(paths);
    final adpu = ADPU(
        cla: CLA_BOLOS,
        ins: INS_GET_WALLET_PUBLIC_KEY,
        p1: 0,
        p2: 0,
        payload: pathData);
    final buffer = await ledger.exchangeADPU(adpu);
    int offset = 0;
    final publicKey = buffer.sublist(1, (buffer[offset] & 0xff) + 1);
    offset += publicKey.length + 1;
    final address = hex.encode(
        buffer.sublist(offset + 1, offset + (buffer[offset] & 0xff) + 1));
    offset += address.length + 1;
    final chainCode = buffer.sublist(offset, offset + 32);
    return {
      "publicKey": publicKey,
      "address": address,
      "chainCode": chainCode,
      "path": paths
    };
  }

  static Future<Map<String, dynamic>> getEthAddress(
      LedgerHardwareWallet ledger, List<int> paths) async {
    final pathData = pathToData(paths);
    final adpu =
        ADPU(cla: CLA_BOLOS, ins: 0x02, p1: 0, p2: 0, payload: pathData);
    final buffer = await ledger.exchangeADPU(adpu);
    int offset = 0;
    final publicKey = buffer.sublist(1, (buffer[offset] & 0xff) + 1);
    offset += publicKey.length + 1;
    final address =
        buffer.sublist(offset + 1, offset + (buffer[offset] & 0xff) + 1);
    offset += address.length + 1;
    final chainCode = buffer.sublist(offset, offset + 32);
    return {
      "publicKey": publicKey,
      "address": address,
      "chainCode": chainCode,
      "path": paths
    };
  }
}
