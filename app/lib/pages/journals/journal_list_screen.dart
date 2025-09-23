import 'package:flutter/material.dart';
import 'package:omi/pages/journals/journal_editor_screen.dart';
import 'package:omi/providers/journal_provider.dart';
import 'package:provider/provider.dart';

class JournalListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('My Journals'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<JournalProvider>(
        builder: (context, journalProvider, child) {
          if (journalProvider.journals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book, size: 80, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'No journals yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to create your first journal',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: journalProvider.journals.length,
            itemBuilder: (context, index) {
              final journal = journalProvider.journals[index];
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                elevation: 2,
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Text(
                    journal.title.isEmpty ? 'Untitled' : journal.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      if (journal.content.isNotEmpty)
                        Text(
                          journal.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                          SizedBox(width: 4),
                          Text(
                            _formatDate(journal.updatedAt),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          if (journal.imagePaths.isNotEmpty) ...[
                            SizedBox(width: 16),
                            Icon(Icons.image, size: 16, color: Colors.grey[500]),
                            SizedBox(width: 4),
                            Text(
                              '${journal.imagePaths.length}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteDialog(context, journal.id);
                      }
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JournalEditorScreen(journalId: journal.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final journalProvider = Provider.of<JournalProvider>(context, listen: false);
          final newJournal = await journalProvider.createJournal();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JournalEditorScreen(journalId: newJournal.id),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showDeleteDialog(BuildContext context, String journalId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Journal'),
          content: Text('Are you sure you want to delete this journal? This action cannot be undone.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Provider.of<JournalProvider>(context, listen: false).deleteJournal(journalId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
