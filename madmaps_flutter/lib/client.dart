import 'package:flutter/foundation.dart';
import 'package:madmaps_client/madmaps_client.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

/// Edit this getter and hot reload to reconnect the running app.
String get serverUrl => 'http://10.141.35.17:8080/';

Client? _client;
String? _connectedUrl;
final clientRevision = ValueNotifier<int>(0);
Client get client => _client ?? (throw StateError('Client is not initialized'));

Future<void> initializeClient() async {
  reconnectClient();
}

/// Top-level initializers survive hot reload; a getter deliberately does not.
bool reconnectClient() {
  final url = serverUrl;
  if (_client != null && _connectedUrl == url) return false;
  final previous = _client;
  _client = Client(url)..connectivityMonitor = FlutterConnectivityMonitor();
  _connectedUrl = url;
  clientRevision.value++;
  previous?.close();
  return true;
}
