class PushConfig {
  static const vapidPublicKey =
      String.fromEnvironment('VAPID_PUBLIC_KEY', defaultValue: '');
}
