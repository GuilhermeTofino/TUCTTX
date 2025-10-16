// lib/flavors.dart
enum Flavor {
  dev,
  prod,
}

class FlavorConfig {
  final Flavor flavor;
  final String name;
  // Adicione outras variáveis que mudam por ambiente aqui
  // Ex: final String apiBaseUrl;

  static FlavorConfig? _instance;

  FlavorConfig._internal(this.flavor, this.name);

  static FlavorConfig get instance {
    if (_instance == null) {
      throw Exception(
          "FlavorConfig not initialized. Call FlavorConfig.initialize() first.");
    }
    return _instance!;
  }

  static void initialize(Flavor flavor) {
    if (_instance != null) {
      print("FlavorConfig already initialized. Ignoring subsequent calls.");
      return;
    }
    switch (flavor) {
      case Flavor.dev:
        _instance = FlavorConfig._internal(Flavor.dev, "TucTTX Dev");
        break;
      case Flavor.prod:
        _instance = FlavorConfig._internal(Flavor.prod, "TucTTX");
        break;
    }
  }
}
