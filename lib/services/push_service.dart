import 'push_service_stub.dart'
    if (dart.library.html) 'push_service_web.dart';

abstract class PushService {
  Future<bool> isSupported();
  Future<String> permission();
  Future<bool> isSubscribed();
  Future<bool> subscribe();
  Future<bool> unsubscribe();
}

final pushService = PushServiceImpl();
