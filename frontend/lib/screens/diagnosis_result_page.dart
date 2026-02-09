import 'package:flutter/material.dart';

import '../services/api_config.dart';
import '../services/app_localizations.dart';
import 'remediation_page.dart';

// Screen that displays diagnosis results and imagery.
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
    // Normalize raw result values for display.
    final diseaseName = result['disease_name']?.toString() ?? 'Unknown';
    final severity = result['severity']?.toString() ?? 'unknown';
    final confidencePercent = _parseConfidencePercent(result['confidence']);
    final isHealthy = result['is_healthy'] == true;
    final boxes = _parseBoxes(result['bounding_boxes']);
    final isLowConfidence =
        !isHealthy && confidencePercent > 0 && confidencePercent < 40;
    final displayDiseaseName = isLowConfidence
        ? context.t('Unknown disease')
        : (isHealthy ? context.t('Healthy') : diseaseName);
    final displaySeverity = isLowConfidence ? 'unknown' : severity;
    final diseaseId = isLowConfidence
        ? ''
        : _resolveDiseaseId(result, isHealthy);
    final confidenceLabel = confidencePercent > 0
        ? context.t(
            'Confidence {value}%',
            args: {'value': confidencePercent.toStringAsFixed(0)},
          )
        : context.t('Confidence -');

    final imageUrl = _resolveUrl(result['image_url']?.toString());
    final heatmapUrl = _resolveUrl(result['heatmap_url']?.toString());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(context.t('Diagnosis result'))),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cropLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        displayDiseaseName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _StatusChip(label: displaySeverity.toUpperCase()),
                          _StatusChip(label: confidenceLabel),
                          if (boxes.isNotEmpty)
                            _StatusChip(
                              label: context.t(
                                'Boxes {count}',
                                args: {'count': boxes.length.toString()},
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: diseaseId.isEmpty
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RemediationPage(
                                        diseaseId: diseaseId,
                                        diseaseName: displayDiseaseName,
                                        severity: displaySeverity,
                                        isHealthy: isHealthy,
                                      ),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.medical_services_outlined),
                          label: Text(context.t('View remediation')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (imageUrl.isNotEmpty)
                _ImageSection(
                  label: context.t('Image'),
                  url: imageUrl,
                  boxes: boxes,
                ),
              if (heatmapUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                if (imageUrl.isNotEmpty)
                  _MatchedImageSection(
                    label: context.t('Heatmap'),
                    imageUrl: heatmapUrl,
                    matchUrl: imageUrl,
                  )
                else
                  _ImageSection(label: context.t('Heatmap'), url: heatmapUrl),
              ],
              if (imageUrl.isNotEmpty && diseaseId.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SideBySideComparison(
                  capturedUrl: imageUrl,
                  referenceAsset:
                      'assets/images/reference_diseases/$diseaseId.jpeg',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _resolveUrl(String? path) {
    // Resolve relative API paths to full URLs.
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

  List<_BoundingBox> _parseBoxes(dynamic data) {
    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(_BoundingBox.fromJson)
        .toList();
  }

  double _parseConfidencePercent(dynamic value) {
    // Accept 0-1 or 0-100 confidence values.
    if (value == null) {
      return 0;
    }
    double? parsed;
    if (value is num) {
      parsed = value.toDouble();
    } else {
      parsed = double.tryParse(value.toString());
    }
    if (parsed == null || parsed.isNaN) {
      return 0;
    }
    if (parsed <= 1) {
      return parsed * 100;
    }
    return parsed;
  }

  String _resolveDiseaseId(Map<String, dynamic> data, bool isHealthy) {
    final id = data['disease_id']?.toString();
    if (id != null && id.isNotEmpty) {
      return id;
    }

    if (!isHealthy) {
      return '';
    }

    final cropType = data['crop_type']?.toString();
    if (cropType != null && cropType.isNotEmpty) {
      return '${cropType}_healthy';
    }

    return '';
  }
}

class _ImageSection extends StatelessWidget {
  const _ImageSection({
    required this.label,
    required this.url,
    this.boxes = const [],
  });

  final String label;
  final String url;
  final List<_BoundingBox> boxes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: boxes.isEmpty
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      padding: const EdgeInsets.all(20),
                      child: const Center(child: Icon(Icons.broken_image)),
                    );
                  },
                )
              : _ImageWithBoxes(url: url, boxes: boxes),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      label: Text(label),
      backgroundColor: scheme.primary.withOpacity(0.1),
      labelStyle: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
      side: BorderSide(color: scheme.primary.withOpacity(0.4)),
    );
  }
}

class _MatchedImageSection extends StatelessWidget {
  const _MatchedImageSection({
    required this.label,
    required this.imageUrl,
    required this.matchUrl,
  });

