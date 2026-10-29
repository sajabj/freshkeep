import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import '../../../core/database/local_database.dart';
import '../../../core/time/clock.dart';
import '../domain/date_candidates.dart';

String? productBarcode(String input) {
  final code = normalizeDigits(input).trim();
  return RegExp(r'^\d{8}$|^\d{12,14}$').hasMatch(code) ? code : null;
}

/// UPC-E encodes a zero-suppressed UPC-A. Expand only when the camera
/// explicitly identifies UPC-E; an EAN-8 must retain its original digits.
String? expandUpce(String input) {
  final code = normalizeDigits(input).trim();
  if (!RegExp(r'^[01]\d{7}$').hasMatch(code)) return null;
  final payload = code.substring(1, 7);
  final tail = payload[5];
  final middle = switch (tail) {
    '0' ||
    '1' ||
    '2' => '${payload.substring(0, 2)}${tail}0000${payload.substring(2, 5)}',
    '3' => '${payload.substring(0, 3)}00000${payload.substring(3, 5)}',
    '4' => '${payload.substring(0, 4)}00000${payload[4]}',
    _ => '${payload.substring(0, 5)}0000$tail',
  };
  return '${code[0]}$middle${code[7]}';
}

class ProductData {
  const ProductData({
    required this.barcode,
    this.name = '',
    this.brand = '',
    this.quantity = '',
    this.imageUrl,
  });
  final String barcode, name, brand, quantity;
  final String? imageUrl;
  Map<String, dynamic> toJson() => {
    'barcode': barcode,
    'name': name,
    'brand': brand,
    'quantity': quantity,
    'imageUrl': imageUrl,
  };
  factory ProductData.fromJson(Map<String, dynamic> json) => ProductData(
    barcode: json['barcode'] as String,
    name: json['name'] as String? ?? '',
    brand: json['brand'] as String? ?? '',
    quantity: json['quantity'] as String? ?? '',
    imageUrl: json['imageUrl'] as String?,
  );
  (double, String)? get measuredQuantity {
    final m = RegExp(
      r'^\s*(\d+(?:[.,]\d+)?)\s*(kg|g|ml|cl|l)\s*$',
      caseSensitive: false,
    ).firstMatch(normalizeDigits(quantity));
    if (m == null) return null;
    final value = double.tryParse(m[1]!.replaceAll(',', '.'));
    return value == null || !value.isFinite || value <= 0
        ? null
        : (value, m[2]!.toLowerCase());
  }
}

enum LookupIssue { offline, unavailable, rateLimited, invalid }

class LookupException implements Exception {
  const LookupException(this.issue);
  final LookupIssue issue;
}

class ProductResult {
  const ProductResult(this.product, {this.cached = false, this.stale = false});
  final ProductData? product;
  final bool cached, stale;
}

final productLookupProvider = FutureProvider<ProductLookup>((ref) async {
  final db = await LocalDatabase.open();
  final client = http.Client();
  ref.onDispose(() {
    client.close();
    unawaited(db.close());
  });
  return ProductLookup(db, client, now: ref.read(clockProvider));
});

class ProductLookup {
  ProductLookup(
    this.db,
    this.client, {
    DateTime Function()? now,
    this.timeout = const Duration(seconds: 12),
  }) : now = now ?? DateTime.now;
  final Database db;
  final http.Client client;
  final DateTime Function() now;
  final Duration timeout;
  DateTime? _lastRequest, _blockedUntil;
  final _pending = <String, Future<ProductResult>>{};
  static const useProduction = bool.fromEnvironment('OFF_PRODUCTION');
  static const contact = String.fromEnvironment(
    'OFF_CONTACT',
    defaultValue: 'FreshKeep Android local development',
  );
  Future<ProductResult> lookup(String raw, String language) {
    final code = productBarcode(raw);
    if (code == null) {
      return Future.error(const LookupException(LookupIssue.invalid));
    }
    final key = '${useProduction ? 'production' : 'staging'}:$code:$language';
    return _pending.putIfAbsent(
      key,
      () => _lookup(code, language).whenComplete(() {
        _pending.remove(key);
      }),
    );
  }

