// journal_editor_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:omi/models/journal_entry.dart';
import 'package:omi/providers/journal_provider.dart';
import 'package:provider/provider.dart';

class JournalEditorScreen extends StatefulWidget {
  final String? journalId; // Made optional

  const JournalEditorScreen({this.journalId}); // Removed required

  @override
  _JournalEditorScreenState createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<JournalEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();

  JournalEntry? _journal;
  bool _isLoading = true;
  bool _isNewJournal = false;

  @override
  void initState() {
    super.initState();
    _loadJournal();
    _titleFocus.addListener(_onTitleFocusChange);
  }

  @override
  void dispose() {
    _saveJournal();
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  void _loadJournal() async {
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);

    if (widget.journalId != null) {
      // Editing existing journal
      _journal = journalProvider.getJournalById(widget.journalId!);
      _isNewJournal = false;
    } else {
      // Creating new journal
      _journal = await journalProvider.createJournal();
      _isNewJournal = true;
    }

    if (_journal != null) {
      _titleController.text = _journal!.title;
      _contentController.text = _journal!.content;
    }

    setState(() {
      _isLoading = false;
    });

    // Auto-focus title if it's empty (especially for new journals)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_journal != null && _journal!.title.isEmpty) {
        _titleFocus.requestFocus();
      }
    });
  }

  void _onTitleFocusChange() {
    if (!_titleFocus.hasFocus && _titleController.text.isEmpty) {
      _titleController.text = 'Add a title';
      _titleController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _titleController.text.length,
      );
    }
  }

  Future<void> _saveJournal() async {
    if (_journal == null) return;

    final updatedJournal = _journal!.copyWith(
      title: _titleController.text,
      content: _contentController.text,
      updatedAt: DateTime.now(),
    );

    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    await journalProvider.updateJournal(updatedJournal);
    _journal = updatedJournal;
  }

  Future<void> _addImage() async {
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    final imagePath = await journalProvider.addImage();

    if (imagePath != null && _journal != null) {
      final updatedImagePaths = List<String>.from(_journal!.imagePaths)..add(imagePath);
      final updatedJournal = _journal!.copyWith(
        imagePaths: updatedImagePaths,
        updatedAt: DateTime.now(),
      );

      await journalProvider.updateJournal(updatedJournal);
      setState(() {
        _journal = updatedJournal;
      });
    }
  }

  void _removeImage(String imagePath) async {
    if (_journal == null) return;

    final updatedImagePaths = List<String>.from(_journal!.imagePaths)..remove(imagePath);
    final updatedJournal = _journal!.copyWith(
      imagePaths: updatedImagePaths,
      updatedAt: DateTime.now(),
    );

    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    await journalProvider.updateJournal(updatedJournal);

    // Delete the image file
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }

    setState(() {
      _journal = updatedJournal;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_journal == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Journal not found')),
        body: Center(child: Text('Journal not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          _isNewJournal
              ? ''
              : '${_journal!.createdAt.day.toString().padLeft(2, '0')}—${_journal!.createdAt.month.toString().padLeft(2, '0')} Journal — Entry',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: () {
                // _saveJournal().then((_) => Navigator.pop(context));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromRGBO(139, 191, 201, 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Title Section
          Container(
            padding: EdgeInsets.all(16),
            child: TextFormField(
              controller: _titleController,
              focusNode: _titleFocus,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Add a title',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.normal,
                ),
              ),
              onFieldSubmitted: (_) {
                _contentFocus.requestFocus();
              },
            ),
          ),

          // Images Section
          if (_journal!.imagePaths.isNotEmpty)
            Container(
              height: 120,
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _journal!.imagePaths.length,
                itemBuilder: (context, index) {
                  final imagePath = _journal!.imagePaths[index];
                  return Container(
                    width: 120,
                    margin: EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(imagePath),
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey[300],
                                child: Icon(Icons.broken_image, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(imagePath),
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // Content Section
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              child: TextFormField(
                controller: _contentController,
                focusNode: _contentFocus,
                maxLines: null,
                expands: true,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Tap and start writing...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Color.fromRGBO(139, 191, 201, 1),
                  ),
                ),
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ),

          // Bottom Toolbar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                top: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.format_bold),
                  onPressed: () {
                    // Bold text functionality
                    _insertFormatting('**', '**');
                  },
                ),
                IconButton(
                  icon: Icon(Icons.format_italic),
                  onPressed: () {
                    // Italic text functionality
                    _insertFormatting('_', '_');
                  },
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: _addImage,
                ),
                Spacer(),
                Text(
                  '${_contentController.text.length} characters',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _insertFormatting(String prefix, String suffix) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (selection.isValid) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );

      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(
        offset: selection.start + prefix.length + selectedText.length + suffix.length,
      );
    }
  }
}
