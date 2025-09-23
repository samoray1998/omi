import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:omi/models/journal_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class JournalProvider extends ChangeNotifier {
  static const String _journalsKey = 'journals';
  List<JournalEntry> _journals = [];
  final ImagePicker _imagePicker = ImagePicker();

  List<JournalEntry> get journals => List.unmodifiable(_journals);

  // Load journals from SharedPreferences
  Future<void> loadJournals() async {
    final prefs = await SharedPreferences.getInstance();
    final String? journalsJson = prefs.getString(_journalsKey);
    
    if (journalsJson != null) {
      final List<dynamic> journalsList = json.decode(journalsJson);
      _journals = journalsList.map((json) => JournalEntry.fromJson(json)).toList();
      _journals.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      notifyListeners();
    }
  }

  // Save journals to SharedPreferences
  Future<void> _saveJournals() async {
    final prefs = await SharedPreferences.getInstance();
    final String journalsJson = json.encode(
      _journals.map((journal) => journal.toJson()).toList(),
    );
    await prefs.setString(_journalsKey, journalsJson);
  }

  // Create new journal
  Future<JournalEntry> createJournal() async {
    final now = DateTime.now();
    final newJournal = JournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '',
      content: '',
      imagePaths: [],
      createdAt: now,
      updatedAt: now,
    );
    
    _journals.insert(0, newJournal);
    await _saveJournals();
    notifyListeners();
    return newJournal;
  }

  // Update journal
  Future<void> updateJournal(JournalEntry updatedJournal) async {
    final index = _journals.indexWhere((journal) => journal.id == updatedJournal.id);
    if (index != -1) {
      _journals[index] = updatedJournal;
      _journals.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      await _saveJournals();
      notifyListeners();
    }
  }

  // Delete journal
  Future<void> deleteJournal(String journalId) async {
    final journalIndex = _journals.indexWhere((journal) => journal.id == journalId);
    if (journalIndex != -1) {
      final journal = _journals[journalIndex];
      
      // Delete associated images
      for (String imagePath in journal.imagePaths) {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      _journals.removeAt(journalIndex);
      await _saveJournals();
      notifyListeners();
    }
  }

  // Add image to journal
  Future<String?> addImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // Save image to app directory
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String imagesDir = path.join(appDir.path, 'journal_images');
        await Directory(imagesDir).create(recursive: true);
        
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String imagePath = path.join(imagesDir, fileName);
        
        await File(image.path).copy(imagePath);
        return imagePath;
      }
    } catch (e) {
      debugPrint('Error adding image: $e');
    }
    return null;
  }

  // Get journal by ID
  JournalEntry? getJournalById(String id) {
    try {
      return _journals.firstWhere((journal) => journal.id == id);
    } catch (e) {
      return null;
    }
  }
}