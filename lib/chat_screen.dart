// lib/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'styles.dart'; // <-- centralized theme
import 'package:flutter_dotenv/flutter_dotenv.dart';


class ChatScreen extends StatefulWidget {
  final String? conversationId;
  const ChatScreen({super.key, this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final String _apiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';
  final _user = const types.User(id: 'user');
  final _aiUser = const types.User(id: 'ai', firstName: 'HugFit');

  String? _currentChatId;
  late final GenerativeModel _model;
  List<types.Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: _apiKey);

    if (widget.conversationId == null) {
      _startNewChat();
    } else {
      _loadChat(widget.conversationId!);
    }
  }

  void _startNewChat() {
    setState(() {
      _currentChatId = const Uuid().v4();
      _messages = [];
    });
  }

  void _loadChat(String chatId) {
    setState(() {
      _currentChatId = chatId;
    });
  }

  void _handleSendPressed(types.PartialText message) async {
    final chatDocRef =
        FirebaseFirestore.instance.collection('chats').doc(_currentChatId!);
    final chatDoc = await chatDocRef.get();
    if (!chatDoc.exists) {
      await chatDocRef.set({
        'createdAt': FieldValue.serverTimestamp(),
        'preview': message.text,
      });
    }

    // Add user message
    chatDocRef.collection('messages').add({
      'text': message.text,
      'sender': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // AI Logic
    final prompt = """
**Persona:** You are "HugFit," a confidential, empathetic AI wellness companion for Indian youth. Your tone is gentle, supportive, and non-judgmental.

**Rules:**
1. NEVER provide a medical diagnosis. You are a supportive friend, not a doctor.
2. Keep responses concise and easy to read.

**Task:**
1. **Analyze the user's message for crisis indicators** (keywords: "kill myself", "end my life", "can't go on", "want to die", etc.). If a crisis is detected, your ONLY response must be: "It sounds like you are in severe distress. Please reach out for help immediately. You can contact AASRA at 9820466726. They are available 24/7 to support you."
2. **If no crisis, provide an empathetic, conversational response** based on their message. Validate their feelings.

**User's Message:** "${message.text}"

**HugFit's Response:**""";

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      if (response.text != null) {
        chatDocRef.collection('messages').add({
          'text': response.text,
          'sender': 'ai',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error generating content: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'HugFit Wellness Chat 💬',
          style: AppTextStyles.headingWhite,
        ),
        backgroundColor: AppColors.primary,
        elevation: 4,
      ),
      drawer: _buildConversationsDrawer(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .doc(_currentChatId)
            .collection('messages')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final messages = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return types.TextMessage.fromJson({
                'author':
                    (data['sender'] == 'user' ? _user : _aiUser).toJson(),
                'id': doc.id,
                'text': data['text'],
                'createdAt': (data['createdAt'] as Timestamp?)
                        ?.millisecondsSinceEpoch ??
                    DateTime.now().millisecondsSinceEpoch,
              });
            }).toList();
            _messages = messages;
          }

          return Chat(
            messages: _messages,
            onSendPressed: _handleSendPressed,
            user: _user,
            theme: DefaultChatTheme(
              primaryColor: AppColors.primary,
              backgroundColor: AppColors.background,
              userAvatarNameColors: [AppColors.deepOrange, AppColors.orange],
              inputBackgroundColor: AppColors.inputBackground,
              inputTextColor: AppColors.black,
              sentMessageBodyTextStyle: AppTextStyles.message,
              receivedMessageBodyTextStyle: AppTextStyles.message,
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationsDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            color: AppColors.primary,
            child: const Text(
              'Past Conversations',
              style: TextStyle(color: AppColors.white, fontSize: 20),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_comment, color: AppColors.primary),
            title: const Text('New Chat', style: AppTextStyles.body),
            onTap: () {
              Navigator.pop(context);
              _startNewChat();
            },
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  );
                }

                final conversations = snapshot.data!.docs;
                if (conversations.isEmpty) {
                  return Center(
                    child: Text(
                      "No past chats.",
                      style: AppTextStyles.subText,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final convo = conversations[index].data() as Map<String, dynamic>;
                    final docId = conversations[index].id;
                    final preview = convo['preview'] as String? ?? 'No preview';
                    final timestamp = convo['createdAt'] as Timestamp?;

                    return ListTile(
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
                        Navigator.pop(context);
                        _loadChat(docId);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
