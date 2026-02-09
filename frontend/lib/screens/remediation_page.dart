import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/token_storage.dart';
import '../services/app_localizations.dart';

// Screen for remediation guidance per diagnosis.
class RemediationPage extends StatelessWidget {
  const RemediationPage({
    super.key,
    required this.diseaseId,
    required this.diseaseName,
    required this.severity,
    required this.isHealthy,
  });

  final String diseaseId;
  final String diseaseName;
  final String severity;
  final bool isHealthy;

  Future<_RemediationData> _loadData() async {
    // Load remediation JSON and apply preferred language.
    final raw = await rootBundle.loadString(
      'assets/remediation/remediation.json',
    );
    final decoded = jsonDecode(raw);

    String language = 'en';
    final profile = await const TokenStorage().readUserProfile();
    final preferred = profile?['preferred_language']?.toString();
    if (preferred != null && preferred.isNotEmpty) {
      language = preferred;
    }

    return _RemediationData(decoded, language);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(context.t('Remediation guide'))),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F1EA), Color(0xFFE7F0E8)],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<_RemediationData>(
            future: _loadData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return Center(
                  child: Text(context.t('Remediation data unavailable.')),
                );
              }

              final data = snapshot.data!;
              final disease =
                  data.findDisease(diseaseId) ??
                  (isHealthy ? data.findHealthyFallback() : null);

              if (disease == null) {
                return Center(
                  child: Text(
                    context.t(
                      'No remediation found for {name}.',
                      args: {'name': diseaseName},
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final localizedName =
                  data.localize(disease['name']) ?? diseaseName;
              final description = data.localize(disease['description']) ?? '';
              final prevention = data.localizeList(disease['prevention_steps']);
              final severityGuidance = data.localizeSeverity(
                disease['severity_guidance'],
                severity,
              );
              final noTreatmentNeeded =
                  disease['no_treatment_needed'] == true || isHealthy;
              final treatments = disease['treatments'] as Map<String, dynamic>?;

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizedName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(description),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              _InfoChip(label: severity.toUpperCase()),
                              if (noTreatmentNeeded)
                                _InfoChip(
                                  label: context.t('No treatment needed'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (severityGuidance.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionHeader(
                      title: context.t('Severity guidance'),
                      subtitle: severityGuidance,
                    ),
                  ],
                  if (!noTreatmentNeeded && treatments != null) ...[
                    const SizedBox(height: 20),
                    _TreatmentSection(
                      title: context.t('Organic treatment'),
                      treatment: treatments['organic'] as Map<String, dynamic>?,
                      language: data.language,
                    ),
                    const SizedBox(height: 16),
                    _TreatmentSection(
                      title: context.t('Chemical treatment'),
                      treatment:
                          treatments['chemical'] as Map<String, dynamic>?,
                      language: data.language,
                    ),
                  ],
                  if (prevention.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionHeader(
                      title: context.t('Prevention tips'),
                      subtitle: context.t(
                        'Keep plants resilient with these steps.',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...prevention.map((tip) => _BulletRow(text: tip)),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RemediationData {
  _RemediationData(this.raw, this.language);

  final dynamic raw;
  final String language;

  Map<String, dynamic>? findDisease(String id) {
    final diseases = raw is Map<String, dynamic>
        ? raw['diseases'] as List<dynamic>?
        : null;
    if (diseases == null) {
      return null;
    }
    for (final item in diseases) {
      if (item is Map<String, dynamic> && item['disease_id'] == id) {
        return item;
      }
    }
    return null;
  }

  Map<String, dynamic>? findHealthyFallback() {
    return findDisease('tomato_healthy');
  }

  String? localize(dynamic value) {
    // Fall back to English when the language entry is missing.
    if (value is Map<String, dynamic>) {
      final localized = value[language] ?? value['en'];
      return localized?.toString();
    }
    return value?.toString();
  }

  List<String> localizeList(dynamic value) {
    if (value is Map<String, dynamic>) {
      final localized = value[language] ?? value['en'];
      if (localized is List) {
        return localized.map((item) => item.toString()).toList();
      }
    }
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }

  String localizeSeverity(dynamic value, String severity) {
    if (value is Map<String, dynamic>) {
      final entry = value[severity];
      return localize(entry) ?? '';
    }
    return '';
  }
}

class _TreatmentSection extends StatelessWidget {
  const _TreatmentSection({
    required this.title,
    required this.treatment,
    required this.language,
  });

  final String title;
  final Map<String, dynamic>? treatment;
  final String language;

  String _localize(dynamic value) {
    if (value is Map<String, dynamic>) {
      final localized = value[language] ?? value['en'];
      return localized?.toString() ?? '';
    }
    return value?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (treatment == null || treatment!.isEmpty) {
      return const SizedBox.shrink();
    }

    final steps = treatment!['steps'] as List<dynamic>? ?? [];
    final dosage = _localize(treatment!['dosage']);
    final frequency = _localize(treatment!['frequency']);
    final cost = treatment!['cost_estimate']?.toString() ?? '';

    final safetyWarnings = <String>[];
    for (final step in steps) {
      if (step is Map<String, dynamic>) {
        final warning = _localize(step['safety_warning']);
        if (warning.isNotEmpty) {
          safetyWarnings.add(warning);
        }
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...steps.map(
              (step) => _StepRow(
                step: step as Map<String, dynamic>,
                language: language,
              ),
            ),
            if (dosage.isNotEmpty ||
                frequency.isNotEmpty ||
                cost.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (dosage.isNotEmpty)
                    _InfoChip(
                      label: context.t(
                        'Dosage {value}',
                        args: {'value': dosage},
                      ),
                    ),
                  if (frequency.isNotEmpty)
                    _InfoChip(
                      label: context.t(
                        'Frequency {value}',
                        args: {'value': frequency},
                      ),
                    ),
                  if (cost.isNotEmpty)
                    _InfoChip(
                      label: context.t('Cost {value}', args: {'value': cost}),
                    ),
                ],
              ),
            ],
            if (safetyWarnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                context.t('Safety warnings'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              ...safetyWarnings.map((warning) => _BulletRow(text: warning)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.language});

  final Map<String, dynamic> step;
  final String language;

  String _localize(dynamic value) {
    if (value is Map<String, dynamic>) {
      final localized = value[language] ?? value['en'];
      return localized?.toString() ?? '';
    }
    return value?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final stepNumber = step['step_number']?.toString() ?? '';
    final description = _localize(step['description']);
    final duration = _localize(step['duration']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              stepNumber,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description),
                if (duration.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      duration,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ],
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

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
