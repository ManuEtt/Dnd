import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/services/backend_narrator.dart';

final _now = DateTime.utc(2026, 10, 13, 12);
const _token = 'test_session_payload.test_session_signature';

class _Request {
  const _Request(this.method, this.uri, this.token, this.body);
  final String method;
  final Uri uri;
  final String token;
  final Map<String, Object?>? body;
}

class _Transport implements BackendTransport {
  final requests = <_Request>[];
  Future<BackendResponse> Function(_Request)? handler;

  @override
  Future<BackendResponse> request({
    required String method,
    required Uri uri,
    required String bearerToken,
    Map<String, Object?>? body,
  }) async {
    final request = _Request(method, uri, bearerToken, body);
    requests.add(request);
    return handler == null ? _response(method) : await handler!(request);
  }
}

class _CancellableTransport extends _Transport
    implements CancellableBackendTransport {
  int cancellations = 0;
  bool throwOnCancel = false;

  @override
  void cancelPendingRequests() {
    ++cancellations;
    if (throwOnCancel) throw StateError('private cancellation failure $_token');
  }
}

BackendResponse _response(String method, {String provider = 'mock'}) =>
    BackendResponse(
      statusCode: 200,
      body: method == 'GET'
          ? {
              'scope': 'narration:read-only',
              'provider': provider,
              'expiresAt': _now
                  .add(const Duration(minutes: 5))
                  .toIso8601String(),
            }
          : {
              'text': 'Liora, die Lichtung wartet auf deine Entscheidung.',
              'provider': provider,
              'stateChanges': [],
            },
    );

Future<void> _connect(BackendNarrator narrator, {int limit = 20}) =>
    narrator.connect(
      url: 'https://example.test/api/',
      sessionToken: _token,
      requestLimit: limit,
    );

Future<BackendNarration?> _narrate(BackendNarrator narrator) =>
    narrator.narrate(
      campaignId: 'demo-123',
      playerName: 'Liora',
      action: 'Ich schaue mich um.',
      scene: 'Die Lichtung von Mooswacht.',
      outcome: 'Liora, die Lichtung ist still. Was möchtest du tun?',
      memories: ['Der Schlüssel bleibt im Inventar.'],
    );

