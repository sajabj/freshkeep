import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'local_database.dart';

final appDatabaseProvider = FutureProvider<Database>((ref) async {
  final db = await LocalDatabase.open();
  if (!ref.mounted) {
    await db.close();
    throw StateError('Database owner disposed');
  }
  ref.onDispose(() => unawaited(db.close()));
  return db;
});
