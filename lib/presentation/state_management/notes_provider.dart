import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/note_model.dart';
import '../../data/providers/repository_providers.dart';
import 'auth_provider.dart';

final notesProvider = StateNotifierProvider<NotesNotifier, AsyncValue<List<NoteModel>>>((ref) {
  return NotesNotifier(ref);
});

class NotesNotifier extends StateNotifier<AsyncValue<List<NoteModel>>> {
  final Ref _ref;

  NotesNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    state = await AsyncValue.guard(() => _ref.read(noteRepositoryProvider).getNotes());
  }

  Future<void> addNote(String title, String content) async {
    final note = NoteModel(
      id: const Uuid().v4(),
      title: title,
      content: content,
      createdAt: DateTime.now(),
    );
    await _ref.read(noteRepositoryProvider).addNote(note);
    await loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await _ref.read(noteRepositoryProvider).deleteNote(id);
    await loadNotes();
  }

  Future<void> syncNotes() async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      await _ref.read(noteRepositoryProvider).syncWithFirestore(user.uid);
      await loadNotes();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
