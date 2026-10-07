import '../models/environment_source.dart';
import '../models/environment_variable.dart';
import '../models/path_entry.dart';
import '../service/environment_service.dart';

class EnvironmentController {
  final EnvironmentService _service;

  EnvironmentController({EnvironmentService? service})
    : _service = service ?? EnvironmentService();

  List<EnvironmentVariable> variables = [];

  List<EnvironmentVariable> managedVariables = [];

  List<PathEntry> pathEntries = [];

  List<PathEntry> persistentPathEntries = [];

  List<EnvironmentSourceInfo> sources = [];

  bool isLoading = false;
  bool hasPendingChanges = false;

  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;

    try {
      variables = await _service.getEnvironmentVariables();

      managedVariables = await _service.getManagedEnvironmentVariables();

      pathEntries = await _service.getCurrentPathEntries();

      persistentPathEntries = await _service.getManagedPathEntries();

      sources = await _service.getSources();

      hasPendingChanges = await _service.needsBashrcSync();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
    }
  }

  List<EnvironmentVariable> get displayedVariables {
    final result = <String, EnvironmentVariable>{};

    for (final variable in variables) {
      result[variable.name] = variable;
    }

    for (final variable in managedVariables) {
      result[variable.name] = variable;
    }

    final list = result.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return list;
  }

  bool isVariableManaged(String name) {
    return managedVariables.any((variable) => variable.name == name);
  }

  void addPath(String path) {
    final normalizedPath = path.trim();

    if (normalizedPath.isEmpty) {
      return;
    }

    final exists = persistentPathEntries.any(
      (entry) => entry.value == normalizedPath,
    );

    if (exists) {
      return;
    }

    persistentPathEntries = [
      ...persistentPathEntries,
      PathEntry(value: normalizedPath),
    ];

    hasPendingChanges = true;
  }

  void removePath(String path) {
    persistentPathEntries = persistentPathEntries
        .where((entry) => entry.value != path)
        .toList();

    hasPendingChanges = true;
  }

  void addVariable(String name, String value) {
    final normalizedName = name.trim();
    final normalizedValue = value;

    if (!_isValidVariableName(normalizedName)) {
      return;
    }

    final exists = managedVariables.any(
      (variable) => variable.name == normalizedName,
    );

    if (exists) {
      return;
    }

    managedVariables = [
      ...managedVariables,
      EnvironmentVariable(
        name: normalizedName,
        value: normalizedValue,
        scope: EnvironmentScope.user,
      ),
    ];

    hasPendingChanges = true;
  }

  void updateVariable(String oldName, String name, String value) {
    final normalizedName = name.trim();

    if (!_isValidVariableName(normalizedName)) {
      return;
    }

    final duplicate = managedVariables.any(
      (variable) => variable.name == normalizedName && variable.name != oldName,
    );

    if (duplicate) {
      return;
    }

    final exists = managedVariables.any((variable) => variable.name == oldName);

    if (exists) {
      managedVariables = managedVariables.map((variable) {
        if (variable.name != oldName) {
          return variable;
        }

        return EnvironmentVariable(
          name: normalizedName,
          value: value,
          scope: EnvironmentScope.user,
        );
      }).toList();
    } else {
      managedVariables = [
        ...managedVariables,
        EnvironmentVariable(
          name: normalizedName,
          value: value,
          scope: EnvironmentScope.user,
        ),
      ];
    }

    hasPendingChanges = true;
  }

  void removeVariable(String name) {
    managedVariables = managedVariables
        .where((variable) => variable.name != name)
        .toList();

    hasPendingChanges = true;
  }

  bool _isValidVariableName(String name) {
    return RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(name);
  }

  Future<void> applyChanges() async {
    await _service.saveManagedEnvironmentVariables(managedVariables);

    await _service.saveManagedPathEntries(persistentPathEntries);

    await load();
  }

  Future<void> discardChanges() async {
    await load();
  }
}
