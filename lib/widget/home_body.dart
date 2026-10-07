import 'package:flutter/material.dart';

import '../models/environment_variable.dart';
import '../models/path_entry.dart';
import 'environment_variable_list.dart';
import 'path_list.dart';
import 'persistent_path_list.dart';

class HomeBody extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final List<EnvironmentVariable> variables;
  final List<EnvironmentVariable> managedVariables;
  final List<PathEntry> pathEntries;
  final List<PathEntry> persistentPathEntries;
  final VoidCallback onAddVariable;
  final void Function(EnvironmentVariable variable) onEditVariable;
  final void Function(String name) onRemoveVariable;
  final VoidCallback onAddPath;
  final void Function(String path) onRemovePath;
  final List<EnvironmentVariable> displayedVariables;

  const HomeBody({
    super.key,
    required this.isLoading,
    required this.error,
    required this.variables,
    required this.managedVariables,
    required this.pathEntries,
    required this.persistentPathEntries,
    required this.onAddVariable,
    required this.onEditVariable,
    required this.onRemoveVariable,
    required this.onAddPath,
    required this.onRemovePath,
    required this.displayedVariables,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text(error!));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: EnvironmentVariableList(
              variables: displayedVariables,
              managedVariables: managedVariables,
              onAdd: onAddVariable,
              onEdit: onEditVariable,
              onRemove: onRemoveVariable,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(child: PathList(entries: pathEntries)),
                const SizedBox(height: 16),
                Expanded(
                  child: PersistentPathList(
                    entries: persistentPathEntries,
                    onAdd: onAddPath,
                    onRemove: onRemovePath,
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
