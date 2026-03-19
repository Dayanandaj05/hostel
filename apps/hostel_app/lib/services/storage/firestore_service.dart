import 'package:cloud_firestore/cloud_firestore.dart';

typedef FromFirestore<T> = T Function(
  DocumentSnapshot<Map<String, dynamic>> snapshot,
);
typedef ToFirestore<T> = Map<String, dynamic> Function(T value);

class FirestoreService {
  FirestoreService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  DocumentReference<Map<String, dynamic>> doc(String path) {
    return _firestore.doc(path);
  }

  Future<Map<String, dynamic>?> getDocument(String path) async {
    final snapshot = await doc(path).get();
    return snapshot.data();
  }

  Stream<Map<String, dynamic>?> watchDocument(String path) {
    return doc(path).snapshots().map((snapshot) => snapshot.data());
  }

  Future<void> setDocument({
    required String path,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    final now = FieldValue.serverTimestamp();
    final payload = <String, dynamic>{
      ...data,
      'updatedAt': now,
    };

    if (!data.containsKey('createdAt')) {
      payload['createdAt'] = now;
    }

    await doc(path).set(payload, SetOptions(merge: merge));
  }

  Future<void> updateDocument({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    final payload = <String, dynamic>{
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await doc(path).update(payload);
  }

  Future<void> deleteDocument(String path) async {
    await doc(path).delete();
  }

  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler,
  ) {
    return _firestore.runTransaction(transactionHandler);
  }

  WriteBatch batch() => _firestore.batch();

  CollectionReference<T> typedCollection<T>({
    required String path,
    required FromFirestore<T> fromFirestore,
    required ToFirestore<T> toFirestore,
  }) {
    return collection(path).withConverter<T>(
      fromFirestore: (snapshot, _) => fromFirestore(snapshot),
      toFirestore: (value, _) => toFirestore(value),
    );
  }

  Future<void> setUserScopedDocument({
    required String uid,
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    final path = '$collectionPath/$uid/$documentId';
    await setDocument(path: path, data: data, merge: merge);
  }
}
