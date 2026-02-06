import 'package:flutter/material.dart';

import '../../services/auth_api.dart';
import '../../services/token_storage.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';
import '../home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const String routeName = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _api = AuthApi();
  final _tokenStorage = const TokenStorage();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _api.login(
        username: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final accessToken = result['access_token']?.toString();
      final refreshToken = result['refresh_token']?.toString();
      final tokenType = result['token_type']?.toString();

      if (accessToken == null || refreshToken == null) {
        throw Exception('Missing tokens in response.');
      }

      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        tokenType: tokenType,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login successful.')));
      Navigator.pushReplacementNamed(context, HomePage.routeName);
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
      appBar: AppBar(title: const Text('Sign in')),
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
                            Icons.eco,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              'Sign in to continue',
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
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                ),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Email is required.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                ),
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password is required.';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters.';
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
                                    : const Text('Login'),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    ForgotPasswordPage.routeName,
                                  );
                                },
                                child: const Text('Forgot password?'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('New here?'),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              RegisterPage.routeName,
                            );
                          },
                          child: const Text('Create account'),
                        ),
                      ],
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
