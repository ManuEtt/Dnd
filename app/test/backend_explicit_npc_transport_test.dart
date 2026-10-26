import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/services/backend_narrator.dart';

final _now = DateTime.utc(2026, 10, 26, 12);
const _token = 'explicit_npc_test.session_signature';

class _Transport implements BackendTransport {
  _Transport({required this.supportsSelection});

  final bool supportsSelection;
  final requests = <Map<String, Object?>>[];

  @override
  Future<BackendResponse> request({
    required String method,
    required Uri uri,
    required String bearerToken,
    Map<String, Object?>? body,
  }) async {
    if (method == 'GET') {
      return BackendResponse(
        statusCode: 200,
        body: {
          'scope': 'narration:read-only',
          'provider': 'mock',
          'expiresAt': _now
              .add(const Duration(minutes: 5))
              .toIso8601String(),
          'capabilities': [
            'npc-identity-v1',
            if (supportsSelection) 'npc-selection-v1',
          ],
        },
      );
    }
    requests.add(body!);
    return const BackendResponse(
      statusCode: 200,
      body: {
        'provider': 'mock',
        'stateChanges': [],
        'turn': {
          'narration': 'Mira betrachtet die Karte.',
          'threadUpdates': [],
          'newThreads': [],
          'npcUpdates': [],
          'adventure': null,
        },
      },
    );
  }
}

Map<String, Object> _identity() => {
  'campaignId': 'choice-demo',
  'campaignRevision': 8,
  'npcId': 'mira-two',
  'npcName': 'Mira',
  'relationship': 'misstrauisch',
  'alive': true,
  'notes': [
    {
      'id': 'note-two',
      'npcId': 'mira-two',
      'relationship': 'misstrauisch',
      'note': 'Die zweite Mira bewacht das Stadttor.',
      'recordedAt': '2026-10-26T12:00:00.000Z',
    },
  ],
};

Future<void> _connect(BackendNarrator narrator) => narrator.connect(
  url: 'https://story.example.test',
  sessionToken: _token,
);

Future<Map<String, dynamic>?> _send(
  BackendNarrator narrator, {
  String? selectedNpcId,
  List<Map<String, Object>>? contexts,
}) => narrator.advanceStory(
  campaignId: 'choice-demo',
  heroName: 'Aria',
  action: 'Ich suche den Ring.',
  scene: 'Die Bibliothek',
  premise: 'Ein alter Schwur',
  goal: 'Die Stadt retten',
  secret: 'Das verborgene Siegel',
  threads: const [],
  npcs: const [
    {'id': 'mira-one', 'name': 'Mira', 'relationship': 'freundlich'},
    {'id': 'mira-two', 'name': 'Mira', 'relationship': 'misstrauisch'},
  ],
  memories: const [],
  recentActions: const [],
  campaignRevision: 8,
  npcContexts: contexts ?? [_identity()],
  selectedNpcId: selectedNpcId,
);

void main() {
  test('explicit selection is sent only after separate capability negotiation', () async {
    final transport = _Transport(supportsSelection: true);
    final narrator = BackendNarrator(transport: transport, clock: () => _now);
    addTearDown(narrator.dispose);
    await _connect(narrator);
    expect(narrator.enabled, isTrue);
    expect(narrator.supportsNpcIdentityContexts, isTrue);
    expect(narrator.supportsExplicitNpcSelection, isTrue);

    final result = await _send(narrator, selectedNpcId: 'mira-two');
    expect(result?['narration'], contains('Karte'));
    expect(transport.requests, hasLength(1));
    expect(transport.requests.single['selectedNpcId'], 'mira-two');
    expect(transport.requests.single['campaignRevision'], 8);
    final contexts = transport.requests.single['npcContexts'] as List;
    expect((contexts.single as Map)['npcId'], 'mira-two');
    expect(narrator.requestsUsed, 1);
  });

  test('older identity-only server receives no unsupported selection', () async {
    final transport = _Transport(supportsSelection: false);
    final narrator = BackendNarrator(transport: transport, clock: () => _now);
    addTearDown(narrator.dispose);
    await _connect(narrator);
    expect(narrator.supportsNpcIdentityContexts, isTrue);
    expect(narrator.supportsExplicitNpcSelection, isFalse);

    expect(
      () => _send(narrator, selectedNpcId: 'mira-two'),
      throwsFormatException,
    );
    expect(transport.requests, isEmpty);
    expect(narrator.requestsUsed, 0);

    final legacy = await _send(narrator);
    expect(legacy, isNotNull);
    expect(transport.requests, hasLength(1));
    expect(transport.requests.single.containsKey('selectedNpcId'), isFalse);
  });

  test('unknown, mismatched and ambiguous ID selections fail before network', () async {
    final transport = _Transport(supportsSelection: true);
    final narrator = BackendNarrator(transport: transport, clock: () => _now);
    addTearDown(narrator.dispose);
    await _connect(narrator);

    for (final invalid in ['', 'mira-one', '../mira-two', 'ghost']) {
      expect(() => _send(narrator, selectedNpcId: invalid), throwsFormatException);
    }
    expect(
      () => _send(narrator, selectedNpcId: 'mira-two', contexts: []),
      throwsFormatException,
    );
    expect(
      () => _send(
        narrator,
        selectedNpcId: 'mira-two',
        contexts: [_identity(), _identity()],
      ),
      throwsFormatException,
    );
    expect(transport.requests, isEmpty);
    expect(narrator.requestsUsed, 0);
  });

  test('disconnect revokes negotiated selection capability', () async {
    final transport = _Transport(supportsSelection: true);
    final narrator = BackendNarrator(transport: transport, clock: () => _now);
    addTearDown(narrator.dispose);
    await _connect(narrator);
    expect(narrator.supportsExplicitNpcSelection, isTrue);
    narrator.disconnect();
    expect(narrator.supportsNpcIdentityContexts, isFalse);
    expect(narrator.supportsExplicitNpcSelection, isFalse);
  });
}
