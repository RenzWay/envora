import 'package:flutter/material.dart';

import '../models/path_entry.dart';

class PersistentPathList extends StatelessWidget {
  final List<PathEntry> entries;

  final VoidCallback onAdd;

  final void Function(String path) onRemove;

  const PersistentPathList({
    super.key,
    required this.entries,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Persistent PATH',
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                const Spacer(),

                IconButton(
                  tooltip: 'Add PATH',
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Expanded(
              child: entries.isEmpty
                  ? const Center(child: Text('No paths managed by Envora'))
                  : ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (context, index) {
                        final entry = entries[index];

                        return ListTile(
                          leading: const Icon(Icons.folder_outlined),
                          title: Text(
                            entry.value,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            tooltip: 'Remove',
                            onPressed: () {
                              onRemove(entry.value);
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
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
