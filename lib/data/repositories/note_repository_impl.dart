import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  static const String _boxName = 'notes_box';
  final FirebaseFirestore _firestore;

  NoteRepositoryImpl(this._firestore);

  Future<Box<NoteModel>> get _box async => await Hive.openBox<NoteModel>(_boxName);

  @override
  Future<List<NoteModel>> getNotes() async {
    final box = await _box;
    return box.values.toList();
  }

  @override
  Future<void> addNote(NoteModel note) async {
    final box = await _box;
    await box.put(note.id, note);
  }

  @override
  Future<void> updateNote(NoteModel note) async {
    final box = await _box;
    await box.put(note.id, note);
  }

  @override
  Future<void> deleteNote(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  @override
  Future<void> syncWithFirestore(String userId) async {
    final box = await _box;
    final notes = box.values.toList();
    
    final batch = _firestore.batch();
    for (var note in notes) {
      // Correct path based on the rules we set: users/{userId}/notes/{noteId}
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(note.id);
      batch.set(docRef, note.toJson());
    }
    await batch.commit();
  }
}
