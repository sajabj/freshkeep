import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freshkeep/core/database/local_database.dart';
import 'package:freshkeep/features/scanning/data/product_lookup.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/food_fixture.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  var time = DateTime(2026, 10, 20);
  setUp(() async {
    db = await LocalDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    time = DateTime(2026, 10, 20);
  });
  tearDown(() => db.close());
  http.Response found() => http.Response(
    jsonEncode({
      'product': {
        'product_name': 'Milk',
        'product_name_ar': 'حليب',
        'brands': 'Brand',
        'quantity': '250 ml',
        'image_front_small_url': 'https://images.openfoodfacts.org/test.jpg',
      },
    }),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
  test('request identifies app, fields, staging and language; cache survives new service', () async {
    var count = 0;
    final client = MockClient((r) async {
      count++;
      expect(r.url.path, '/api/v3.6/product/3017620422003.json');
      expect(r.url.queryParameters['lc'], 'ar');
      expect(r.headers['User-Agent'], contains('FreshKeep/0.3.0'));
      expect(r.headers['Authorization'], startsWith('Basic '));
      return found();
    });
    final service = ProductLookup(db, client, now: () => time);
    final result = await service.lookup('3017620422003', 'ar');
    expect(result.product!.name, 'حليب');
    expect(result.product!.measuredQuantity, (250.0, 'ml'));
    final cached = await ProductLookup(
      db,
      client,
      now: () => time,
    ).lookup('3017620422003', 'ar');
    expect(cached.cached, isTrue);
    expect(count, 1);
  });
  test('not-found negatively cached; invalid input sends no request', () async {
    var count = 0;
    final service = ProductLookup(
      db,
      MockClient((_) async {
        count++;
        return http.Response('{}', 404);
      }),
      now: () => time,
    );
    expect((await service.lookup('12345678', 'en')).product, isNull);
    expect((await service.lookup('12345678', 'en')).cached, isTrue);
    await expectLater(
      service.lookup('abc', 'en'),
      throwsA(isA<LookupException>()),
    );
    expect(count, 1);
  });
  test(
    'offline error without cache, expired positive cache is explicitly stale',
    () async {
      final service = ProductLookup(
        db,
        MockClient((_) async => found()),
        now: () => time,
      );
      await service.lookup('12345678', 'en');
      time = time.add(const Duration(days: 8));
      final offline = ProductLookup(
        db,
        MockClient((_) async => throw const SocketException('offline')),
        now: () => time,
      );
      expect((await offline.lookup('12345678', 'en')).stale, isTrue);
      time = time.add(const Duration(seconds: 6));
      await expectLater(
        offline.lookup('87654321', 'en'),
        throwsA(
          isA<LookupException>().having(
            (e) => e.issue,
            'issue',
            LookupIssue.offline,
          ),
        ),
      );
    },
  );
  test('429, malformed JSON, server errors and timeout remain distinct from a miss', () async {
    for (final response in [
      http.Response('{}', 429),
      http.Response('bad', 200),
      http.Response('{}', 503),
    ]) {
      final service = ProductLookup(
        db,
        MockClient((_) async => response),
        now: () => time,
      );
      await expectLater(
        service.lookup('12345678', 'en'),
        throwsA(isA<LookupException>()),
      );
      expect(await db.query('product_cache'), isEmpty);
    }
    final timeout = ProductLookup(
      db,
      MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        return found();
      }),
      timeout: const Duration(milliseconds: 1),
    );
    await expectLater(
      timeout.lookup('12345678', 'en'),
      throwsA(isA<LookupException>()),
    );
  });
  test(
    'coalesces concurrent same scan and throttles other product requests',
    () async {
      var count = 0;
      final response = Completer<http.Response>();
      final service = ProductLookup(
        db,
        MockClient((_) {
          count++;
          return response.future;
        }),
        now: () => time,
      );
      final first = service.lookup('12345678', 'en');
      final duplicate = service.lookup('12345678', 'en');
      response.complete(found());
      await Future.wait([first, duplicate]);
      expect(count, 1);
      await expectLater(
        service.lookup('87654321', 'en'),
        throwsA(
          isA<LookupException>().having(
            (e) => e.issue,
            'issue',
            LookupIssue.rateLimited,
          ),
        ),
      );
      expect(count, 1);
    },
  );
  test(
    'v2 upgrade preserves inventory and events, adds cache and provenance',
    () async {
      final folder = await Directory.systemTemp.createTemp('freshkeep-v3-');
      final path = '${folder.path}/migration.db';
      final old = await LocalDatabase.open(
        factory: databaseFactoryFfiNoIsolate,
        path: path,
        targetVersion: 2,
      );
      await old.insert('food_items', foodFixture().toMap());
      await old.insert('inventory_events', {
        'id': 'event',
        'food_id': foodFixture().id,
        'kind': 'created',
        'occurred_at': '2026-10-20',
        'snapshot': '{}',
      });
      await old.close();
      final migrated = await LocalDatabase.open(
        factory: databaseFactoryFfiNoIsolate,
        path: path,
      );
      expect((await migrated.query('food_items')).single['name'], 'Milk');
      expect((await migrated.query('inventory_events')).length, 1);
      await migrated.insert('product_cache', {
        'barcode': '12345678:en',
        'payload': null,
        'fetched_at': time.toIso8601String(),
      });
      await migrated.update('food_items', {
        'source_url': 'https://world.openfoodfacts.org/product/12345678',
      });
      await migrated.close();
      await File(path).delete();
      await folder.delete();
    },
  );
}
