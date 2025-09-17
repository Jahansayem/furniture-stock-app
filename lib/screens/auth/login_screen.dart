import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1024;

    return Scaffold(
      body: Stack(
        children: [
          // Blue background with rounded bottom corners - responsive height
          Container(
            height: screenSize.height * (isDesktop ? 0.5 : isTablet ? 0.55 : 0.6),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF0958D9),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(60),
                bottomRight: Radius.circular(60),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 64 : isTablet ? 48 : screenSize.width * 0.08,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 80),

                      // Welcome Back Title - responsive font size
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: isDesktop ? 42 : isTablet ? 38 : 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                    // Email Label
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Email',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF8FAFC),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Email Field - responsive height
                    Container(
                      height: isDesktop ? 48 : isTablet ? 44 : 40.229,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00203D),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          color: const Color(0xFFF8FAFC),
                          fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Email',
                          hintStyle: TextStyle(
                            color: const Color(0xFFF8FAFC),
                            fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
                          ),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: Color(0xFFF8FAFC),
                            size: 16,
                          ),
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Password Label
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Password',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF8FAFC),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Password Field - responsive height
                    Container(
                      height: isDesktop ? 48 : isTablet ? 44 : 40.229,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00203D),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(
                          color: const Color(0xFFF8FAFC),
                          fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: TextStyle(
                            color: const Color(0xFFF8FAFC),
                            fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: Color(0xFFF8FAFC),
                            size: 16,
                          ),
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Sign In Button - responsive width and height
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final buttonWidth = isDesktop
                                ? 400.0
                                : isTablet
                                    ? 350.0
                                    : constraints.maxWidth * 0.85;
                            return Container(
                              width: buttonWidth,
                              height: isDesktop ? 52 : isTablet ? 48 : 46,
                              child: ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1677FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 0,
                            ),
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: isDesktop ? 18 : isTablet ? 17 : 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Forgot Login Detail
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Forgot Login Detail? ',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFADADAD),
                          ),
                        ),
                        GestureDetector(
                          onTap: _handleForgotPassword,
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0958D9),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Don't have account
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFADADAD),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/register'),
                          child: const Text(
                            'Now Sign Up',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0958D9),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Error Message
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        if (authProvider.errorMessage != null) {
                          return Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SelectableText(
                                    authProvider.errorMessage!,
                                    style: TextStyle(color: Colors.red[700]),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () => authProvider.clearError(),
                                  color: Colors.red[700],
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      context.go('/orders');
    }
  }

  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (context) => _ForgotPasswordDialog(),
    );
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset Password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SelectableText('Enter your email address to receive a password reset link.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return ElevatedButton(
              onPressed: authProvider.isLoading ? null : _handleResetPassword,
              child: authProvider.isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send Reset Link'),
            );
          },
        ),
      ],
    );
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resetPassword(_emailController.text.trim());

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent to your email'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

