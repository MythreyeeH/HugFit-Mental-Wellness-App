// lib/exercise_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';
import 'styles.dart'; // <-- centralized theme
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

enum ExerciseStage {
  askingEmotionalState,
  askingTimeAvailability,
  askingDesiredOutcome,
  generatingExercises,
  displayingExercises,
  completed,
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final String _apiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';
  late final GenerativeModel _model;

  final _user = const types.User(id: 'user');
  final _aiUser = const types.User(id: 'ai', firstName: 'HugFit');

  List<types.Message> _messages = [];
  ExerciseStage _currentStage = ExerciseStage.askingEmotionalState;

  String? _emotionalState;
  String? _timeAvailability;
  String? _desiredOutcome;

  List<ExerciseRecommendation> _exerciseRecommendations = [];
  int _completedExercisesCount = 0;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: _apiKey);
    _startNewSession();
  }

  void _startNewSession() {
    setState(() {
      _messages = [];
      _exerciseRecommendations = [];
      _completedExercisesCount = 0;
      _emotionalState = null;
      _timeAvailability = null;
      _desiredOutcome = null;
      _addAiMessage("Hello! Let's find a helpful exercise. How are you feeling right now?");
      _currentStage = ExerciseStage.askingEmotionalState;
    });
  }

  void _addAiMessage(String text) {
    setState(() {
      _messages.insert(
        0,
        types.TextMessage(
          author: _aiUser,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: text,
        ),
      );
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.insert(
        0,
        types.TextMessage(
          author: _user,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: text,
        ),
      );
    });
  }

  void _handleSendPressed(types.PartialText message) async {
    if (_currentStage != ExerciseStage.askingEmotionalState &&
        _currentStage != ExerciseStage.askingTimeAvailability &&
        _currentStage != ExerciseStage.askingDesiredOutcome) return;

    _addUserMessage(message.text);
    switch (_currentStage) {
      case ExerciseStage.askingEmotionalState:
        _emotionalState = message.text;
        _addAiMessage("Got it. How much time do you have? (e.g., 2 minutes)");
        _currentStage = ExerciseStage.askingTimeAvailability;
        break;
      case ExerciseStage.askingTimeAvailability:
        _timeAvailability = message.text;
        _addAiMessage("And what is your goal? (e.g., Calm down, Focus)");
        _currentStage = ExerciseStage.askingDesiredOutcome;
        break;
      case ExerciseStage.askingDesiredOutcome:
        _desiredOutcome = message.text;
        _addAiMessage("Thanks! Generating some exercises for you...");
        _currentStage = ExerciseStage.generatingExercises;
        await _generateExercises();
        break;
      default:
        break;
    }
  }

  Future<void> _generateExercises() async {
    final prompt =
        "Based on: Emotional State: $_emotionalState, Time: $_timeAvailability, Goal: $_desiredOutcome. Suggest 3 short, distinct wellness exercises. Format as a numbered list with a catchy title in bold, a time estimate, and a 1-2 sentence description.";

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      if (response.text != null && response.text!.isNotEmpty) {
        _parseAndDisplayExercises(response.text!);
      } else {
        _addAiMessage("I couldn't generate exercises right now. Please try again.");
      }
    } catch (e) {
      print("Error generating exercises: $e");
      _addAiMessage("I'm having trouble generating exercises. Please try again.");
    }
  }

  void _parseAndDisplayExercises(String rawText) {
    final recommendations = rawText
        .split(RegExp(r'\d+\.\s*'))
        .where((s) => s.isNotEmpty)
        .map((item) {
      final parts = item.split('**');
      if (parts.length >= 3) {
        return ExerciseRecommendation(
            title: '**${parts[1]}**', description: parts[2].trim());
      }
      return ExerciseRecommendation(title: 'Exercise', description: item.trim());
    }).toList();

    setState(() {
      _exerciseRecommendations = recommendations;
      _currentStage = ExerciseStage.displayingExercises;
      _addAiMessage("Here are some exercises for you. Check them off as you complete them.");
    });
  }

  void _onExerciseChecked(int index, bool? isChecked) {
    setState(() {
      if (isChecked == true) {
        _exerciseRecommendations[index].isCompleted = true;
        _completedExercisesCount++;
      } else {
        _exerciseRecommendations[index].isCompleted = false;
        _completedExercisesCount--;
      }
    });

    if (_completedExercisesCount >= _exerciseRecommendations.length) {
      _addAiMessage("Fantastic work! You've completed all the exercises. Job well done!");
      setState(() {
        _currentStage = ExerciseStage.completed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Wellness Exercises', style: AppTextStyles.headingWhite),
        backgroundColor: AppColors.primary,
        elevation: 4,
      ),
      body: Column(
        children: [
          Expanded(flex: 2, child: _buildTopSection()),
          Expanded(
            flex: 3,
            child: Chat(
              messages: _messages,
              onSendPressed: _handleSendPressed,
              user: _user,
              theme: DefaultChatTheme(
                primaryColor: AppColors.primary,
                inputBackgroundColor: AppColors.inputBackground,
                inputTextColor: AppColors.black,
                sentMessageBodyTextStyle: AppTextStyles.message,
                receivedMessageBodyTextStyle: AppTextStyles.message,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    if (_currentStage == ExerciseStage.completed) {
      return Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text("Start New Session"),
          onPressed: _startNewSession,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
        ),
      );
    }

    if (_currentStage == ExerciseStage.displayingExercises ||
        _currentStage == ExerciseStage.generatingExercises) {
      return ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _exerciseRecommendations.length,
        itemBuilder: (context, index) {
          final exercise = _exerciseRecommendations[index];
          return Card(
            color: AppColors.white,
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: CheckboxListTile(
              title: Text(exercise.title,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text(exercise.description, style: AppTextStyles.body),
              value: exercise.isCompleted,
              onChanged: (bool? newValue) {
                if (_currentStage == ExerciseStage.displayingExercises) {
                  _onExerciseChecked(index, newValue);
                }
              },
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}

class ExerciseRecommendation {
  final String title;
  final String description;
  bool isCompleted;

  ExerciseRecommendation(
      {required this.title, required this.description, this.isCompleted = false});
}