  final String label;
  final String imageUrl;
  final String matchUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _ImageWithMatchedAspect(
            imageUrl: imageUrl,
            matchUrl: matchUrl,
          ),
        ),
      ],
    );
  }
}

class _ImageWithMatchedAspect extends StatefulWidget {
  const _ImageWithMatchedAspect({
    required this.imageUrl,
    required this.matchUrl,
  });

  final String imageUrl;
  final String matchUrl;

  @override
  State<_ImageWithMatchedAspect> createState() =>
      _ImageWithMatchedAspectState();
}

class _ImageWithMatchedAspectState extends State<_ImageWithMatchedAspect> {
  Size? _matchSize;

  @override
  void initState() {
    super.initState();
    _resolveMatchImage();
  }

  @override
  void didUpdateWidget(covariant _ImageWithMatchedAspect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matchUrl != widget.matchUrl) {
      _matchSize = null;
      _resolveMatchImage();
    }
  }

  void _resolveMatchImage() {
    // Match aspect ratio to the reference image.
    final image = Image.network(widget.matchUrl);
    final stream = image.image.resolve(const ImageConfiguration());
    stream.addListener(
      ImageStreamListener(
        (info, _) {
          if (!mounted) {
            return;
          }
          setState(() {
            _matchSize = Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            );
          });
        },
        onError: (_, __) {
          if (!mounted) {
            return;
          }
          setState(() {
            _matchSize = null;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final matchSize = _matchSize;
        final width = constraints.maxWidth;
        final height = matchSize == null
            ? 220.0
            : (width * (matchSize.height / matchSize.width));

        return SizedBox(
          width: width,
          height: height,
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.all(20),
                child: const Center(child: Icon(Icons.broken_image)),
              );
            },
          ),
        );
      },
    );
  }
}

class _SideBySideComparison extends StatelessWidget {
  const _SideBySideComparison({
    required this.capturedUrl,
    required this.referenceAsset,
  });

  final String capturedUrl;
  final String referenceAsset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t('Comparison'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ComparisonTile(
                label: context.t('Captured'),
                child: Image.network(
                  capturedUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const _ImageFallback();
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ComparisonTile(
                label: context.t('Reference'),
                child: Image.asset(
                  referenceAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const _ImageFallback();
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ComparisonTile extends StatelessWidget {
  const _ComparisonTile({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(aspectRatio: 1, child: child),
        ),
      ],
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.broken_image)),
    );
  }
}

class _ImageWithBoxes extends StatefulWidget {
  const _ImageWithBoxes({required this.url, required this.boxes});

  final String url;
  final List<_BoundingBox> boxes;

  @override
  State<_ImageWithBoxes> createState() => _ImageWithBoxesState();
}

class _ImageWithBoxesState extends State<_ImageWithBoxes> {
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant _ImageWithBoxes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _imageSize = null;
      _resolveImage();
    }
  }

  void _resolveImage() {
    final image = Image.network(widget.url);
    final stream = image.image.resolve(const ImageConfiguration());
    stream.addListener(
      ImageStreamListener(
        (info, _) {
          if (!mounted) {
            return;
          }
          setState(() {
            _imageSize = Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            );
          });
        },
        onError: (_, __) {
          if (!mounted) {
            return;
          }
          setState(() {
            _imageSize = null;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSize = _imageSize;
        final width = constraints.maxWidth;
        final height = imageSize == null
            ? 220.0
            : (width * (imageSize.height / imageSize.width));

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                widget.url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    padding: const EdgeInsets.all(20),
                    child: const Center(child: Icon(Icons.broken_image)),
                  );
                },
              ),
              if (imageSize != null)
                CustomPaint(
                  painter: _BoundingBoxPainter(
                    boxes: widget.boxes,
                    imageSize: imageSize,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BoundingBoxPainter extends CustomPainter {
  _BoundingBoxPainter({required this.boxes, required this.imageSize});

  final List<_BoundingBox> boxes;
  final Size imageSize;

  @override
  void paint(Canvas canvas, Size size) {
    // Scale model coordinates to the rendered image size.
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    final paint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final box in boxes) {
      final rect = Rect.fromLTWH(
        box.x * scaleX,
        box.y * scaleY,
        box.width * scaleX,
        box.height * scaleY,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoundingBoxPainter oldDelegate) {
    return oldDelegate.boxes != boxes || oldDelegate.imageSize != imageSize;
  }
}

class _BoundingBox {
  const _BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;

  factory _BoundingBox.fromJson(Map<String, dynamic> json) {
    return _BoundingBox(
      x: _asDouble(json['x']),
      y: _asDouble(json['y']),
      width: _asDouble(json['width']),
      height: _asDouble(json['height']),
    );
  }

  static double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return 0.0;
  }
}
