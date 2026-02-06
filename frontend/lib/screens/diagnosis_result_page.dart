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
    final boxes = _parseBoxes(result['bounding_boxes']);

    final imageUrl = _resolveUrl(result['image_url']?.toString());
    final heatmapUrl = _resolveUrl(result['heatmap_url']?.toString());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Diagnosis result')),
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
                        isHealthy ? 'Healthy' : diseaseName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _StatusChip(label: severity.toUpperCase()),
                          _StatusChip(label: 'Confidence $confidence'),
                          if (boxes.isNotEmpty)
                            _StatusChip(label: 'Boxes ${boxes.length}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (imageUrl.isNotEmpty)
                _ImageSection(label: 'Image', url: imageUrl, boxes: boxes),
              if (heatmapUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                _ImageSection(label: 'Heatmap', url: heatmapUrl),
              ],
            ],
          ),
        ),
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

  List<_BoundingBox> _parseBoxes(dynamic data) {
    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(_BoundingBox.fromJson)
        .toList();
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
