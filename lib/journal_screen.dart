// lib/journal_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'add_journal_entry_screen.dart';
import 'chat_screen.dart';
import 'styles.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  void _toggleJournalBookmark(String docId, bool currentStatus) {
    FirebaseFirestore.instance
        .collection('journals')
        .doc(docId)
        .update({'isBookmarked': !currentStatus});
  }

  void _toggleChatBookmark(String docId, bool currentStatus) {
    FirebaseFirestore.instance
        .collection('chats')
        .doc(docId)
        .update({'isBookmarked': !currentStatus});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Journal', style: AppTextStyles.headingWhite),
          backgroundColor: AppColors.primary,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Entries', icon: Icon(Icons.edit_note)),
              Tab(text: 'Bookmarked', icon: Icon(Icons.bookmark)),
              Tab(text: 'Chat Reflections', icon: Icon(Icons.chat)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildManualEntriesView(),
            _buildBookmarkedTabView(),
            _buildChatReflectionsView(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddJournalEntryScreen()),
            );
          },
          backgroundColor: AppColors.primary,
          tooltip: 'New Entry',
          child: const Icon(Icons.add, color: AppColors.white),
        ),
      ),
    );
  }

  Widget _buildManualEntriesView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('journals')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Your journal is empty.',
              style: AppTextStyles.subText,
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final entry = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final docId = snapshot.data!.docs[index].id;
            final isBookmarked = entry['isBookmarked'] ?? false;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                title: Text(
                  entry['content'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  (entry['createdAt'] as Timestamp?) != null
                      ? DateFormat.yMMMd()
                          .add_jm()
                          .format((entry['createdAt'] as Timestamp).toDate())
                      : 'No date',
                  style: AppTextStyles.subtitle,
                ),
                trailing: IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _toggleJournalBookmark(docId, isBookmarked),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBookmarkedTabView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text('Bookmarked Entries', style: AppTextStyles.heading),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('journals')
                .where('isBookmarked', isEqualTo: true)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.docs.isEmpty) {
                return const ListTile(
                  title: Text('No bookmarked entries.', style: AppTextStyles.subText),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final entry = snapshot.data!.docs[index].data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      title: Text(
                        entry['content'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const Divider(height: 30),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text('Bookmarked Conversations', style: AppTextStyles.heading),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .where('isBookmarked', isEqualTo: true)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.docs.isEmpty) {
                return const ListTile(
                  title: Text('No bookmarked conversations.', style: AppTextStyles.subText),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final convo = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  final docId = snapshot.data!.docs[index].id;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      title: Text(
                        convo['preview'] ?? 'No preview',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChatScreen(conversationId: docId)),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatReflectionsView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('chats').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No conversations to reflect on.', style: AppTextStyles.subText),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final convo = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final docId = snapshot.data!.docs[index].id;
            final isBookmarked = convo['isBookmarked'] ?? false;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                title: Text(
                  convo['preview'] ?? 'No preview',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  (convo['createdAt'] as Timestamp?) != null
                      ? DateFormat.yMMMd().format((convo['createdAt'] as Timestamp).toDate())
                      : 'No date',
                  style: AppTextStyles.subtitle,
                ),
                trailing: IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _toggleChatBookmark(docId, isBookmarked),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatScreen(conversationId: docId)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
