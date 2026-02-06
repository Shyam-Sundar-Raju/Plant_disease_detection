import 'package:flutter/material.dart';

import '../services/api_config.dart';

class DiagnosisResultPage extends StatelessWidget {
  const DiagnosisResultPage({
    super.key,
    required this.cropLabel,
    required this.result,
  });

  final String cropLabel;
  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final diseaseName = result['disease_name']?.toString() ?? 'Unknown';
    final severity = result['severity']?.toString() ?? 'unknown';
    final confidence = result['confidence']?.toString() ?? '-';
    final isHealthy = result['is_healthy'] == true;

    final imageUrl = _resolveUrl(result['image_url']?.toString());
    final heatmapUrl = _resolveUrl(result['heatmap_url']?.toString());

    return Scaffold(
      appBar: AppBar(title: const Text('Diagnosis result')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(cropLabel, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            isHealthy ? 'Healthy' : diseaseName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text('Severity: $severity'),
          Text('Confidence: $confidence'),
          const SizedBox(height: 16),
          if (imageUrl.isNotEmpty) _ImageSection(label: 'Image', url: imageUrl),
          if (heatmapUrl.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ImageSection(label: 'Heatmap', url: heatmapUrl),
          ],
          const SizedBox(height: 16),
          if (result['bounding_boxes'] is List)
            Text(
              'Bounding boxes: ${(result['bounding_boxes'] as List).length}',
            ),
        ],
      ),
    );
  }

  String _resolveUrl(String? path) {
    if (path == null || path.isEmpty) {
      return '';
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('/')) {
      return '${ApiConfig.baseHost}$path';
    }
    return '${ApiConfig.baseHost}/$path';
  }
}

class _ImageSection extends StatelessWidget {
  const _ImageSection({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.all(20),
                child: const Center(child: Icon(Icons.broken_image)),
              );
            },
          ),
        ),
      ],
    );
  }
}
