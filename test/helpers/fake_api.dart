import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:rewardsapp/core/network/api_client.dart';
import 'package:rewardsapp/core/network/auth_interceptor.dart';
import 'package:rewardsapp/core/security/secure_token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Loads a JSON example extracted from docs/FLUTTER_INTEGRATION-5.md.
Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map<String, dynamic>;

class FakeResponse {
  const FakeResponse(this.status, [this.body = const {}]);

  final int status;
  final Map<String, dynamic> body;
}

/// Records requests and answers them from [handler] (no network).
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  FakeResponse Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  int count(String method, String path) =>
      requests.where((r) => r.method == method && r.path == path).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    await Future<void>.delayed(Duration.zero);
    final response = handler(options);
    return ResponseBody.fromString(
      response.status == 204 ? '' : jsonEncode(response.body),
      response.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

FakeResponse apiError(int status, String code, [Map<String, dynamic> details = const {}]) =>
    FakeResponse(status, {
      'error': {'code': code, 'message': code, 'details': details},
      'requestId': 'req-1',
    });

/// Real [ApiClient] over a [FakeAdapter] and in-memory secure storage.
class FakeApi {
  FakeApi(
    FakeResponse Function(RequestOptions options) handler, {
    Map<String, String> stored = const {},
  }) : adapter = FakeAdapter(handler) {
    FlutterSecureStorage.setMockInitialValues(Map.of(stored));
    tokens = SecureTokenStorage();
    client = ApiClient.create(
      baseUrl: 'https://api.test/api/v1',
      tokens: tokens,
      onSessionEnded: ended.add,
      adapter: adapter,
    );
  }

  final FakeAdapter adapter;
  late final SecureTokenStorage tokens;
  late final ApiClient client;
  final ended = <SessionEndReason>[];
}
