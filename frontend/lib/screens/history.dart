import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Hive.openBox('history_box'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final box = Hive.box('history_box');

        if (box.isEmpty) {
          return const Center(child: Text("No scans yet."));
        }

        return ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (context, Box box, _) {
            return ListView.builder(
              itemCount: box.length,
              itemBuilder: (context, index) {
                // Get data in reverse order (newest first)
                final item = box.getAt(box.length - 1 - index);

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: item['image'] != null
                        ? Image.file(
                            File(item['image']),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image_not_supported),
                    title: Text(item['name'] ?? "Unknown"),
                    subtitle: Text(
                      item['date'].toString().split('.')[0],
                    ), // Simple date formatting
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
