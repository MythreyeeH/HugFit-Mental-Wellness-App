// lib/conversation_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'chat_screen.dart';
import 'styles.dart'; // <-- centralized theme

class ConversationListScreen extends StatelessWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('All Conversations', style: AppTextStyles.headingWhite),
        backgroundColor: AppColors.primary,
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No conversations yet.',
                style: AppTextStyles.subText,
              ),
            );
          }

          final conversations = snapshot.data!.docs;

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final convo = conversations[index].data() as Map<String, dynamic>;
              final docId = conversations[index].id;
              final timestamp = convo['createdAt'] as Timestamp?;
              final preview = convo['preview'] as String? ?? 'No preview available';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                color: AppColors.white,
                elevation: 2,
                child: ListTile(
                  title: Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body,
                  ),
                  subtitle: Text(
                    timestamp != null
                        ? DateFormat.yMMMd().format(timestamp.toDate())
                        : 'No date',
                    style: AppTextStyles.subText,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(conversationId: docId),
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
        child: const Icon(Icons.add_comment),
        tooltip: 'New Chat',
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatScreen(),
            ),
          );
        },
      ),
    );
  }
}
