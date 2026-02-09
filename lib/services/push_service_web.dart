import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../config/push_config.dart';
import 'auth_service.dart';
import 'push_service.dart';

class PushServiceImpl implements PushService {
  bool _hasSupport() {
    return html.window.navigator.serviceWorker != null &&
        html.Notification.supported;
  }

  @override
  Future<bool> isSupported() async => _hasSupport();

  @override
  Future<String> permission() async {
    if (!_hasSupport()) return 'unsupported';
    return html.Notification.permission ?? 'default';
  }

  @override
  Future<bool> isSubscribed() async {
    if (!_hasSupport()) return false;
    final reg = await html.window.navigator.serviceWorker?.ready;
    if (reg == null) return false;
    final pushManager = reg.pushManager;
    if (pushManager == null) return false;
    final sub = await pushManager.getSubscription();
    return sub != null;
  }

  @override
  Future<bool> subscribe() async {
    if (!_hasSupport()) return false;
    if (PushConfig.vapidPublicKey.isEmpty) return false;

    final perm = await html.Notification.requestPermission();
    if (perm != 'granted') return false;

    final reg = await html.window.navigator.serviceWorker?.ready;
    if (reg == null) return false;

    final pushManager = reg.pushManager;
    if (pushManager == null) return false;

    var sub = await pushManager.getSubscription();
    if (sub == null) {
      final options = js_util.jsify({
        'userVisibleOnly': true,
        'applicationServerKey': _decodeVapidKey(PushConfig.vapidPublicKey),
      });

      sub = await js_util.promiseToFuture<html.PushSubscription>(
        js_util.callMethod(pushManager, 'subscribe', [options]),
      );
    }

    return _sendSubscription(sub);
  }

  @override
  Future<bool> unsubscribe() async {
    if (!_hasSupport()) return false;
    final reg = await html.window.navigator.serviceWorker?.ready;
    if (reg == null) return false;
    final pushManager = reg.pushManager;
    if (pushManager == null) return false;
    final sub = await pushManager.getSubscription();
    if (sub == null) return true;

    final endpoint = sub.endpoint;
    await sub.unsubscribe();

    final still = await pushManager.getSubscription();
    final removed = still == null;
    if (!removed) return false;

    if (endpoint == null || endpoint.isEmpty) return true;
    await _removeSubscription(endpoint);
    return true;
  }

  Future<bool> _sendSubscription(html.PushSubscription sub) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/push/subscribe');

    final payload = {
      'endpoint': sub.endpoint,
      'keys': {
        'p256dh': _encodeKey(sub.getKey('p256dh')),
        'auth': _encodeKey(sub.getKey('auth')),
      },
      'content_encoding': 'aesgcm',
      'user_agent': html.window.navigator.userAgent,
    };

    final resp = await AuthService.sendWithRefresh(
      (token) => http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      ),
    );

    return resp.statusCode == 200;
  }

  Future<bool> _removeSubscription(String endpoint) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/push/unsubscribe');

    final resp = await AuthService.sendWithRefresh(
      (token) => http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'endpoint': endpoint}),
      ),
    );

    return resp.statusCode == 200;
  }

  Uint8List _decodeVapidKey(String base64String) {
    var input = base64String.replaceAll('-', '+').replaceAll('_', '/');
    switch (input.length % 4) {
      case 2:
        input += '==';
        break;
      case 3:
        input += '=';
        break;
    }
    return Uint8List.fromList(base64Decode(input));
  }

  String _encodeKey(Object? key) {
    if (key == null) return '';
    if (key is ByteBuffer) {
      return base64UrlEncode(Uint8List.view(key));
    }
    if (key is Uint8List) {
      return base64UrlEncode(key);
    }
    return '';
  }
}
