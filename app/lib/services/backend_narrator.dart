import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Optional narration only. Credentials remain in memory and never enter saves.
class BackendNarration {
  const BackendNarration({required this.text, required this.provider});

  final String text;
  final String provider;
}

class BackendResponse {
  const BackendResponse({required this.statusCode, required this.body});

  final int statusCode;
  final Object? body;
}

/// Injectable boundary; production requests keep TLS verification enabled.
abstract class BackendTransport {
  Future<BackendResponse> request({
    required String method,
    required Uri uri,
    required String bearerToken,
    Map<String, Object?>? body,
  });
}

/// Optional transport cleanup. Existing injected transports need not implement it.
abstract class CancellableBackendTransport implements BackendTransport {
  void cancelPendingRequests();
}

class HttpBackendTransport implements CancellableBackendTransport {
  HttpBackendTransport({this.timeout = const Duration(seconds: 25)});

  final Duration timeout;
  static const _maxResponseBytes = 65536;
  final _pendingClients = <HttpClient>{};

  @override
  void cancelPendingRequests() {
    final clients = _pendingClients.toList();
    _pendingClients.clear();
    for (final client in clients) {
      client.close(force: true);
    }
  }

  @override
  Future<BackendResponse> request({
    required String method,
    required Uri uri,
    required String bearerToken,
    Map<String, Object?>? body,
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    _pendingClients.add(client);
    try {
      return await (() async {
        final request = await client.openUrl(method, uri);
        // Bearer credentials must never follow redirects to another server.
        request.followRedirects = false;
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $bearerToken',
        );
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        if (body != null) {
          request.headers.contentType = ContentType.json;
          request.write(jsonEncode(body));
        }
        final response = await request.close();
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return BackendResponse(statusCode: response.statusCode, body: null);
        }
        if (response.headers.contentType?.mimeType != 'application/json' ||
            response.contentLength > _maxResponseBytes) {
          throw const FormatException('invalid_backend_response');
        }
        final bytes = <int>[];
        await for (final chunk in response) {
          if (bytes.length + chunk.length > _maxResponseBytes) {
            throw const FormatException('backend_response_too_large');
          }
          bytes.addAll(chunk);
        }
        return BackendResponse(
          statusCode: response.statusCode,
          body: jsonDecode(utf8.decode(bytes)),
        );
      })().timeout(timeout);
    } finally {
      _pendingClients.remove(client);
      client.close(force: true);
    }
  }
}

class BackendNarrator extends ChangeNotifier {
  BackendNarrator({
    BackendTransport? transport,
    DateTime Function()? clock,
    this.allowInsecureLoopbackForTests = false,
    this.timeout = const Duration(seconds: 25),
  }) : _transport = transport ?? HttpBackendTransport(timeout: timeout),
       _clock = clock ?? DateTime.now;

  final BackendTransport _transport;
  final DateTime Function() _clock;
  final bool allowInsecureLoopbackForTests;
  final Duration timeout;

  String backendUrl = '';
  bool enabled = false;
  bool connecting = false;
  String? statusMessage;
  String? provider;
  DateTime? expiresAt;
  int requestLimit = 20;
  int requestsUsed = 0;
  bool allowPaidProvider = false;

  String? _sessionToken;
  String? _authorizedProvider;
  Uri? _baseUri;
  int _generation = 0;
  bool _disposed = false;
  Completer<void> _pendingCancellation = Completer<void>();

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void _clearSession() {
    _sessionToken = null;
    _authorizedProvider = null;
    _baseUri = null;
    enabled = false;
    connecting = false;
    provider = null;
    expiresAt = null;
    requestsUsed = 0;
    allowPaidProvider = false;
  }

  bool _current(int generation) => !_disposed && generation == _generation;

  void _cancelPending() {
    final cancellation = _pendingCancellation;
    _pendingCancellation = Completer<void>();
    if (!cancellation.isCompleted) cancellation.complete();
    final transport = _transport;
    if (transport is CancellableBackendTransport) {
      try {
        transport.cancelPendingRequests();
      } catch (_) {
        // Cancellation must unblock local play even if optional cleanup fails.
      }
    }
  }

