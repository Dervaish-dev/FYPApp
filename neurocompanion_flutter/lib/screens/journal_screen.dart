import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/bloc/bloc.dart';
import 'package:neurocompanion_flutter/bloc/blocs.dart';
import 'package:neurocompanion_flutter/models/models.dart';
import 'package:neurocompanion_flutter/services/services.dart';
import 'package:neurocompanion_flutter/widgets/voice_journal_button.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _contentController = TextEditingController();
  bool _isWriting = false;
  bool _isAnalyzing = false;
  JournalEntry? _editingEntry;
  bool _showChatbot = false;
  final List<Map<String, dynamic>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  bool _isChatTyping = false;

  @override
  void initState() {
    super.initState();
    _loadJournalEntries();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _loadJournalEntries() {
    context.read<JournalBloc>().add(LoadJournalEntries());
  }

  Future<void> _saveEntry() async {
    if (_contentController.text.trim().isEmpty) return;

    setState(() => _isAnalyzing = true);

    try {
      final authService = context.read<AuthService>();
      
      // Ensure user is loaded
      var userId = authService.currentUser?.id;
      if (userId == null) {
        final user = await authService.getCurrentUser();
        userId = user?.id;
      }

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (_editingEntry != null) {
        context.read<JournalBloc>().add(UpdateJournalEntry(
              entryId: _editingEntry!.id,
              content: _contentController.text.trim(),
            ));
      } else {
        context.read<JournalBloc>().add(CreateJournalEntry(
              userId: userId,
              content: _contentController.text.trim(),
              mood: 5,
              tags: [],
            ));
      }

      setState(() {
        _contentController.clear();
        _isWriting = false;
        _editingEntry = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save entry: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  void _deleteEntry(String entryId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<JournalBloc>().add(DeleteJournalEntry(entryId: entryId));
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editEntry(JournalEntry entry) {
    setState(() {
      _editingEntry = entry;
      _contentController.text = entry.content;
      _isWriting = true;
    });
  }

  bool _needsSupport(String? emotion) {
    if (emotion == null) return false;
    const negativeEmotions = [
      'sad',
      'angry',
      'stressed',
      'anxious',
      'depressed',
      'worried',
      'confused',
      'lonely',
      'frustrated',
      'overwhelmed',
      'nervous',
      'pessimistic'
    ];
    return negativeEmotions.contains(emotion.toLowerCase());
  }

  Future<void> _sendChatMessage() async {
    if (_chatController.text.trim().isEmpty) return;

    final userMessage = _chatController.text.trim();
    setState(() {
      _chatMessages.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'text': userMessage,
        'sender': 'user',
        'timestamp': DateTime.now(),
      });
      _chatController.clear();
      _isChatTyping = true;
    });

    try {
      // Simulate AI response (in production, call backend chatbot API)
      await Future.delayed(const Duration(seconds: 1));
      
      final responses = [
        "I'm here for you. You can share your feelings with me.",
        "Everything will be okay. I'm with you.",
        "Is something bothering you? I'm listening.",
        "Take a deep breath. Let's work through this together.",
        "You're not alone. I'm here to support you.",
      ];
      
      final botResponse = responses[DateTime.now().second % responses.length];
      
      if (mounted) {
        setState(() {
          _chatMessages.add({
            'id': DateTime.now().millisecondsSinceEpoch + 1,
            'text': botResponse,
            'sender': 'bot',
            'timestamp': DateTime.now(),
          });
          _isChatTyping = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChatTyping = false);
      }
    }
  }

  String _getMoodEmoji(String? emotion) {
    const emojis = {
      'happy': '😊',
      'sad': '😢',
      'angry': '😠',
      'stressed': '😰',
      'anxious': '😟',
      'depressed': '😔',
      'calm': '😌',
      'excited': '🤩',
      'worried': '😥',
      'confused': '🤔',
      'lonely': '😞',
      'grateful': '🙏',
      'hopeful': '🌟',
      'frustrated': '😤',
      'peaceful': '☮️',
      'overwhelmed': '😵',
      'content': '😊',
      'nervous': '😬',
      'optimistic': '😄',
      'pessimistic': '😕',
      'neutral': '😐',
    };
    return emojis[emotion?.toLowerCase()] ?? emojis['neutral']!;
  }

  Color _getMoodColor(String? emotion) {
    const colors = {
      'happy': Colors.green,
      'sad': Colors.blue,
      'angry': Colors.red,
      'stressed': Colors.orange,
      'anxious': Colors.amber,
      'depressed': Colors.purple,
      'calm': Colors.indigo,
      'excited': Colors.pink,
      'neutral': Colors.grey,
    };
    return colors[emotion?.toLowerCase()] ?? colors['neutral']!;
  }

  Map<String, double> _getMoodStats(List<JournalEntry> entries) {
    if (entries.isEmpty) {
      return {'positive': 0, 'negative': 0, 'neutral': 0};
    }

    const positiveMoods = [
      'happy',
      'calm',
      'excited',
      'grateful',
      'hopeful',
      'peaceful',
      'content',
      'optimistic'
    ];
    const negativeMoods = [
      'sad',
      'angry',
      'stressed',
      'anxious',
      'depressed',
      'worried',
      'confused',
      'lonely',
      'frustrated',
      'overwhelmed',
      'nervous',
      'pessimistic'
    ];

    int positive = 0, negative = 0, neutral = 0;

    for (var entry in entries) {
      final emotion = entry.emotion?.toLowerCase() ?? 'neutral';
      if (positiveMoods.contains(emotion)) {
        positive++;
      } else if (negativeMoods.contains(emotion)) {
        negative++;
      } else {
        neutral++;
      }
    }

    final total = entries.length;
    return {
      'positive': (positive / total * 100),
      'negative': (negative / total * 100),
      'neutral': (neutral / total * 100),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;

        return Scaffold(
          backgroundColor: theme.background,
          body: BlocConsumer<JournalBloc, JournalState>(
            listener: (context, state) {
              if (state is JournalError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              } else if (state is JournalLoaded && state.entries.isNotEmpty) {
                final latestEntry = state.entries.first;
                if (_needsSupport(latestEntry.emotion)) {
                  // Show chatbot button after a delay
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      setState(() => _showChatbot = false);
                    }
                  });
                }
              }
            },
            builder: (context, state) {
              if (state is JournalLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: theme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Loading your journal...',
                        style: TextStyle(color: theme.text.withOpacity(0.7)),
                      ),
                    ],
                  ),
                );
              }

              if (state is JournalError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Something went wrong',
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        style: TextStyle(color: theme.text.withOpacity(0.7)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadJournalEntries,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final entries =
                  state is JournalLoaded ? state.entries : <JournalEntry>[];
              final moodStats = _getMoodStats(entries);
              final totalWords = entries.fold<int>(
                  0, (sum, entry) => sum + entry.content.split(' ').length);

              return SafeArea(
                child: Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: () async {
                        context.read<JournalBloc>().add(LoadJournalEntries());
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      color: theme.primary,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                        // Header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.book,
                                        size: 32, color: theme.primary),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Journal & AI Analysis',
                                            style: TextStyle(
                                              color: theme.text,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Express your thoughts',
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
                              ],
                            ),
                          ),
                        ),

                        // Quick Stats
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.book,
                                    label: 'Entries',
                                    value: entries.length.toString(),
                                    color: theme.primary,
                                    theme: theme,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.text_fields,
                                    label: 'Words',
                                    value: totalWords.toString(),
                                    color: theme.primary,
                                    theme: theme,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.sentiment_satisfied,
                                    label: 'Positive',
                                    value: '${moodStats['positive']!.toStringAsFixed(0)}%',
                                    color: Colors.green,
                                    theme: theme,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(
                            child: SizedBox(height: 16)),

                        // Writing Section
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Card(
                              color: theme.card,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Write Your Thoughts',
                                            style: TextStyle(
                                              color: theme.text,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (!_isWriting)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              VoiceJournalButton(
                                                onCallComplete: _loadJournalEntries,
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: Icon(Icons.add,
                                                    color: theme.primary),
                                                onPressed: () =>
                                                    setState(() => _isWriting = true),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    if (_isWriting) ...[
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _contentController,
                                        maxLines: 5,
                                        style: TextStyle(color: theme.text),
                                        decoration: InputDecoration(
                                          hintText:
                                              'How are you feeling today? Write in any language...',
                                          hintStyle: TextStyle(
                                              color:
                                                  theme.text.withOpacity(0.5)),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                                color: theme.border),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                                color: theme.border),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                                color: theme.primary,
                                                width: 2),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${_contentController.text.trim().split(' ').length} words',
                                            style: TextStyle(
                                                color:
                                                    theme.text.withOpacity(0.7),
                                                fontSize: 12),
                                          ),
                                          Row(
                                            children: [
                                              TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _isWriting = false;
                                                    _contentController.clear();
                                                    _editingEntry = null;
                                                  });
                                                },
                                                child: const Text('Cancel'),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton(
                                                onPressed:
                                                    _isAnalyzing ? null : _saveEntry,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      theme.primary,
                                                ),
                                                child: _isAnalyzing
                                                    ? const SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                      )
                                                    : Text(_editingEntry != null
                                                        ? 'Update'
                                                        : 'Save'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(
                            child: SizedBox(height: 16)),

                        // Entries Header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Recent Entries',
                              style: TextStyle(
                                color: theme.text,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(
                            child: SizedBox(height: 12)),

                        // Journal Entries
                        entries.isEmpty
                            ? SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.book_outlined,
                                          size: 64,
                                          color: theme.text.withOpacity(0.3)),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No entries yet',
                                        style: TextStyle(
                                          color: theme.text,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Start writing to track your thoughts',
                                        style: TextStyle(
                                            color:
                                                theme.text.withOpacity(0.7)),
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton(
                                        onPressed: () =>
                                            setState(() => _isWriting = true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme.primary,
                                        ),
                                        child: const Text(
                                            'Write Your First Entry'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final entry = entries[index];
                                    return _buildJournalEntryCard(
                                        entry, theme);
                                  },
                                  childCount: entries.length,
                                ),
                              ),

                        const SliverToBoxAdapter(
                            child: SizedBox(height: 80)),
                      ],
                    ),
                    ),

                    // Chatbot Dialog
                    if (_showChatbot)
                      Positioned(
                        bottom: 100,
                        right: 16,
                        child: _buildChatbotDialog(theme),
                      ),

                    // Floating Chatbot Button
                    if (!_showChatbot &&
                        entries.isNotEmpty &&
                        _needsSupport(entries.first.emotion))
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton(
                          onPressed: () {
                            setState(() {
                              _showChatbot = true;
                              _chatMessages.add({
                                'id': DateTime.now().millisecondsSinceEpoch,
                                'text':
                                    "Is everything okay? How are you feeling? I'm here for you. 💙",
                                'sender': 'bot',
                                'timestamp': DateTime.now(),
                              });
                            });
                          },
                          backgroundColor: theme.primary,
                          child: const Icon(Icons.chat_bubble_outline),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required dynamic theme,
  }) {
    return Card(
      color: theme.card,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: theme.text,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: theme.text.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalEntryCard(JournalEntry entry, dynamic theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Card(
        color: theme.card,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getMoodEmoji(entry.emotion),
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('MMM d, y')
                                    .format(entry.createdAt),
                                style: TextStyle(
                                  color: theme.text,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                DateFormat('h:mm a').format(entry.createdAt),
                                style: TextStyle(
                                  color: theme.text.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, size: 18, color: theme.text),
                        onPressed: () => _editEntry(entry),
                        padding: EdgeInsets.all(8),
                        constraints: BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 18, color: Colors.red),
                        onPressed: () => _deleteEntry(entry.id),
                        padding: EdgeInsets.all(8),
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Content
              Text(
                entry.content,
                style: TextStyle(
                  color: theme.text.withOpacity(0.9),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 12),

              // AI Analysis
              if (entry.aiAnalysis != null && entry.aiAnalysis!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.psychology,
                          size: 16, color: theme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.aiAnalysis!,
                          style: TextStyle(
                            color: theme.text.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${entry.content.split(' ').length} words',
                    style: TextStyle(
                      color: theme.text.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getMoodColor(entry.emotion).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              (entry.emotion ?? 'neutral')
                                  .replaceFirst(
                                      entry.emotion![0],
                                      entry.emotion![0].toUpperCase())
                                  .toString(),
                              style: TextStyle(
                                color: _getMoodColor(entry.emotion),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(entry.emotionConfidence * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: theme.text.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatbotDialog(dynamic theme) {
    return Container(
      width: 300,
      height: 400,
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green,
                      radius: 16,
                      child: const Icon(Icons.chat_bubble,
                          size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Support Buddy',
                          style: TextStyle(
                            color: theme.text,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'I\'m here to help',
                          style: TextStyle(
                            color: theme.text.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close, color: theme.text),
                  onPressed: () => setState(() => _showChatbot = false),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final message = _chatMessages[index];
                final isUser = message['sender'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 220),
                    decoration: BoxDecoration(
                      color: isUser
                          ? theme.primary
                          : theme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message['text'],
                      style: TextStyle(
                        color: isUser ? Colors.white : theme.text,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Typing indicator
          if (_isChatTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      3,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: theme.text.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(color: theme.border, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: TextStyle(color: theme.text),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle:
                          TextStyle(color: theme.text.withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: theme.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendChatMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: theme.primary),
                  onPressed: _sendChatMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
