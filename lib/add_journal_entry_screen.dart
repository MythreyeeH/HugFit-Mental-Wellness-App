// lib/add_journal_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'styles.dart'; // <-- import your theme

class AddJournalEntryScreen extends StatefulWidget {
  const AddJournalEntryScreen({super.key});

  @override
  State<AddJournalEntryScreen> createState() => _AddJournalEntryScreenState();
}

class _AddJournalEntryScreenState extends State<AddJournalEntryScreen> {
  final _textController = TextEditingController();

  void _saveEntry() {
    final content = _textController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Journal entry cannot be empty."),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    FirebaseFirestore.instance.collection('journals').add({
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'New Journal Entry',
          style: AppTextStyles.headingWhite,
        ),
        backgroundColor: AppColors.primary,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveEntry,
            tooltip: 'Save Entry',
            color: AppColors.white,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _textController,
          autofocus: true,
          maxLines: null,
          expands: true,
          keyboardType: TextInputType.multiline,
          style: AppTextStyles.body,
          decoration: AppInputDecorations.textField(
            hint: 'Write about your day, your thoughts, or anything on your mind...',
          ),
        ),
      ),
    );
  }
}
