//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/service/cloud_firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class FirestorePersonaDao {
  Future<List<Persona>> getPersonas();

  Future<List<Persona>> getDefaultPersonas();

  Future<int?> getPersonasCount();

  Future<void> insertPersona(Persona persona);

  Future<void> insertPersonas(List<Persona> personas);

  Future<Persona?> findById(String uuid);

  Future<void> updatePersona(Persona persona);

  Future<void> deletePersona(Persona persona);

  Future<void> removeAll();
}

class FirestorePersonaDaoImp implements FirestorePersonaDao {
  CloudFirestoreService firestoreService;
  final _collection = FirestoreCollection.persona;

  CollectionReference<Persona> get _collectionRef =>
      firestoreService.getCollection(_collection).withConverter<Persona>(
          fromFirestore: (snapshot, _) => Persona.fromJson(snapshot.data()!),
          toFirestore: (persona, _) => persona.toJson());

  FirestorePersonaDaoImp(this.firestoreService);

  @override
  Future<List<Persona>> getPersonas() async => _collectionRef.get().then(
        (snapshot) => snapshot.docs.map((e) => e.data()).toList(),
      );

  @override
  Future<List<Persona>> getDefaultPersonas() async =>
      _collectionRef.where('defaultAccount', isEqualTo: 1).get().then(
            (snapshot) => snapshot.docs.map((e) => e.data()).toList(),
          );

  @override
  Future<int?> getPersonasCount() async => _collectionRef.get().then(
        (snapshot) => snapshot.docs.map((e) => e.data()).toList().length,
      );

  @override
  Future<void> insertPersona(Persona persona) async =>
      _collectionRef.doc(persona.uuid).set(persona);

  @override
  Future<void> insertPersonas(List<Persona> personas) async {
    final batch = firestoreService.getBatch();
    for (var persona in personas) {
      batch.set(_collectionRef.doc(persona.uuid), persona);
    }
    return batch.commit();
  }

  @override
  Future<Persona?> findById(String uuid) async =>
      _collectionRef.doc(uuid).get().then(
        (snapshot) {
          if (snapshot.exists) {
            return snapshot.data();
          } else {
            return null;
          }
        },
      );

  @override
  Future<void> updatePersona(Persona persona) async =>
      _collectionRef.doc(persona.uuid).update(persona.toJson());

  @override
  Future<void> deletePersona(Persona persona) async =>
      _collectionRef.doc(persona.uuid).delete();

  @override
  Future<void> removeAll() async => _collectionRef.get().then(
        (snapshot) {
          final batch = firestoreService.getBatch();
          for (final doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
          return batch.commit();
        },
      );
}
