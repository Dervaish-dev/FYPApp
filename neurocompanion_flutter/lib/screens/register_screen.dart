import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/bloc/bloc.dart';
import 'package:neurocompanion_flutter/bloc/blocs.dart';
import 'package:neurocompanion_flutter/screens/login_screen.dart';
import 'package:neurocompanion_flutter/screens/onboarding_screen.dart';
import 'package:neurocompanion_flutter/services/api_exceptions.dart';
import 'package:neurocompanion_flutter/services/invite_service.dart';
import 'package:neurocompanion_flutter/services/services.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 0;
  String? _maskedEmail;
  String? _claimToken;

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;

    final inviteService = context.read<InviteService>();
    final authService = context.read<AuthService>();

    setState(() {
      _isLoading = true;
    });

    try {
      if (_step == 0) {
        final result = await inviteService.lookupCode(_codeController.text);
        setState(() {
          _maskedEmail = result.maskedEmail;
          _step = 1;
        });
      } else if (_step == 1) {
        final result = await inviteService.sendOtp(
          code: _codeController.text,
          email: _emailController.text,
        );
        setState(() {
          _maskedEmail = result.maskedEmail;
          _step = 2;
        });
      } else if (_step == 2) {
        final result = await inviteService.verifyOtp(
          code: _codeController.text,
          email: _emailController.text,
          otp: _otpController.text,
        );
        if (result.claimToken.isEmpty) {
          throw const ApiException(message: 'Missing claim token');
        }
        setState(() {
          _claimToken = result.claimToken;
          _step = 3;
        });
      } else if (_step == 3) {
        final user = await authService.finalizeInviteSignup(
          claimToken: _claimToken ?? '',
          password: _passwordController.text,
        );

        if (!mounted) return;
        context.read<AuthBloc>().add(AuthStatusChanged(user: user));

        // Navigate to onboarding flow
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      final retryAfter = (e.details is Map && (e.details as Map).containsKey('retryAfterSeconds'))
          ? (e.details as Map)['retryAfterSeconds']
          : null;
      final extra = retryAfter != null ? ' (try again in ${retryAfter}s)' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${e.message}$extra'), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _primaryButtonText() {
    switch (_step) {
      case 0:
        return 'Verify Invite Code';
      case 1:
        return 'Send OTP';
      case 2:
        return 'Verify OTP';
      case 3:
        return 'Create Account';
      default:
        return 'Continue';
    }
  }

  String _stepTitle() {
    switch (_step) {
      case 0:
        return 'Enter Invite Code';
      case 1:
        return 'Confirm Email';
      case 2:
        return 'Enter OTP';
      case 3:
        return 'Set Password';
      default:
        return 'Join';
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
                      const SizedBox(height: 40),

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
                        'Join NeuroCompanion',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: theme.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Invite-only signup. Use your caregiver code.',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.text.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_maskedEmail != null && _maskedEmail!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Invite email: $_maskedEmail',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.text.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 40),

                      // Registration Form
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _stepTitle(),
                                  style: TextStyle(
                                    color: theme.text,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              if (_step == 0) ...[
                                TextFormField(
                                  controller: _codeController,
                                  textInputAction: TextInputAction.done,
                                  style: TextStyle(color: theme.text),
                                  decoration: InputDecoration(
                                    labelText: 'Invite Code',
                                    hintText: 'e.g. ABC123',
                                    prefixIcon: Icon(
                                      Icons.vpn_key_outlined,
                                      color: theme.text.withOpacity(0.7),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Invite code is required';
                                    }
                                    return null;
                                  },
                                ),
                              ],

                              if (_step == 1) ...[
                                TextFormField(
                                  controller: _codeController,
                                  enabled: false,
                                  style: TextStyle(color: theme.text),
                                  decoration: InputDecoration(
                                    labelText: 'Invite Code',
                                    prefixIcon: Icon(
                                      Icons.vpn_key_outlined,
                                      color: theme.text.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
                                  style: TextStyle(color: theme.text),
                                  decoration: InputDecoration(
                                    labelText: 'Email Address',
                                    hintText: 'Must match invite email',
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: theme.text.withOpacity(0.7),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Email is required';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                              ],

                              if (_step == 2) ...[
                                TextFormField(
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  style: TextStyle(color: theme.text),
                                  decoration: InputDecoration(
                                    labelText: 'OTP Code',
                                    hintText: 'Enter the code sent to your email',
                                    prefixIcon: Icon(
                                      Icons.verified_outlined,
                                      color: theme.text.withOpacity(0.7),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'OTP is required';
                                    }
                                    return null;
                                  },
                                ),
                              ],

                              if (_step == 3) ...[
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.next,
                                  style: TextStyle(color: theme.text),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: 'At least 8 chars, letters + numbers',
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
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    final v = value ?? '';
                                    if (v.isEmpty) return 'Password is required';
                                    if (v.length < 8) {
                                      return 'Password must be at least 8 characters';
                                    }
                                    if (!RegExp(r'[a-z]').hasMatch(v)) {
                                      return 'Must contain at least one lowercase letter';
                                    }
                                    if (!RegExp(r'[A-Z]').hasMatch(v)) {
                                      return 'Must contain at least one uppercase letter';
                                    }
                                    if (!RegExp(r'[0-9]').hasMatch(v)) {
                                      return 'Must contain at least one number';
                                    }
                                    if (!RegExp(r'[!@#$%^&*()_+=\[\]{};:,.<>?/|\\-]').hasMatch(v)) {
                                      return 'Must contain at least one special character';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _next(),
                                  style: TextStyle(color: theme.text),
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    hintText: 'Re-enter your password',
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: theme.text.withOpacity(0.7),
                                    ),
                                  ),
                                  validator: (value) {
                                    if ((value ?? '') != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                              const SizedBox(height: 24),

                              // Register Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _next,
                                  child: _isLoading
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
                                            Text('Please wait...'),
                                          ],
                                        )
                                      : Text(_primaryButtonText()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign In Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
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
                              'Sign in',
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
