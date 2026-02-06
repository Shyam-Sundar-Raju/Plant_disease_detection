import 'package:flutter/material.dart';

import '../../services/auth_api.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  static const String routeName = '/forgot-password';

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _api = AuthApi();

  bool _isLoading = false;
  bool _showResetForm = false;
  String? _resetToken;
  String? _message;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _message = null;
    });

    try {
      final result = await _api.forgotPassword(
        username: _usernameController.text.trim(),
      );

      final message =
          result['message']?.toString() ??
          'If the account exists, a reset code will be sent.';

      if (!mounted) {
        return;
      }

      setState(() {
        _message = message;
        _resetToken = result['reset_token']?.toString();
        _showResetForm = true;
      });
    } catch (error) {
      setState(() {
        _errorMessage = _friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitReset() async {
    if (!_resetFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_resetToken == null || _resetToken!.isEmpty) {
        throw Exception('Reset token is missing.');
      }

      final result = await _api.resetPassword(
        token: _resetToken!,
        otp: _otpController.text.trim(),
        newPassword: _newPasswordController.text,
      );

      final message =
          result['message']?.toString() ??
          'Password reset successful. You can log in now.';

      if (!mounted) {
        return;
      }

      setState(() {
        _message = message;
      });
    } catch (error) {
      setState(() {
        _errorMessage = _friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    return message.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Reset password')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F1EA), Color(0xFFE7F0E8)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.12),
                          child: Icon(
                            Icons.lock_reset,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Forgot your password?',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              'We will send a reset code',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Email or phone',
                                ),
                                textInputAction: TextInputAction.done,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Email or phone is required.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              if (_errorMessage != null)
                                Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              if (_message != null)
                                Text(
                                  _message!,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Send reset code'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_showResetForm) ...[
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _resetFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Enter the OTP sent to your email.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _otpController,
                                  decoration: const InputDecoration(
                                    labelText: 'OTP',
                                  ),
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'OTP is required.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _newPasswordController,
                                  decoration: const InputDecoration(
                                    labelText: 'New password',
                                  ),
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'New password is required.';
                                    }
                                    if (value.length < 8) {
                                      return 'Password must be at least 8 characters.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _submitReset,
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Reset password'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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
