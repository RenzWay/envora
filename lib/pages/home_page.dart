import 'package:envora/widget/home_body.dart';
import 'package:flutter/material.dart';

import '../controllers/environment_controller.dart';
import '../models/environment_variable.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final EnvironmentController _controller = EnvironmentController();

  @override
  void initState() {
    super.initState();

    _loadEnvironment();
  }

  Future<void> _loadEnvironment() async {
    await _controller.load();

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _addPath() async {
    final textController = TextEditingController();

    final path = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add PATH'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Directory',
              hintText: '/home/user/flutter/bin',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = textController.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.pop(context, value);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    textController.dispose();

    if (path == null) {
      return;
    }

    _controller.addPath(path);

    setState(() {});
  }

  Future<void> _addEnvironmentVariable() async {
    final result = await _showVariableDialog();

    if (result == null) {
      return;
    }

    _controller.addVariable(result.name, result.value);

    setState(() {});
  }

  Future<void> _editEnvironmentVariable(EnvironmentVariable variable) async {
    final result = await _showVariableDialog(variable: variable);

    if (result == null) {
      return;
    }

    _controller.updateVariable(variable.name, result.name, result.value);

    setState(() {});
  }

  Future<_VariableFormResult?> _showVariableDialog({
    EnvironmentVariable? variable,
  }) async {
    final nameController = TextEditingController(text: variable?.name ?? '');

    final valueController = TextEditingController(text: variable?.value ?? '');

    final result = await showDialog<_VariableFormResult>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            variable == null
                ? 'Add Environment Variable'
                : 'Edit Environment Variable',
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'JAVA_HOME',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: valueController,
                  decoration: const InputDecoration(
                    labelText: 'Value',
                    hintText: '/usr/lib/jvm/java-21',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();

                final value = valueController.text.trim();

                if (name.isEmpty) {
                  return;
                }

                Navigator.pop(
                  context,
                  _VariableFormResult(name: name, value: value),
                );
              },
              child: Text(variable == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    valueController.dispose();

    return result;
  }

  Future<void> _applyChanges() async {
    try {
      await _controller.applyChanges();

      if (!mounted) {
        return;
      }

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Environment changes applied')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to apply changes: $e')));
    }
  }

  Future<void> _discardChanges() async {
    await _controller.discardChanges();

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Envora'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _controller.isLoading ? null : _loadEnvironment,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: HomeBody(
        isLoading: _controller.isLoading,
        error: _controller.error,
        variables: _controller.variables,
        displayedVariables: _controller.displayedVariables,
        managedVariables: _controller.managedVariables,
        pathEntries: _controller.pathEntries,
        persistentPathEntries: _controller.persistentPathEntries,
        onAddVariable: _addEnvironmentVariable,
        onEditVariable: _editEnvironmentVariable,
        onRemoveVariable: (name) {
          _controller.removeVariable(name);
          setState(() {});
        },
        onAddPath: _addPath,
        onRemovePath: (path) {
          _controller.removePath(path);
          setState(() {});
        },
      ),
      bottomNavigationBar: _controller.hasPendingChanges
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _discardChanges,
                      child: const Text('Discard'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _applyChanges,
                      icon: const Icon(Icons.check),
                      label: const Text('Apply Changes'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _VariableFormResult {
  final String name;
  final String value;

  const _VariableFormResult({required this.name, required this.value});
}
