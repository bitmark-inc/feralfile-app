import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:floor/floor.dart';

@dao
abstract class WalletAddressDao {
  @Query('SELECT * FROM WalletAddress')
  Future<List<WalletAddress>> getAllAddresses();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertAddresses(List<WalletAddress> addresses);

  @Query('DELETE FROM WalletAddress')
  Future<void> removeAll();
}
