import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../services/location_service.dart';
import '../services/history_api.dart';
import '../services/auth_api.dart';
import '../services/token_storage.dart';
import '../services/user_api.dart';
import '../services/weather_api.dart';
import 'auth/login_page.dart';
import 'crop_capture_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const String routeName = '/home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _tokenStorage = const TokenStorage();
  final _userApi = UserApi();
  final _locationService = const LocationService();
  final _weatherApi = WeatherApi();
  final _historyApi = HistoryApi();
  final _authApi = AuthApi();
  Map<String, dynamic>? _profile;
  bool _isRefreshingProfile = false;
  WeatherInfo? _weatherInfo;
  String? _weatherError;
  bool _isLoadingWeather = false;
  Map<String, dynamic>? _historyAnalytics;
  List<Map<String, dynamic>> _historyItems = [];
  bool _isLoadingHistory = false;
  bool _isOnline = false;

  Future<void> _logout() async {
    await _tokenStorage.clearTokens();

    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginPage.routeName,
      (route) => false,
    );
  }

  Future<void> _refreshProfile() async {
    if (_isRefreshingProfile) {
      return;
    }

    setState(() {
      _isRefreshingProfile = true;
    });

    try {
      final accessToken = await _tokenStorage.readAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return;
      }

      final profile = await _userApi.getProfile(accessToken: accessToken);
      await _tokenStorage.saveUserProfile(profile);
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = profile;
      });
    } catch (_) {
      // Keep cached profile if refresh fails.
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingProfile = false;
        });
      }
    }
  }

  Future<void> _loadCachedProfile() async {
    final cached = await _tokenStorage.readUserProfile();
    if (cached != null && mounted) {
      setState(() {
        _profile = cached;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
    _updateConnectivity();
  }

  Future<void> _initializeData() async {
    await _refreshTokenIfWifi();
    _loadCachedProfile();
    _refreshProfile();
    _loadWeather();
    _loadCachedHistory();
    _loadCachedAnalytics();
    _loadHistory();
    _loadAnalytics();
  }

  Future<void> _updateConnectivity() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (!mounted) {
      return;
    }
    setState(() {
      _isOnline =
          connectivity.contains(ConnectivityResult.wifi) ||
          connectivity.contains(ConnectivityResult.mobile);
    });
  }

  Future<void> _refreshTokenIfWifi() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (!connectivity.contains(ConnectivityResult.wifi)) {
      return;
    }

    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return;
    }

    try {
      final result = await _authApi.refreshToken(refreshToken: refreshToken);

      final accessToken = result['access_token']?.toString();
      final newRefreshToken = result['refresh_token']?.toString();
      final tokenType = result['token_type']?.toString();

      if (accessToken == null || newRefreshToken == null) {
        return;
      }

      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
        tokenType: tokenType,
      );
    } catch (_) {
      // Ignore refresh errors and keep existing tokens.
    }
  }

  Future<void> _loadCachedHistory() async {
    final cached = await _tokenStorage.readHistory();
    if (cached != null && mounted) {
      setState(() {
        _historyItems = cached;
      });
    }
  }

  Future<void> _loadCachedAnalytics() async {
    final cached = await _tokenStorage.readHistoryAnalytics();
    if (cached != null && mounted) {
      setState(() {
        _historyAnalytics = cached;
      });
    }
  }

  Future<void> _loadHistory() async {
    if (_isLoadingHistory) {
      return;
    }

    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final accessToken = await _tokenStorage.readAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return;
      }

      final history = await _historyApi.getHistory(accessToken: accessToken);

      await _tokenStorage.saveHistory(history);

      if (!mounted) {
        return;
      }

      setState(() {
        _historyItems = history;
      });
    } catch (_) {
      // Keep cached history if request fails.
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      final accessToken = await _tokenStorage.readAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return;
      }

      final analytics = await _historyApi.getAnalytics(
        accessToken: accessToken,
      );

      await _tokenStorage.saveHistoryAnalytics(analytics);

      if (!mounted) {
        return;
      }

      setState(() {
        _historyAnalytics = analytics;
      });
    } catch (_) {
      // Keep cached analytics if request fails.
    }
  }

  Future<void> _deleteHistoryItem(String historyId) async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }

    try {
      await _historyApi.deleteHistory(
        accessToken: accessToken,
        historyId: historyId,
      );

      final updated = _historyItems
          .where((item) => item['_id']?.toString() != historyId)
          .toList();
      await _tokenStorage.saveHistory(updated);

      if (!mounted) {
        return;
      }

      setState(() {
        _historyItems = updated;
      });

      _loadAnalytics();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _downloadReport(String diagnosisId) async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }

    try {
      final path = await _historyApi.downloadReport(
        accessToken: accessToken,
        diagnosisId: diagnosisId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Report saved: $path')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _loadWeather() async {
    if (_isLoadingWeather) {
      return;
    }

    setState(() {
      _isLoadingWeather = true;
      _weatherError = null;
    });

    try {
      final location = await _locationService.getCurrentLocation();
      final weather = await _weatherApi.getCurrentWeather(
        latitude: location.latitude,
        longitude: location.longitude,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _weatherInfo = weather;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _weatherError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Field dashboard'),
        actions: [
          IconButton(
            onPressed: _initializeData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          Icon(
            _isOnline ? Icons.wifi : Icons.wifi_off,
            color: _isOnline ? scheme.primary : scheme.error,
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.pushNamed(context, ProfilePage.routeName);
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'profile', child: Text('Profile')),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F1EA), Color(0xFFE7F0E8)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: scheme.primary.withOpacity(0.12),
                        child: Icon(Icons.eco, color: scheme.primary, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${_profile?['name']?.toString() ?? 'Farmer'}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _profile?['email']?.toString() ?? '-',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(_isOnline ? 'Online' : 'Offline'),
                        backgroundColor: _isOnline
                            ? scheme.primary.withOpacity(0.12)
                            : null,
                        labelStyle: TextStyle(
                          color: _isOnline ? scheme.primary : scheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide(
                          color: _isOnline ? scheme.primary : scheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isRefreshingProfile)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(),
                ),
              const SizedBox(height: 20),
              _SectionHeader(
                title: 'Current weather',
                subtitle: 'Live conditions near your farm',
              ),
              const SizedBox(height: 12),
              if (_isLoadingWeather)
                const Center(child: CircularProgressIndicator())
              else if (_weatherError != null)
                Text(_weatherError!, style: TextStyle(color: scheme.error))
              else if (_weatherInfo != null)
                _WeatherCard(weather: _weatherInfo!)
              else
                const Text('Weather data unavailable.'),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'History analytics',
                subtitle: 'Trends from your recent scans',
              ),
              const SizedBox(height: 12),
              _AnalyticsCard(analytics: _historyAnalytics),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'History records',
                subtitle: 'Download or remove past reports',
              ),
              const SizedBox(height: 12),
              if (_isLoadingHistory)
                const Center(child: CircularProgressIndicator())
              else if (_historyItems.isEmpty)
                const Text('No history yet.')
              else
                ..._historyItems.map(
                  (item) => _HistoryCard(
                    item: item,
                    onDelete: () =>
                        _deleteHistoryItem(item['_id']?.toString() ?? ''),
                    onDownload: () =>
                        _downloadReport(item['diagnosis_id']?.toString() ?? ''),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, CropCapturePage.routeName);
        },
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan crop'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: SizedBox(height: 48),
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({required this.weather});

  final WeatherInfo weather;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather.locationName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weather.conditionText,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (weather.conditionIconUrl.isNotEmpty)
                    Image.network(
                      weather.conditionIconUrl,
                      width: 44,
                      height: 44,
                    ),
                  Text(
                    '${weather.tempC.toStringAsFixed(1)} C',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _InfoChip(
                label: 'Feels ${weather.feelsLikeC.toStringAsFixed(1)} C',
              ),
              _InfoChip(label: 'Humidity ${weather.humidity}%'),
              _InfoChip(
                label: 'Wind ${weather.windKph.toStringAsFixed(1)} kph',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({required this.analytics});

  final Map<String, dynamic>? analytics;

  @override
  Widget build(BuildContext context) {
    if (analytics == null) {
      return const Text('Analytics data unavailable.');
    }

    final total = analytics?['total_diagnoses']?.toString() ?? '0';
    final severity =
        analytics?['severity_distribution'] as Map<String, dynamic>?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total diagnoses',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(total, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            if (severity != null)
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _InfoChip(label: 'Low ${severity['low'] ?? 0}'),
                  _InfoChip(label: 'Medium ${severity['medium'] ?? 0}'),
                  _InfoChip(label: 'High ${severity['high'] ?? 0}'),
                  _InfoChip(label: 'Healthy ${severity['healthy'] ?? 0}'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.item,
    required this.onDelete,
    required this.onDownload,
  });

  final Map<String, dynamic> item;
  final VoidCallback onDelete;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final cropType = item['crop_type']?.toString() ?? 'Unknown crop';
    final diseaseName = item['disease_name']?.toString() ?? 'Unknown disease';
    final severity = item['severity']?.toString() ?? 'unknown';
    final createdAt = item['created_at']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    diseaseName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _InfoChip(label: severity.toUpperCase()),
              ],
            ),
            const SizedBox(height: 6),
            Text('Crop: $cropType'),
            if (createdAt.isNotEmpty) Text('Date: $createdAt'),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download),
                  label: const Text('Report'),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      label: Text(label),
      backgroundColor: scheme.primary.withOpacity(0.08),
      labelStyle: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
      side: BorderSide(color: scheme.primary.withOpacity(0.4)),
    );
  }
}
