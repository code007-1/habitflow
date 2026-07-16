import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'package:habbit/models/habbit_log_model.dart';
import 'package:habbit/models/habbit_model.dart';
import 'package:firebase_core/firebase_core.dart';

class DataProvider {
  static DataProvider? _instance;
  static var db;

  static late CollectionReference<HabbitModel> habitsRef;
  static late CollectionReference<HabbitLogModel> habitslogRef;

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
}
