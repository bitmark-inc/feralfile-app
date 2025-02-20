//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:floor/floor.dart';
import 'package:autonomy_flutter/nft_collection/models/address_collection.dart';

@dao
abstract class AddressCollectionDao {
  @Query('SELECT * FROM AddressCollection')
  Future<List<AddressCollection>> findAllAddresses();

  @Query('SELECT * FROM AddressCollection WHERE address IN (:addresses)')
  Future<List<AddressCollection>> findAddresses(List<String> addresses);

  @Query('SELECT address FROM AddressCollection WHERE isHidden = :isHidden')
  Future<List<String>> findAddressesIsHidden(bool isHidden);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertAddresses(List<AddressCollection> addresses);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertAddressesAbort(List<AddressCollection> addresses);

  @Query(
      'UPDATE AddressCollection SET isHidden = :isHidden WHERE address IN (:addresses)')
  Future<void> setAddressIsHidden(List<String> addresses, bool isHidden);

  @Query(
      'UPDATE AddressCollection SET lastRefreshedTime = :time WHERE address IN (:addresses)')
  Future<void> updateRefreshTime(List<String> addresses, int time);

  @update
  Future<void> updateAddresses(List<AddressCollection> addresses);

  @Query('DELETE FROM AddressCollection WHERE address IN (:addresses)')
  Future<void> deleteAddresses(List<String> addresses);

  @delete
  Future<void> deleteAddress(AddressCollection address);

  @Query('DELETE FROM AddressCollection')
  Future<void> removeAll();
}
