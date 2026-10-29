import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../features/inventory/domain/food_item.dart';

abstract final class LocalDatabase {
  static const version = 7;
  static Future<Database> open({
    DatabaseFactory? factory,
    String? path,
    int targetVersion = version,
  }) async {
    final driver = factory ?? databaseFactory;
    final location =
        path ?? p.join(await driver.getDatabasesPath(), 'freshkeep.db');
    return driver.openDatabase(
      location,
      options: OpenDatabaseOptions(
        version: targetVersion,
        singleInstance: false,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, v) => migrate(db, 0, v),
        onUpgrade: migrate,
        onDowngrade: (db, old, next) async =>
            throw StateError('Database downgrade refused'),
      ),
    );
  }

  /// Callbacks are already transactional in sqflite. Never delete/recreate
  /// user tables during an upgrade; each version is additive and ordered.
  static Future<void> migrate(Database db, int old, int next) async {
    if (next > version) throw StateError('Unsupported schema version');
    if (old < 1 && next >= 1) {
      await db.execute(
        'CREATE TABLE categories (id TEXT PRIMARY KEY, sort_order INTEGER NOT NULL)',
      );
      for (var i = 0; i < categoryIds.length; i++) {
        await db.insert('categories', {'id': categoryIds[i], 'sort_order': i});
      }
      await db.execute('''CREATE TABLE food_items (
        id TEXT PRIMARY KEY, name TEXT NOT NULL CHECK(length(trim(name)) BETWEEN 1 AND 100),
        barcode TEXT, brand TEXT, category_id TEXT NOT NULL REFERENCES categories(id),
        quantity REAL NOT NULL CHECK(quantity > 0), unit TEXT NOT NULL CHECK(length(trim(unit)) > 0),
        purchase_date TEXT, expiry_date TEXT NOT NULL,
        date_kind TEXT NOT NULL CHECK(date_kind IN ('expiry','bestBefore','unknown')),
        storage TEXT NOT NULL CHECK(storage IN ('fridge','freezer','pantry','other')),
        price REAL CHECK(price >= 0), image_path TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
        status TEXT NOT NULL CHECK(status IN ('available','used','discarded')),
        status_changed_at TEXT, disposal_reason TEXT, revision INTEGER NOT NULL DEFAULT 0
      )''');
    }
    if (old < 2 && next >= 2) {
      await db.execute('''CREATE TABLE inventory_events (
        id TEXT PRIMARY KEY, food_id TEXT REFERENCES food_items(id) ON DELETE SET NULL,
        kind TEXT NOT NULL, occurred_at TEXT NOT NULL, snapshot TEXT NOT NULL
      )''');
      await db.execute(
        'CREATE INDEX food_dates ON food_items(status, expiry_date)',
      );
      await db.execute(
        'CREATE INDEX food_names ON food_items(name COLLATE NOCASE)',
      );
      // Barcode is intentionally non-unique: each batch owns its own date.
      await db.execute('CREATE INDEX food_barcodes ON food_items(barcode)');
      await db.execute(
        'CREATE INDEX events_dates ON inventory_events(occurred_at)',
      );
      await db.execute('CREATE INDEX events_food ON inventory_events(food_id)');
    }
    if (old < 3 && next >= 3) {
      await db.execute('ALTER TABLE food_items ADD COLUMN source_url TEXT');
      await db.execute('''CREATE TABLE product_cache (
        barcode TEXT PRIMARY KEY, payload TEXT, fetched_at TEXT NOT NULL
      )''');
    }
    if (old < 4 && next >= 4) {
      await db.execute('''CREATE TABLE shopping_items (
        id TEXT PRIMARY KEY, name TEXT NOT NULL, quantity REAL NOT NULL CHECK(quantity > 0),
        unit TEXT NOT NULL, category_id TEXT NOT NULL REFERENCES categories(id),
        purchased INTEGER NOT NULL DEFAULT 0 CHECK(purchased IN (0,1)),
        inventory_id TEXT REFERENCES food_items(id) ON DELETE SET NULL,
        converted INTEGER NOT NULL DEFAULT 0 CHECK(converted IN (0,1)),
        revision INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL
      )''');
      await db.execute('''CREATE TABLE recipes (
        id TEXT PRIMARY KEY, content TEXT NOT NULL,
        favorite INTEGER NOT NULL DEFAULT 0 CHECK(favorite IN (0,1))
      )''');
      await db.execute(
        'CREATE TABLE reminder_settings (id INTEGER PRIMARY KEY CHECK(id=1), content TEXT NOT NULL)',
      );
      await db.execute('''CREATE TABLE reminder_ids (
        id INTEGER PRIMARY KEY AUTOINCREMENT, food_id TEXT NOT NULL, days INTEGER NOT NULL,
        UNIQUE(food_id, days)
      )''');
    }
    if (old < 5 && next >= 5) {
      await db.execute('''CREATE TABLE meal_plans (
        id TEXT PRIMARY KEY, meal_date TEXT NOT NULL,
        slot TEXT NOT NULL CHECK(slot IN ('breakfast','lunch','dinner')),
        recipe_id TEXT NOT NULL, servings REAL NOT NULL CHECK(servings > 0),
        created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
        UNIQUE(meal_date, slot)
      )''');
      await db.execute(
        'CREATE INDEX meal_plan_dates ON meal_plans(meal_date, slot)',
      );
    }
    if (old < 6 && next >= 6) {
      await db.execute('''CREATE TABLE custom_recipes (
        id TEXT PRIMARY KEY CHECK(id LIKE 'user:%'), content TEXT NOT NULL,
        favorite INTEGER NOT NULL DEFAULT 0 CHECK(favorite IN (0,1)),
        image_path TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL
      )''');
      await db.execute('''CREATE TABLE cooking_timers (
        notification_id INTEGER PRIMARY KEY AUTOINCREMENT,
        id TEXT NOT NULL UNIQUE, name TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL CHECK(duration_seconds > 0),
        remaining_seconds INTEGER NOT NULL CHECK(remaining_seconds >= 0),
        end_at TEXT, state TEXT NOT NULL CHECK(state IN ('running','paused','finished')),
        notified INTEGER NOT NULL DEFAULT 0 CHECK(notified IN (0,1)),
        created_at TEXT NOT NULL, updated_at TEXT NOT NULL
      )''');
    }
    if (old < 7 && next >= 7) {
      // v1 required a positive quantity. Consumption needs a real zero for a
      // fully used batch, so rebuild only this table while preserving every
      // row, id and foreign-key target.
      await db.execute('PRAGMA defer_foreign_keys = ON');
      // ON DELETE SET NULL is triggered by the table rebuild itself. Keep the
      // two nullable references and restore them after the replacement table
      // has the original name again.
      await db.execute(
        'CREATE TEMP TABLE v7_shopping_refs AS SELECT id, inventory_id FROM shopping_items WHERE inventory_id IS NOT NULL',
      );
      await db.execute(
        'CREATE TEMP TABLE v7_event_refs AS SELECT id, food_id FROM inventory_events WHERE food_id IS NOT NULL',
      );
      await db.execute('''CREATE TABLE food_items_v7 (
        id TEXT PRIMARY KEY, name TEXT NOT NULL CHECK(length(trim(name)) BETWEEN 1 AND 100),
        barcode TEXT, brand TEXT, category_id TEXT NOT NULL REFERENCES categories(id),
        quantity REAL NOT NULL CHECK(quantity >= 0), unit TEXT NOT NULL CHECK(length(trim(unit)) > 0),
        purchase_date TEXT, expiry_date TEXT NOT NULL,
        date_kind TEXT NOT NULL CHECK(date_kind IN ('expiry','bestBefore','unknown')),
        storage TEXT NOT NULL CHECK(storage IN ('fridge','freezer','pantry','other')),
        price REAL CHECK(price >= 0), image_path TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
        status TEXT NOT NULL CHECK(status IN ('available','used','discarded')),
        status_changed_at TEXT, disposal_reason TEXT, revision INTEGER NOT NULL DEFAULT 0,
        source_url TEXT
      )''');
      await db.execute('''INSERT INTO food_items_v7 (
        id,name,barcode,brand,category_id,quantity,unit,purchase_date,expiry_date,date_kind,
        storage,price,image_path,created_at,updated_at,status,status_changed_at,disposal_reason,
        revision,source_url
      ) SELECT id,name,barcode,brand,category_id,quantity,unit,purchase_date,expiry_date,date_kind,
        storage,price,image_path,created_at,updated_at,status,status_changed_at,disposal_reason,
        revision,source_url FROM food_items''');
      await db.execute('DROP TABLE food_items');
      await db.execute('ALTER TABLE food_items_v7 RENAME TO food_items');
      await db.execute('''UPDATE shopping_items SET inventory_id=(
        SELECT inventory_id FROM v7_shopping_refs WHERE v7_shopping_refs.id=shopping_items.id
      ) WHERE id IN (SELECT id FROM v7_shopping_refs)''');
      await db.execute('''UPDATE inventory_events SET food_id=(
        SELECT food_id FROM v7_event_refs WHERE v7_event_refs.id=inventory_events.id
      ) WHERE id IN (SELECT id FROM v7_event_refs)''');
      await db.execute('DROP TABLE v7_shopping_refs');
      await db.execute('DROP TABLE v7_event_refs');
      await db.execute(
        'CREATE INDEX food_dates ON food_items(status, expiry_date)',
      );
      await db.execute(
        'CREATE INDEX food_names ON food_items(name COLLATE NOCASE)',
      );
      await db.execute('CREATE INDEX food_barcodes ON food_items(barcode)');
      await db.execute('''CREATE TABLE consumption_operations (
        id TEXT PRIMARY KEY,
        kind TEXT NOT NULL CHECK(kind IN ('manual','recipe')),
        recipe_id TEXT,
        occurred_at TEXT NOT NULL,
        undone_at TEXT,
        state TEXT NOT NULL CHECK(state IN ('applied','undone')) DEFAULT 'applied'
      )''');
      await db.execute('''CREATE TABLE consumption_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_id TEXT NOT NULL REFERENCES consumption_operations(id) ON DELETE CASCADE,
        food_id TEXT NOT NULL,
        food_name TEXT NOT NULL,
        amount REAL NOT NULL CHECK(amount > 0),
        unit TEXT NOT NULL,
        quantity_before REAL NOT NULL,
        quantity_after REAL NOT NULL CHECK(quantity_after >= 0),
        revision_before INTEGER NOT NULL,
        revision_after INTEGER NOT NULL,
        status_before TEXT NOT NULL,
        status_after TEXT NOT NULL
      )''');
      await db.execute(
        'CREATE INDEX consumption_dates ON consumption_operations(occurred_at)',
      );
      await db.execute(
        'CREATE INDEX consumption_entries_operation ON consumption_entries(operation_id)',
      );
    }
  }
}
