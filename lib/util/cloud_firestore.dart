import 'package:cloud_firestore/cloud_firestore.dart';

const virtualDocumentId = 'virtualDocumentId';

class CloudFireStore {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference collection(String collectionName) =>
      _firestore.collection(collectionName);
}

extension CloudFireStoreCollectionExtension on CollectionReference {
  CollectionReference getSubCollection(String subCollectionName) {
    final firestore = this.firestore;
    final path = this.path;
    final subCollectionPath = '$path/$virtualDocumentId/$subCollectionName';
    return firestore.collection(subCollectionPath);
  }

  Future<QuerySnapshot> getDocuments() async => await get();

  Future<DocumentSnapshot> getDocument(String documentId) async =>
      await doc(documentId).get();

  Future<void> addDocument(Map<String, dynamic> data) async {
    await add(data);
  }

  Future<void> updateDocument(
      String documentId, Map<String, dynamic> data) async {
    await doc(documentId).update(data);
  }

  Future<void> deleteDocument(String documentId) async {
    await doc(documentId).delete();
  }
}

extension CloudFireStoreDocumentExtension on DocumentReference {
  Future<DocumentSnapshot> getDocument() async => await get();

  Future<void> updateDocument(Map<String, dynamic> data) async {
    await update(data);
  }

  Future<void> deleteDocument() async {
    await delete();
  }
}
