import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _AuthMethod { email, phone }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const String _redirectUrl = 'io.supabase.flutter://login-callback/';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  _AuthMethod _method = _AuthMethod.email;
  bool _isEmailSignUp = false;
  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _error;

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (!mounted) {
        return;
      }
      if (event.session != null) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<_AuthMethod>(
                segments: const [
                  ButtonSegment(
                    value: _AuthMethod.email,
                    label: Text('Email'),
                    icon: Icon(Icons.email_outlined),
                  ),
                  ButtonSegment(
                    value: _AuthMethod.phone,
                    label: Text('Phone'),
                    icon: Icon(Icons.phone_outlined),
                  ),
                ],
                selected: {_method},
                onSelectionChanged: (selection) {
                  setState(() {
                    _method = selection.first;
                    _error = null;
                  });
                },
              ),
              const Gap(16),
              if (_method == _AuthMethod.email) _buildEmailForm(context),
              if (_method == _AuthMethod.phone) _buildPhoneForm(context),
              const Gap(20),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const Gap(16),
              const Divider(),
              const Gap(12),
              Text(
                'Or continue with',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Gap(12),
              ElevatedButton.icon(
                onPressed:
                    _isLoading ? null : () => _signInWithOAuth(OAuthProvider.google),
                icon: const Icon(Icons.g_mobiledata),
                label: const Text('Continue with Google'),
              ),
              const Gap(8),
              if (defaultTargetPlatform == TargetPlatform.iOS)
                ElevatedButton.icon(
                  onPressed:
                      _isLoading ? null : () => _signInWithOAuth(OAuthProvider.apple),
                  icon: const Icon(Icons.apple),
                  label: const Text('Continue with Apple'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        const Gap(12),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
          autofillHints: const [AutofillHints.password],
        ),
        if (_isEmailSignUp) ...[
          const Gap(12),
          TextField(
            controller: _confirmController,
            decoration: const InputDecoration(
              labelText: 'Confirm password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            autofillHints: const [AutofillHints.password],
          ),
        ],
        const Gap(12),
        FilledButton(
          onPressed: _isLoading ? null : _handleEmailAuth,
          child: Text(_isEmailSignUp ? 'Create account' : 'Sign in'),
        ),
        const Gap(8),
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  setState(() {
                    _isEmailSignUp = !_isEmailSignUp;
                    _error = null;
                  });
                },
          child: Text(
            _isEmailSignUp
                ? 'Already have an account? Sign in'
                : 'Need an account? Sign up',
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone number',
            hintText: '+1 555 123 4567',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
        ),
        const Gap(12),
        if (_isOtpSent)
          TextField(
            controller: _otpController,
            decoration: const InputDecoration(
              labelText: 'Verification code',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        const Gap(12),
        FilledButton(
          onPressed: _isLoading ? null : (_isOtpSent ? _verifyOtp : _sendOtp),
          child: Text(_isOtpSent ? 'Verify code' : 'Send code'),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  setState(() {
                    _isOtpSent = false;
                    _otpController.clear();
                    _error = null;
                  });
                },
          child: const Text('Use a different phone'),
        ),
      ],
    );
  }

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (email.isEmpty || password.isEmpty) {
      _setError('Email and password are required.');
      return;
    }
    if (_isEmailSignUp && password != confirm) {
      _setError('Passwords do not match.');
      return;
    }

    await _runAuthAction(() async {
      final auth = Supabase.instance.client.auth;
      if (_isEmailSignUp) {
        await auth.signUp(email: email, password: password);
        _setError('Check your email to confirm your account.');
      } else {
        await auth.signInWithPassword(email: email, password: password);
      }
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _setError('Phone number is required.');
      return;
    }

    await _runAuthAction(() async {
      await Supabase.instance.client.auth.signInWithOtp(phone: phone);
      setState(() {
        _isOtpSent = true;
      });
    });
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneController.text.trim();
    final token = _otpController.text.trim();
    if (phone.isEmpty || token.isEmpty) {
      _setError('Enter the phone number and verification code.');
      return;
    }

    await _runAuthAction(() async {
      await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.sms,
        token: token,
        phone: phone,
      );
    });
  }

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    await _runAuthAction(() async {
      await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: _redirectUrl,
      );
    });
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await action();
    } catch (error) {
      _setError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setError(String message) {
    setState(() {
      _error = message;
    });
  }
}
