import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tm_dashboard/models/feature_flags.dart';
import 'package:tm_dashboard/services/api_client.dart';
import 'package:tm_dashboard/services/feature_service.dart';

void main() {
  ApiClient clientReturning(http.Response Function(http.Request) handler) =>
      ApiClient(client: MockClient((r) async => handler(r)));

  setUp(Features.reset);

  group('FeatureFlags.fromJson', () {
    test('reads both flags', () {
      final f = FeatureFlags.fromJson({'trading': true, 'investing': true});
      expect(f.trading, isTrue);
      expect(f.investing, isTrue);
    });

    test('missing or non-boolean trading means off', () {
      expect(FeatureFlags.fromJson({}).trading, isFalse);
      expect(FeatureFlags.fromJson({'trading': 'true'}).trading, isFalse);
    });

    test('investing defaults to on', () {
      expect(FeatureFlags.fromJson({}).investing, isTrue);
    });
  });

  group('FeatureService.fetch', () {
    test('returns the server flags and calls /features', () async {
      Uri? called;
      final client = clientReturning((r) {
        called = r.url;
        return http.Response('{"trading":true,"investing":true}', 200);
      });
      final flags = await FeatureService.fetch(client: client);
      expect(flags.trading, isTrue);
      expect(called!.path, '/api/v1/features');
    });

    test('non-200 fails closed', () async {
      final client = clientReturning((_) => http.Response('{}', 500));
      expect(await FeatureService.fetch(client: client),
          FeatureFlags.investingOnly);
    });

    test('malformed body fails closed', () async {
      final client = clientReturning((_) => http.Response('[1,2]', 200));
      expect(await FeatureService.fetch(client: client),
          FeatureFlags.investingOnly);
    });

    test('network error fails closed', () async {
      final client = ApiClient(
        client: MockClient((_) async => throw http.ClientException('down')),
      );
      expect(await FeatureService.fetch(client: client),
          FeatureFlags.investingOnly);
    });
  });

  group('Features', () {
    test('starts investing-only', () {
      expect(Features.tradingEnabled, isFalse);
    });

    test('load publishes the flags', () async {
      final client = clientReturning(
        (_) => http.Response('{"trading":true,"investing":true}', 200),
      );
      await Features.load(client: client);
      expect(Features.tradingEnabled, isTrue);
    });
  });
}
