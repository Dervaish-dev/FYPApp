import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen> with TickerProviderStateMixin {
  bool _isActive = false;
  String _currentPhase = 'inhale';
  int _currentCycle = 0;
  double _progress = 0.0;
  bool _sessionComplete = false;
  String _selectedExercise = '478';
  
  Timer? _timer;
  late AnimationController _circleController;
  late AnimationController _particleController;

  final Map<String, Map<String, dynamic>> _exercises = {
    '478': {
      'name': '4-7-8 Breathing',
      'description': 'Natural tranquilizer for the nervous system',
      'icon': Icons.psychology,
      'phases': [
        {'name': 'inhale', 'duration': 4000, 'instruction': 'Inhale through nose (4s)'},
        {'name': 'hold', 'duration': 7000, 'instruction': 'Hold your breath (7s)'},
        {'name': 'exhale', 'duration': 8000, 'instruction': 'Exhale through mouth (8s)'},
      ],
      'cycles': 4,
      'color': const Color(0xFF3B82F6),
    },
    'box': {
      'name': 'Box Breathing',
      'description': 'Used by Navy SEALs for focus and calm',
      'icon': Icons.flash_on,
      'phases': [
        {'name': 'inhale', 'duration': 4000, 'instruction': 'Inhale slowly (4s)'},
        {'name': 'hold', 'duration': 4000, 'instruction': 'Hold your breath (4s)'},
        {'name': 'exhale', 'duration': 4000, 'instruction': 'Exhale gently (4s)'},
        {'name': 'hold', 'duration': 4000, 'instruction': 'Hold empty (4s)'},
      ],
      'cycles': 4,
      'color': const Color(0xFF10B981),
    },
    'relaxation': {
      'name': 'Deep Relaxation',
      'description': 'Perfect for stress relief and sleep',
      'icon': Icons.favorite,
      'phases': [
        {'name': 'inhale', 'duration': 5000, 'instruction': 'Breathe in deeply (5s)'},
        {'name': 'hold', 'duration': 2000, 'instruction': 'Hold gently (2s)'},
        {'name': 'exhale', 'duration': 7000, 'instruction': 'Exhale slowly (7s)'},
      ],
      'cycles': 5,
      'color': const Color(0xFFA855F7),
    },
  };

  @override
  void initState() {
    super.initState();
    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _circleController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _currentExercise => _exercises[_selectedExercise]!;

  void _startExercise() {
    setState(() {
      _isActive = true;
      _currentCycle = 0;
      _currentPhase = 'inhale';
      _progress = 0.0;
      _sessionComplete = false;
    });

    _circleController.repeat();
    _runBreathingCycle();
  }

  void _stopExercise() {
    _timer?.cancel();
    _circleController.stop();
    setState(() {
      _isActive = false;
      _currentCycle = 0;
      _currentPhase = 'inhale';
      _progress = 0.0;
    });
  }

  void _resetExercise() {
    _stopExercise();
    setState(() {
      _sessionComplete = false;
    });
  }

  void _runBreathingCycle() {
    final phases = _currentExercise['phases'] as List;
    int currentPhaseIndex = 0;
    int cycleCount = 0;
    double progress = 0;

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isActive) {
        timer.cancel();
        return;
      }

      final currentPhase = phases[currentPhaseIndex];
      final phaseDuration = currentPhase['duration'] as int;

      setState(() {
        _currentPhase = currentPhase['name'];
        progress += 100 / (phaseDuration / 100);
        _progress = progress.clamp(0.0, 100.0);
      });

      if (progress >= 100) {
        currentPhaseIndex = (currentPhaseIndex + 1) % phases.length;
        progress = 0;

        if (currentPhaseIndex == 0) {
          cycleCount++;
          setState(() => _currentCycle = cycleCount);

          if (cycleCount >= _currentExercise['cycles']) {
            _stopExercise();
            setState(() => _sessionComplete = true);
            timer.cancel();
          }
        }
      }
    });
  }

  String _getCurrentInstruction() {
    if (!_isActive) return 'Ready to begin';
    final phases = _currentExercise['phases'] as List<Map<String, Object>>;
    final phase = phases.firstWhere(
      (p) => p['name'] == _currentPhase,
      orElse: () => phases[0] as Map<String, Object>,
    );
    return phase['instruction'] as String;
  }

  double _getCircleSize() {
    final baseSize = 120.0;
    final progress = _progress / 100;
    
    switch (_currentPhase) {
      case 'inhale':
        return baseSize + (progress * 100);
      case 'hold':
        return progress < 0.5 ? 220 : 220 - ((progress - 0.5) * 10);
      case 'exhale':
        return 220 - (progress * 100);
      default:
        return baseSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseColor = _currentExercise['color'] as Color;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Breathing Exercises'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Exercise Selection
            SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _exercises.entries.map((entry) {
                  final isSelected = _selectedExercise == entry.key;
                  final color = entry.value['color'] as Color;
                  
                  return GestureDetector(
                    onTap: () {
                      if (!_isActive) {
                        setState(() => _selectedExercise = entry.key);
                        _resetExercise();
                      }
                    },
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? color : Colors.grey.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(entry.value['icon'] as IconData, color: color, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            entry.value['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(
                              entry.value['description'],
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Main Animation Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.air, color: exerciseColor, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          _currentExercise['name'],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Breathing Circle Animation
                    SizedBox(
                      height: 300,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Animated particles
                          if (_isActive)
                            ...List.generate(8, (index) {
                              return AnimatedBuilder(
                                animation: _particleController,
                                builder: (context, child) {
                                  final angle = (index * 45) * math.pi / 180;
                                  final distance = 80 * math.sin(_particleController.value * math.pi);
                                  return Transform.translate(
                                    offset: Offset(
                                      math.cos(angle) * distance,
                                      math.sin(angle) * distance,
                                    ),
                                    child: Opacity(
                                      opacity: (math.sin(_particleController.value * math.pi)).abs(),
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: exerciseColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),
                          
                          // Main breathing circle
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            width: _getCircleSize(),
                            height: _getCircleSize(),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: exerciseColor, width: 4),
                              color: exerciseColor.withOpacity(0.1),
                              boxShadow: [
                                BoxShadow(
                                  color: exerciseColor.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          
                          // Center content
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_currentCycle}/${_currentExercise['cycles']}',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getCurrentInstruction(),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: exerciseColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_isActive) ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: 200,
                                  child: LinearProgressIndicator(
                                    value: _progress / 100,
                                    backgroundColor: Colors.grey.withOpacity(0.2),
                                    valueColor: AlwaysStoppedAnimation<Color>(exerciseColor),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Control Buttons
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (!_isActive)
                          ElevatedButton.icon(
                            onPressed: _startExercise,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Exercise'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: exerciseColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: _stopExercise,
                            icon: const Icon(Icons.pause),
                            label: const Text('Stop Exercise'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        if ((_sessionComplete || _currentCycle > 0) && !_isActive)
                          OutlinedButton.icon(
                            onPressed: _resetExercise,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    // Completion Message
                    if (_sessionComplete)
                      Container(
                        margin: const EdgeInsets.only(top: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: exerciseColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: exerciseColor),
                        ),
                        child: Column(
                          children: [
                            const Text('🌿', style: TextStyle(fontSize: 32)),
                            const SizedBox(height: 8),
                            Text(
                              'Exercise Complete!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: exerciseColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Great work! Your breathing is more relaxed now.',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Benefits Info
            const Text(
              'Benefits',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildBenefitCard('😌', 'Reduces Stress', 'Calms the nervous system and lowers cortisol levels'),
            _buildBenefitCard('🧠', 'Improves Focus', 'Increases oxygen flow to the brain for better concentration'),
            _buildBenefitCard('💤', 'Better Sleep', 'Prepares your body for restful and deep sleep'),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitCard(String emoji, String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
