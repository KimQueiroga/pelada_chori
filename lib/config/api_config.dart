enum Environment { dev, homol, prod }

class ApiConfig {
  static const Environment env = Environment.dev;

  static String get baseUrl {
    switch (env) {
      case Environment.dev:
        return 'http://localhost:8000/api'; // para emulador Android com Laravel local
      case Environment.homol:
        return 'https://homol.seusite.com/api';
      case Environment.prod:
        return 'https://api.seusite.com/api';
    }
  }
}
