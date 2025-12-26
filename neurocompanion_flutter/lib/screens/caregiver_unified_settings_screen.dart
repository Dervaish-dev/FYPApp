import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/services/caregiver_service.dart';
import 'package:neurocompanion_flutter/services/api_client.dart';

class CaregiverUnifiedSettingsScreen extends StatefulWidget {
  const CaregiverUnifiedSettingsScreen({super.key});

  @override
  State<CaregiverUnifiedSettingsScreen> createState() => _CaregiverUnifiedSettingsScreenState();
}

class _CaregiverUnifiedSettingsScreenState extends State<CaregiverUnifiedSettingsScreen> {
  late CaregiverService _caregiverService;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String? _success;

  // Profile fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _specializationController = TextEditingController();
  final _organizationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  bool _twoFactorEnabled = false;

  @override
  void initState() {
    super.initState();
    _caregiverService = CaregiverService(apiClient: context.read<ApiClient>());
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _specializationController.dispose();
    _organizationController.dispose();
    _phoneController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _caregiverService.getProfile();
      final caregiver = response['caregiver'] as Map<String, dynamic>?;

      if (mounted && caregiver != null) {
        setState(() {
          _nameController.text = caregiver['name'] ?? '';
          _emailController.text = caregiver['email'] ?? '';
          _specializationController.text = caregiver['specialization'] ?? '';
          _organizationController.text = caregiver['organization'] ?? '';
          _phoneController.text = caregiver['phone'] ?? '';
          _licenseNumberController.text = caregiver['licenseNumber'] ?? '';
          _twoFactorEnabled = caregiver['twoFactorEnabled'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    try {
      setState(() {
        _isSaving = true;
        _error = null;
        _success = null;
      });

      final payload = {
        'name': _nameController.text,
        'specialization': _specializationController.text,
        'organization': _organizationController.text,
        'phone': _phoneController.text,
        'licenseNumber': _licenseNumberController.text,
      };

      await _caregiverService.updateProfile(payload);

      if (mounted) {
        setState(() {
          _success = 'Profile updated successfully';
          _isSaving = false;
        });

        // Clear success message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _success = null;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to update profile';
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _toggle2FA() async {
    try {
      setState(() {
        _error = null;
        _success = null;
      });

      final response = await _caregiverService.toggle2FA();

      if (mounted && response['success'] == true) {
        setState(() {
          _twoFactorEnabled = response['twoFactorEnabled'] ?? false;
          _success = 'Two-factor authentication ${_twoFactorEnabled ? "enabled" : "disabled"}';
        });

        // Clear success message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _success = null;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to toggle 2FA';
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
          appBar: AppBar(
            title: const Text('Profile & Settings'),
            centerTitle: true,
            elevation: 0,
            backgroundColor: theme.background,
            iconTheme: IconThemeData(color: theme.text),
          ),
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: theme.primary),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  color: theme.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text(
                          'Caregiver Profile',
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Update your profile and security preferences',
                          style: TextStyle(
                            color: theme.text.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Error/Success Message
                        if (_error != null || _success != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: _error != null
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _error != null
                                    ? Colors.red.withOpacity(0.3)
                                    : Colors.green.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _error != null
                                      ? Icons.error_outline
                                      : Icons.check_circle_outline,
                                  color: _error != null ? Colors.red : Colors.green,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _error ?? _success ?? '',
                                    style: TextStyle(color: theme.text),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Profile Form
                        _buildProfileSection(theme),
                        const SizedBox(height: 24),

                        // Security Section
                        _buildSecuritySection(theme),
                        const SizedBox(height: 24),

                        // Privacy & Compliance Section
                        _buildPrivacySection(theme),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildProfileSection(AppTheme theme) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile Information',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveProfile,
                icon: Icon(
                  _isSaving ? Icons.hourglass_empty : Icons.save,
                  size: 18,
                ),
                label: Text(_isSaving ? 'Saving...' : 'Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Full Name
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Dr. Jane Smith',
            icon: Icons.person,
            theme: theme,
          ),
          const SizedBox(height: 16),

          // Email (read-only)
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'email@example.com',
            icon: Icons.email,
            theme: theme,
            readOnly: true,
            opacity: 0.6,
          ),
          const SizedBox(height: 16),

          // Specialization
          _buildTextField(
            controller: _specializationController,
            label: 'Specialization',
            hint: 'Therapist, Psychiatrist, etc.',
            icon: Icons.medical_services,
            theme: theme,
          ),
          const SizedBox(height: 16),

          // Organization
          _buildTextField(
            controller: _organizationController,
            label: 'Organization',
            hint: 'Clinic / Hospital',
            icon: Icons.business,
            theme: theme,
          ),
          const SizedBox(height: 16),

          // Phone
          _buildTextField(
            controller: _phoneController,
            label: 'Phone',
            hint: '+1 555 123 4567',
            icon: Icons.phone,
            theme: theme,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          // License Number
          _buildTextField(
            controller: _licenseNumberController,
            label: 'License Number',
            hint: 'Optional',
            icon: Icons.badge,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security',
            style: TextStyle(
              color: theme.text,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // 2FA Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.shield,
                    color: theme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Two-Factor Authentication',
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add an extra layer of security',
                        style: TextStyle(
                          color: theme.text.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _twoFactorEnabled,
                  onChanged: (value) => _toggle2FA(),
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection(AppTheme theme) {
    return Container(
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Privacy & Compliance',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HIPAA Compliance',
                            style: TextStyle(
                              color: theme.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This system maintains full audit trails required for HIPAA compliance. Never share patient data outside this system.',
                            style: TextStyle(
                              color: theme.text.withOpacity(0.7),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data Security',
                            style: TextStyle(
                              color: theme.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Patient information is encrypted and access is logged with IP addresses and timestamps for security.',
                            style: TextStyle(
                              color: theme.text.withOpacity(0.7),
                              fontSize: 13,
                              height: 1.4,
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
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required AppTheme theme,
    bool readOnly = false,
    double opacity = 1.0,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.text.withOpacity(0.9),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.border),
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            style: TextStyle(
              color: theme.text.withOpacity(opacity),
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: theme.text.withOpacity(0.4),
                fontSize: 15,
              ),
              prefixIcon: Icon(
                icon,
                color: theme.text.withOpacity(0.5),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
