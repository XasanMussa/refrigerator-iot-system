import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Stream temperature data
  Stream<double> streamTemperature() {
    return _database.child('tempData').onValue.map((event) {
      final value = event.snapshot.value;
      if (value != null) {
        return double.parse(value.toString());
      }
      return 0.0;
    });
  }

  // Update fan speed
  Future<void> updateFanSpeed(int speed) async {
    await _database.child('fanSpeed').set(speed);
  }

  // Get current fan speed
  Future<int> getCurrentFanSpeed() async {
    final snapshot = await _database.child('fanSpeed').get();
    if (snapshot.exists && snapshot.value != null) {
      return int.parse(snapshot.value.toString());
    }
    return 0;
  }

  Future<void> updateSchedule(
      String docId, DateTime startTime, DateTime finishTime) async {
    await FirebaseFirestore.instance.collection('userData').doc(docId).set({
      'startTime': startTime,
      'finishTime': finishTime,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getSchedule(String docId) async {
    final doc = await FirebaseFirestore.instance
        .collection('userData')
        .doc(docId)
        .get();
    return doc.data();
  }

  Future<void> cancelSchedule(String docId) async {
    await FirebaseFirestore.instance.collection('userData').doc(docId).update({
      'startTime': FieldValue.delete(),
      'finishTime': FieldValue.delete(),
    });
  }
}
