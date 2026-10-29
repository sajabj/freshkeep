# Architecture and implementation boundaries

## Phase one

`lib/app` composes MaterialApp, localization, themes, and the startup gate.
`lib/core` holds shared tokens, original vector artwork, content framing and a testable clock.
`lib/features` owns presentation by feature. Settings additionally owns domain,
application and data layers because it is the only persisted feature in this phase.
`lib/l10n` contains English and Arabic ARB sources and generated localization classes.

The Riverpod AsyncNotifier reads preferences through a repository interface. Native
SharedPreferencesAsync stores one versioned JSON snapshot. Mutations are serialized
and the visible state changes only after a successful write. On write failure the
previous state remains, the control becomes available again and a localized error is shown.
On read failure the startup gate offers retry without silently replacing data.

In the initial phase, inventory, recipes, statistics and shopping destinations
were explicitly marked as future work. Phase two now implements inventory and
the data-backed home screen; recipes, statistics and shopping still explain their
future availability. There are no fake scans or account buttons.
Navigation uses the Flutter Navigator for secondary routes and an IndexedStack for
the four primary destinations. Android back returns to Home before exiting.

## Phase two (implemented)

`LocalDatabase` opens `freshkeep.db` with foreign keys and ordered, additive
migrations: v1 introduces food/categories; v2 introduces audit events and indexes.
Upgrades are transactional and downgrade attempts fail without deleting data.
Barcodes are indexed but deliberately not unique. Each batch has a UUID and its
own confirmed civil date, optional purchase date, price and local photo.

`InventoryRepository` separates persistence from presentation. SQLite mutation
and event insertion share a transaction. Revision checks reject stale writes;
updating cannot silently replace an archived or deleted batch. A deleted batch's
events retain a JSON snapshot and detach their foreign key for future reporting.

Riverpod publishes a refreshed inventory after successful mutations. Read errors
are retryable and failed writes keep the last displayed snapshot. If a write
commits and its refresh fails, the caller still receives write success while the
view shows a read error, avoiding a duplicate retry. A shared day provider refreshes
after local midnight and app resume; differences use civil dates across DST.

Search, category/storage/lifecycle filtering and sorting apply to the same snapshot.
Dashboard counts are derived from retained records. Its use-first list excludes
past dates and archived batches, without declaring best-before food unsafe.

Gallery files are copied to application documents before saving a path. Unsaved
copies created by a form are cleaned on cancellation; shared saved photos are
not deleted blindly. Saved orphan-photo cleanup and full local-data erasure remain
work for the settings/privacy stage.

## Phase three (implemented)

Schema v3 adds an independent `product_cache` and nullable `food_items.source_url`.
No existing table is dropped or recreated. Inventory writes and audit semantics stay
in the existing repository. A scan returns a reviewed prefill, never a database write.
The form still requires a user-confirmed batch date before saving.

`ProductLookup` uses OFF v3.6 field projection, language fallback, a custom User-Agent,
a 12-second timeout, same-code request coalescing and a five-second minimum interval.
HTTP 429 adds a bounded cooldown. It defaults to authenticated public staging;
production and owner contact are compile-time options documented in README.
Cache keys include environment, barcode and language. Positive entries are fresh
for seven days, negative entries six hours; stale positives can be shown with an
explicit warning on service failure. Stale negative entries never establish absence.
Only 300 product-cache entries are retained. Cache failures do not block manual entry.

Product image URLs are restricted to HTTPS `images.openfoodfacts.org`; the existing
photo view uses a disk cache for remote images and retains local-file behavior.
The source product URL follows the saved batch (including duplicate/edit flows)
and audit snapshots. License/source information is visible in review, form and detail.

`DateOcr` uses image_picker and closes a Latin ML Kit recognizer in finally. It does
not upload images or use date photographs as product photos. The pure parser
normalizes Arabic/Persian digits, validates full civil dates and exposes both DMY/MDY
interpretations when ambiguous. Manufacture candidates cannot be applied as expiry.
Month/year-only labels are deferred to manual entry; the app never invents a day.
Two-digit years are shown in 2000–2099 and must be reviewed. The date picker is the
explicit confirmation/correction boundary, not the OCR recognition callback.

The scanner gates callbacks before awaiting, stops on a capture and pauses on app
inactivity. It supports manual barcode entry and localized camera/network errors.
Only camera and network permission are needed; Android photo picker does not need
broad media-storage access. Arabic script is outside the Latin model's supported
scripts, so recognition accuracy is not claimed for Arabic labels.

## Phase four (implemented)

Schema v4 adds shopping_items, recipes, reminder_settings and reminder_ids without
recreating v1–v3 tables. A shared Riverpod database provider owns the app connection;
the existing inventory repository still handles inventory validation and audit writes.
Shopping conversion calls its transaction helper inside the same SQLite transaction
as marking/linking the shopping row. Revision/converted guards prevent duplicate
conversion. Deleting shopping does not delete food; deleting food nulls the link
but does not enable accidental reconversion of an already consumed purchase.

