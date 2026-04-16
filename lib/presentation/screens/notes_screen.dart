import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state_management/notes_provider.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing with Firestore...')),
              );
              await ref.read(notesProvider.notifier).syncNotes();
              if (context.mounted) {
                notesAsync.whenData((_) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sync successful!'), backgroundColor: Colors.green),
                  );
                });
              }
            },
          ),
        ],
      ),
      body: notesAsync.when(
        data: (notes) => notes.isEmpty 
          ? const Center(child: Text('No notes yet. Tap + to add one.'))
          : ListView.builder(
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(note.content),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => ref.read(notesProvider.notifier).deleteNote(note.id),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $err', style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: () => ref.read(notesProvider.notifier).loadNotes(),
                child: const Text('Retry'),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController, 
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentController, 
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                ref.read(notesProvider.notifier).addNote(
                  titleController.text,
                  contentController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }
}
