import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/core/error/app_exception.dart';
import 'package:rewardsapp/core/network/auth_interceptor.dart';

import '../../helpers/fake_api.dart';

const _stored = {'api_access_token': 'old-access', 'api_refresh_token': 'old-refresh'};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthInterceptor', () {
    test('attaches the bearer token and skips it for public requests', () async {
      final api = FakeApi((_) => const FakeResponse(200, {'ok': true}), stored: _stored);
      await api.client.get('/me');
      await api.client.get('/categories', auth: false);
      expect(api.adapter.requests[0].headers['Authorization'], 'Bearer old-access');
      expect(api.adapter.requests[1].headers.containsKey('Authorization'), isFalse);
    });

    test('refreshes once on TOKEN_EXPIRED and retries with the new token', () async {
      final api = FakeApi((options) {
        if (options.path == '/auth/refresh') return FakeResponse(200, fixture('auth_refresh'));
        final bearer = options.headers['Authorization'];
        return bearer == 'Bearer old-access'
            ? apiError(401, 'TOKEN_EXPIRED')
            : const FakeResponse(200, {'user': 'ok'});
      }, stored: _stored);

      final body = await api.client.get('/me');

      expect(body['user'], 'ok');
      expect(api.adapter.count('POST', '/auth/refresh'), 1);
      expect(api.adapter.requests.first.path, '/me');
      final refreshBody = api.adapter.requests.firstWhere((r) => r.path == '/auth/refresh').data;
      expect(refreshBody, {'refreshToken': 'old-refresh'});
      final newAccess = (fixture('auth_refresh')['tokens'] as Map)['accessToken'];
      expect(await api.tokens.accessToken, newAccess);
      expect(api.adapter.requests.last.headers['Authorization'], 'Bearer $newAccess');
    });

    test('concurrent 401s share a single refresh', () async {
      final api = FakeApi((options) {
        if (options.path == '/auth/refresh') return FakeResponse(200, fixture('auth_refresh'));
        return options.headers['Authorization'] == 'Bearer old-access'
            ? apiError(401, 'TOKEN_EXPIRED')
            : const FakeResponse(200, {'ok': true});
      }, stored: _stored);

      await Future.wait([
        api.client.get('/me'),
        api.client.get('/wallet'),
        api.client.get('/orders'),
      ]);

      expect(api.adapter.count('POST', '/auth/refresh'), 1);
      expect(api.adapter.count('GET', '/me'), 2);
      expect(api.adapter.count('GET', '/wallet'), 2);
    });

    test('INVALID_REFRESH_TOKEN clears tokens and ends the session', () async {
      final api = FakeApi((options) {
        if (options.path == '/auth/refresh') return apiError(401, 'INVALID_REFRESH_TOKEN');
        return apiError(401, 'TOKEN_EXPIRED');
      }, stored: _stored);

      await expectLater(
        api.client.get('/me'),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'TOKEN_EXPIRED')),
      );
      expect(api.ended, [SessionEndReason.refreshRejected]);
      expect(await api.tokens.refreshToken, isNull);
    });

    test('a network failure while refreshing keeps the session', () async {
      final api = FakeApi((options) {
        if (options.path == '/auth/refresh') return apiError(503, 'SERVICE_UNAVAILABLE');
        return apiError(401, 'TOKEN_EXPIRED');
      }, stored: _stored);

      await expectLater(api.client.get('/me'), throwsA(isA<AppException>()));
      expect(api.ended, isEmpty);
      expect(await api.tokens.refreshToken, 'old-refresh');
    });
  });

  group('error mapping', () {
    test('maps the error envelope with field errors and request id', () async {
      final api = FakeApi((_) => FakeResponse(422, fixture('order_invalid_fields')));
      try {
        await api.client.post('/orders', body: const {});
        fail('expected an AppException');
      } on AppException catch (error) {
        expect(error.code, 'VALIDATION_FAILED');
        expect(error.statusCode, 422);
        expect(error.requestId, '<request-id>');
        expect(error.fieldErrors, {'playerId': 'INVALID_FORMAT', 'password': 'UNKNOWN_FIELD'});
      }
    });

    test('a 204 response decodes to an empty map', () async {
      final api = FakeApi((_) => const FakeResponse(204));
      expect(await api.client.post('/notifications/read-all'), isEmpty);
    });
  });
}
