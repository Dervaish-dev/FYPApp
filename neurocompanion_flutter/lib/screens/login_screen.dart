import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/bloc/bloc.dart';
import 'package:neurocompanion_flutter/bloc/blocs.dart';
import 'package:neurocompanion_flutter/screens/register_screen.dart';
import 'package:neurocompanion_flutter/screens/main_layout.dart';
import 'package:neurocompanion_flutter/screens/verify_2fa_screen.dart';
import 'package:neurocompanion_flutter/screens/forgot_password_screen.dart';
import 'package:neurocompanion_flutter/screens/caregiver_login_screen.dart';
import 'package:neurocompanion_flutter/screens/caregiver_layout_screen.dart';
import 'package:neurocompanion_flutter/services/api_client.dart';
import 'package:neurocompanion_flutter/services/token_store.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _userType = 'patient'; // 'patient' or 'caregiver'

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      print('🔐 [AUTH] Login attempt for: ${_emailController.text.trim()}');
      
      if (_userType == 'caregiver') {
        // Handle caregiver login inline
        _handleCaregiverLogin();
      } else {
        // Patient login
        context.read<AuthBloc>().add(
          LoginRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
      }
    }
  }

  Future<void> _handleCaregiverLogin() async {
    setState(() {
      // Show loading state
    });

    try {
      final apiClient = context.read<ApiClient>();
      
      print('🔐 [CAREGIVER LOGIN] Login attempt for: ${_emailController.text.trim()}');
      
      final response = await apiClient.post('/caregiver/login', body: {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      }, authenticated: false);

      print('✅ [CAREGIVER LOGIN] Login response received');

      if (response['success'] == true) {
        // Check if 2FA is required
        if (response['requires2FA'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('2FA for caregivers - Please use the full caregiver login screen'),
                backgroundColor: Colors.orange,
              ),
            );
            // Navigate to full caregiver login screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CaregiverLoginScreen(),
              ),
            );
          }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Invalid credentials')
                  ? 'Invalid email or password'
                  : 'Login failed. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
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
                          Icons.psychology,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: theme.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _userType == 'patient'
                            ? 'Sign in to your NeuroCompanion account'
                            : 'Sign in to support your patients',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.text.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // User Type Selector
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _userType = 'patient';
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _userType == 'patient'
                                        ? theme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        size: 20,
                                        color: _userType == 'patient'
                                            ? Colors.white
                                            : theme.text.withOpacity(0.6),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Patient',
                                        style: TextStyle(
                                          color: _userType == 'patient'
                                              ? Colors.white
                                              : theme.text.withOpacity(0.6),
                                          fontWeight: _userType == 'patient'
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _userType = 'caregiver';
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _userType == 'caregiver'
                                        ? theme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 20,
                                        color: _userType == 'caregiver'
                                            ? Colors.white
                                            : theme.text.withOpacity(0.6),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Caregiver',
                                        style: TextStyle(
                                          color: _userType == 'caregiver'
                                              ? Colors.white
                                              : theme.text.withOpacity(0.6),
                                          fontWeight: _userType == 'caregiver'
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login Form
                      BlocListener<AuthBloc, AuthState>(
                        listener: (context, state) {
                          if (state is AuthSuccess) {
                            print('✅ [AUTH] Login successful for: ${state.user.email}');
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MainLayout(),
                              ),
                            );
                          } else if (state is Auth2FARequired) {
                            print('🔐 [AUTH] 2FA required for user: ${state.userId}');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Verify2FAScreen(userId: state.userId),
                              ),
                            );
                          } else if (state is AuthFailure) {
                            print('❌ [AUTH] Login failed: ${state.message}');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(state.message),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: Container(
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
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Email Field
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  style: TextStyle(color: theme.text),
                                  decoration: InputDecoration(
                                    labelText: 'Email Address',
                                    hintText: 'Enter your email',
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: theme.text.withOpacity(0.7),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Email is required';
                                    }
                                    if (!RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value)) {
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
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleLogin(),
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
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: theme.text.withOpacity(0.7),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password is required';
                                    }
                                    if (value.length < 8) {
                                      return 'Password must be at least 8 characters';
                                    }
                                    if (!RegExp(r'[a-z]').hasMatch(value)) {
                                      return 'Must contain at least one lowercase letter';
                                    }
                                    if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                      return 'Must contain at least one uppercase letter';
                                    }
                                    if (!RegExp(r'[0-9]').hasMatch(value)) {
                                      return 'Must contain at least one number';
                                    }
                                    if (!RegExp(r'[!@#$%^&*()_+=\[\]{};:,.<>?/|\\-]').hasMatch(value)) {
                                      return 'Must contain at least one special character';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Forgot Password Link
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ForgotPasswordScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        color: theme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Login Button
                                BlocBuilder<AuthBloc, AuthState>(
                                  builder: (context, state) {
                                    return SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: state is AuthLoading
                                            ? null
                                            : _handleLogin,
                                        child: state is AuthLoading
                                            ? const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  ),
                                                  SizedBox(width: 12),
                                                  Text('Signing in...'),
                                                ],
                                              )
                                            : const Text('Sign In'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: theme.text.withOpacity(0.7),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (_userType == 'patient') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterScreen(),
                                  ),
                                );
                              } else {
                                // Navigate to caregiver registration
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Caregiver registration - Coming soon'),
                                    backgroundColor: theme.primary,
                                  ),
                                );
                              }
                            },
                            child: Text(
                              'Sign up',
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
                        '© 2024 NeuroCompanion. Your intelligent mental health companion.',
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
}
