import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/services/caregiver_service.dart';
import 'package:neurocompanion_flutter/services/api_client.dart';
import 'package:neurocompanion_flutter/models/caregiver_models.dart';
import 'package:neurocompanion_flutter/screens/caregiver_patient_detail_screen.dart';

class CaregiverPatientListScreen extends StatefulWidget {
  const CaregiverPatientListScreen({super.key});

  @override
  State<CaregiverPatientListScreen> createState() => _CaregiverPatientListScreenState();
}

class _CaregiverPatientListScreenState extends State<CaregiverPatientListScreen> {
  late CaregiverService _caregiverService;
  List<CaregiverPatient> _patients = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _caregiverProfile;
  bool _isGridView = false; // false = list view, true = grid view

  // Invites state
  List<Map<String, dynamic>> _invites = [];
  bool _invitesLoading = false;
  bool _invitesExpanded = false;
  Map<String, String> _inviteCodeById = {};
  Map<String, bool> _inviteCodeLoadingById = {};

  @override
  void initState() {
    super.initState();
    _caregiverService = CaregiverService(apiClient: context.read<ApiClient>());
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadPatients(),
      _loadCaregiverProfile(),
      _loadInvites(),
    ]);
  }

  Future<void> _loadInvites() async {
    try {
      setState(() {
        _invitesLoading = true;
      });

      final invites = await _caregiverService.getInvites();
      
      // Debug: Print invite structure to see what fields are available
      if (invites.isNotEmpty) {
        print('DEBUG: First invite structure: ${invites[0]}');
      }
      
      if (mounted) {
        setState(() {
          _invites = invites;
          _invitesLoading = false;
        });
      }
    } catch (e) {
      print('Error loading invites: $e');
      if (mounted) {
        setState(() {
          _invitesLoading = false;
        });
      }
    }
  }

  void _showAddPatientDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddPatientDialog(
        caregiverService: _caregiverService,
        onSuccess: () {
          _loadInvites();
        },
      ),
    );
  }

  Future<void> _toggleInviteCode(String inviteId) async {
    // Validate inviteId before making API call
    if (inviteId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid invite ID')),
      );
      return;
    }

    if (_inviteCodeById.containsKey(inviteId)) {
      setState(() {
        _inviteCodeById.remove(inviteId);
      });
      return;
    }

    try {
      setState(() {
        _inviteCodeLoadingById[inviteId] = true;
      });

      final response = await _caregiverService.getInviteCode(inviteId);
      if (mounted) {
        setState(() {
          _inviteCodeById[inviteId] = response['invite']?['code'] ?? '';
          _inviteCodeLoadingById[inviteId] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _inviteCodeLoadingById[inviteId] = false;
        });
        final errorMessage = e.toString().contains('already claimed')
            ? 'This invite has already been accepted by the patient'
            : 'Failed to load invite code: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  Future<void> _regenerateInvite(String inviteId) async {
    try {
      final response = await _caregiverService.regenerateInvite(inviteId);
      final newCode = response['invite']?['code'] ?? '';
      
      if (mounted) {
        setState(() {
          _inviteCodeById[inviteId] = newCode;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('New invite code: $newCode')),
        );
        _loadInvites();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to regenerate invite: $e')),
        );
      }
    }
  }

  Future<void> _revokeInvite(String inviteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Invite'),
        content: const Text('Are you sure you want to revoke this invite?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _caregiverService.revokeInvite(inviteId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invite revoked')),
          );
          _loadInvites();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to revoke invite: $e')),
          );
        }
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  Future<void> _loadCaregiverProfile() async {
    try {
      final profile = await _caregiverService.getProfile();
      if (mounted) {
        setState(() {
          _caregiverProfile = profile['caregiver'] as Map<String, dynamic>?;
        });
      }
    } catch (e) {
      print('Error loading caregiver profile: $e');
    }
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final patientsData = await _caregiverService.getPatients();
      if (mounted) {
        setState(() {
          _patients = patientsData.map((p) => CaregiverPatient.fromJson(p)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load patients';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;

        return Scaffold(
          backgroundColor: theme.background,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showAddPatientDialog,
            backgroundColor: theme.primary,
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: const Text('Add Patient', style: TextStyle(color: Colors.white)),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Greeting Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _buildGreetingCard(theme),
                ),

                // Header with view toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Patients',
                                style: TextStyle(
                                  color: theme.text,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_patients.length} active patients',
                                style: TextStyle(
                                  color: theme.text.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              _isGridView ? Icons.view_list : Icons.grid_view,
                              color: theme.primary,
                            ),
                            onPressed: () {
                              setState(() {
                                _isGridView = !_isGridView;
                              });
                            },
                            tooltip: _isGridView ? 'List View' : 'Grid View',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: theme.primary),
                        )
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                                  const SizedBox(height: 16),
                                  Text(_error!, style: TextStyle(color: theme.text)),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadData,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.primary,
                                    ),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              color: theme.primary,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Column(
                                  children: [
                                    // Invites Section
                                    if (_invites.isNotEmpty) _buildInvitesSection(theme),
                                    
                                    // Patients List/Grid
                                    if (_patients.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(48),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.people_outline,
                                              size: 64,
                                              color: theme.text.withOpacity(0.3),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'No patients yet',
                                              style: TextStyle(
                                                color: theme.text,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Tap "Add Patient" to invite your first patient',
                                              style: TextStyle(
                                                color: theme.text.withOpacity(0.7),
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (_isGridView)
                                      GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 0.85,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                        ),
                                        itemCount: _patients.length,
                                        itemBuilder: (context, index) {
                                          return _buildPatientGridCard(theme, _patients[index]);
                                        },
                                      )
                                    else
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        itemCount: _patients.length,
                                        itemBuilder: (context, index) {
                                          return _buildPatientCard(theme, _patients[index]);
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvitesSection(AppTheme theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
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
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _invitesExpanded = !_invitesExpanded;
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        _invitesExpanded ? Icons.expand_less : Icons.expand_more,
                        color: theme.text,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Patient Invites',
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_invites.length}',
                          style: TextStyle(
                            color: theme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: theme.text.withOpacity(0.7),
                ),
                onPressed: _invitesLoading ? null : _loadInvites,
              ),
            ],
          ),
          if (_invitesExpanded) ...[
            const SizedBox(height: 12),
            ..._invites.map((invite) => _buildInviteItem(theme, invite)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildInviteItem(AppTheme theme, Map<String, dynamic> invite) {
    final inviteId = (invite['_id'] ?? invite['id']) as String? ?? '';
    // Skip rendering if inviteId is empty
    if (inviteId.isEmpty) {
      return const SizedBox.shrink();
    }
    // Check multiple field name variations
    final patientName = (invite['patientName'] ?? invite['patient_name'] ?? invite['name']) as String? ?? 'Unknown';
    final patientEmail = (invite['patientEmail'] ?? invite['patient_email'] ?? invite['email']) as String? ?? '';
    final status = invite['status'] as String? ?? 'pending';
    final isCodeVisible = _inviteCodeById.containsKey(inviteId);
    final isCodeLoading = _inviteCodeLoadingById[inviteId] ?? false;
    final code = _inviteCodeById[inviteId] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      patientEmail,
                      style: TextStyle(
                        color: theme.text.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'accepted'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: status == 'accepted' ? Colors.green : Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (isCodeVisible && code.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      code,
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 14,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, size: 18, color: theme.primary),
                    onPressed: () => _copyToClipboard(code),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: isCodeLoading ? null : () => _toggleInviteCode(inviteId),
                  icon: Icon(
                    isCodeVisible ? Icons.visibility_off : Icons.visibility,
                    size: 16,
                  ),
                  label: Text(isCodeVisible ? 'Hide Code' : 'Show Code'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _regenerateInvite(inviteId),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Regenerate'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _revokeInvite(inviteId),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Revoke'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(AppTheme theme, CaregiverPatient patient) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CaregiverPatientDetailScreen(patientId: patient.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.primary, theme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name and info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (patient.neurotype != null)
                        Text(
                          patient.neurotype!,
                          style: TextStyle(
                            color: theme.text.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                // Status indicator
                if (patient.lastActive != null)
                  Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _getActivityColor(patient.lastActive!),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getActivityText(patient.lastActive!),
                        style: TextStyle(
                          color: theme.text.withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (patient.currentMood != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getMoodColor(patient.currentMood!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getMoodColor(patient.currentMood!).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getMoodIcon(patient.currentMood!),
                      size: 16,
                      color: _getMoodColor(patient.currentMood!),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Feeling ${patient.currentMood}',
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (patient.moodScore != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${patient.moodScore!.toStringAsFixed(1)}/10)',
                        style: TextStyle(
                          color: theme.text.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getActivityColor(DateTime lastActive) {
    final diff = DateTime.now().difference(lastActive);
    if (diff.inHours < 1) return Colors.green;
    if (diff.inHours < 24) return Colors.orange;
    return Colors.grey;
  }

  String _getActivityText(DateTime lastActive) {
    final diff = DateTime.now().difference(lastActive);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'excited':
        return Colors.green;
      case 'sad':
      case 'depressed':
        return Colors.blue;
      case 'calm':
        return Colors.teal;
      case 'stressed':
      case 'anxious':
        return Colors.orange;
      case 'angry':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildGreetingCard(AppTheme theme) {
    // Get caregiver name
    String caregiverName = 'Caregiver';
    if (_caregiverProfile != null) {
      final fullName = _caregiverProfile!['name'] as String? ?? 'Caregiver';
      caregiverName = fullName.split(' ').first; // Get first name only
    }

    // Time-based greeting
    final hour = DateTime.now().hour;
    String greeting;
    String emoji;
    
    if (hour < 12) {
      greeting = 'Good Morning';
      emoji = '☀️';
    } else if (hour < 18) {
      greeting = 'Good Afternoon';
      emoji = '🌤️';
    } else {
      greeting = 'Good Evening';
      emoji = '🌙';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primary.withOpacity(0.08), theme.secondary.withOpacity(0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting $emoji',
            style: TextStyle(
              color: theme.text.withOpacity(0.7),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caregiverName,
            style: TextStyle(
              color: theme.text,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready to support your patients today?',
            style: TextStyle(
              color: theme.text.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMoodIcon(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'calm':
        return Icons.spa;
      case 'stressed':
      case 'anxious':
        return Icons.warning_amber;
      case 'angry':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  Widget _buildPatientGridCard(AppTheme theme, CaregiverPatient patient) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CaregiverPatientDetailScreen(patientId: patient.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primary, theme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Name
            Text(
              patient.name,
              style: TextStyle(
                color: theme.text,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            // Neurotype
            if (patient.neurotype != null)
              Text(
                patient.neurotype!,
                style: TextStyle(
                  color: theme.text.withOpacity(0.6),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),
            // Status indicator
            if (patient.lastActive != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getActivityColor(patient.lastActive!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getActivityText(patient.lastActive!),
                    style: TextStyle(
                      color: theme.text.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            // Mood indicator
            if (patient.currentMood != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getMoodColor(patient.currentMood!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getMoodColor(patient.currentMood!).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getMoodIcon(patient.currentMood!),
                      size: 14,
                      color: _getMoodColor(patient.currentMood!),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        patient.currentMood!,
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

// Add Patient Dialog Widget
class _AddPatientDialog extends StatefulWidget {
  final CaregiverService caregiverService;
  final VoidCallback onSuccess;

  const _AddPatientDialog({
    required this.caregiverService,
    required this.onSuccess,
  });

  @override
  State<_AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends State<_AddPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _neurotypeController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _createdInvite;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _neurotypeController.dispose();
    super.dispose();
  }

  Future<void> _createInvite() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final age = _ageController.text.trim().isEmpty
          ? null
          : int.tryParse(_ageController.text.trim());

      final response = await widget.caregiverService.createInvite(
        patientName: _nameController.text.trim(),
        patientEmail: _emailController.text.trim(),
        age: age,
        neurotype: _neurotypeController.text.trim().isEmpty
            ? null
            : _neurotypeController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _createdInvite = response['invite'] as Map<String, dynamic>?;
          _isLoading = false;
        });
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Patient',
                            style: TextStyle(
                              color: theme.text,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _createdInvite == null
                                ? 'Create an invite for your patient'
                                : 'Invite code generated',
                            style: TextStyle(
                              color: theme.text.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: theme.text),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (_createdInvite == null) ...[
                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            style: TextStyle(color: theme.text),
                            decoration: InputDecoration(
                              labelText: 'Patient Name *',
                              hintText: 'John Doe',
                              filled: true,
                              fillColor: theme.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.border),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Patient name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            style: TextStyle(color: theme.text),
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Patient Email *',
                              hintText: 'patient@example.com',
                              filled: true,
                              fillColor: theme.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.border),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _ageController,
                            style: TextStyle(color: theme.text),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Age (Optional)',
                              hintText: '25',
                              filled: true,
                              fillColor: theme.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.border),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _neurotypeController,
                            style: TextStyle(color: theme.text),
                            decoration: InputDecoration(
                              labelText: 'Neurotype (Optional)',
                              hintText: 'ADHD, Autism, etc.',
                              filled: true,
                              fillColor: theme.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.border),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(color: theme.text),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createInvite,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text(
                                'Create Invite',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ] else ...[
                    // Success - Show invite code
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Invite created successfully!',
                                  style: TextStyle(
                                    color: theme.text,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Invite Code:',
                            style: TextStyle(
                              color: theme.text.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _createdInvite!['code'] ?? '',
                                    style: TextStyle(
                                      color: theme.text,
                                      fontSize: 18,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.copy, color: theme.primary),
                                  onPressed: () => _copyToClipboard(
                                    _createdInvite!['code'] ?? '',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Patient uses this code at /join, then verifies email with OTP.',
                            style: TextStyle(
                              color: theme.text.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
