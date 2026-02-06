import 'package:flutter/material.dart';

import '../../services/auth_api.dart';
import '../../services/location_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  static const String routeName = '/register';

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final List<Map<String, String>> _countryCodes = const [
    {'code': '+91', 'label': 'India (+91)'},
    {'code': '+1', 'label': 'USA (+1)'},
    {'code': '+44', 'label': 'UK (+44)'},
    {'code': '+61', 'label': 'Australia (+61)'},
    {'code': '+65', 'label': 'Singapore (+65)'},
  ];
  String _selectedCountryCode = '+91';
  final List<Map<String, String>> _languages = const [
    {'code': 'en', 'label': 'English'},
    {'code': 'hi', 'label': 'हिन्दी'},
    {'code': 'ta', 'label': 'தமிழ்'},
    {'code': 'te', 'label': 'తెలుగు'},
    {'code': 'kn', 'label': 'ಕನ್ನಡ'},
    {'code': 'ml', 'label': 'മലയാളം'},
  ];
  String _selectedLanguage = 'en';

  final _api = AuthApi();
  final _locationService = const LocationService();

  bool _isLoading = false;
  String? _errorMessage;
  LocationData? _location;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
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
      final location = await _locationService.getCurrentLocation();
      _location = location;

      await _api.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: '$_selectedCountryCode${_phoneController.text.trim()}',
        password: _passwordController.text,
        preferredLanguage: _selectedLanguage,
        latitude: location.latitude,
        longitude: location.longitude,
        address: _addressController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registration complete.')));
      Navigator.pop(context);
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
    final locationText = _location == null
        ? 'Location will be captured automatically.'
        : 'Location: ${_location!.latitude.toStringAsFixed(5)}, '
              '${_location!.longitude.toStringAsFixed(5)}';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Create account')),
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
                            Icons.landscape,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Join the community',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              'GPS helps personalize your reports',
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
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Full name',
                                ),
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Name is required.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
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
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedCountryCode,
                                      decoration: const InputDecoration(
                                        labelText: 'Code',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                      ),
                                      isExpanded: true,
                                      items: _countryCodes
                                          .map(
                                            (country) =>
                                                DropdownMenuItem<String>(
                                                  value: country['code'],
                                                  child: Text(
                                                    country['label'] ?? '',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        if (value == null) {
                                          return;
                                        }
                                        setState(() {
                                          _selectedCountryCode = value;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 5,
                                    child: TextFormField(
                                      controller: _phoneController,
                                      decoration: const InputDecoration(
                                        labelText: 'Phone',
                                      ),
                                      keyboardType: TextInputType.phone,
                                      textInputAction: TextInputAction.next,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Phone is required.';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                ),
                                obscureText: true,
                                textInputAction: TextInputAction.next,
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
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _addressController,
                                decoration: const InputDecoration(
                                  labelText: 'Address',
                                ),
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Address is required.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedLanguage,
                                decoration: const InputDecoration(
                                  labelText: 'Preferred language',
                                ),
                                items: _languages
                                    .map(
                                      (language) => DropdownMenuItem<String>(
                                        value: language['code'],
                                        child: Text(language['label'] ?? ''),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setState(() {
                                    _selectedLanguage = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              Text(
                                locationText,
                                style: Theme.of(context).textTheme.bodySmall,
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
                                    : const Text('Create account'),
                              ),
                            ],
                          ),
                        ),
                      ),
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
