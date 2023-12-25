// hiveService abstract class
import 'package:autonomy_flutter/model/eth_pending_tx_amount.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:hive/hive.dart';

abstract class HiveService {
  Future<void> saveEthPendingTxAmount(
      EthereumPendingTxAmount tx, String address);

  Future<void> deleteEthPendingTxAmount(String txHash, String address);

  Future<List<EthereumPendingTxAmount>> getEthPendingTxAmounts(String address);
}

class HiveServiceImpl implements HiveService {
  static const ethPendingTxBox = 'ethPendingTxBox';

  @override
  Future<void> deleteEthPendingTxAmount(String txHash, String address) async {
    final key = address.toLowerCase();
    try {
      final box = Hive.box<List<EthereumPendingTxAmount>>(ethPendingTxBox);
      final List<EthereumPendingTxAmount> existingList =
          box.get(key, defaultValue: null) ?? [];
      if (existingList.any((element) => element.txHash == txHash)) {
        existingList.removeWhere((element) => element.txHash == txHash);
        await box.put(key, existingList);
      }
    } catch (e) {
      log.info('Hive error deleting tx from Hive: $e');
      return Future.value();
    }
  }

  @override
  Future<List<EthereumPendingTxAmount>> getEthPendingTxAmounts(
      String address) async {
    final key = address.toLowerCase();
    try {
      final box =
          await Hive.openBox<List<EthereumPendingTxAmount>>(ethPendingTxBox);

      final List<EthereumPendingTxAmount> existingList =
          box.get(key, defaultValue: null) ?? [];
      if (existingList.any((element) => element.isExpired)) {
        final newList =
            existingList.where((element) => !element.isExpired).toList();
        await box.put(key, newList);
        return newList;
      }
      return existingList;
    } catch (e) {
      log.info('Hive error getting tx from Hive: $e');
      return [];
    }
  }

  @override
  Future<void> saveEthPendingTxAmount(
      EthereumPendingTxAmount tx, String address) async {
    final key = address.toLowerCase();
    try {
      final box =
          await Hive.openBox<List<EthereumPendingTxAmount>>(ethPendingTxBox);

      // Get the existing list of transactions or create a new list
      final List<EthereumPendingTxAmount> existingList =
          box.get(key, defaultValue: null) ?? []
            ..add(tx);

      // Save the updated list back to the box
      await box.put(key, existingList);
    } catch (e) {
      log.info('Hive error saving tx to Hive: $e');
    }
  }
}
