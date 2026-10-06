import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm_dashboard/screens/auth/auth_cubit.dart';
import 'package:tm_dashboard/screens/auth/auth_guard.dart';
import 'package:tm_dashboard/services/api_client.dart';
import 'package:tm_dashboard/services/auth_service.dart';

void main() {
  final now = DateTime.utc(2026, 10, 6);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  AuthService buildService(
    Future<http.Response> Function(http.Request) handler,
  ) {
    final api = ApiClient(client: MockClient(handler));
    addTearDown(api.close);
    return AuthService(api: api, now: () => now);
  }

  String loginBody() => jsonEncode({
    'token': 'tok',
    'expiresAt': now.add(const Duration(days: 14)).toIso8601String(),
  });

  group('AuthService', () {
    test('login stores the token and sends it on later requests', () async {
      final seen = <String?>[];
      final service = buildService((req) async {
        seen.add(req.headers['Authorization']);
        if (req.url.path.endsWith('/auth/login')) {
          expect(jsonDecode(req.body), {'password': 'pw'});
          return http.Response(loginBody(), 200);
        }
        return http.Response('{"status":"ok"}', 200);
      });

      await service.login('pw');
      expect(service.token, 'tok');

      await service.restore();
      expect(seen.last, 'Bearer tok');
      expect(seen.first, isNull); // login itself carries no token
    });

    test('maps wrong password, rate limit and unconfigured server', () async {
      for (final entry in {
        401: 'Incorrect password',
        429: 'Too many attempts. Try again later.',
        503: 'Login is not configured on the server',
      }.entries) {
        final service = buildService((_) async => http.Response('', entry.key));
        await expectLater(
          service.login('x'),
          throwsA(
            isA<AuthException>()
                .having((e) => e.statusCode, 'statusCode', entry.key)
                .having((e) => e.message, 'message', entry.value),
          ),
        );
        expect(service.token, isNull);
      }
    });

    test('restore drops a token the server rejects', () async {
      var reject = false;
      final service = buildService((req) async {
        if (req.url.path.endsWith('/auth/login')) {
          return http.Response(loginBody(), 200);
        }
        return http.Response('', reject ? 401 : 200);
      });
      await service.login('pw');

      reject = true;
      expect(await service.restore(), isFalse);
      expect(service.token, isNull);
      expect(
        (await SharedPreferences.getInstance()).getString('auth.token'),
        isNull,
      );
    });

    test(
      'restore discards an expired token without calling the server',
      () async {
        SharedPreferences.setMockInitialValues({
          'auth.token': 'old',
          'auth.expiresAt': now
              .subtract(const Duration(days: 1))
              .toIso8601String(),
        });
        var calls = 0;
        final service = buildService((_) async {
          calls++;
          return http.Response('', 200);
        });
        expect(await service.restore(), isFalse);
        expect(calls, 0);
      },
    );

    test(
      'restore keeps an unexpired token when the server is unreachable',
      () async {
        SharedPreferences.setMockInitialValues({
          'auth.token': 'tok',
          'auth.expiresAt': now.add(const Duration(days: 1)).toIso8601String(),
        });
        final service = buildService((_) async => throw Exception('offline'));
        expect(await service.restore(), isTrue);
        expect(service.token, 'tok');
      },
    );

    test('logout clears the token', () async {
      final service = buildService(
        (_) async => http.Response(loginBody(), 200),
      );
      await service.login('pw');
      await service.logout();
      expect(service.token, isNull);
    });
  });

  group('AuthCubit', () {
    test(
      'emits authenticated after login and unauthenticated after logout',
      () async {
        final service = buildService(
          (_) async => http.Response(loginBody(), 200),
        );
        final cubit = AuthCubit(service);
        addTearDown(cubit.close);

        expect(cubit.state, AuthStatus.unknown);
        await cubit.login('pw');
        expect(cubit.state, AuthStatus.authenticated);
        await cubit.logout();
        expect(cubit.state, AuthStatus.unauthenticated);
      },
    );

    test('a failed login leaves the state unchanged', () async {
      final service = buildService((_) async => http.Response('', 401));
      final cubit = AuthCubit(service);
      addTearDown(cubit.close);
      await expectLater(cubit.login('bad'), throwsA(isA<AuthException>()));
      expect(cubit.state, AuthStatus.unknown);
    });
  });

  group('authRedirect', () {
    test('sends signed-out users from /invest to login, remembering where', () {
      expect(
        authRedirect(AuthStatus.unauthenticated, Uri.parse('/invest')),
        '/login?from=%2Finvest',
      );
      expect(
        authRedirect(AuthStatus.unknown, Uri.parse('/invest/notes')),
        startsWith('/login'),
      );
    });

    test('leaves the existing trade-journal routes open', () {
      for (final path in ['/', '/trades', '/goals', '/investments']) {
        expect(
          authRedirect(AuthStatus.unauthenticated, Uri.parse(path)),
          isNull,
          reason: path,
        );
      }
    });

    test('signed-in users skip the login page', () {
      expect(
        authRedirect(AuthStatus.authenticated, Uri.parse('/login')),
        '/invest',
      );
      expect(
        authRedirect(
          AuthStatus.authenticated,
          Uri.parse('/login?from=%2Finvest%2Fnotes'),
        ),
        '/invest/notes',
      );
      expect(
        authRedirect(AuthStatus.authenticated, Uri.parse('/invest')),
        isNull,
      );
    });

    test('ignores an open-redirect style from parameter', () {
      expect(
        authRedirect(
          AuthStatus.authenticated,
          Uri.parse('/login?from=https%3A%2F%2Fevil.example'),
        ),
        '/invest',
      );
    });
  });
}
