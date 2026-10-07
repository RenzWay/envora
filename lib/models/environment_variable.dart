enum EnvironmentScope { user, system }

class EnvironmentVariable {
  final String name;
  final String value;
  final EnvironmentScope scope;

  const EnvironmentVariable({
    required this.name,
    required this.value,
    required this.scope,
  });
  
}
