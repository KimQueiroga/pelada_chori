import 'push_service.dart';

class PushServiceImpl implements PushService {
  @override
  Future<bool> isSupported() async => false;

  @override
  Future<String> permission() async => 'unsupported';

  @override
  Future<bool> isSubscribed() async => false;

  @override
  Future<bool> subscribe() async => false;

  @override
  Future<bool> unsubscribe() async => false;
}
