import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../state_management/notes_provider.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(filteredNotesProvider);
    final searchQuery = ref.watch(notesSearchQueryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 180,
            floating: true,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            surfaceTintColor: theme.colorScheme.surface,
            title: Text('My Notes', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.sync, color: theme.colorScheme.primary, size: 20),
                ),
                tooltip: 'Sync with Cloud',
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Syncing with Firestore...'), duration: Duration(seconds: 1)),
                  );
                  try {
                    await ref.read(notesProvider.notifier).syncNotes();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Sync successful!'), 
                          backgroundColor: Colors.green.shade600,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sync failed: $e'), 
                          backgroundColor: theme.colorScheme.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SearchBar(
                  elevation: WidgetStateProperty.all(0),
                  backgroundColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
                  hintText: 'Search notes...',
                  hintStyle: WidgetStateProperty.all(TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7))),
                  leading: Icon(Icons.search, color: theme.colorScheme.primary),
                  onChanged: (value) => ref.read(notesSearchQueryProvider.notifier).state = value,
                  trailing: searchQuery.isNotEmpty 
                    ? [IconButton(icon: const Icon(Icons.clear), onPressed: () => ref.read(notesSearchQueryProvider.notifier).state = '')]
                    : null,
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ),
            ),
          ),
          notesAsync.when(
            data: (notes) => notes.isEmpty 
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.note_alt_outlined, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                        const SizedBox(height: 24),
                        Text(
                          searchQuery.isEmpty ? 'No notes yet' : 'No matching notes found', 
                          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        if (searchQuery.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Tap + to create your first note', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
                        ]
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.only(top: 16, bottom: 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final note = notes[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Dismissible(
                            key: Key(note.id),
                            background: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: Icon(Icons.delete_outline, color: theme.colorScheme.onErrorContainer),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => ref.read(notesProvider.notifier).deleteNote(note.id),
                            child: Card(
                              margin: EdgeInsets.zero,
                              elevation: 0,
                              color: theme.colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {}, // For future edit functionality
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              note.title, 
                                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          Icon(Icons.push_pin_outlined, size: 18, color: theme.colorScheme.outline),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        note.content, 
                                        maxLines: 3, 
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time, size: 14, color: theme.colorScheme.outline),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('MMM dd, hh:mm a').format(note.createdAt),
                                            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.secondaryContainer,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text('Note', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSecondaryContainer)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: notes.length,
                    ),
                  ),
                ),
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (err, stack) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddNoteDialog(context, ref),
        elevation: 4,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        label: const Text('New Note', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24, right: 24, top: 12
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Create New Note', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Title',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Write something...',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  ref.read(notesProvider.notifier).addNote(titleController.text, contentController.text);
                  Navigator.pop(context);
                }
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Save Note', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
