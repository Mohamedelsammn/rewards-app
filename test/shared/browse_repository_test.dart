import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/services/cache/cache_service.dart';
import 'package:rewardsapp/shared/models/giveaway_category.dart';
import 'package:rewardsapp/shared/repositories/category_repository.dart';
import 'package:rewardsapp/shared/repositories/giveaway_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Cache extends Mock implements CacheService {}

void main() {
  late HttpServer server;
  late SupabaseClient client;
  late Uri requested;
  late String method;
  late dynamic submitted;
  dynamic response;
  const category = GiveawayCategory(id: 'phone', nameEn: 'Phones', nameAr: 'Phones Arabic');
  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'test-key');
    response = [];
    server.listen((request) async {
      requested = request.uri;
      method = request.method;
      final body = await utf8.decoder.bind(request).join();
      submitted = body.isEmpty ? null : jsonDecode(body);
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(response));
      await request.response.close();
    });
  });
  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });
  test('active catalog is ordered ascending, including stable ties', () async {
    response = [
      {'id': category.id, ...category.toJson()},
    ];
    final result = await CategoryRepository(client).getCategories();
    expect(result.fold((_) => null, (v) => v.single), category);
    expect(requested.queryParameters['is_active'], 'eq.true');
    expect(
      requested.queryParameters['order'],
      'sort_order.asc.nullslast,name_en.asc.nullslast,id.asc.nullslast',
    );
  });
  test(
    'management fetch includes disabled categories; anonymous management flag grants nothing',
    () async {
      final repository = CategoryRepository(client);
      expect(await repository.canManage(), false);
      await repository.getCategories(management: true);
      expect(requested.queryParameters.containsKey('is_active'), false);
    },
  );
  test('catalog creation and edits use database-assigned IDs and a scoped PATCH', () async {
    final repository = CategoryRepository(client);
    await repository.save(category, create: true);
    expect(method, 'POST');
    expect(submitted.containsKey('id'), false);
    response = {'id': category.id, ...category.toJson()};
    await repository.save(category);
    expect(method, 'PATCH');
    expect(requested.queryParameters['id'], 'eq.phone');
    expect(submitted['name_ar'], category.nameAr);
  });
  test('browse requests one bounded page with category and literal Unicode search', () async {
    final repository = GiveawayRepository(client, Cache());
    await repository.getBrowsePage(page: 1, query: 'هاتف_50%', categoryId: category.id);
    expect(requested.queryParameters['offset'], '24');
    expect(requested.queryParameters['limit'], '24');
    expect(requested.queryParameters['category_id'], 'eq.phone');
    expect(requested.queryParameters['title'], r'ilike.%هاتف\_50\%%');
    expect(requested.queryParameters['status'], 'in.("scheduled","active","ended")');
    expect(requested.queryParameters['order'], 'created_at.desc.nullslast,id.desc.nullslast');
  });
}
