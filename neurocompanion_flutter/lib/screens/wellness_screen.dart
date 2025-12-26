import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/services/services.dart';

class WellnessScreen extends StatefulWidget {
  const WellnessScreen({super.key});

  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  bool _loading = true;
  String? _error;

  int? _wellnessScore;
  double? _averageMood;
  List<dynamic> _recentMoodEntries = const [];

  double _moodSlider = 5;
  final Set<String> _selectedEmotions = {};
  final _notesController = TextEditingController();

  static const List<String> _emotionChoices = [
    'happy',
    'sad',
    'calm',
    'stressed',
    'angry',
    'neutral',
    'excited',
    'worried',
    'confused',
    'surprised',
    'depressed',
    'anxious',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWellness();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadWellness() async {
    final wellnessService = context.read<WellnessService>();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        wellnessService.getAnalytics(days: 30),
        wellnessService.getMood(days: 30, limit: 10),
      ]);

      final analyticsRes = results[0];
      final moodRes = results[1];

      final analyticsData = (analyticsRes['data'] is Map) ? analyticsRes['data'] as Map : null;
      final moodData = (moodRes['data'] is Map) ? moodRes['data'] as Map : null;

      final wellnessScore = analyticsData?['wellnessScore'];
      final avgMood = (analyticsData?['mood'] is Map) ? (analyticsData?['mood'] as Map)['averageMood'] : null;

      final moodEntries = moodData?['entries'];

      if (!mounted) return;
      setState(() {
        _wellnessScore = wellnessScore is num ? wellnessScore.round() : null;
        _averageMood = avgMood is num ? avgMood.toDouble() : null;
        _recentMoodEntries = moodEntries is List ? moodEntries : const [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _submitMood() async {
    final wellnessService = context.read<WellnessService>();

    setState(() {
      _error = null;
    });

    try {
      await wellnessService.logMood(
        mood: _moodSlider.round().clamp(1, 10),
        emotions: _selectedEmotions.toList(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mood logged successfully')),
      );

      setState(() {
        _moodSlider = 5;
        _selectedEmotions.clear();
        _notesController.clear();
      });

      await _loadWellness();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            title: const Text('Wellness'),
          ),
          body: SafeArea(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(color: theme.primary),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.border),
                            ),
                            child: Text(
                              _error!,
                              style: TextStyle(color: theme.text.withOpacity(0.8)),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Analytics
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Wellness score',
                                  style: TextStyle(
                                    color: theme.text,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _wellnessScore != null ? '$_wellnessScore/100' : '—',
                                  style: TextStyle(
                                    color: theme.primary,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _averageMood != null ? 'Average mood (30d): ${_averageMood!.toStringAsFixed(1)}/10' : 'Average mood (30d): —',
                                  style: TextStyle(color: theme.text.withOpacity(0.8)),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Log mood
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Log your mood',
                                  style: TextStyle(
                                    color: theme.text,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Mood: ${_moodSlider.round()}/10',
                                  style: TextStyle(color: theme.text),
                                ),
                                Slider(
                                  value: _moodSlider,
                                  min: 1,
                                  max: 10,
                                  divisions: 9,
                                  activeColor: theme.primary,
                                  onChanged: (v) {
                                    setState(() {
                                      _moodSlider = v;
                                    });
                                  },
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Emotions (optional)',
                                  style: TextStyle(color: theme.text),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _emotionChoices.map((e) {
                                    final selected = _selectedEmotions.contains(e);
                                    return FilterChip(
                                      label: Text(e),
                                      selected: selected,
                                      onSelected: (v) {
                                        setState(() {
                                          if (v) {
                                            _selectedEmotions.add(e);
                                          } else {
                                            _selectedEmotions.remove(e);
                                          }
                                        });
                                      },
                                      selectedColor: theme.primary.withOpacity(0.2),
                                      checkmarkColor: theme.primary,
                                      labelStyle: TextStyle(color: theme.text),
                                      backgroundColor: theme.background,
                                      shape: StadiumBorder(side: BorderSide(color: theme.border)),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _notesController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Notes (optional)',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _submitMood,
                                    child: const Text('Save mood'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Recent mood
                        Text(
                          'Recent mood entries',
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_recentMoodEntries.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'No mood entries yet.',
                                style: TextStyle(color: theme.text.withOpacity(0.8)),
                              ),
                            ),
                          )
                        else
                          ..._recentMoodEntries.take(10).map((entry) {
                            if (entry is! Map) return const SizedBox.shrink();
                            final mood = entry['mood'];
                            final createdAt = entry['createdAt']?.toString();
                            final emotions = entry['emotions'];

                            final moodText = mood is num ? '${mood.round()}/10' : '—';
                            final dateText = createdAt != null && createdAt.isNotEmpty
                                ? createdAt.split('T').first
                                : '';
                            final emotionsText = emotions is List && emotions.isNotEmpty
                                ? emotions.map((e) => e.toString()).join(', ')
                                : '—';

                            return Card(
                              child: ListTile(
                                leading: Icon(Icons.mood, color: theme.primary),
                                title: Text(
                                  'Mood $moodText',
                                  style: TextStyle(color: theme.text, fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  '${dateText.isEmpty ? '' : '$dateText • '}Emotions: $emotionsText',
                                  style: TextStyle(color: theme.text.withOpacity(0.75)),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}
