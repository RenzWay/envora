import 'package:flutter/material.dart';

import '../models/path_entry.dart';

class PathList extends StatelessWidget {
  final List<PathEntry> entries;

  const PathList({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PATH', style: Theme.of(context).textTheme.titleLarge),

            const SizedBox(height: 16),

            Expanded(
              child: ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final entry = entries[index];

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 14,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(entry.value, overflow: TextOverflow.ellipsis),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
