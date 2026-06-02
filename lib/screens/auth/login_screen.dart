import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String _errorMessage = '';
  String _successMessage = '';

  void _toggleMode() {
    setState(() {
      isLogin = !isLogin;
      _errorMessage = '';
      _successMessage = '';
    });
  }

  void _showMessage(String text, bool isError) {
    setState(() {
      if (isError) {
        _errorMessage = text;
        _successMessage = '';
      } else {
        _errorMessage = '';
        _successMessage = text;
      }
    });
    // Hide message after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _errorMessage = '';
          _successMessage = '';
        });
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (isLogin) {
        await authService.login(email, password);
        
        if (!authService.isEmailVerified) {
          _showMessage("Please verify your email before continuing. Check your inbox.", true);
          return;
        }

        _showMessage('Login successful!', false);
      } else {
        final name = _nameController.text.trim();
        final confirm = _confirmController.text;

        if (password != confirm) {
          _showMessage("Passwords do not match.", true);
          return;
        }

        await authService.signUp(name, email, password);
        _showMessage('Account created! Please verify your email before logging in.', false);
        _toggleMode(); // Switch back to login
      }
    } on FirebaseAuthException catch (error) {
      String msg = error.message ?? "An error occurred";
      if (error.code == 'email-already-in-use') {
        msg = 'Email already in use. Please login instead.';
      } else if (error.code == 'invalid-email') {
        msg = 'Please enter a valid email address.';
      } else if (error.code == 'weak-password') {
        msg = 'Password should be at least 6 characters.';
      } else if (error.code == 'user-not-found') {
        msg = 'No account found with this email. Please sign up.';
      } else if (error.code == 'wrong-password') {
        msg = 'Incorrect password. Please try again.';
      }
      _showMessage(msg, true);
    } catch (e) {
      _showMessage(e.toString(), true);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage("Please enter your email above to reset your password.", true);
      return;
    }

    final authService = context.read<AuthService>();
    try {
      await authService.sendPasswordReset(email);
      _showMessage("Password reset link sent. Check your inbox.", false);
    } catch (e) {
      _showMessage("Failed to send password reset email. Try again.", true);
    }
  }

  Future<void> _resendVerification() async {
    final authService = context.read<AuthService>();
    try {
      await authService.resendVerificationEmail();
      _showMessage("Verification email sent. Check your inbox.", false);
    } catch (e) {
      _showMessage("Failed to resend verification email.", true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.glass,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'TaskMate',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your premium productivity companion',
                      style: TextStyle(
                        color: AppTheme.grayLight,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withValues(alpha: 0.2),
                          border: Border.all(color: AppTheme.danger),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppTheme.dangerLight),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMessage, style: const TextStyle(color: AppTheme.dangerLight))),
                          ],
                        ),
                      ),
                    
                    if (_successMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withValues(alpha: 0.2),
                          border: Border.all(color: AppTheme.secondary),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: AppTheme.secondaryLight),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_successMessage, style: const TextStyle(color: AppTheme.secondaryLight))),
                          ],
                        ),
                      ),

                    if (!isLogin)
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_outline, color: AppTheme.gray),
                          hintText: 'Full Name',
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                    if (!isLogin) const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined, color: AppTheme.gray),
                        hintText: 'Email',
                      ),
                      validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: !isPasswordVisible,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.gray),
                        hintText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: AppTheme.gray),
                          onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                        ),
                      ),
                      validator: (value) => value == null || value.length < 6 ? 'Min 6 characters' : null,
                    ),
                    const SizedBox(height: 16),

                    if (!isLogin)
                      TextFormField(
                        controller: _confirmController,
                        obscureText: !isConfirmPasswordVisible,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.gray),
                          hintText: 'Confirm Password',
                          suffixIcon: IconButton(
                            icon: Icon(isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off, color: AppTheme.gray),
                            onPressed: () => setState(() => isConfirmPasswordVisible = !isConfirmPasswordVisible),
                          ),
                        ),
                        validator: (value) => value == null || value.length < 6 ? 'Min 6 characters' : null,
                      ),
                    
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: Text(isLogin ? 'Login' : 'Sign Up'),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLogin ? "Don't have an account?" : "Already have an account?",
                          style: const TextStyle(color: AppTheme.grayLight),
                        ),
                        TextButton(
                          onPressed: _toggleMode,
                          child: Text(
                            isLogin ? 'Sign Up' : 'Login',
                            style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    if (isLogin)
                      TextButton(
                        onPressed: _forgotPassword,
                        child: const Text('Forgot Password?', style: TextStyle(color: AppTheme.primaryLight)),
                      ),
                    
                    // Resend verification button is visible conditionally in logic, but here we provide it
                    if (isLogin && _errorMessage.contains('verify'))
                      TextButton(
                        onPressed: _resendVerification,
                        child: const Text('Resend Verification Email', style: TextStyle(color: AppTheme.primaryLight)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
