import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:habbit/models/habbit_log_model.dart';
import 'package:habbit/models/habbit_model.dart';
import 'package:firebase_core/firebase_core.dart';

class DataProvider {
  static DataProvider? _instance;
  static var db;

  static late CollectionReference<HabbitModel> habitsRef;
  static late CollectionReference<HabbitLogModel> habitslogRef;

  static User? get currentUser => FirebaseAuth.instance.currentUser;

  /// Stable per-user id used to scope all habit/log documents. Empty string
  /// when signed out (callers run behind [AuthGate], so this is defensive).
  static String get currentUserId => currentUser?.uid ?? '';

  DataProvider._() {
    db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: '(default)',
    );

    habitsRef = db
        .collection('habits')
        .withConverter<HabbitModel>(
          fromFirestore: (snapshot, _) =>
              HabbitModel.fromJson(snapshot.data()!),
          toFirestore: (HabbitModel habit, _) => habit.toJson(),
        );

    habitslogRef = db
        .collection('habitslog')
        .withConverter<HabbitLogModel>(
          fromFirestore: (snapshot, _) =>
              HabbitLogModel.fromJson(snapshot.data()!),
          toFirestore: (HabbitLogModel log, _) => log.toJson(),
        );
  }

  static DataProvider intialize() {
    _instance ??= DataProvider._();
    return _instance!;
  }

  static Future<String> saveData<T>(
    T data,
    CollectionReference<T> collectionReference,
  ) async {
    DocumentReference<T> ref = await collectionReference.add(data);
    return ref.id;
  }

  static Future<List<T>> getData<T>(
    CollectionReference<T> collectionReference,
  ) async {
    final List<T> list = [];
    QuerySnapshot snapshot = await collectionReference.get();

    for (var docSnapshot in snapshot.docs) {
      list.add(docSnapshot.data() as T);
    }
    return list;
  }

  /// Fetches only the documents owned by the signed-in user (those whose
  /// `userId` field matches [currentUserId]).
  static Future<List<T>> getUserData<T>(
    CollectionReference<T> collectionReference,
  ) {
    return getFilteredData('userId', currentUserId, collectionReference);
  }

  static Future<List<T>> getFilteredData<T>(
    String field,
    dynamic value,
    CollectionReference<T> collectionReference,
  ) async {
    final List<T> list = [];
    QuerySnapshot snapshot = await collectionReference
        .where(field, isEqualTo: value)
        .get();

    for (var docSnapshot in snapshot.docs) {
      list.add(docSnapshot.data() as T);
    }
    return list;
  }

  /// Deletes every document in [collectionReference] whose [field] equals
  /// [value]. The habit/log model `id` fields are stored inside the document
  /// (not the Firestore doc id), so we query for the matching docs first.
  static Future<void> deleteWhere<T>(
    String field,
    dynamic value,
    CollectionReference<T> collectionReference,
  ) async {
    final snapshot = await collectionReference
        .where(field, isEqualTo: value)
        .get();

    await Future.wait(snapshot.docs.map((doc) => doc.reference.delete()));
  }

  /// Deletes a habit together with all of its related logs.
  static Future<void> deleteHabitWithLogs(String habitId) async {
    await Future.wait([
      deleteWhere('id', habitId, habitsRef),
      deleteWhere('habbitId', habitId, habitslogRef),
    ]);
  }
}
