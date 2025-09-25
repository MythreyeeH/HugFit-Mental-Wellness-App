// lib/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'chat_screen.dart';
import 'journal_screen.dart';
import 'exercise_screen.dart';
import 'habit_tracker_screen.dart';
import 'resources.dart'; // <-- import resources page
import 'styles.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String _apiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';
  late final GenerativeModel _model;
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    ChatScreen(),
    JournalScreen(),
    ExerciseScreen(),
    HabitTrackerScreen(),
    ResourcesScreen(), // add resources here
  ];

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: _apiKey);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showFortuneCookie() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      const prompt =
          "Generate a short, insightful, and positive one-sentence affirmation for someone feeling anxious or stressed.";
      final response = await _model.generateContent([Content.text(prompt)]);
      final String? affirmation = response.text;

      if (!context.mounted) return;
      Navigator.pop(context);

      if (affirmation != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.cookie_outlined, color: AppColors.primary),
                SizedBox(width: 10),
                Text("A Message for You", style: AppTextStyles.heading),
              ],
            ),
            content: Text(affirmation, style: AppTextStyles.body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: AppTextStyles.link),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print("Error generating affirmation: $e");
      if (!context.mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HugFit', style: AppTextStyles.headingWhite),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.cookie),
            tooltip: 'Fortune Cookie',
            onPressed: _showFortuneCookie,
            color: AppColors.white,
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Journal'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center), label: 'Exercises'),
          BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline), label: 'Tracker'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book), label: 'Resources'), // <-- new
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        onTap: _onItemTapped,
      ),
    );
  }
}
