import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tm_dashboard/services/api_client.dart';

void main() {
  final url = Uri.parse('http://localhost/api/v1/trade');

  test(
    'deduplicates concurrent reads and expires from completion time',
    () async {
      var calls = 0;
      var now = DateTime(2026);
      final result = Completer<http.Response>();
      final api = ApiClient(
        now: () => now,
        client: MockClient((_) {
          calls++;
          return result.future;
        }),
      );
      addTearDown(api.close);
      final first = api.get(url);
      final second = api.get(url);
      result.complete(http.Response('[]', 200));
      await Future.wait([first, second]);
      await api.get(url);
      expect(calls, 1);
      now = now.add(const Duration(seconds: 30));
      await api.get(url);
      expect(calls, 2);
    },
  );

  test('keys searches by body, URL and headers', () async {
    var calls = 0;
    final api = ApiClient(
      client: MockClient((_) async {
        calls++;
        return http.Response('{"status":"success","data":[]}', 200);
      }),
    );
    addTearDown(api.close);
    for (var i = 0; i < 2; i++) {
      await api.search(url, body: '{"page":0}');
      await api.search(url, body: '{"page":1}');
      await api.get(url.replace(query: 'weeks=8'));
      await api.get(url, headers: {'Authorization': 'account-a'});
      await api.get(url, headers: {'Authorization': 'account-b'});
    }
    expect(calls, 5);
  });

  test('writes are never cached and invalidate related resources', () async {
    var reads = 0;
    var writes = 0;
    final api = ApiClient(
      client: MockClient((r) async {
        if (r.method == 'GET') {
          reads++;
        } else {
          writes++;
        }
        return http.Response('[]', 200);
      }),
    );
    addTearDown(api.close);
    final capital = url.replace(path: '/api/v1/capital');
    await api.get(capital);
    for (final write in [api.post, api.put, api.patch, api.delete]) {
      await write(url);
      await api.get(capital);
    }
    await api.post(url);
    expect(reads, 5);
    expect(writes, 5);
  });

  test('failed writes retain cache; failed reads can be retried', () async {
    var calls = 0;
    var status = 200;
    final api = ApiClient(
      client: MockClient((_) async {
        calls++;
        return http.Response('[]', status);
      }),
    );
    addTearDown(api.close);
    await api.get(url);
    status = 500;
    await api.post(url);
    await api.get(url);
    expect(calls, 2);
    api.clear();
    await api.get(url);
    await api.get(url);
    expect(calls, 4);
  });

  test('malformed JSON, error envelopes and no-store are not cached', () async {
    for (final response in [
      http.Response('invalid', 200),

      http.Response('[]', 200, headers: {'cache-control': 'no-store'}),
    ]) {
      var calls = 0;
      final api = ApiClient(
        client: MockClient((_) async {
          calls++;
          return response;
        }),
      );
      await api.get(url);
      await api.get(url);
      expect(calls, 2);
      api.close();
    }
  });

  test(
    'search errors retry while domain status fields are cacheable',
    () async {
      var calls = 0;
      final api = ApiClient(
        client: MockClient((_) async {
          calls++;
          return http.Response('{"status":"ACTIVE"}', 200);
        }),
      );
      addTearDown(api.close);
      await api.get(url);
      await api.get(url);
      expect(calls, 1);
      await api.search(url);
      await api.search(url);
      expect(calls, 3);
    },
  );

  test('network errors do not leave a rejected pending entry', () async {
    var calls = 0;
    final api = ApiClient(
      client: MockClient((_) async {
        if (++calls == 1) throw http.ClientException('offline');
        return http.Response('[]', 200);
      }),
    );
    addTearDown(api.close);
    await expectLater(api.get(url), throwsA(isA<http.ClientException>()));
    await api.get(url);
    expect(calls, 2);
  });

  test(
    'pre-write reads cannot refill cache or remove newer pending reads',
    () async {
      final old = Completer<http.Response>();
      final fresh = Completer<http.Response>();
      var reads = 0;
      final api = ApiClient(
        client: MockClient((r) {
          if (r.method != 'GET') return Future.value(http.Response('{}', 200));
          return ++reads == 1 ? old.future : fresh.future;
        }),
      );
      addTearDown(api.close);
      final before = api.get(url);
      await api.post(url);
      final after = api.get(url);
      old.complete(http.Response('[1]', 200));
      await before;
      final joined = api.get(url);
      fresh.complete(http.Response('[2]', 200));
      expect((await after).body, '[2]');
      expect((await joined).body, '[2]');
      expect((await api.get(url)).body, '[2]');
      expect(reads, 2);
    },
  );

  test('refresh bypasses a fresh cached response', () async {
    var calls = 0;
    final api = ApiClient(
      client: MockClient((_) async => http.Response('[${++calls}]', 200)),
    );
    addTearDown(api.close);
    await api.get(url);
    expect((await api.refresh(() => api.get(url))).body, '[2]');
  });

  test('LRU entry and byte limits evict older responses', () async {
    for (final bytes in [4, 1024]) {
      var calls = 0;
      final api = ApiClient(
        maxEntries: 2,
        maxBytes: bytes,
        client: MockClient((_) async {
          calls++;
          return http.Response('[]', 200);
        }),
      );
      final b = url.replace(query: 'page=1');
      final c = url.replace(query: 'page=2');
      await api.get(url);
      await api.get(b);
      await api.get(url); // Touch A so B is evicted.
      await api.get(c);
      await api.get(url);
      expect(calls, 3);
      await api.get(b);
      expect(calls, 4);
      api.close();
    }
  });

  test('oversized responses are returned without being retained', () async {
    var calls = 0;
    final api = ApiClient(
      maxBytes: 1,
      client: MockClient((_) async {
        calls++;
        return http.Response('[]', 200);
      }),
    );
    addTearDown(api.close);
    await api.get(url);
    await api.get(url);
    expect(calls, 2);
  });

  test('static data uses a longer TTL but still expires', () async {
    var now = DateTime(2026);
    var calls = 0;
    final api = ApiClient(
      now: () => now,
      client: MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      }),
    );
    addTearDown(api.close);
    final lookup = url.replace(path: '/api/v1/staticData');
    await api.get(lookup);
    now = now.add(const Duration(minutes: 1));
    await api.get(lookup);
    expect(calls, 1);
    now = now.add(const Duration(minutes: 30));
    await api.get(lookup);
    expect(calls, 2);
  });
}