  Future<BackendResponse?> _request({
    required int generation,
    required String method,
    required Uri uri,
    required String bearerToken,
    Map<String, Object?>? body,
  }) async {
    if (!_current(generation)) return null;
    final cancelled = _pendingCancellation.future;
    // Future.any also observes late transport errors after cancellation. Neither
    // delayed responses nor a failing transport can reactivate the old session.
    return Future.any<BackendResponse?>([
      _transport.request(
        method: method,
        uri: uri,
        bearerToken: bearerToken,
        body: body,
      ),
      cancelled.then<BackendResponse?>((_) => null),
    ]).timeout(timeout);
  }

  Uri? _validateUrl(String input) {
    if (input.length > 2048) return null;
    // Dart normalizes an empty user-info marker away; inspect it before parsing.
    if (RegExp(r'^[A-Za-z][A-Za-z0-9+.-]*://[^/?#]*@').hasMatch(input.trim())) {
      return null;
    }
    final uri = Uri.tryParse(input.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.authority.contains('@') ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }
    final loopback = ['127.0.0.1', '::1', 'localhost'].contains(uri.host);
    if (uri.scheme != 'https' &&
        !(allowInsecureLoopbackForTests && uri.scheme == 'http' && loopback)) {
      return null;
    }
    return uri.replace(path: uri.path.replaceFirst(RegExp(r'/+$'), ''));
  }

  Uri _endpoint(Uri base, String path) =>
      base.replace(path: '${base.path}$path');

  String _failure(int status) {
    if (status == 401) {
      return 'Die Backend-Sitzung ist ungültig oder abgelaufen. Bitte erneut verbinden. Der lokale Spielleiter bleibt verfügbar.';
    }
    if (status == 429) {
      return 'Das Backend-Anfragelimit ist erreicht. Der lokale Spielleiter übernimmt.';
    }
    if (status >= 300 && status < 400) {
      return 'Die Backend-Adresse leitet weiter. Verwende die direkte HTTPS-Adresse. Der lokale Spielleiter bleibt verfügbar.';
    }
    return 'Der Backend-Spielleiter ist nicht verfügbar. Der lokale Spielleiter übernimmt.';
  }

  Future<void> connect({
    required String url,
    required String sessionToken,
    bool allowPaidProvider = false,
    int requestLimit = 20,
  }) async {
    if (_disposed) return;
    final generation = ++_generation;
    _clearSession();
    _cancelPending();
    statusMessage = null;
    final uri = _validateUrl(url);
    final token = sessionToken.trim();
    if (uri == null) {
      statusMessage =
          'Verwende eine HTTPS-Backend-Adresse ohne Zugangsdaten, Abfrageparameter oder Fragment.';
      _changed();
      return;
    }
    backendUrl = uri.toString();
    if (token.length > 2048 ||
        token.startsWith('sk-') ||
        !RegExp(r'^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$').hasMatch(token)) {
      statusMessage =
          'Gib ausschließlich einen kurzlebigen Backend-Sitzungstoken ein. Anbieter-API-Schlüssel werden nicht akzeptiert.';
      _changed();
      return;
    }
    if (requestLimit < 1 || requestLimit > 100) {
      statusMessage = 'Das lokale Anfragelimit muss zwischen 1 und 100 liegen.';
      _changed();
      return;
    }
    this.requestLimit = requestLimit;
    connecting = true;
    _changed();
    try {
      final response = await _request(
        generation: generation,
        method: 'GET',
        uri: _endpoint(uri, '/v1/session'),
        bearerToken: token,
      );
      if (!_current(generation) || response == null) return;
      if (response.statusCode != 200) {
        statusMessage = _failure(response.statusCode);
        return;
      }
      final body = response.body;
      if (body is! Map ||
          body['scope'] != 'narration:read-only' ||
          !['mock', 'openai'].contains(body['provider']) ||
          body['expiresAt'] is! String) {
        statusMessage =
            'Das Backend hat keine gültige Erzähl-Sitzung bestätigt. Der lokale Spielleiter bleibt verfügbar.';
        return;
      }
      final rawExpiry = body['expiresAt'] as String;
      final expiry = DateTime.tryParse(rawExpiry);
      final now = _clock();
      if (expiry == null ||
          !RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(rawExpiry) ||
          !expiry.isAfter(now) ||
          expiry.difference(now) > const Duration(minutes: 15)) {
        statusMessage =
            'Die Backend-Sitzung ist abgelaufen oder nicht ausreichend kurzlebig. Bitte einen neuen Sitzungstoken verwenden.';
        return;
      }
      if (body['provider'] == 'openai' && !allowPaidProvider) {
        statusMessage =
            'Dieses Backend verwendet einen kostenpflichtigen Anbieter. Aktiviere die ausdrückliche Kostenfreigabe, um dich zu verbinden.';
        return;
      }
      _sessionToken = token;
      _baseUri = uri;
      _authorizedProvider = body['provider'] as String;
      provider = _authorizedProvider;
      expiresAt = expiry;
      this.allowPaidProvider = allowPaidProvider;
      enabled = true;
      statusMessage =
          'Backend verbunden. Es erhält nur Erzählkontext und darf keine Spielwerte verändern.';
    } catch (_) {
      if (_current(generation)) {
        statusMessage =
            'Das Backend konnte nicht sicher erreicht werden. Prüfe die Adresse und Verbindung. Der lokale Spielleiter bleibt verfügbar.';
      }
    } finally {
      if (_current(generation)) {
        connecting = false;
        _changed();
      }
    }
  }

