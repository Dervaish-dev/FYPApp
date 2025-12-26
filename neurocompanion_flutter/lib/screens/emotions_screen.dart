import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/bloc/bloc.dart';
import 'package:neurocompanion_flutter/bloc/blocs.dart';
import 'package:neurocompanion_flutter/services/services.dart';
import 'dart:io';
import 'dart:math';

class EmotionsScreen extends StatefulWidget {
  const EmotionsScreen({super.key});

  @override
  State<EmotionsScreen> createState() => _EmotionsScreenState();
}

class _EmotionsScreenState extends State<EmotionsScreen> {
  final ImagePicker _picker = ImagePicker();
  String _selectedEmotion = 'Happy';
  double _intensity = 5.0;
  bool _isAnalyzing = false;
  String _analysisResult = '';
  File? _selectedImage;

  final List<String> _emotions = [
    'Happy',
    'Sad',
    'Angry',
    'Anxious',
    'Calm',
    'Excited',
    'Stressed',
    'Confused',
    'Grateful',
    'Lonely',
    'Proud',
    'Worried',
  ];

  @override
  void initState() {
    super.initState();
    // Using backend for emotion analysis (secure approach)
    context.read<EmotionBloc>().add(LoadEmotions());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;

        return Scaffold(
          backgroundColor: theme.background,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<EmotionBloc>().add(LoadEmotions());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              color: theme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(theme),
                    const SizedBox(height: 24),

                    // Manual Emotion Selection Card
                    _buildManualSelectionCard(theme),
                    const SizedBox(height: 20),

                    // OR Divider
                    _buildDivider(theme),
                    const SizedBox(height: 20),

                    // AI Analysis Card
                    _buildAIAnalysisCard(theme),
                    const SizedBox(height: 24),

                    // Emotion History Section
                    _buildEmotionHistory(theme),
                    const SizedBox(height: 24),

                    // Analytics Section
                    _buildAnalytics(theme),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: _buildFloatingActionButton(theme),
        );
      },
    );
  }

  Widget _buildHeader(AppTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.favorite, color: theme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emotion Recognition',
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Track & analyze your emotions',
                  style: TextStyle(
                    color: theme.text.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualSelectionCard(AppTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.touch_app, color: theme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Select Your Emotion',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Emotion Dropdown
          DropdownButtonFormField<String>(
            value: _selectedEmotion,
            decoration: InputDecoration(
              labelText: 'Choose your current emotion',
              labelStyle: TextStyle(color: theme.text),
              hintStyle: TextStyle(color: theme.text.withOpacity(0.7)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.background,
            ),
            style: TextStyle(color: theme.text),
            items: _emotions.map((emotion) {
              return DropdownMenuItem(
                value: emotion,
                child: Text(emotion, style: TextStyle(color: theme.text)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedEmotion = value!;
              });
            },
          ),
          const SizedBox(height: 20),

          // Intensity Slider
          Text(
            'Intensity: ${_intensity.round()}/10',
            style: TextStyle(
              color: theme.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: theme.primary,
              inactiveTrackColor: theme.border,
              thumbColor: theme.primary,
              overlayColor: theme.primary.withOpacity(0.2),
            ),
            child: Slider(
              value: _intensity,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) {
                setState(() {
                  _intensity = value;
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Low', style: TextStyle(color: theme.text.withOpacity(0.7))),
              Text(
                'High',
                style: TextStyle(color: theme.text.withOpacity(0.7)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveEmotion,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save Emotion'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(AppTheme theme) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: theme.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: theme.text.withOpacity(0.5),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: theme.border)),
      ],
    );
  }

  Widget _buildAIAnalysisCard(AppTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.camera_alt, color: theme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Photo Analysis',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Image Upload Area
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: theme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.border,
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: theme.text.withOpacity(0.5),
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap to upload photo',
                          style: TextStyle(
                            color: theme.text.withOpacity(0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'JPG, PNG, GIF up to 10MB',
                          style: TextStyle(
                            color: theme.text.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Analyze Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedImage != null ? _analyzeImage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isAnalyzing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Analyzing...'),
                      ],
                    )
                  : const Text(
                      'Analyze Your Emotion',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ),

          // Analysis Result
          if (_analysisResult.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology, color: theme.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'AI Analysis',
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _analysisResult,
                    style: TextStyle(color: theme.text, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmotionHistory(AppTheme theme) {
    return BlocBuilder<EmotionBloc, EmotionState>(
      builder: (context, state) {
        print('📊 [EMOTIONS] BLoC state: ${state.runtimeType}');
        
        if (state is EmotionLoading) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: theme.primary),
            ),
          );
        }

        if (state is EmotionError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Text(
              'Error loading emotions: ${state.message}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        if (state is EmotionLoaded) {
          final emotions = state.emotions;
          print('📊 [EMOTIONS] Loaded ${emotions.length} emotions');
          
          if (emotions.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.border),
              ),
              child: Column(
                children: [
                  Icon(Icons.sentiment_satisfied, size: 48, color: theme.text.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  Text(
                    'No emotions logged yet',
                    style: TextStyle(
                      color: theme.text.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start tracking your emotions above!',
                    style: TextStyle(
                      color: theme.text.withOpacity(0.4),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Emotion History',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${emotions.length} entries',
                    style: TextStyle(
                      color: theme.text.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...emotions.take(10).map((emotion) {
                print('📊 [EMOTIONS] Displaying emotion: ${emotion.emotion}');
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getEmotionColor(emotion.emotion).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            _getEmotionEmoji(emotion.emotion),
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  emotion.emotion.toUpperCase(),
                                  style: TextStyle(
                                    color: theme.text,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _formatDate(emotion.timestamp),
                                  style: TextStyle(
                                    color: theme.text.withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Intensity: ',
                                  style: TextStyle(
                                    color: theme.text.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                ),
                                ...List.generate(10, (index) => Icon(
                                  index < emotion.intensity ? Icons.circle : Icons.circle_outlined,
                                  size: 8,
                                  color: index < emotion.intensity 
                                    ? _getEmotionColor(emotion.emotion) 
                                    : theme.text.withOpacity(0.2),
                                )),
                              ],
                            ),
                            if (emotion.note != null && emotion.note!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                emotion.note!,
                                style: TextStyle(
                                  color: theme.text.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'excited':
      case 'grateful':
      case 'proud':
        return Colors.green;
      case 'calm':
      case 'peaceful':
        return Colors.blue;
      case 'sad':
      case 'lonely':
        return Colors.indigo;
      case 'angry':
      case 'stressed':
        return Colors.red;
      case 'anxious':
      case 'worried':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'angry':
        return '😠';
      case 'anxious':
        return '😰';
      case 'calm':
        return '😌';
      case 'excited':
        return '🤩';
      case 'stressed':
        return '😫';
      case 'confused':
        return '😕';
      case 'grateful':
        return '🙏';
      case 'lonely':
        return '😔';
      case 'proud':
        return '😎';
      case 'worried':
        return '😟';
      default:
        return '😐';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildAnalytics(AppTheme theme) {
    return BlocBuilder<EmotionBloc, EmotionState>(
      builder: (context, state) {
        if (state is! EmotionLoaded) {
          return const SizedBox.shrink();
        }

        final emotions = state.emotions;
        if (emotions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emotion Analytics',
              style: TextStyle(
                color: theme.text,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Weekly Trend Chart
            _buildChartCard(
              theme,
              'Weekly Emotion Trend',
              Icons.show_chart,
              _buildLineChart(theme, emotions),
            ),
            const SizedBox(height: 16),

            // Emotion Distribution Chart
            _buildChartCard(
              theme,
              'Emotion Distribution',
              Icons.pie_chart,
              _buildPieChart(theme, emotions),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartCard(
    AppTheme theme,
    String title,
    IconData icon,
    Widget chart,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: theme.text,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: 180, child: chart),
        ],
      ),
    );
  }

  Widget _buildLineChart(AppTheme theme, List emotions) {
    return CustomPaint(
      size: const Size(double.infinity, 180),
      painter: LineChartPainter(theme, emotions),
    );
  }

  Widget _buildPieChart(AppTheme theme, List emotions) {
    return CustomPaint(
      size: const Size(double.infinity, 180),
      painter: PieChartPainter(theme, emotions),
    );
  }

  Widget _buildFloatingActionButton(AppTheme theme) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.purple,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(child: Text('😘', style: const TextStyle(fontSize: 24))),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.priority_high,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _analysisResult = '';
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Use Hugging Face facial emotion detection
      final emotionService = context.read<EmotionService>();
      final result = await emotionService.analyzeFacialEmotion(_selectedImage!);

      print('📊 Facial emotion result: $result');

      // Extract emotion data from Hugging Face response
      final emotion = result['emotion']?.toString() ?? 'neutral';
      final confidence = (result['confidence'] ?? 0.0) as num;
      final intensity = (result['intensity'] ?? 5) as num;
      final allResults = result['allResults'] as List?;
      
      String analysisText = 'Detected: $emotion (${(confidence * 100).toStringAsFixed(1)}% confident)';
      
      // Add all results for more context
      if (allResults != null && allResults.isNotEmpty) {
        analysisText += '\\n\\nAll detected emotions:';
        for (var i = 0; i < allResults.length && i < 5; i++) {
          final r = allResults[i] as Map;
          final emotionName = r['emotion']?.toString() ?? '';
          final emotionConf = (r['confidence'] ?? 0.0) as num;
          analysisText += '\\n${i + 1}. $emotionName: ${(emotionConf * 100).toStringAsFixed(1)}%';
        }
      }
      
      if (mounted) {
        setState(() {
          _analysisResult = analysisText;
          _selectedEmotion = emotion.toLowerCase();
          _intensity = intensity.toDouble().clamp(1.0, 10.0);
          _isAnalyzing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Detected: $emotion'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Auto-log the detected emotion if confidence is high
        if (confidence > 0.5) {
          context.read<EmotionBloc>().add(AddEmotion(
            emotion: emotion,
            intensity: intensity.round().clamp(1, 10),
            note: 'Detected from facial image',
          ));
        }
      }
    } catch (e) {
      print('❌ Facial emotion analysis error: $e');
      if (mounted) {
        setState(() {
          _analysisResult = 'Error: ${e.toString()}';
          _isAnalyzing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to analyze: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _saveEmotion() {
    context.read<EmotionBloc>().add(
      AddEmotion(
        emotion: _selectedEmotion,
        intensity: _intensity.round(),
        note: _analysisResult.isNotEmpty
            ? 'AI Analysis: $_analysisResult'
            : null,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Emotion saved: $_selectedEmotion (${_intensity.round()}/10)',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// Custom Painters for Charts
class LineChartPainter extends CustomPainter {
  final AppTheme theme;
  final List emotions;

  LineChartPainter(this.theme, this.emotions);

  @override
  void paint(Canvas canvas, Size size) {
    if (emotions.isEmpty) return;

    // Group emotions by day for last 7 days
    final now = DateTime.now();
    final last7Days = List.generate(7, (index) {
      return DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - index));
    });

    final dailyAverages = <double>[];
    final labels = <String>[];

    for (final day in last7Days) {
      final dayEmotions = emotions.where((e) {
        final emotionDate = e.timestamp;
        return emotionDate.year == day.year &&
               emotionDate.month == day.month &&
               emotionDate.day == day.day;
      }).toList();

      if (dayEmotions.isNotEmpty) {
        final avgIntensity = dayEmotions.fold<double>(0, (sum, e) => sum + e.intensity) / dayEmotions.length;
        dailyAverages.add(avgIntensity);
      } else {
        dailyAverages.add(0);
      }

      labels.add(['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][day.weekday % 7]);
    }

    if (dailyAverages.every((v) => v == 0)) {
      // No data to display
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'No data for the past week',
          style: TextStyle(color: theme.text.withOpacity(0.5), fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
      );
      return;
    }

    // Normalize to chart height
    final maxIntensity = dailyAverages.reduce((a, b) => a > b ? a : b);
    final points = <Offset>[];
    
    for (int i = 0; i < dailyAverages.length; i++) {
      final x = (size.width / (dailyAverages.length - 1)) * i;
      final normalizedValue = maxIntensity > 0 ? dailyAverages[i] / maxIntensity : 0;
      final y = size.height * 0.8 - (normalizedValue * size.height * 0.6);
      points.add(Offset(x, y));
    }

    // Draw line
    final paint = Paint()
      ..color = theme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = theme.primary
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }

    // Draw labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < labels.length; i++) {
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(color: theme.text.withOpacity(0.7), fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, size.height - 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PieChartPainter extends CustomPainter {
  final AppTheme theme;
  final List emotions;

  PieChartPainter(this.theme, this.emotions);

  @override
  void paint(Canvas canvas, Size size) {
    if (emotions.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 3;

    // Count emotions by type
    final emotionCounts = <String, int>{};
    for (final emotion in emotions) {
      final emotionName = emotion.emotion.toLowerCase();
      emotionCounts[emotionName] = (emotionCounts[emotionName] ?? 0) + 1;
    }

    // Sort by count and take top 5
    final sortedEmotions = emotionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEmotions = sortedEmotions.take(5).toList();

    if (topEmotions.isEmpty) return;

    final total = topEmotions.fold<int>(0, (sum, e) => sum + e.value);
    double startAngle = -90; // Start from top

    final emotionColors = {
      'happy': Colors.green,
      'excited': Colors.lightGreen,
      'grateful': Colors.teal,
      'proud': Colors.lime,
      'calm': Colors.blue,
      'peaceful': Colors.lightBlue,
      'sad': Colors.indigo,
      'lonely': Colors.deepPurple,
      'angry': Colors.red,
      'stressed': Colors.deepOrange,
      'anxious': Colors.orange,
      'worried': Colors.amber,
      'confused': Colors.grey,
    };

    for (int i = 0; i < topEmotions.length; i++) {
      final entry = topEmotions[i];
      final percentage = (entry.value / total) * 100;
      final sweepAngle = (entry.value / total) * 360;
      
      final color = emotionColors[entry.key] ?? Colors.grey;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle * (pi / 180),
        sweepAngle * (pi / 180),
        true,
        paint,
      );

      // Draw labels only if segment is large enough
      if (percentage > 10) {
        final labelAngle = startAngle + sweepAngle / 2;
        final labelRadius = radius * 0.65;
        final labelX = center.dx + labelRadius * cos(labelAngle * (pi / 180));
        final labelY = center.dy + labelRadius * sin(labelAngle * (pi / 180));

        final textPainter = TextPainter(
          text: TextSpan(
            text: '${entry.key}\n${percentage.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
        );
      }

      startAngle += sweepAngle;
    }

    // Draw legend below if space allows
    double legendY = size.height - 60;
    double legendX = 10;
    
    for (int i = 0; i < topEmotions.length; i++) {
      final entry = topEmotions[i];
      final color = emotionColors[entry.key] ?? Colors.grey;
      final percentage = (entry.value / total) * 100;
      
      // Draw color box
      final boxPaint = Paint()..color = color;
      canvas.drawRect(
        Rect.fromLTWH(legendX, legendY + i * 12, 10, 10),
        boxPaint,
      );
      
      // Draw label
      final textPainter = TextPainter(
        text: TextSpan(
          text: ' ${entry.key}: ${percentage.toStringAsFixed(0)}%',
          style: TextStyle(
            color: theme.text.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(legendX + 12, legendY + i * 12));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
