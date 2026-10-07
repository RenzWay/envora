import 'dart:io';

import '../models/environment_source.dart';
import '../models/environment_variable.dart';
import '../models/path_entry.dart';

class EnvironmentService {
  static const String _envoraPathStart = '# >>> Envora PATH >>>';

  static const String _envoraPathEnd = '# <<< Envora PATH <<<';

  static const String _envoraEnvironmentStart = '# >>> Envora ENV >>>';

  static const String _envoraEnvironmentEnd = '# <<< Envora ENV <<<';

  static const String _envoraPathLoaded = '_ENVORA_PATH_LOADED';

  static const String _envoraEnvironmentLoaded = '_ENVORA_ENV_LOADED';

  File get _profileFile {
    return File('$homeDirectory/.profile');
  }

  File get _bashrcFile {
    return File('$homeDirectory/.bashrc');
  }

  String get homeDirectory {
    return Platform.environment['HOME'] ?? '';
  }

  Map<String, String> get currentEnvironment {
    return Map<String, String>.from(Platform.environment);
  }

  Future<List<EnvironmentVariable>> getEnvironmentVariables() async {
    final environment = Platform.environment;

    return environment.entries
        .map(
          (entry) => EnvironmentVariable(
            name: entry.key,
            value: entry.value,
            scope: EnvironmentScope.user,
          ),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<List<EnvironmentVariable>> getManagedEnvironmentVariables() async {
    final file = _profileFile;

    if (!await file.exists()) {
      return [];
    }

    final content = await file.readAsString();

    final startIndex = content.indexOf(_envoraEnvironmentStart);

    final endIndex = content.indexOf(_envoraEnvironmentEnd);

    if (startIndex == -1 || endIndex == -1 || endIndex < startIndex) {
      return [];
    }

    final block = content.substring(
      startIndex + _envoraEnvironmentStart.length,
      endIndex,
    );

    final variables = <EnvironmentVariable>[];

    for (final line in block.split('\n')) {
      final trimmed = line.trim();

      final match = RegExp(r'^export\s+([A-Za-z_][A-Za-z0-9_]*)=(.*)$')
          .firstMatch(trimmed);

      if (match == null) {
        continue;
      }

      final name = match.group(1)!;

      var value = match.group(2)!.trim();

      if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
        value = value.substring(1, value.length - 1);
      }

      variables.add(
        EnvironmentVariable(
          name: name,
          value: value,
          scope: EnvironmentScope.user,
        ),
      );
    }

    return variables;
  }

  Future<void> saveManagedEnvironmentVariables(
    List<EnvironmentVariable> variables,
  ) async {
    final lines = variables.map((variable) {
      final escapedValue = variable.value
          .replaceAll(r'\', r'\\')
          .replaceAll('"', r'\"');

      return 'export ${variable.name}="$escapedValue"';
    }).toList();

    for (final file in [_profileFile, _bashrcFile]) {
      await _saveManagedBlock(
        file,
        _envoraEnvironmentStart,
        _envoraEnvironmentEnd,
        lines,
        _envoraEnvironmentLoaded,
      );
    }
  }

  Future<void> saveManagedPathEntries(List<PathEntry> entries) async {
    final lines = entries
        .map((entry) => 'export PATH="\$PATH:${entry.value}"')
        .toList();

    for (final file in [_profileFile, _bashrcFile]) {
      await _saveManagedBlock(
        file,
        _envoraPathStart,
        _envoraPathEnd,
        lines,
        _envoraPathLoaded,
      );
    }
  }

  Future<void> _saveManagedBlock(
    File file,
    String startMarker,
    String endMarker,
    List<String> lines,
    String loadedMarker,
  ) async {
    var content = await file.exists() ? await file.readAsString() : '';

    final guardedLines = [
      'if [ -z "\${$loadedMarker:-}" ]; then',
      '  $loadedMarker=1',
      ...lines.map((line) => '  $line'),
      'fi',
    ];
    final block = [startMarker, ...guardedLines, endMarker].join('\n');
    final startIndex = content.indexOf(startMarker);
    final endIndex = content.indexOf(endMarker);

    if (startIndex != -1 && endIndex != -1 && endIndex >= startIndex) {
      final before = content.substring(0, startIndex);
      final after = content.substring(endIndex + endMarker.length);
      content = '$before$block$after';
    } else {
      if (content.isNotEmpty && !content.endsWith('\n')) {
        content += '\n';
      }
      content += '\n$block\n';
    }

    await _backupFile(file);
    await file.writeAsString(content);
  }

  Future<void> _backupFile(File file) async {
    if (!await file.exists()) {
      return;
    }

    final backupDirectory = Directory('$homeDirectory/.config/envora/backups');

    await backupDirectory.create(recursive: true);

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');

    final backupFile = File(
      '${backupDirectory.path}/${file.uri.pathSegments.last}-$timestamp.bak',
    );

    await file.copy(backupFile.path);
  }

  Future<List<PathEntry>> getManagedPathEntries() async {
    final file = _profileFile;

    if (!await file.exists()) {
      return [];
    }

    final content = await file.readAsString();

    final startIndex = content.indexOf(_envoraPathStart);

    final endIndex = content.indexOf(_envoraPathEnd);

    if (startIndex == -1 || endIndex == -1 || endIndex < startIndex) {
      return [];
    }

    final block = content.substring(
      startIndex + _envoraPathStart.length,
      endIndex,
    );

    final entries = <PathEntry>[];

    for (final line in block.split('\n')) {
      final trimmed = line.trim();

      final match = RegExp(r'export PATH="\$PATH:(.*)"').firstMatch(trimmed);

      if (match == null) {
        continue;
      }

      final value = match.group(1)?.trim();

      if (value == null || value.isEmpty) {
        continue;
      }

      entries.add(PathEntry(value: value));
    }

    return entries;
  }

  Future<List<PathEntry>> getCurrentPathEntries() async {
    final path = Platform.environment['PATH'] ?? '';

    return _splitPath(path);
  }

  Future<List<PathEntry>> getPersistentPathEntries() async {
    final paths = <String>[];

    final environment = currentEnvironment;

    final files = [
      File('$homeDirectory/.profile'),
      File('$homeDirectory/.bashrc'),
    ];

    for (final file in files) {
      if (!await file.exists()) {
        continue;
      }

      final content = await file.readAsString();

      final pathEntries = _extractPathEntries(content, environment);

      for (final entry in pathEntries) {
        if (!paths.contains(entry)) {
          paths.add(entry);
        }
      }
    }

    return paths.map((entry) => PathEntry(value: entry)).toList();
  }

  Future<List<EnvironmentSourceInfo>> getSources() async {
    final profilePath = '$homeDirectory/.profile';

    final bashrcPath = '$homeDirectory/.bashrc';

    return [
      EnvironmentSourceInfo(
        source: EnvironmentSource.current,
        path: 'Current process environment',
        exists: true,
      ),
      EnvironmentSourceInfo(
        source: EnvironmentSource.profile,
        path: profilePath,
        exists: await File(profilePath).exists(),
      ),
      EnvironmentSourceInfo(
        source: EnvironmentSource.bashrc,
        path: bashrcPath,
        exists: await File(bashrcPath).exists(),
      ),
    ];
  }

  List<PathEntry> _splitPath(String path) {
    final entries = <String>[];

    for (final rawEntry in path.split(':')) {
      final entry = rawEntry.trim();

      if (entry.isEmpty) {
        continue;
      }

      if (!entries.contains(entry)) {
        entries.add(entry);
      }
    }

    return entries.map((entry) => PathEntry(value: entry)).toList();
  }

  List<String> _extractPathEntries(
    String content,
    Map<String, String> environment,
  ) {
    final result = <String>[];

    for (final rawLine in content.split('\n')) {
      final line = rawLine.trim();

      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }

      final match = RegExp(r'^(?:export\s+)?PATH\s*=\s*(.+)$').firstMatch(line);

      if (match == null) {
        continue;
      }

      var value = match.group(1)!.trim();

      if (value.endsWith(';')) {
        value = value.substring(0, value.length - 1).trim();
      }

      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }

      value = _expandVariables(value, environment);

      for (final rawEntry in value.split(':')) {
        final entry = rawEntry.trim();

        if (entry.isEmpty) {
          continue;
        }

        if (entry == r'$PATH' || entry == r'${PATH}') {
          continue;
        }

        if (!result.contains(entry)) {
          result.add(entry);
        }
      }
    }

    return result;
  }

  String _expandVariables(String value, Map<String, String> environment) {
    var result = value;

    final variablePattern = RegExp(
      r'\$(?:\{([A-Za-z_][A-Za-z0-9_]*)\}|([A-Za-z_][A-Za-z0-9_]*))',
    );

    for (var i = 0; i < 5; i++) {
      var changed = false;

      result = result.replaceAllMapped(variablePattern, (match) {
        final name = match.group(1) ?? match.group(2)!;

        if (name == 'PATH') {
          return match.group(0)!;
        }

        final replacement = environment[name];

        if (replacement == null) {
          return match.group(0)!;
        }

        changed = true;

        return replacement;
      });

      if (!changed) {
        break;
      }
    }

    return result;
  }
}
