import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/services/api_client.dart';
import 'package:neurocompanion_flutter/services/api_config.dart';
import 'package:neurocompanion_flutter/services/token_store.dart';
import 'package:neurocompanion_flutter/screens/caregiver_layout_screen.dart';
import 'package:neurocompanion_flutter/screens/login_screen.dart';

class CaregiverLoginScreen extends StatefulWidget {
  const CaregiverLoginScreen({super.key});

  @override
  State<CaregiverLoginScreen> createState() => _CaregiverLoginScreenState();
}

class _CaregiverLoginScreenState extends State<CaregiverLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _showOTP = false;
  bool _obscurePassword = true;
  bool _isRegistering = false;
  String? _errorMessage;
  String? _userEmail;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ApiClient(
        baseUrl: ApiConfig.baseUrl,
        tokenStore: SharedPrefsTokenStore(),
      );

      print('🔐 [CAREGIVER LOGIN] Login attempt for: ${_emailController.text.trim()}');
      
      final response = await apiClient.post('/caregiver/login', body: {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      }, authenticated: false);

      print('✅ [CAREGIVER LOGIN] Login response received');

      if (response['success'] == true) {
        // Check if 2FA or OTP is required
        if (response['requires2FA'] == true || response['requiresOTP'] == true) {
          setState(() {
            _showOTP = true;
            _userEmail = _emailController.text.trim();
            _isLoading = false;
          });
          print('🔐 [CAREGIVER LOGIN] OTP required');
          return;
        }

        // Store caregiver token
        final token = response['token'] as String?;
        if (token != null) {
          await SharedPrefsTokenStore().writeToken(token);
          print('✅ [CAREGIVER LOGIN] Token stored');
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const CaregiverLayoutScreen(),
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('❌ [CAREGIVER LOGIN] Error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('Invalid credentials')
              ? 'Invalid email or password'
              : 'Login failed. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ApiClient(
        baseUrl: ApiConfig.baseUrl,
        tokenStore: SharedPrefsTokenStore(),
      );

      print('📝 [CAREGIVER REGISTER] Registration attempt for: ${_emailController.text.trim()}');
      
      final response = await apiClient.post('/caregiver/register', body: {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'phone': _phoneController.text.trim(),
      }, authenticated: false);

      print('✅ [CAREGIVER REGISTER] Registration response received');

      if (response['success'] == true) {
        // Check if OTP verification is required
        if (response['requiresOTP'] == true) {
          setState(() {
            _showOTP = true;
            _userEmail = _emailController.text.trim();
            _isLoading = false;
          });
          print('📧 [CAREGIVER REGISTER] OTP sent to email');
          return;
        }

        // Store caregiver token if no OTP required
        final token = response['token'] as String?;
        if (token != null) {
          await SharedPrefsTokenStore().writeToken(token);
          print('✅ [CAREGIVER REGISTER] Token stored');
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const CaregiverLayoutScreen(),
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Registration failed');
      }
    } catch (e) {
      print('❌ [CAREGIVER REGISTER] Error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Registration failed. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter the verification code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ApiClient(
        baseUrl: ApiConfig.baseUrl,
        tokenStore: SharedPrefsTokenStore(),
      );

      print('🔐 [CAREGIVER] Verifying OTP code');
      
      final response = await apiClient.post('/caregiver/verify-otp', body: {
        'email': _userEmail,
        'otp': _otpController.text.trim(),
      }, authenticated: false);

      print('✅ [CAREGIVER] OTP verified successfully');

      if (response['success'] == true) {
        // Store caregiver token
        final token = response['token'] as String?;
        if (token != null) {
          await SharedPrefsTokenStore().writeToken(token);
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const CaregiverLayoutScreen(),
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Verification failed');
      }
    } catch (e) {
      print('❌ [CAREGIVER LOGIN] Error verifying 2FA: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Invalid verification code. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ApiClient(
        baseUrl: ApiConfig.baseUrl,
        tokenStore: SharedPrefsTokenStore(),
      );

      final response = await apiClient.post('/caregiver/resend-otp', body: {
        'email': _userEmail,
      }, authenticated: false);

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'New OTP sent to your email!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to resend OTP');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to resend OTP. Please try again.';
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
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
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),

                      // Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [theme.primary, theme.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.people,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        'Caregiver Portal',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: theme.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _showOTP
                            ? 'Enter the verification code sent to your email'
                            : 'Sign in to access patient information',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.text.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // Login Form
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.border),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primary.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _showOTP ? _buildOTPForm(theme) : _buildLoginForm(theme),
                      ),
                      const SizedBox(height: 24),

                      // Back to Patient Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Not a caregiver? ",
                            style: TextStyle(
                              color: theme.text.withOpacity(0.7),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Patient Login',
                              style: TextStyle(
                                color: theme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Footer
                      Text(
                        '© 2024 NeuroCompanion. Secure caregiver access portal.',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.text.withOpacity(0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginForm(AppTheme theme) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Name Field (only for registration)
          if (_isRegistering) ...[
            TextFormField(
              controller: _nameController,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              style: TextStyle(color: theme.text),
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: theme.text.withOpacity(0.7),
                ),
              ),
              validator: (value) {
                if (_isRegistering && (value == null || value.isEmpty)) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: TextStyle(color: theme.text),
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter your caregiver email',
              prefixIcon: Icon(
                Icons.email_outlined,
                color: theme.text.withOpacity(0.7),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: _isRegistering ? TextInputAction.next : TextInputAction.done,
            onFieldSubmitted: (_) => _isRegistering ? null : _handleLogin(),
            style: TextStyle(color: theme.text),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: Icon(
                Icons.lock_outlined,
                color: theme.text.withOpacity(0.7),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: theme.text.withOpacity(0.7),
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Phone Field (only for registration)
          if (_isRegistering) ...[
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleRegister(),
              style: TextStyle(color: theme.text),
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: '+1 234 567 8900',
                prefixIcon: Icon(
                  Icons.phone_outlined,
                  color: theme.text.withOpacity(0.7),
                ),
              ),
              validator: (value) {
                if (_isRegistering && (value == null || value.isEmpty)) {
                  return 'Phone number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Login/Register Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : (_isRegistering ? _handleRegister : _handleLogin),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(_isRegistering ? 'Creating Account...' : 'Signing in...'),
                      ],
                    )
                  : Text(_isRegistering ? 'Create Account' : 'Sign In'),
            ),
          ),
          const SizedBox(height: 16),

          // Toggle between Login and Register
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isRegistering ? 'Already have an account? ' : "Don't have an account? ",
                style: TextStyle(
                  color: theme.text.withOpacity(0.7),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isRegistering = !_isRegistering;
                    _errorMessage = null;
                    _nameController.clear();
                    _phoneController.clear();
                  });
                },
                child: Text(
                  _isRegistering ? 'Sign In' : 'Sign Up',
                  style: TextStyle(
                    color: theme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOTPForm(AppTheme theme) {
    return Form(
      child: Column(
        children: [
          Text(
            'We sent a 6-digit verification code to your email.',
            style: TextStyle(
              color: theme.text.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // OTP Field
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _verifyOTP(),
            style: TextStyle(color: theme.text),
            decoration: InputDecoration(
              labelText: 'Verification Code',
              hintText: 'Enter 6-digit code',
              prefixIcon: Icon(
                Icons.lock_outlined,
                color: theme.text.withOpacity(0.7),
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Verify Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Verifying...'),
                      ],
                    )
                  : const Text('Verify Code'),
            ),
          ),
          const SizedBox(height: 16),

          // Resend OTP Button
          TextButton(
            onPressed: _isLoading ? null : _resendOTP,
            child: Text(
              'Resend Code',
              style: TextStyle(
                color: theme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Back Button
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() {
                      _showOTP = false;
                      _errorMessage = null;
                      _otpController.clear();
                    });
                  },
            child: Text(
              'Back to Login',
              style: TextStyle(
                color: theme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
