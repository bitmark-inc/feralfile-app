import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:floor/floor.dart';
//ignore_for_file: lines_longer_than_80_chars

@dao
abstract class WalletAddressDao {
  @Query('SELECT * FROM WalletAddress')
  Future<List<WalletAddress>> getAllAddresses();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertAddress(WalletAddress address);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertAddresses(List<WalletAddress> addresses);

  @Query('SELECT * FROM WalletAddress WHERE address = :address')
  Future<WalletAddress?> findByAddress(String address);

  @Query('SELECT * FROM WalletAddress WHERE uuid = :uuid')
  Future<List<WalletAddress>> findByWalletID(String uuid);

  @Query('SELECT * FROM WalletAddress WHERE isHidden = :isHidden')
  Future<List<WalletAddress>> findAddressesWithHiddenStatus(bool isHidden);

  @Query(
      'SELECT * FROM WalletAddress WHERE uuid = :uuid AND cryptoType = :cryptoType')
  Future<List<WalletAddress>> getAddresses(String uuid, String cryptoType);

  @Query('SELECT * FROM WalletAddress WHERE cryptoType = :cryptoType')
  Future<List<WalletAddress>> getAddressesByType(String cryptoType);

  @Query(
      'UPDATE WalletAddress SET isHidden = :isHidden WHERE address = :address')
  Future<void> setAddressIsHidden(String address, bool isHidden);

  // update order query
  @Query(
      'UPDATE WalletAddress SET accountOrder = :accountOrder WHERE address = :address')
  Future<void> setAddressOrder(String address, int accountOrder);

  @update
  Future<void> updateAddress(WalletAddress address);

  @delete
  Future<void> deleteAddress(WalletAddress address);

  @Query('DELETE FROM WalletAddress')
  Future<void> removeAll();
}
