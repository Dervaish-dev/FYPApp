import 'package:flutter/material.dart';
import 'package:neurocompanion_flutter/services/api_client.dart';
import 'package:neurocompanion_flutter/services/api_config.dart';
import 'package:neurocompanion_flutter/services/token_store.dart';

class CaregiverProfileScreen extends StatefulWidget {
  const CaregiverProfileScreen({Key? key}) : super(key: key);

  @override
  State<CaregiverProfileScreen> createState() => _CaregiverProfileScreenState();
}

class _CaregiverProfileScreenState extends State<CaregiverProfileScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _caregiverData;
  late ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(
      baseUrl: ApiConfig.baseUrl,
      tokenStore: SharedPrefsTokenStore(),
    );
    _loadCaregiverProfile();
  }

  Future<void> _loadCaregiverProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Fetch caregiver profile
      final response = await _apiClient.get('/caregiver/profile');
      
      setState(() {
        _caregiverData = response;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading caregiver profile: $e');
      setState(() {
        _error = 'Failed to load profile';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(theme)
              : _buildProfile(theme),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: theme.textTheme.bodyLarge?.color?.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(
              fontSize: 16,
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadCaregiverProfile,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(ThemeData theme) {
    final name = _caregiverData?['name'] ?? 'Caregiver';
    final email = _caregiverData?['email'] ?? 'caregiver@example.com';
    final phone = _caregiverData?['phone'] ?? 'Not provided';
    final specialization = _caregiverData?['specialization'] ?? 'Not specified';
    final yearsOfExperience = _caregiverData?['yearsOfExperience'] ?? 0;
    final bio = _caregiverData?['bio'] ?? 'No bio available';
    final has2FA = _caregiverData?['has2FA'] ?? false;
    final totalPatients = _caregiverData?['totalPatients'] ?? 0;
    final createdAt = _caregiverData?['createdAt'];

    return RefreshIndicator(
      onRefresh: _loadCaregiverProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(theme, name, email),
            const SizedBox(height: 24),

            // Stats Cards
            _buildStatsCards(theme, totalPatients, yearsOfExperience),
            const SizedBox(height: 24),

            // Personal Information
            _buildSectionTitle('Personal Information', theme),
            const SizedBox(height: 12),
            _buildInfoCard(
              theme: theme,
              items: [
                _InfoItem(Icons.person_rounded, 'Full Name', name),
                _InfoItem(Icons.email_rounded, 'Email', email),
                _InfoItem(Icons.phone_rounded, 'Phone', phone),
                _InfoItem(Icons.medical_services_rounded, 'Specialization', specialization),
              ],
            ),
            const SizedBox(height: 24),

            // Professional Info
            _buildSectionTitle('Professional Details', theme),
            const SizedBox(height: 12),
            _buildInfoCard(
              theme: theme,
              items: [
                _InfoItem(Icons.work_rounded, 'Experience', '$yearsOfExperience years'),
                _InfoItem(Icons.people_rounded, 'Total Patients', '$totalPatients'),
                _InfoItem(Icons.shield_rounded, '2FA Enabled', has2FA ? 'Yes' : 'No'),
              ],
            ),
            const SizedBox(height: 24),

            // Bio
            if (bio.isNotEmpty && bio != 'No bio available') ...[
              _buildSectionTitle('About', theme),
              const SizedBox(height: 12),
              _buildBioCard(theme, bio),
              const SizedBox(height: 24),
            ],

            // Account Info
            if (createdAt != null) ...[
              _buildSectionTitle('Account Information', theme),
              const SizedBox(height: 12),
              _buildInfoCard(
                theme: theme,
                items: [
                  _InfoItem(
                    Icons.calendar_today_rounded,
                    'Member Since',
                    _formatDate(createdAt),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Edit Profile Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to edit profile
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit profile coming soon')),
                  );
                },
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, String name, String email) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withOpacity(0.1),
            theme.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: theme.primaryColor,
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(ThemeData theme, int totalPatients, int yearsOfExperience) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme: theme,
            icon: Icons.people_rounded,
            label: 'Patients',
            value: '$totalPatients',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme: theme,
            icon: Icons.work_rounded,
            label: 'Experience',
            value: '$yearsOfExperience yrs',
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required ThemeData theme,
    required List<_InfoItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item.icon,
                        size: 20,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.value,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: theme.dividerColor.withOpacity(0.1),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBioCard(ThemeData theme, String bio) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        bio,
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  _InfoItem(this.icon, this.label, this.value);
}
