//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/service/cloud_firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class FirestoreConnectionDao {
  Future<List<Connection>> getConnections();

  Future<List<Connection>> getLinkedAccounts();

  Future<List<Connection>> getUpdatedLinkedAccounts();

  Future<List<Connection>> getRelatedPersonaConnections();

  Future<List<Connection>> getConnectionsByType(String type);

  Future<List<Connection>> getConnectionsByAccountNumber(String accountNumber);

  Future<void> insertConnection(Connection connection);

  Future<void> insertConnections(List<Connection> connections);

  Future<Connection?> findById(String key);

  Future<void> removeAll();

  Future<void> deleteConnection(Connection connection);

  Future<void> deleteConnections(List<Connection> connections);

  Future<void> deleteConnectionsByAccountNumber(String accountNumber);

  Future<void> deleteConnectionsByType(String type);

  Future<void> updateConnection(Connection connection);
}

class FirestoreConnectionDaoImp implements FirestoreConnectionDao {
  final _collectionName = 'connection';
  CloudFirestoreService firestoreService;

  CollectionReference<Connection> get _collectionRef =>
      firestoreService.getCollection(_collectionName).withConverter<Connection>(
          fromFirestore: (snapshot, _) => Connection.fromJson(snapshot.data()!),
          toFirestore: (connection, _) => connection.toJson());

  FirestoreConnectionDaoImp(this.firestoreService);

  @override
  Future<List<Connection>> getConnections() async => _collectionRef.get().then(
        (snapshot) => snapshot.docs.map((e) => e.data()).toList(),
      );

  @override
  Future<List<Connection>> getLinkedAccounts() {
    final query = _collectionRef.where('connectionType', whereNotIn: [
      'dappConnect',
      'dappConnect2',
      'walletConnect2',
      'beaconP2PPeer',
      'manuallyIndexerTokenID'
    ]);
    return query.get().then(
          (snapshot) => snapshot.docs.map((e) => e.data()).toList(),
        );
  }

  @override
  Future<List<Connection>> getUpdatedLinkedAccounts() async {
    final linkedAccounts = await getLinkedAccounts();
    final deprecatedConnections = linkedAccounts
        .where((element) => element.connectionType != 'manuallyAddress');
    if (deprecatedConnections.isNotEmpty) {
      await _migrateDeprecatedConnections(deprecatedConnections.toList());
      return getUpdatedLinkedAccounts();
    }

    return linkedAccounts;
  }

  @override
  Future<List<Connection>> getRelatedPersonaConnections() {
    final query = _collectionRef.where('connectionType', whereIn: [
      'dappConnect',
      'dappConnect2',
      'beaconP2PPeer',
    ]);
    return query.get().then(
          (snapshot) => snapshot.docs.map((e) => e.data()).toList(),
        );
  }

  @override
  Future<List<Connection>> getConnectionsByType(String type) async {
    final query = _collectionRef.where('connectionType', isEqualTo: type);
    // .orderBy('createdAt', descending: true);
    final connections = await query.get();
    if (connections.docs.isEmpty) {
      return [];
    } else {
      return connections.docs.map((e) => e.data()).toList();
    }
  }

  @override
  Future<List<Connection>> getConnectionsByAccountNumber(String accountNumber) {
    final query = _collectionRef
        .where('accountNumber', isEqualTo: accountNumber)
        .orderBy('createdAt', descending: true);
    return query.get().then(
          (snapshot) => snapshot.docs.map((e) => e.data()).toList(),
        );
  }

  @override
  Future<void> insertConnection(Connection connection) =>
      _collectionRef.doc(connection.key).set(connection);

  @override
  Future<void> insertConnections(List<Connection> connections) {
    final batch = firestoreService.getBatch();
    for (final connection in connections) {
      batch.set(_collectionRef.doc(connection.key), connection);
    }
    return batch.commit();
  }

  @override
  Future<Connection?> findById(String key) =>
      _collectionRef.doc(key).get().then(
        (snapshot) {
          if (snapshot.exists) {
            return snapshot.data()!;
          } else {
            return null;
          }
        },
      );

  @override
  Future<void> removeAll() => _collectionRef.get().then(
        (snapshot) {
          final batch = firestoreService.getBatch();
          for (final doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
          return batch.commit();
        },
      );

  @override
  Future<void> deleteConnection(Connection connection) =>
      _collectionRef.doc(connection.key).delete();

  @override
  Future<void> deleteConnections(List<Connection> connections) {
    final batch = firestoreService.getBatch();
    for (final connection in connections) {
      batch.delete(_collectionRef.doc(connection.key));
    }
    return batch.commit();
  }

  @override
  Future<void> deleteConnectionsByAccountNumber(String accountNumber) {
    final query =
        _collectionRef.where('accountNumber', isEqualTo: accountNumber);
    return query.get().then(
      (snapshot) {
        final batch = firestoreService.getBatch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        return batch.commit();
      },
    );
  }

  @override
  Future<void> deleteConnectionsByType(String type) {
    final query = _collectionRef.where('connectionType', isEqualTo: type);
    return query.get().then(
      (snapshot) {
        final batch = firestoreService.getBatch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        return batch.commit();
      },
    );
  }

  @override
  Future<void> updateConnection(Connection connection) =>
      _collectionRef.doc(connection.key).update(connection.toJson());

  // migrate: combine ledgerEthereum and ledgerTezos into ledger
  Future _migrateDeprecatedConnections(List<Connection> connections) async {
    final List<String> address = [];
    for (final oldConnection in connections) {
      switch (oldConnection.connectionType) {
        case 'ledger':
          final jsonData = json.decode(oldConnection.data);
          final etheremAddress = (jsonData['etheremAddress'] == null
                  ? []
                  : (jsonData['etheremAddress'] as List<dynamic>))
              .map((e) => e as String)
              .toList();
          final tezosAddress = (jsonData['tezosAddress'] == null
                  ? []
                  : (jsonData['tezosAddress'] as List<dynamic>))
              .map((e) => e as String)
              .toList();
          address.addAll(etheremAddress);
          address.addAll(tezosAddress);
          break;
        default:
          address.addAll(oldConnection.accountNumbers);
      }
      await deleteConnection(oldConnection);
    }

    final List<Connection> newConnections = [];
    for (final address in address) {
      final newConnection = Connection.getManuallyAddress(address);
      newConnection != null ? newConnections.add(newConnection) : null;
    }
    await insertConnections(newConnections);
  }
}
