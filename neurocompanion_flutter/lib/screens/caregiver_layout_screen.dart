import 'package:flutter/material.dart';
import 'package:neurocompanion_flutter/screens/caregiver_dashboard_screen.dart';
import 'package:neurocompanion_flutter/screens/caregiver_patient_list_screen.dart';
import 'package:neurocompanion_flutter/screens/caregiver_unified_settings_screen.dart';
import 'package:neurocompanion_flutter/services/token_store.dart';
import 'package:neurocompanion_flutter/services/caregiver_service.dart';
import 'package:neurocompanion_flutter/services/api_client.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/widgets/theme_toggle_button.dart';
import 'package:neurocompanion_flutter/screens/login_screen.dart';

class CaregiverLayoutScreen extends StatefulWidget {
  final int initialIndex;

  const CaregiverLayoutScreen({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<CaregiverLayoutScreen> createState() => _CaregiverLayoutScreenState();
}

class _CaregiverLayoutScreenState extends State<CaregiverLayoutScreen> {
  late int _currentIndex;
  late PageController _pageController;
  bool _isDropdownOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Map<String, dynamic>? _caregiverProfile;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadCaregiverProfile();
  }

  Future<void> _loadCaregiverProfile() async {
    try {
      final caregiverService = context.read<CaregiverService>();
      final profile = await caregiverService.getProfile();
      if (mounted) {
        setState(() {
          _caregiverProfile = profile['caregiver'] as Map<String, dynamic>?;
        });
      }
    } catch (e) {
      print('Error loading caregiver profile: $e');
      if (mounted) {
        setState(() {
          // Profile loading failed, continue with default values
        });
      }
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
    setState(() {
      _isDropdownOpen = !_isDropdownOpen;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () {
          _toggleDropdown();
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              right: 16,
              top: offset.dy + 70,
              child: Material(
                color: Colors.transparent,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 200),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      alignment: Alignment.topRight,
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: _buildDropdownMenu(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    _removeOverlay();
    setState(() {
      _isDropdownOpen = false;
    });

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SharedPrefsTokenStore().clearToken();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _navigateToProfile() {
    _removeOverlay();
    setState(() {
      _isDropdownOpen = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CaregiverUnifiedSettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final screens = [
      const CaregiverDashboardScreen(showNavigationBar: false),
      const CaregiverPatientListScreen(),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header with Greeting and Profile Dropdown
            _buildHeader(theme),
            // Page Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const NeverScrollableScrollPhysics(),
                children: screens,
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar (fixed to bottom)
      bottomNavigationBar: _buildBottomNavigation(theme),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    // greeting and emoji removed as they're not currently used in the UI

    // Extract first name and initial for avatar
    String initial = 'C';
    
    if (_caregiverProfile != null) {
      final fullName = _caregiverProfile!['name'] as String? ?? 'Caregiver';
      initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'C';
    }

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.card,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo and Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.shield_rounded,
                      color: theme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NeuroCompanion',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.text,
                        ),
                      ),
                      Text(
                        'Caregiver Portal',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.text.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Theme Toggler
              const ThemeToggleButton(),
              const SizedBox(width: 8),
              // User Profile Dropdown
              CompositedTransformTarget(
                link: _layerLink,
                child: InkWell(
                  onTap: _toggleDropdown,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isDropdownOpen
                          ? theme.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: theme.background,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: theme.border,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildDropdownMenu() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;
        
        String caregiverName = 'Caregiver';
        String caregiverEmail = '';
        
        if (_caregiverProfile != null) {
          caregiverName = _caregiverProfile!['name'] as String? ?? 'Caregiver';
          caregiverEmail = _caregiverProfile!['email'] as String? ?? '';
        }

        return Container(
          width: 220,
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // User Info Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.border.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caregiverName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      caregiverEmail,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.text.withOpacity(0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Menu Items
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.person_rounded,
                      label: 'Profile & Settings',
                      onTap: _navigateToProfile,
                      theme: theme,
                    ),
                    const SizedBox(height: 4),
                    Divider(
                      height: 1,
                      color: theme.border.withOpacity(0.5),
                    ),
                    const SizedBox(height: 4),
                    _buildMenuItem(
                      icon: Icons.logout_rounded,
                      label: 'Sign Out',
                      onTap: _handleLogout,
                      theme: theme,
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required AppTheme theme,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive ? Colors.red : theme.text,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDestructive ? Colors.red : theme.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(ThemeData theme) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;
        
        return Container(
          decoration: BoxDecoration(
            color: theme.card,
            border: Border(
              top: BorderSide(
                color: theme.border.withOpacity(0.5),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    index: 0,
                    theme: theme,
                  ),
                  _buildNavItem(
                    icon: Icons.people_rounded,
                    label: 'Patients',
                    index: 1,
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required AppTheme theme,
  }) {
    final isActive = _currentIndex == index;
    final primaryColor = theme.primary;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: isActive ? primaryColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isActive ? primaryColor : theme.text.withOpacity(0.6),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? primaryColor : theme.text.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
