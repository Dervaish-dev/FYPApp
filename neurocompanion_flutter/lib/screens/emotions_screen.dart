import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/bloc/bloc.dart';
import 'package:neurocompanion_flutter/bloc/blocs.dart';
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

  // Gemini AI Configuration
  static const String _apiKey = 'AIzaSyBTNGM1Qsl_z_CX87npTkeT7Zw0c4Cfl_w';
  late GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
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
            child: SingleChildScrollView(
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

                  // Analytics Section
                  _buildAnalytics(theme),
                ],
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

  Widget _buildAnalytics(AppTheme theme) {
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
          _buildLineChart(theme),
        ),
        const SizedBox(height: 16),

        // Emotion Distribution Chart
        _buildChartCard(
          theme,
          'Emotion Distribution',
          Icons.pie_chart,
          _buildPieChart(theme),
        ),
      ],
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

  Widget _buildLineChart(AppTheme theme) {
    return CustomPaint(
      size: const Size(double.infinity, 180),
      painter: LineChartPainter(theme),
    );
  }

  Widget _buildPieChart(AppTheme theme) {
    return CustomPaint(
      size: const Size(double.infinity, 180),
      painter: PieChartPainter(theme),
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
      final imageBytes = await _selectedImage!.readAsBytes();
      final content = [
        Content.multi([
          TextPart(
            'Analyze the emotion in this image. Provide a brief analysis of the person\'s emotional state, including the primary emotion and intensity level (1-10).',
          ),
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

      final response = await _model.generateContent(content);
      final analysis = response.text ?? 'Unable to analyze image';

      setState(() {
        _analysisResult = analysis;
        _isAnalyzing = false;
      });

      // Extract emotion and intensity from analysis
      _extractEmotionFromAnalysis(analysis);
    } catch (e) {
      setState(() {
        _analysisResult = 'Error analyzing image: $e';
        _isAnalyzing = false;
      });
    }
  }

  void _extractEmotionFromAnalysis(String analysis) {
    // Simple emotion extraction logic
    final lowerAnalysis = analysis.toLowerCase();

    // Check for emotions
    for (String emotion in _emotions) {
      if (lowerAnalysis.contains(emotion.toLowerCase())) {
        setState(() {
          _selectedEmotion = emotion;
        });
        break;
      }
    }

    // Extract intensity (look for numbers)
    final intensityMatch = RegExp(r'\b(\d+)\b').firstMatch(analysis);
    if (intensityMatch != null) {
      final intensity = int.tryParse(intensityMatch.group(1)!) ?? 5;
      setState(() {
        _intensity = intensity.clamp(1, 10).toDouble();
      });
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

  LineChartPainter(this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final points = [
      Offset(0, size.height * 0.2), // Mon
      Offset(size.width * 0.3, size.height * 0.4), // Wed
      Offset(size.width * 0.6, size.height * 0.3), // Fri
      Offset(size.width, size.height * 0.35), // Sat
    ];

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

    final labels = ['Mon', 'Wed', 'Fri', 'Sat'];
    for (int i = 0; i < points.length; i++) {
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(color: theme.text.withOpacity(0.7), fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, size.height - 20),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PieChartPainter extends CustomPainter {
  final AppTheme theme;

  PieChartPainter(this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    final colors = [Colors.green, Colors.blue, Colors.orange];
    final labels = ['Happy 33%', 'Calm 33%', 'Stressed 33%'];
    final sweepAngles = [120, 120, 120]; // Equal segments

    double startAngle = -90; // Start from top

    for (int i = 0; i < 3; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle * (pi / 180),
        sweepAngles[i] * (pi / 180),
        true,
        paint,
      );

      // Draw labels
      final labelAngle = startAngle + sweepAngles[i] / 2;
      final labelRadius = radius * 0.7;
      final labelX = center.dx + labelRadius * cos(labelAngle * (pi / 180));
      final labelY = center.dy + labelRadius * sin(labelAngle * (pi / 180));

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
      );

      startAngle += sweepAngles[i];
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