  void disconnect() {
    if (_disposed) return;
    ++_generation;
    _clearSession();
    _cancelPending();
    statusMessage = 'Backend getrennt. Der lokale Spielleiter ist aktiv.';
    _changed();
  }

  Future<BackendNarration?> narrate({
    required String campaignId,
    required String playerName,
    required String action,
    required String scene,
    required String outcome,
    List<String> memories = const [],
  }) async {
    if (_disposed || !enabled || _sessionToken == null || _baseUri == null) {
      return null;
    }
    if (expiresAt == null || !expiresAt!.isAfter(_clock())) {
      disconnect();
      statusMessage = _failure(401);
      _changed();
      return null;
    }
    if (requestsUsed >= requestLimit) {
      statusMessage =
          'Das lokale Anfragelimit dieser Verbindung ist erreicht. Der lokale Spielleiter übernimmt.';
      _changed();
      return null;
    }
    bool validText(String value, int maximum) =>
        value.trim().isNotEmpty && value.length <= maximum;
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(campaignId) ||
        !validText(playerName, 80) ||
        !validText(action, 2000) ||
        !validText(scene, 4000) ||
        !validText(outcome, 4000) ||
        memories.length > 20 ||
        memories.any((value) => !validText(value, 400))) {
      statusMessage =
          'Der Erzählkontext ist zu groß oder unvollständig. Der lokale Spielleiter übernimmt.';
      _changed();
      return null;
    }
    final generation = _generation;
    ++requestsUsed; // Count every attempt, even timeout/error. Never retry silently.
    _changed();
    if (!_current(generation)) return null;
    try {
      final response = await _request(
        generation: generation,
        method: 'POST',
        uri: _endpoint(_baseUri!, '/v1/narrate'),
        bearerToken: _sessionToken!,
        body: {
          'campaignId': campaignId,
          'playerName': playerName,
          'action': action,
          'scene': scene,
          'outcome': outcome,
          'memories': List<String>.of(memories),
        },
      );
      if (!_current(generation) || response == null) return null;
      if (expiresAt == null || !expiresAt!.isAfter(_clock())) {
        disconnect();
        statusMessage = _failure(401);
        _changed();
        return null;
      }
      if (response.statusCode != 200) {
        if (response.statusCode == 401) {
          ++_generation;
          _clearSession();
          _cancelPending();
        }
        statusMessage = _failure(response.statusCode);
        _changed();
        return null;
      }
      final body = response.body;
      if (body is! Map ||
          body['provider'] != _authorizedProvider ||
          body['stateChanges'] is! List ||
          (body['stateChanges'] as List).isNotEmpty ||
          body['text'] is! String ||
          !validText(body['text'] as String, 4000) ||
          (body['text'] as String).contains(_sessionToken!)) {
        statusMessage =
            'Eine unzulässige Backend-Antwort wurde verworfen. Der lokale Spielleiter übernimmt.';
        _changed();
        return null;
      }
      statusMessage =
          'Erzählung vom Backend empfangen. Spielregeln und Speicher bleiben lokal.';
      _changed();
      return BackendNarration(
        text: (body['text'] as String).trim(),
        provider: _authorizedProvider!,
      );
    } catch (_) {
      if (_current(generation)) {
        statusMessage =
            'Die Backend-Erzählung ist ausgefallen oder hat zu lange gedauert. Der lokale Spielleiter übernimmt.';
        _changed();
      }
      return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    _clearSession();
    _cancelPending();
    super.dispose();
  }
}
