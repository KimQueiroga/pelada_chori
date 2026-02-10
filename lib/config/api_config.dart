enum Environment { dev, homol, prod }

class ApiConfig {
  static final Environment env = _getEnv();

  static Environment _getEnv() {
    const envStr = String.fromEnvironment('ENV', defaultValue: 'dev');
    switch (envStr) {
      case 'homol':
        return Environment.homol;
      case 'prod':
        return Environment.prod;
      default:
        return Environment.dev;
    }
  }

  static String get baseUrl {
    switch (env) {
      case Environment.homol:
        return 'https://api-homol.peladadochori.com/api';
      case Environment.prod:
        return 'https://api.peladadochori.com/api';
      case Environment.dev:
      default:
        return 'http://pelada-chori.local/api';
    }
  }
}
