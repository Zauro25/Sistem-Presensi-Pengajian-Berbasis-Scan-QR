import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';

import '../models/attendance_record.dart';
import '../models/study_session.dart';
import '../models/teacher.dart';
import '../models/user_profile.dart';

class FirestoreService {
  FirestoreService() : _db = FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _sessions => _db.collection('sessions');
  CollectionReference<Map<String, dynamic>> get _teachers => _db.collection('teachers');
  CollectionReference<Map<String, dynamic>> get _attendance => _db.collection('attendance');

  Future<void> upsertUserProfile(UserProfile profile) async {
    await _users.doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
  }

  Stream<UserProfile?> watchUserProfile(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data();
      if (data == null) return null;
      return UserProfile.fromMap(data);
    });
  }

  Future<UserProfile?> fetchUserProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    return UserProfile.fromMap(data);
  }

  Future<String> createSession(StudySession session) async {
    final doc = _sessions.doc();
    await doc.set({
      ...session.toMap(),
      'qrCode': session.qrCode ?? doc.id,
      'id': doc.id,
    });
    return doc.id;
  }

  Stream<List<StudySession>> watchSessions() {
    return _sessions.orderBy('scheduledAt').snapshots().map((snapshot) {
      return snapshot.docs.map(StudySession.fromDoc).toList();
    });
  }

  Future<void> addTeacher(Teacher teacher) async {
    final doc = _teachers.doc();
    await doc.set(teacher.toMap());
  }

  Stream<List<Teacher>> watchTeachers() {
    return _teachers.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map(Teacher.fromDoc).toList();
    });
  }

  Stream<List<UserProfile>> watchParticipants() {
    return _users.where('role', isEqualTo: 'peserta').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserProfile.fromMap(doc.data())).toList();
    });
  }

  Future<List<UserProfile>> fetchParticipantsOnce() async {
    final snapshot = await _users.where('role', isEqualTo: 'peserta').get();
    return snapshot.docs.map((doc) => UserProfile.fromMap(doc.data())).toList();
  }

  Future<void> saveFaceTemplate({
    required String uid,
    required List<double> embedding,
    String? faceImage,
  }) async {
    await _users.doc(uid).set(
      {
        'faceEmbedding': embedding,
        if (faceImage != null) 'faceImage': faceImage,
        'faceUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> markAttendance({
    required String sessionId,
    required UserProfile user,
    String method = 'qr',
  }) async {
    final docId = '${sessionId}_${user.uid}';
    final record = AttendanceRecord(
      id: docId,
      sessionId: sessionId,
      userId: user.uid,
      timestamp: DateTime.now(),
      method: method,
      userName: user.name,
    );
    await _attendance.doc(docId).set(record.toMap(), SetOptions(merge: true));
  }

  Stream<List<AttendanceRecord>> watchAttendanceForSession(String sessionId) {
    return _attendance
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map((snapshot) {
      final records = snapshot.docs.map(AttendanceRecord.fromDoc).toList();
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return records;
    });
  }

  Stream<List<AttendanceRecord>> watchAttendanceForUser(String userId) {
    return _attendance
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final records = snapshot.docs.map(AttendanceRecord.fromDoc).toList();
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return records;
    });
  }

  Future<String> generateCsvForSession(String sessionId) async {
    final sessionDoc = await _sessions.doc(sessionId).get();
    final session = StudySession.fromDoc(sessionDoc);
    final snapshot = await _attendance
        .where('sessionId', isEqualTo: sessionId)
        .get();
    final records = snapshot.docs.map(AttendanceRecord.fromDoc).toList();
    records.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final rows = <List<dynamic>>[
      ['Judul Kajian', session.title],
      ['Pemateri', session.teacherName],
      ['Lokasi', session.location],
      ['Waktu', session.scheduledAt.toIso8601String()],
      [],
      ['Nama', 'User ID', 'Metode', 'Status', 'Waktu'],
      ...records.map((record) {
        return [
          record.userName,
          record.userId,
          record.method,
          record.status,
          record.timestamp.toIso8601String(),
        ];
      }),
    ];

    return const ListToCsvConverter().convert(rows);
  }
}
