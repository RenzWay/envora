enum EnvironmentSource { current, profile, bashrc }

class EnvironmentSourceInfo {
  final EnvironmentSource source;
  final String path;
  final bool exists;

  const EnvironmentSourceInfo({
    required this.source,
    required this.path,
    required this.exists,
  });
}
