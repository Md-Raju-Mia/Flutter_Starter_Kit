import '../../data/models/note_model.dart';

abstract class NoteRepository {
  Future<List<NoteModel>> getNotes();
  Future<void> addNote(NoteModel note);
  Future<void> updateNote(NoteModel note);
  Future<void> deleteNote(String id);
  Future<void> syncWithFirestore(String userId);
}