Shopping and recipes use AsyncNotifier controllers with serialized mutations.
Post-commit reload failures surface as read errors without inviting duplicate writes.
Recipes seed original bilingual JSON into SQLite with INSERT OR IGNORE so favorites
remain intact. Canonical ingredient names plus conservative aliases match normalized
inventory names. Only available, non-past-date batches contribute; compatible mass,
volume and count units are compared, and partial/unknown-unit matches remain explicit.
Ranking prioritizes eligible matching ingredients near their printed dates. It is a
name/unit heuristic, not an allergen, brand, food-condition or safety classifier.

Reminder settings default to disabled, 09:00 and offsets [7,3,1,0]. Users select up
to eight unique offsets (0–365). The pure planner builds future civil dates; tz uses
the device's actual IANA identifier from a small Android method channel. Permission
is requested only on explicit enable. Native checks inspect both global permission
and the reminder channel. No exact-alarm, battery-optimization exemption or foreground
service permission is introduced. RECEIVE_BOOT_COMPLETED is for the plugin's
standard boot/package-update receiver; schedule mode is inexactAllowWhileIdle.

ReminderService serializes reconciliation, allocates collision-free autoincrement
IDs per food/offset, and compares managed pending payloads. Changes cancel/replace
requests; removed, archived or disabled items cancel pending and delivered IDs.
Unrelated notification namespaces are left alone. IDs are pruned only after successful
platform work. Startup, app resume and manual refresh force re-arming with the same
IDs, because stored plugin requests can outlive OS alarms after a force stop.
Scheduling errors do not roll back committed food writes; settings expose a retryable
status. OS notification scheduling and SQLite cannot be one atomic transaction.

The earliest 400 future requests are scheduled, below common OEM caps, with the
truncation visible in settings. The app must run again to refill later slots. The
native receiver restores scheduled requests after boot; it cannot override user
force-stop, channel blocks or manufacturer delivery restrictions. A device time-zone
change is reconciled when the app next resumes. Delivery times are not guaranteed.

## Next phases (not implemented)

1. Phase six: disabled-by-default ad configuration, secure entitlement boundary,
   implemented premium features and publication preparation.

Do not reuse preferences for food records. Future sync can implement the repository
contracts without exposing transport details to widgets. No backend or entitlement
verification is simulated in this foundation.

## Reproducibility

Flutter 3.47.7 / Dart 3.13.5 verified locally. `pubspec.lock` is retained.
Riverpod 3.4.3 requires Dart >=3.12; shared_preferences 2.5.6 requires Dart >=3.11
and Flutter >=3.41. Both satisfy this environment; dependency resolution succeeded.
`intl` resolves to the SDK localization constraint (0.20.3 in this lockfile).

Sources checked on 2026-10-19:
- https://pub.dev/packages/flutter_riverpod
- https://pub.dev/packages/shared_preferences
- https://pub.dev/api/packages/flutter_riverpod
- https://pub.dev/api/packages/shared_preferences

The user subsequently added additional Flutter packages. They are preserved;
only the implemented features are wired. Phase two adds sqflite_common_ffi as a
test dependency (verified Dart ^3.12 compatibility). SQLite and image-picker
constraints were checked against their registry metadata on 2026-10-20.
Native notification-package desugaring is configured as its README requires.
AdMob's transitive auto-initialization provider is removed until real ad/consent
configuration exists; no placeholder application ID is supplied.


## Phase five

App version 0.5.0+5 retains SQLite v4; no table replacement or migration is
needed. Statistics read events and inventory within one SQLite read transaction.
Snapshot IDs survive ON DELETE SET NULL. The latest revision per batch defines
its outcome; restoration removes the prior outcome, deletion preserves it, and
retained inventory is authoritative (also supporting pre-event legacy rows).
Status timestamps define local civil weekly (Monday) and monthly buckets. Each
batch contributes once; incompatible quantity units are never added together.
Only known total batch prices are summed, with coverage counts and no currency
conversion or savings claim. Malformed history is reported, not fabricated.

Riverpod reloads statistics after committed inventory changes, including shopping
conversions. Favorites and shopping purchases alone are not consumption events.
AppShell constructs tabs on first visit, retaining visited tabs. RecipeRepository
seeds its bundled library once per repository instance, preserving favorites and
avoiding repeated asset reads on every toggle.

PersonalDataStore exports a transactionally consistent UTF-8 JSON snapshot without
photo bytes or image_path fields (also sanitizing historical snapshots). Native
freshkeep/device exportJson uses Android ACTION_CREATE_DOCUMENT and only writes
the URI selected in the system picker, on a worker thread. No storage permission
or persistent URI grant is requested. It returns false on cancellation; write
failure is surfaced. Export is not an import or encrypted backup format.

Personal-data deletion waits for inventory/shopping/favorite mutations, suspends
and drains ReminderService reconciliation, then cancels owned pending and
allocated delivered notifications. A cancellation error aborts before DB deletion.
A transaction deletes child/history/cache/settings/registry rows before inventory
and clears favorites. Original recipes/categories and display preferences remain.
Owned immediate photo files, remote image cache and memory images are cleaned;
arbitrary stored file paths are never followed. Old reminder services remain
suspended, while provider invalidation reloads all affected views. OS cancellation,
SQL and file operations cannot share one transaction: errors explicitly invite
retry; SQL deletion itself rolls back on error. Exported user documents remain.

Native API references verified 2026-10-20:
- https://developer.android.com/training/data-storage/shared/documents-files
- https://pub.dev/documentation/fl_chart/latest/fl_chart/BarChart-class.html