void main() {
  test('default local mode sends no network request', () async {
    final transport = _Transport();
    final narrator = BackendNarrator(transport: transport, clock: () => _now);
    addTearDown(narrator.dispose);
    expect(narrator.enabled, isFalse);
    expect(await _narrate(narrator), isNull);
    expect(transport.requests, isEmpty);
  });

  test(
    'HTTPS URL credentials, query, fragment and insecure origins fail closed',
    () async {
      final transport = _Transport();
      final narrator = BackendNarrator(transport: transport, clock: () => _now);
      addTearDown(narrator.dispose);
      for (final url in [
        'http://example.test',
        'http://localhost:3000',
        'https://user:password@example.test',
        'https://@example.test',
        'https://example.test?token=secret',
        'https://example.test?',
        'https://example.test#secret',
        'https://example.test#',
        'not-a-url',
        'https:///missing-host',
      ]) {
        await narrator.connect(url: url, sessionToken: _token);
        expect(narrator.enabled, isFalse);
        expect(narrator.statusMessage, isNot(contains('password')));
        expect(narrator.statusMessage, isNot(contains('secret')));
      }
      expect(transport.requests, isEmpty);
    },
  );

  test(
    'client accepts only bounded two-part session tokens, never provider keys',
    () async {
      final transport = _Transport();
      final narrator = BackendNarrator(transport: transport, clock: () => _now);
      addTearDown(narrator.dispose);
      for (final token in [
        '',
        'sk-secret.signature',
        'one',
        'one.two.three',
        'a\nb',
        '${'a' * 2048}.b',
      ]) {
        await narrator.connect(
          url: 'https://example.test',
          sessionToken: token,
        );
        expect(narrator.enabled, isFalse);
        expect(
          narrator.statusMessage,
          isNot(contains(token.length > 20 ? token : 'sk-secret')),
        );
      }
      expect(transport.requests, isEmpty);
    },
  );

  test(
    'connect validates session without generating narration and preserves URL prefix',
    () async {
      final transport = _Transport();
      final narrator = BackendNarrator(transport: transport, clock: () => _now);
      addTearDown(narrator.dispose);
      await _connect(narrator);
      expect(narrator.enabled, isTrue);
      expect(narrator.connecting, isFalse);
      expect(narrator.provider, 'mock');
      expect(narrator.backendUrl, 'https://example.test/api');
      expect(narrator.requestsUsed, 0);
      expect(transport.requests.single.method, 'GET');
      expect(transport.requests.single.uri.path, '/api/v1/session');
      expect(transport.requests.single.token, _token);
      expect(transport.requests.single.body, isNull);
      final response = await _narrate(narrator);
      expect(response?.provider, 'mock');
      expect(response?.text, contains('Liora'));
      expect(transport.requests.last.uri.path, '/api/v1/narrate');
      expect(
        transport.requests.last.body?['outcome'],
        contains('Lichtung ist still'),
      );
      expect(transport.requests.last.body?['memories'], [
        'Der Schlüssel bleibt im Inventar.',
      ]);
      expect(narrator.requestsUsed, 1);
    },
  );

  test(
    'session scope, provider and expiration must be valid and at most 15 minutes',
    () async {
      for (final patch in [
        {'scope': 'campaign:write'},
        {'provider': 'untrusted'},
        {'expiresAt': null},
        {'expiresAt': 'tomorrow'},
        {'expiresAt': _now.toIso8601String()},
        {'expiresAt': _now.add(const Duration(minutes: 16)).toIso8601String()},
        {'expiresAt': '2026-10-13T12:05:00'},
      ]) {
        final transport = _Transport()
          ..handler = (request) async => BackendResponse(
            statusCode: 200,
            body: {...(_response('GET').body! as Map), ...patch},
          );
        final narrator = BackendNarrator(
          transport: transport,
          clock: () => _now,
        );
        addTearDown(narrator.dispose);
        await _connect(narrator);
        expect(narrator.enabled, isFalse);
        expect(await _narrate(narrator), isNull);
        expect(transport.requests.length, 1);
      }
    },
  );

  test(
    'OpenAI provider needs explicit cost opt-in on every connection',
    () async {
      final transport = _Transport()
        ..handler = (request) async =>
            _response(request.method, provider: 'openai');
      final narrator = BackendNarrator(transport: transport, clock: () => _now);
      addTearDown(narrator.dispose);
      await _connect(narrator);
      expect(narrator.enabled, isFalse);
      expect(narrator.statusMessage, contains('Kostenfreigabe'));
      expect(await _narrate(narrator), isNull);
      await narrator.connect(
        url: 'https://example.test',
        sessionToken: _token,
        allowPaidProvider: true,
      );
      expect(narrator.enabled, isTrue);
      expect((await _narrate(narrator))?.provider, 'openai');
      narrator.disconnect();
      expect(narrator.allowPaidProvider, isFalse);
      await _connect(narrator);
      expect(narrator.enabled, isFalse);
    },
  );

  test(
    'request cap validates bounds and counts attempted failures without retries',
    () async {
      final transport = _Transport();
      final narrator = BackendNarrator(transport: transport, clock: () => _now);
      addTearDown(narrator.dispose);
      for (final limit in [0, 101]) {
        await _connect(narrator, limit: limit);
        expect(narrator.enabled, isFalse);
      }
      expect(transport.requests, isEmpty);
      await _connect(narrator, limit: 1);
      transport.handler = (_) async =>
          throw StateError('private $_token details');
      expect(await _narrate(narrator), isNull);
      expect(narrator.requestsUsed, 1);
      expect(await _narrate(narrator), isNull);
      expect(transport.requests.length, 2);
      expect(narrator.statusMessage, contains('Anfragelimit'));
    },
  );

  test('expired session is cleared before any POST', () async {
    var now = _now;
    final transport = _Transport();
    final narrator = BackendNarrator(transport: transport, clock: () => now);
    addTearDown(narrator.dispose);
    await _connect(narrator);
    now = _now.add(const Duration(minutes: 5));
    expect(await _narrate(narrator), isNull);
    expect(narrator.enabled, isFalse);
    expect(narrator.provider, isNull);
    expect(transport.requests.length, 1);
  });

  test(
    '401 disconnects, rate/provider/redirect errors fall back safely',
    () async {
      for (final status in [401, 429, 502, 307]) {
        final transport = _Transport();
        final narrator = BackendNarrator(
          transport: transport,
          clock: () => _now,
        );
        addTearDown(narrator.dispose);
        await _connect(narrator);
        transport.handler = (_) async =>
            BackendResponse(statusCode: status, body: {'error': _token});
        expect(await _narrate(narrator), isNull);
        expect(narrator.enabled, status != 401);
        expect(narrator.statusMessage, isNot(contains(_token)));
        expect(transport.requests.length, 2);
      }
    },
  );

  test(
    'invalid text, provider changes and all nonempty stateChanges are rejected',
    () async {
      for (final patch in [
        {
          'stateChanges': [
            {'hp': 0},
          ],
        },
        {
          'stateChanges': ['anything'],
        },
        {
          'stateChanges': {'hp': 0},
        },
        {'stateChanges': null},
        {'provider': 'openai'},
        {'provider': 'unknown'},
        {'text': ''},
        {'text': '  '},
        {'text': 'x' * 4001},
        {'text': 42},
        {'text': _token},
      ]) {
        final transport = _Transport();
        final narrator = BackendNarrator(
          transport: transport,
          clock: () => _now,
        );
        addTearDown(narrator.dispose);
        await _connect(narrator);
        transport.handler = (_) async => BackendResponse(
          statusCode: 200,
          body: {...(_response('POST').body! as Map), ...patch},
        );
        expect(await _narrate(narrator), isNull);
        expect(narrator.statusMessage, contains('verworfen'));
      }
    },
  );

  test('invalid request context never leaves the device', () async {
    final transport = _Transport();
    final narrator = BackendNarrator(transport: transport, clock: () => _now);
    addTearDown(narrator.dispose);
    await _connect(narrator);
    expect(
      await narrator.narrate(
        campaignId: '../other',
        playerName: 'Liora',
        action: 'Handlung',
        scene: 'Szene',
        outcome: 'Ergebnis',
      ),
      isNull,
    );
    expect(
      await narrator.narrate(
        campaignId: 'demo',
        playerName: 'Liora',
        action: 'Handlung',
        scene: 'Szene',
        outcome: 'Ergebnis',
        memories: List.filled(21, 'Erinnerung'),
      ),
      isNull,
    );
    expect(narrator.requestsUsed, 0);
    expect(transport.requests.length, 1);
  });

  test(
    'transport exceptions never expose tokens or remote error details',
    () async {
      final transport = _Transport()
        ..handler = (_) async =>
            throw StateError('Bearer $_token private details');
      final narrator = BackendNarrator(transport: transport, clock: () => _now);
      addTearDown(narrator.dispose);
      await _connect(narrator);
      expect(narrator.enabled, isFalse);
      expect(narrator.statusMessage, isNot(contains(_token)));
      expect(narrator.statusMessage, isNot(contains('private details')));
      expect(narrator.toString(), isNot(contains(_token)));
    },
  );

  test(
    'timeout returns local fallback and consumes one attempt only',
    () async {
      final transport = _Transport();
      final narrator = BackendNarrator(
        transport: transport,
        clock: () => _now,
        timeout: const Duration(milliseconds: 20),
      );
      addTearDown(narrator.dispose);
      await _connect(narrator);
      transport.handler = (_) => Completer<BackendResponse>().future;
      expect(await _narrate(narrator), isNull);
      expect(narrator.requestsUsed, 1);
      expect(transport.requests.length, 2);
      expect(narrator.statusMessage, contains('zu lange'));
    },
  );

  test(
    'disconnect while connect is pending cannot restore credentials',
    () async {
      final pending = Completer<BackendResponse>();
      final transport = _Transport()..handler = (_) => pending.future;
      final narrator = BackendNarrator(transport: transport, clock: () => _now);
      addTearDown(narrator.dispose);
      final connecting = _connect(narrator);
      expect(narrator.connecting, isTrue);
      narrator.disconnect();
      await connecting.timeout(const Duration(milliseconds: 200));
      pending.complete(_response('GET'));
      await Future<void>.delayed(Duration.zero);
      expect(narrator.enabled, isFalse);
      expect(narrator.provider, isNull);
      expect(narrator.expiresAt, isNull);
      expect(narrator.backendUrl, 'https://example.test/api');
      expect(await _narrate(narrator), isNull);
      expect(transport.requests.length, 1);
    },
  );

  test(
    'expiration while narration is pending also clears the session',
    () async {
      var now = _now;
      final transport = _Transport();
      final narrator = BackendNarrator(transport: transport, clock: () => now);
      addTearDown(narrator.dispose);
      await _connect(narrator);
      final pending = Completer<BackendResponse>();
      transport.handler = (_) => pending.future;
      final narration = _narrate(narrator);
      now = _now.add(const Duration(minutes: 5));
      pending.complete(_response('POST'));
      expect(await narration, isNull);
      expect(narrator.enabled, isFalse);
      expect(narrator.expiresAt, isNull);
      expect(narrator.statusMessage, contains('abgelaufen'));
    },
  );

  test('disconnect/dispose during narration discards stale output', () async {
    for (final dispose in [false, true]) {
      final transport = _Transport();
      final narrator = BackendNarrator(transport: transport, clock: () => _now);
      await _connect(narrator);
      final pending = Completer<BackendResponse>();
      transport.handler = (_) => pending.future;
      final narration = _narrate(narrator);
      if (dispose) {
        narrator.dispose();
      } else {
        narrator.disconnect();
      }
      expect(
        await narration.timeout(const Duration(milliseconds: 200)),
        isNull,
      );
      pending.complete(_response('POST'));
      await Future<void>.delayed(Duration.zero);
      expect(narrator.enabled, isFalse);
      expect(narrator.expiresAt, isNull);
      expect(narrator.allowPaidProvider, isFalse);
      if (!dispose) narrator.dispose();
    }
  });

  test(
    'dispose unblocks pending connect and ignores a late transport error',
    () async {
      final pending = Completer<BackendResponse>();
      final transport = _Transport()..handler = (_) => pending.future;
      final narrator = BackendNarrator(transport: transport, clock: () => _now);
      final connecting = _connect(narrator);
      narrator.dispose();
      await connecting.timeout(const Duration(milliseconds: 200));
      pending.completeError(StateError('private $_token provider details'));
      await Future<void>.delayed(Duration.zero);
      expect(narrator.enabled, isFalse);
      expect(narrator.connecting, isFalse);
      expect(narrator.provider, isNull);
      expect(narrator.expiresAt, isNull);
      expect(narrator.toString(), isNot(contains(_token)));
    },
  );

  test(
    'new connection cancels old connect without affecting the new session',
    () async {
      final pending = Completer<BackendResponse>();
      final transport = _Transport()..handler = (_) => pending.future;
      final narrator = BackendNarrator(transport: transport, clock: () => _now);
      addTearDown(narrator.dispose);
      final first = _connect(narrator);
      transport.handler = (request) async => _response(request.method);
      await _connect(narrator);
      await first.timeout(const Duration(milliseconds: 200));
      expect(narrator.enabled, isTrue);
      pending.complete(_response('GET', provider: 'openai'));
      await Future<void>.delayed(Duration.zero);
      expect(narrator.provider, 'mock');
      expect(transport.requests.length, 2);
      expect((await _narrate(narrator))?.provider, 'mock');
    },
  );

  test(
    'optional cancellation cleanup runs and cannot block disconnect on failure',
    () async {
      for (final failCleanup in [false, true]) {
        final transport = _CancellableTransport();
        final narrator = BackendNarrator(
          transport: transport,
          clock: () => _now,
        );
        await _connect(narrator);
        final pending = Completer<BackendResponse>();
        transport.handler = (_) => pending.future;
        transport.throwOnCancel = failCleanup;
        final narration = _narrate(narrator);
        final cancellations = transport.cancellations;
        narrator.disconnect();
        expect(transport.cancellations, cancellations + 1);
        expect(
          await narration.timeout(const Duration(milliseconds: 200)),
          isNull,
        );
        expect(narrator.enabled, isFalse);
        expect(narrator.statusMessage, isNot(contains(_token)));
        pending.completeError(StateError('late $_token error'));
        await Future<void>.delayed(Duration.zero);
        narrator.dispose();
        expect(transport.cancellations, cancellations + 2);
      }
    },
  );

  test(
    'real HTTP cancellation closes pending clients and allows a fresh request',
    () async {
      for (final method in ['GET', 'POST']) {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        final arrived = Completer<void>();
        var holdResponse = true;
        server.listen((request) async {
          await request.drain<void>();
          if (holdResponse) {
            arrived.complete();
            return; // Deliberately never send headers for the cancelled request.
          }
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode(_response(request.method).body));
          await request.response.close();
        });
        final transport = HttpBackendTransport();
        try {
          final uri = Uri.parse('http://127.0.0.1:${server.port}/v1/session');
          final completion = transport
              .request(
                method: method,
                uri: uri,
                bearerToken: _token,
                body: method == 'POST' ? {'action': 'Test'} : null,
              )
              .then((_) => false, onError: (Object _) => true);
          await arrived.future.timeout(const Duration(seconds: 1));
          transport.cancelPendingRequests();
          expect(await completion.timeout(const Duration(seconds: 1)), isTrue);
          holdResponse = false;
          final fresh = await transport.request(
            method: 'GET',
            uri: uri,
            bearerToken: _token,
          );
          expect(fresh.statusCode, 200);
        } finally {
          transport.cancelPendingRequests();
          await server.close(force: true);
        }
      }
    },
  );

  test(
    'real HTTP transport exchanges JSON only on explicit loopback test mode',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final paths = <String>[];
      final bodies = <Map<String, dynamic>>[];
      server.listen((request) async {
        paths.add(request.uri.path);
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer $_token',
        );
        if (request.method == 'POST') {
          bodies.add(
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>,
          );
        }
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(_response(request.method).body));
        await request.response.close();
      });
      final narrator = BackendNarrator(
        clock: () => _now,
        allowInsecureLoopbackForTests: true,
      );
      addTearDown(narrator.dispose);
      await narrator.connect(
        url: 'http://127.0.0.1:${server.port}',
        sessionToken: _token,
      );
      expect(narrator.enabled, isTrue);
      expect((await _narrate(narrator))?.provider, 'mock');
      expect(paths, ['/v1/session', '/v1/narrate']);
      expect(bodies.single['outcome'], contains('Lichtung ist still'));
    },
  );

  test(
    'redirect transport never forwards the bearer to another server',
    () async {
      final target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final source = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => source.close(force: true));
      addTearDown(() => target.close(force: true));
      var redirectedRequests = 0;
      target.listen((request) async {
        ++redirectedRequests;
        await request.response.close();
      });
      source.listen((request) async {
        request.response.statusCode = 307;
        request.response.headers.set(
          HttpHeaders.locationHeader,
          'http://127.0.0.1:${target.port}/stolen',
        );
        await request.response.close();
      });
      final narrator = BackendNarrator(
        clock: () => _now,
        allowInsecureLoopbackForTests: true,
      );
      addTearDown(narrator.dispose);
      await narrator.connect(
        url: 'http://127.0.0.1:${source.port}',
        sessionToken: _token,
      );
      expect(narrator.enabled, isFalse);
      expect(narrator.statusMessage, contains('leitet weiter'));
      expect(redirectedRequests, 0);
    },
  );

  test(
    'HTTP transport rejects oversized and non-JSON responses safely',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      var oversized = true;
      server.listen((request) async {
        if (oversized) {
          request.response.headers.contentType = ContentType.json;
          final body = jsonEncode({'data': 'x' * 65536});
          request.response.contentLength = utf8.encode(body).length;
          request.response.write(body);
        } else {
          request.response.headers.contentType = ContentType.html;
          request.response.write('<html>private provider data</html>');
        }
        await request.response.close();
      });
      final narrator = BackendNarrator(
        clock: () => _now,
        allowInsecureLoopbackForTests: true,
      );
      addTearDown(narrator.dispose);
      for (var attempt = 0; attempt < 2; ++attempt) {
        await narrator.connect(
          url: 'http://127.0.0.1:${server.port}',
          sessionToken: _token,
        );
        expect(narrator.enabled, isFalse);
        expect(narrator.statusMessage, isNot(contains('private provider')));
        oversized = false;
      }
    },
  );
}
