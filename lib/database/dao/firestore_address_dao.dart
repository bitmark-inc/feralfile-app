import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:autonomy_flutter/service/cloud_firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:floor/floor.dart';

abstract class FirestoreWalletAddressDao {
  Future<List<WalletAddress>> getAllAddresses();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertAddress(WalletAddress address);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertAddresses(List<WalletAddress> addresses);

  Future<WalletAddress?> findByAddress(String address);

  Future<List<WalletAddress>> findByWalletID(String uuid);

  Future<List<WalletAddress>> findAddressesWithHiddenStatus(bool isHidden);

  Future<List<WalletAddress>> getAddresses(String uuid, String cryptoType);

  Future<List<WalletAddress>> getAddressesByType(String cryptoType);

  Future<void> setAddressIsHidden(String address, bool isHidden);

  @update
  Future<void> updateAddress(WalletAddress address);

  @delete
  Future<void> deleteAddress(WalletAddress address);

  Future<void> removeAll();
}

class FirestoreWalletAddressDaoImp implements FirestoreWalletAddressDao {
  CloudFirestoreService firestoreService;
  final _collection = FirestoreCollection.walletAddress;

  CollectionReference<WalletAddress> get _collectionRef =>
      firestoreService.getCollection(_collection).withConverter<WalletAddress>(
          fromFirestore: (snapshot, _) =>
              WalletAddress.fromJson(snapshot.data()!),
          toFirestore: (address, _) => address.toJson());

  FirestoreWalletAddressDaoImp(this.firestoreService);

  @override
  Future<List<WalletAddress>> getAllAddresses() => _collectionRef.get().then(
        (snapshot) => snapshot.docs.map((e) => e.data()).toList(),
      );

  @override
  Future<void> insertAddress(WalletAddress address) =>
      _collectionRef.doc(address.address).set(address);

  @override
  Future<void> insertAddresses(List<WalletAddress> addresses) {
    final batch = firestoreService.getBatch();
    for (final WalletAddress address in addresses) {
      batch.set(_collectionRef.doc(address.address), address);
    }
    return batch.commit();
  }

  @override
  Future<WalletAddress?> findByAddress(String address) =>
      _collectionRef.doc(address).get().then(
        (snapshot) {
          if (snapshot.exists) {
            return snapshot.data();
          } else {
            return null;
          }
        },
      );

  @override
  Future<List<WalletAddress>> findByWalletID(String uuid) => _collectionRef
      .where('uuid', isEqualTo: uuid)
      .get()
      .then((snapshot) => snapshot.docs.map((e) => e.data()).toList());

  @override
  Future<List<WalletAddress>> findAddressesWithHiddenStatus(bool isHidden) =>
      _collectionRef
          .where('isHidden', isEqualTo: isHidden)
          .get()
          .then((snapshot) => snapshot.docs.map((e) => e.data()).toList());

  @override
  Future<List<WalletAddress>> getAddresses(String uuid, String cryptoType) =>
      _collectionRef
          .where('uuid', isEqualTo: uuid)
          .where('cryptoType', isEqualTo: cryptoType)
          .get()
          .then((snapshot) => snapshot.docs.map((e) => e.data()).toList());

  @override
  Future<List<WalletAddress>> getAddressesByType(String cryptoType) =>
      _collectionRef
          .where('cryptoType', isEqualTo: cryptoType)
          .get()
          .then((snapshot) => snapshot.docs.map((e) => e.data()).toList());

  @override
  Future<void> setAddressIsHidden(String address, bool isHidden) =>
      _collectionRef.doc(address).update({'isHidden': isHidden});

  @override
  Future<void> updateAddress(WalletAddress address) =>
      _collectionRef.doc(address.address).update(address.toJson());

  @override
  Future<void> deleteAddress(WalletAddress address) =>
      _collectionRef.doc(address.address).delete();

  @override
  Future<void> removeAll() => _collectionRef.get().then((snapshot) {
        final batch = firestoreService.getBatch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        return batch.commit();
      });
}
