// lib/habit_tracker_screen.dart
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'styles.dart'; // <-- centralized theme
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  final String _apiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';
  late final GenerativeModel _model;

  double _sleepDuration = 8.0;
  int? _sleepQuality;
  final Set<String> _meals = {};
  final List<String> _workouts = [];
  final List<String> _hobbies = [];
  final _workoutController = TextEditingController();
  final _hobbyController = TextEditingController();
  String? _screenTime;

  String? _aiFeedback;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: _apiKey);
  }

  @override
  void dispose() {
    _workoutController.dispose();
    _hobbyController.dispose();
    super.dispose();
  }

  void _getAiFeedback() async {
    if (_sleepQuality == null || _screenTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Sleep Quality and Screen Time.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _aiFeedback = null;
    });

    final prompt = """
You are a friendly, non-judgmental wellness coach. Provide feedback in 3 short, encouraging paragraphs: 1) Positive comment, 2) Suggestion, 3) Motivational closing.

User's Data:
- Sleep Duration: ${_sleepDuration.toStringAsFixed(1)} hours
- Sleep Quality: $_sleepQuality
- Meals: ${_meals.isEmpty ? 'None specified' : _meals.join(', ')}
- Workouts: ${_workouts.isEmpty ? 'None' : _workouts.join(', ')}
- Screen Time: $_screenTime
- Hobbies: ${_hobbies.isEmpty ? 'None' : _hobbies.join(', ')}

Feedback:
""";

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      setState(() => _aiFeedback = response.text);
    } catch (e) {
      setState(() => _aiFeedback = "Sorry, couldn't generate feedback. Try again.");
      print("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Habit Tracker', style: AppTextStyles.headingWhite),
        backgroundColor: AppColors.primary,
        elevation: 4,
      ),
      body: Column(
        children: [
          // TOP: User Inputs
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('😴 Sleep', 'How long and how well did you sleep?'),
                  _buildSleepDurationSelector(),
                  const SizedBox(height: 16),
                  _buildSleepQualitySelector(),
                  const Divider(height: 24),

                  _buildSectionTitle('🍎 Meals', 'What did you eat today?'),
                  _buildMultiSelectChipGroup(items: ['Protein-rich', 'Veggies', 'Fruits', 'Carbs', 'Salad', 'Junk Food'], selectedItems: _meals),
                  const Divider(height: 24),

                  _buildSectionTitle('💪 Workout', 'Log your activities.'),
                  _buildTextEntryTracker(controller: _workoutController, hintText: 'e.g., Running 30 mins', submittedItems: _workouts),
                  const Divider(height: 24),

                  _buildSectionTitle('💖 Hobbies', 'What did you do for fun?'),
                  _buildTextEntryTracker(controller: _hobbyController, hintText: 'e.g., Read a book', submittedItems: _hobbies),
                  const Divider(height: 24),

                  _buildSectionTitle('📱 Screen Time', 'Estimate your daily screen time.'),
                  _buildSegmentedSelector(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // BOTTOM: AI Feedback
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.psychology),
                      label: const Text('Get My Daily Feedback'),
                      onPressed: _getAiFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if (_isLoading) const CircularProgressIndicator(),
                          if (_aiFeedback != null)
                            Card(
                              color: AppColors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(_aiFeedback!,
                                    style: AppTextStyles.body.copyWith(height: 1.5)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Helper Widgets ---

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTextStyles.heading),
      Text(subtitle, style: AppTextStyles.subtitle),
      const SizedBox(height: 8),
    ]);
  }

Widget _buildSleepDurationSelector() {
  return Row(
    children: [
      const Icon(Icons.hourglass_bottom, color: AppColors.primary),
      Expanded(
        child: Slider(
          value: _sleepDuration,
          min: 0,
          max: 12,
          divisions: 24,
          label: '${_sleepDuration.toStringAsFixed(1)} hours',
          onChanged: (v) => setState(() => _sleepDuration = v),
        ),
      ),
      Text(
        '${_sleepDuration.toStringAsFixed(1)} hrs',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    ],
  );
}

Widget _buildSleepQualitySelector() {
  final emojis = ['😫', '😐', '😊', '🤩'];
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Sleep Quality',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(emojis.length, (index) {
          final quality = index + 1;
          return IconButton(
            iconSize: 32,
            icon: Text(
              emojis[index],
              style: const TextStyle(fontSize: 28),
            ),
            style: IconButton.styleFrom(
              backgroundColor: _sleepQuality == quality
                  ? AppColors.primaryContainer
                  : null,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => setState(() => _sleepQuality = quality),
          );
        }),
      ),
    ],
  );
}


  Widget _buildMultiSelectChipGroup({required List<String> items, required Set<String> selectedItems}) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: items.map((item) {
        final isSelected = selectedItems.contains(item);
        return FilterChip(
          label: Text(item, style: AppTextStyles.body),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                selectedItems.add(item);
              } else {
                selectedItems.remove(item);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSegmentedSelector() {
    final items = ['< 2 hrs', '2-4 hrs', '4-6 hrs', '6+ hrs'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.map((item) {
        final isSelected = _screenTime == item;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: isSelected ? AppColors.primaryContainer : null,
              ),
              onPressed: () => setState(() => _screenTime = item),
              child: Text(item, style: AppTextStyles.body),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextEntryTracker({
    required TextEditingController controller,
    required String hintText,
    required List<String> submittedItems,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(
        spacing: 8.0,
        children: submittedItems.map((item) {
          return Chip(
            label: Text(item, style: AppTextStyles.body),
            onDeleted: () => setState(() => submittedItems.remove(item)),
          );
        }).toList(),
      ),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: hintText, hintStyle: AppTextStyles.subtitle),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  submittedItems.add(controller.text);
                  controller.clear();
                });
              }
            },
          ),
        ],
      ),
    ]);
  }
}
