import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:floor/floor.dart';

@dao
abstract class WalletAddressDao {
  @Query('SELECT * FROM WalletAddress')
  Future<List<WalletAddress>> getAllAddresses();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertAddress(WalletAddress address);

  @Query('SELECT * FROM WalletAddress WHERE address = :address')
  Future<WalletAddress?> findByAddress(String address);

  @Query('SELECT * FROM WalletAddress WHERE uuid = :uuid')
  Future<List<WalletAddress>> findById(String uuid);

  @Query('SELECT * FROM WalletAddress WHERE isHidden = :isHidden')
  Future<List<WalletAddress>> findHiddenAddresses(bool isHidden);

  @Query(
      'SELECT * FROM WalletAddress WHERE uuid = (:uuid) AND cryptoType = (:cryptoType)')
  Future<List<WalletAddress>> getAddresses(String uuid, String cryptoType);

  @update
  Future<void> updateAddress(WalletAddress address);

  @delete
  Future<void> deleteAddress(WalletAddress address);

  @Query('DELETE FROM WalletAddress')
  Future<void> removeAll();
}