  Future<ProductResult> _lookup(String code, String language) async {
    final key = '${useProduction ? 'production' : 'staging'}:$code:$language';
    Map<String, Object?>? cached;
    try {
      final rows = await db.query(
        'product_cache',
        where: 'barcode = ?',
        whereArgs: [key],
      );
      if (rows.isNotEmpty) cached = rows.first;
    } catch (_) {
      /* Cache failure must not prevent manual/network use. */
    }
    ProductData? data;
    DateTime? fetched;
    try {
      if (cached != null) {
        fetched = DateTime.parse(cached['fetched_at'] as String);
        if (cached['payload'] != null) {
          data = ProductData.fromJson(
            jsonDecode(cached['payload'] as String) as Map<String, dynamic>,
          );
        }
      }
    } catch (_) {
      cached = null;
    }
    if (cached != null &&
        fetched != null &&
        now().difference(fetched) < Duration(hours: data == null ? 6 : 168)) {
      return ProductResult(data, cached: true);
    }
    try {
      final time = now();
      if ((_blockedUntil != null && time.isBefore(_blockedUntil!)) ||
          (_lastRequest != null &&
              time.difference(_lastRequest!) < const Duration(seconds: 5))) {
        throw const LookupException(LookupIssue.rateLimited);
      }
      _lastRequest = time;
      final uri = Uri.https(
        useProduction ? 'world.openfoodfacts.org' : 'world.openfoodfacts.net',
        '/api/v3.6/product/$code.json',
        {
          'fields': 'code,product_name,product_name_ar,product_name_en,brands,quantity,image_front_small_url',
          'lc': language,
        },
      );
      final response = await client
          .get(
            uri,
            headers: {
              'User-Agent': 'FreshKeep/0.3.0 ($contact)',
              'Accept': 'application/json',
              if (!useProduction)
                'Authorization':
                    'Basic ${base64Encode(utf8.encode('off:off'))}',
            },
          )
          .timeout(timeout);
      if (response.statusCode == 429) {
        final seconds =
            int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        _blockedUntil = time.add(Duration(seconds: seconds.clamp(60, 3600)));
        throw const LookupException(LookupIssue.rateLimited);
      }
      if (response.statusCode != 200 && response.statusCode != 404) {
        throw const LookupException(LookupIssue.unavailable);
      }
      ProductData? product;
      if (response.statusCode == 200) {
        final body =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final p = body['product'];
        if (p is Map<String, dynamic>) {
          String field(String key) =>
              p[key] is String ? (p[key] as String).trim() : '';
          final image = Uri.tryParse(field('image_front_small_url'));
          final safeImage =
              image != null &&
                  image.scheme == 'https' &&
                  image.host == 'images.openfoodfacts.org'
              ? image.toString()
              : null;
          product = ProductData(
            barcode: code,
            name: field('product_name_$language').isNotEmpty
                ? field('product_name_$language')
                : field('product_name'),
            brand: field('brands'),
            quantity: field('quantity'),
            imageUrl: safeImage,
          );
        } else if (body['status'] != 0 && body['status'] != 'failure') {
          throw const LookupException(LookupIssue.unavailable);
        }
      }
      try {
        await db.insert('product_cache', {
          'barcode': key,
          'payload': product == null ? null : jsonEncode(product.toJson()),
          'fetched_at': now().toUtc().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        await db.rawDelete(
          'DELETE FROM product_cache WHERE barcode NOT IN (SELECT barcode FROM product_cache ORDER BY fetched_at DESC LIMIT 300)',
        );
      } catch (_) {
        /* Optional cache. */
      }
      return ProductResult(product);
    } catch (e) {
      // A stale positive result is useful offline; a stale miss is not proof.
      if (data != null) return ProductResult(data, cached: true, stale: true);
      if (e is LookupException) rethrow;
      if (e is FormatException || e is TypeError) {
        throw const LookupException(LookupIssue.unavailable);
      }
      throw const LookupException(LookupIssue.offline);
    }
  }
}
