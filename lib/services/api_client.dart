import 'dart:collection';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Shared transport for every backend service. Only GETs and explicitly
/// identified read-only searches are cached; writes are always sent.
class ApiClient {
  static final ApiClient shared = ApiClient();

  ApiClient({
    http.Client? client,
    DateTime Function()? now,
    this.ttl = const Duration(seconds: 30),
    this.staticTtl = const Duration(minutes: 30),
    this.maxEntries = 128,
    this.maxBytes = 8 * 1024 * 1024,
  }) : _client = client ?? http.Client(),
       _now = now ?? DateTime.now;

  final http.Client _client;
  final DateTime Function() _now;
  final Duration ttl;
  final Duration staticTtl;
  final int maxEntries;
  final int maxBytes;
  final _cache = <String, _CacheEntry>{};
  final _pending = <String, Future<http.Response>>{};
  int _bytes = 0;
  int _generation = 0;

  /// Also detaches pending reads so pre-write responses cannot refill the cache.
  /// Clear on account/server changes as well as explicit refresh actions.
  void clear() {
    _generation++;
    _cache.clear();
    _pending.clear();
    _bytes = 0;
  }

  Future<T> refresh<T>(Future<T> Function() load) {
    clear();
    return load();
  }

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
      _read('GET', url, headers: headers);

  Future<http.Response> search(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) => _read('POST', url, headers: headers, body: body);

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) => _write('POST', url, headers: headers, body: body);

  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) => _write('PUT', url, headers: headers, body: body);

  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) => _write('PATCH', url, headers: headers, body: body);

  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) => _write('DELETE', url, headers: headers, body: body);

  Future<http.Response> _read(
    String method,
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    final sortedHeaders = SplayTreeMap<String, String>.from(headers ?? {});
    final key = jsonEncode([method, url.toString(), sortedHeaders, body]);
    final cached = _cache.remove(key);
    if (cached != null) {
      if (_now().isBefore(cached.expiresAt)) {
        _cache[key] = cached; // Move cache hits to the MRU end.
        return Future.value(cached.response);
      }
      _bytes -= cached.response.bodyBytes.length;
    }
    final pending = _pending[key];
    if (pending != null) return pending;

    final generation = _generation;
    late final Future<http.Response> request;
    request = (() async {
      try {
        final response = await _send(method, url, headers: headers, body: body);
        if (generation == _generation &&
            _cacheable(response, isSearch: method == 'POST')) {
          final lifetime = url.path.endsWith('/staticData') ? staticTtl : ttl;
          final bytes = response.bodyBytes.length;
          if (maxEntries > 0 && bytes <= maxBytes) {
            while (_cache.isNotEmpty &&
                (_cache.length >= maxEntries || _bytes + bytes > maxBytes)) {
              _bytes -= _cache
                  .remove(_cache.keys.first)!
                  .response
                  .bodyBytes
                  .length;
            }
            _cache[key] = _CacheEntry(response, _now().add(lifetime));
            _bytes += bytes;
          }
        }
        return response;
      } finally {
        if (identical(_pending[key], request)) _pending.remove(key);
      }
    })();
    _pending[key] = request;
    return request;
  }

  bool _cacheable(http.Response response, {required bool isSearch}) {
    if (response.statusCode != 200) return false;
    if (response.headers['cache-control']?.contains('no-store') ?? false) {
      return false;
    }
    try {
      final json = jsonDecode(response.body);
      // Search endpoints can report application errors in an HTTP 200 envelope.
      return !isSearch || (json is Map && json['status'] == 'success');
    } on FormatException {
      return false;
    }
  }

  Future<http.Response> _write(
    String method,
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final response = await _send(method, url, headers: headers, body: body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Conservative cross-resource invalidation: trades affect capital,
      // strategies affect nested trades, planner edits affect all summaries.
      clear();
    }
    return response;
  }

  Future<http.Response> _send(
    String method,
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final request = http.Request(method, url);
    if (headers != null) request.headers.addAll(headers);
    if (body is String) {
      request.body = body;
    } else if (body is List<int>) {
      request.bodyBytes = body;
    } else if (body is Map<String, String>) {
      request.bodyFields = body;
    } else if (body != null) {
      throw ArgumentError.value(body, 'body', 'Unsupported request body');
    }
    // One reusable client avoids opening a new connection for every request.
    return http.Response.fromStream(await _client.send(request));
  }

  void close() {
    clear();
    _client.close();
  }
}

class _CacheEntry {
  const _CacheEntry(this.response, this.expiresAt);
  final http.Response response;
  final DateTime expiresAt;
}
