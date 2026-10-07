import 'package:flutter/material.dart';

import '../models/environment_variable.dart';

class EnvironmentVariableList extends StatelessWidget {
  final List<EnvironmentVariable> variables;

  final List<EnvironmentVariable> managedVariables;

  final VoidCallback onAdd;

  final void Function(EnvironmentVariable variable) onEdit;

  final void Function(String name) onRemove;

  const EnvironmentVariableList({
    super.key,
    required this.variables,
    required this.managedVariables,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  bool _isManaged(String name) {
    return managedVariables.any(
      (variable) => variable.name == name,
    );
  }

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
                  'Environment Variables',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Add variable',
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: variables.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final variable = variables[index];
                  final managed = _isManaged(variable.name);

                  return ListTile(
                    title: Text(variable.name),
                    subtitle: Text(
                      variable.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Variable options',
                      onSelected: (action) {
                        if (action == 'edit') {
                          onEdit(variable);
                        }

                        if (action == 'remove') {
                          onRemove(variable.name);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Text(
                            managed
                                ? 'Remove'
                                : 'Remove from Envora',
                          ),
                        ),
                      ],
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