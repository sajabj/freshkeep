// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get home => 'Home';

  @override
  String get inventory => 'Inventory';

  @override
  String get recipes => 'Recipes';

  @override
  String get statistics => 'Statistics';

  @override
  String get settings => 'Settings';

  @override
  String get shopping => 'Shopping list';

  @override
  String get next => 'Continue';

  @override
  String get back => 'Back';

  @override
  String get skip => 'Skip introduction';

  @override
  String get getStarted => 'Enter my kitchen';

  @override
  String get chooseLanguage => 'Make yourself at home';

  @override
  String get languageIntro =>
      'Choose your language. You can change it any time in Settings.';

  @override
  String get onboardTitle1 => 'Good food.\nLess waste.';

  @override
  String get onboardBody1 =>
      'A little care for what is in your kitchen. Keep your food organised, and make room for less waste.';

  @override
  String get onboardTitle2 => 'Every date\nhas a place.';

  @override
  String get onboardBody2 =>
      'FreshKeep is being built to scan product barcodes and printed dates. You will always review the date before saving it.';

  @override
  String get onboardTitle3 => 'A gentle nudge.\nAt the right time.';

  @override
  String get onboardBody3 =>
      'Upcoming reminders will help you plan ahead. Camera and notification permissions will only be requested when you use those features.';

  @override
  String get onboardTitle4 => 'More from\nwhat you have.';

  @override
  String get onboardBody4 =>
      'The next stages will connect your ingredients, recipes and shopping list. A thoughtful routine, one meal at a time.';

  @override
  String get localFirst => 'Your kitchen, on your device. No account needed.';

  @override
  String get language => 'Language';

  @override
  String get appearance => 'Appearance';

  @override
  String get systemTheme => 'Use device setting';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get preferencesNote => 'Your preferences are saved on this device.';

  @override
  String get loading => 'Loading your preferences';

  @override
  String get retry => 'Try again';

  @override
  String get loadError =>
      'We could not read your preferences. Please try again. Your saved data has not been replaced.';

  @override
  String get saveError => 'Could not save this change. Please try again.';

  @override
  String get morning => 'Good morning';

  @override
  String get afternoon => 'Good afternoon';

  @override
  String get evening => 'Good evening';

  @override
  String get homeTitle => 'A little care for your kitchen.';

  @override
  String get homeBody => 'Everything starts with knowing what you have.';

  @override
  String get phaseTitle => 'Your FreshKeep foundation is ready';

  @override
  String get phaseBody =>
      'Your inventory, smart scanning, reminders, shopping, recipes and statistics work together while your core data stays on this device.';

  @override
  String get inventoryTitle => 'A place for every ingredient';

  @override
  String get inventoryBody => 'Keep every batch and its date in one place.';

  @override
  String get recipesTitle => 'Let your ingredients lead';

  @override
  String get recipesBody =>
      'A local recipe library and ingredient matching are planned for stage four. No recipe suggestions are active yet.';

  @override
  String get statisticsTitle => 'Small habits. A clearer picture.';

  @override
  String get statisticsBody =>
      'Usage and waste reports will appear once inventory tracking and statistics are implemented. There are no measured results yet.';

  @override
  String get shoppingTitle => 'Bring home what you need';

  @override
  String get shoppingBody =>
      'Your editable shopping list and transfer to inventory are planned for stage four.';

  @override
  String get exploreInventory => 'Explore my inventory';

  @override
  String get addFood => 'Add food';

  @override
  String get storageTitle => 'Where your food will live';

  @override
  String get fridge => 'Fridge';

  @override
  String get freezer => 'Freezer';

  @override
  String get pantry => 'Pantry';

  @override
  String get useFirst => 'Use it first';

  @override
  String get useFirstBody =>
      'Once food is added, the nearest confirmed dates will appear here.';

  @override
  String get about => 'About FreshKeep';

  @override
  String get version => 'Version 0.5.10 • Smart inventory consumption';

  @override
  String get privacyTitle => 'Private by design';

  @override
  String get privacyBody =>
      'Inventory and preferences are stored locally. Product lookup sends the barcode, language and IP address to Open Food Facts; product images are loaded from its image service when available. Date photos are not uploaded. No ads, analytics or accounts are active.';

  @override
  String get reviewIntro => 'View introduction';

  @override
  String get close => 'Close';

  @override
  String introProgress(int current, int total) {
    return 'Introduction $current of $total';
  }

  @override
  String get editFood => 'Edit food';

  @override
  String get foodName => 'Food name';

  @override
  String get brandField => 'Brand (optional)';

  @override
  String get barcodeField => 'Barcode (optional)';

  @override
  String get quantityField => 'Quantity';

  @override
  String get unitField => 'Unit';

  @override
  String get categoryField => 'Category';

  @override
  String get storageField => 'Storage';

  @override
  String get expiryField => 'Recorded date';

  @override
  String get purchaseField => 'Purchase date (optional)';

  @override
  String get dateKindField => 'Date type';

  @override
  String get expiryKind => 'Use by / expiry';

  @override
  String get bestBeforeKind => 'Best before';

  @override
  String get unknownKind => 'Not specified';

  @override
  String get priceField => 'Total purchase price (optional)';

  @override
  String get priceHelp => 'Use the same currency for all your food entries.';

  @override
  String get saveFood => 'Save food';

  @override
  String get saving => 'Saving…';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get allCategories => 'All categories';

  @override
  String get allStorage => 'All storage';

  @override
  String get available => 'Available';

  @override
  String get used => 'Used';

  @override
  String get discarded => 'Discarded';

  @override
  String get markUsed => 'Mark as used';

  @override
  String get markDiscarded => 'Mark as discarded';

  @override
  String get restoreFood => 'Return to inventory';

  @override
  String get duplicateFood => 'New batch';

  @override
  String get deleteFood => 'Delete food';

  @override
  String get deleteConfirm =>
      'Remove this batch from inventory? Its change history will remain on this device.';

  @override
  String get disposalReason => 'Reason (optional)';

  @override
  String get discardNote => 'This records the whole batch as discarded.';

  @override
  String get usedConfirm => 'Mark the whole batch as used?';

  @override
  String get restoreConfirm =>
      'Return this batch to inventory? Recheck its recorded date.';

  @override
  String get foodSaved => 'Food saved on this device.';

  @override
  String get inventoryError => 'Could not load your food. Please try again.';

  @override
  String get operationError =>
      'Could not complete the change. Your last saved data is kept.';

  @override
  String get conflictError => 'This batch changed. Refresh and try again.';

  @override
  String get requiredField => 'This field is required.';

  @override
  String get quantityError => 'Enter a number greater than zero.';

  @override
  String get priceError => 'Enter zero or a positive number.';

  @override
  String get chooseDate => 'Choose a date';

  @override
  String get dateRequired => 'Choose and confirm the printed date.';

  @override
  String get dateHelp =>
      'Check the label and confirm the date yourself. A date alone does not guarantee food safety.';

  @override
  String get bestBeforeNote =>
      'Best before describes quality; passing it does not automatically mean the food is unsafe.';

  @override
  String get todayDate => 'Today';

  @override
  String get pastDate => 'Past recorded date';

  @override
  String get soonDate => 'Within 7 days';

  @override
  String get normalDate => 'Later';

  @override
  String get searchFood => 'Search by food name';

  @override
  String get sortExpiry => 'Nearest date';

  @override
  String get sortName => 'Name';

  @override
  String get sortAdded => 'Recently added';

  @override
  String get filters => 'Filters and sorting';

  @override
  String get listView => 'List view';

  @override
  String get cardView => 'Card view';

  @override
  String get emptyInventory => 'Your kitchen starts here';

  @override
  String get emptyInventoryBody =>
      'Add your first food and confirm its printed date.';

  @override
  String get noMatches => 'No food matches this view.';

  @override
  String get photo => 'Product photo';

  @override
  String get choosePhoto => 'Choose photo';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get photoError =>
      'Could not open or save the photo. Check photo access in device settings and try again.';

  @override
  String get clearDate => 'Clear purchase date';

  @override
  String get newBatchNote =>
      'This is a separate batch. Confirm its own date before saving.';

  @override
  String get availableCount => 'In your kitchen';

  @override
  String get soonCount => 'Use soon';

  @override
  String get pastCount => 'Past date';

  @override
  String get usedCount => 'Batches used';

  @override
  String get noUrgent => 'Nothing is due within the next 7 days.';

  @override
  String get viewInventory => 'View inventory';

  @override
  String get refresh => 'Refresh';

  @override
  String get moreActions => 'Batch actions';

  @override
  String get dairy => 'Dairy';

  @override
  String get vegetables => 'Vegetables';

  @override
  String get fruit => 'Fruit';

  @override
  String get meat => 'Meat & fish';

  @override
  String get bakery => 'Bakery';

  @override
  String get canned => 'Canned food';

  @override
  String get drinks => 'Drinks';

  @override
  String get frozen => 'Frozen food';

  @override
  String get grains => 'Grains & pulses';

  @override
  String get other => 'Other';

  @override
  String remainingDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days remaining',
      one: '1 day remaining',
    );
    return '$_temp0';
  }

  @override
  String matchingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count batches',
      one: '1 batch',
      zero: 'No batches',
    );
    return '$_temp0';
  }

  @override
  String get smartScan => 'Smart scanning';

  @override
  String get scanBarcode => 'Scan barcode';

  @override
  String get scanHint => 'Place the product barcode inside the frame.';

  @override
  String get scanPrivacy =>
      'Only the barcode is sent to Open Food Facts. Camera images stay on this device.';

  @override
  String get barcodeManual => 'Enter barcode instead';

  @override
  String get barcodeInvalid =>
      'Enter an 8, 12, 13 or 14 digit product barcode.';

  @override
  String get lookupProduct => 'Look up product';

  @override
  String get lookingUp => 'Looking up product…';

  @override
  String get productMissing =>
      'Product not found. Continue manually with this barcode.';

  @override
  String get lookupOffline =>
      'Cannot connect. Check your internet connection or continue manually.';

  @override
  String get lookupUnavailable =>
      'Product service is unavailable. Try again or continue manually.';

  @override
  String get lookupLimited =>
      'Please wait before another lookup. You can continue manually.';

  @override
  String get cameraProblem =>
      'Camera unavailable or permission denied. Allow camera access in Android settings, retry, or enter the barcode manually.';

  @override
  String get retryCamera => 'Retry camera';

  @override
  String get flashlight => 'Toggle flashlight';

  @override
  String get reviewProduct => 'Review product';

  @override
  String get productReviewNote =>
      'Community data may be incomplete. Check the package, then review the form and choose this batch’s date.';

  @override
  String get continueWithProduct => 'Use these details';

  @override
  String get continueManually => 'Continue manually';

  @override
  String get cachedProduct => 'Saved product information';

  @override
  String get staleProduct =>
      'Offline or service unavailable — showing older saved information.';

  @override
  String get offAttribution =>
      'Product data: Open Food Facts · ODbL / DbCL. Images: CC BY-SA.';

  @override
  String get offDevelopment =>
      'Development version: Open Food Facts staging database. Coverage differs from production.';

  @override
  String get noProductName => 'Name unavailable';

  @override
  String get readDate => 'Read printed date';

  @override
  String get ocrGuide =>
      'Photograph the date and its label (EXP, Best Before or MFG) clearly. Review every result; nothing is applied automatically.';

  @override
  String get ocrArabicLimit =>
      'Recognition uses ML Kit Latin text. Arabic script may not be read reliably; Arabic digits are supported by the date parser when detected.';

  @override
  String get captureDate => 'Take date photo';

  @override
  String get galleryDate => 'Choose date photo';

  @override
  String get readingDate => 'Reading date on this device…';

  @override
  String get ocrFailed =>
      'Could not read this photo. Try a clearer image or enter the date manually.';

  @override
  String get noDates =>
      'No complete date found. Month/year alone needs manual interpretation.';

  @override
  String get dateCandidates => 'Possible dates — choose one to review';

  @override
  String get dateAmbiguous =>
      'Day/month order is ambiguous. Check the package.';

  @override
  String get manufactureDate => 'Manufacture date — cannot be used as expiry';

  @override
  String get unknownDateLabel => 'Unidentified printed date';

  @override
  String get confirmPrintedDate => 'Confirm or correct date';

  @override
  String get applyDate => 'Confirm this date';

  @override
  String get manualDate => 'Enter date manually';

  @override
  String get ocrLocal =>
      'Date photos are processed locally and are not added to the product photo.';

  @override
  String get offSourceSaved =>
      'This batch was filled using Open Food Facts. The saved details may have been edited.';

  @override
  String get reminders => 'Expiry reminders';

  @override
  String get remindersIntro =>
      'Choose when FreshKeep reminds you to review the date on each batch.';

  @override
  String get enableReminders => 'Enable reminders';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get reminderOffsets => 'Days before the printed date';

  @override
  String get addOffset => 'Add days';

  @override
  String get offsetHelp =>
      'Choose 0–365 days; 0 means the printed date. Up to 8 reminders per batch.';

  @override
  String get offsetError =>
      'Choose 1–8 distinct reminder days between 0 and 365.';

  @override
  String get notificationDenied =>
      'Notifications are blocked. Allow them in Android app settings, then try enabling reminders again.';

  @override
  String get reminderTimingNote =>
      'Android may delay reminders because of battery, Doze or manufacturer restrictions. Exact delivery is not guaranteed. Reopen FreshKeep after changing time zones or force-stopping the app.';

  @override
  String get reminderFailure =>
      'Reminder scheduling could not finish. Your saved food data is safe; retry scheduling.';

  @override
  String get retryReminders => 'Refresh reminders';

  @override
  String get reminderCap =>
      'Only the earliest 400 future reminders are scheduled. Later reminders are added as space becomes available when you reopen the app.';

  @override
  String get expiryNotificationTitle => 'FreshKeep · Review a food date';

  @override
  String get addShopping => 'Add to shopping';

  @override
  String get editShopping => 'Edit shopping item';

  @override
  String get shoppingEmpty =>
      'Your shopping list is empty. Add what you need for your next shop.';

  @override
  String get purchased => 'Purchased';

  @override
  String get toBuy => 'To buy';

  @override
  String get allItems => 'All';

  @override
  String get convertToInventory => 'Add purchased batch to inventory';

  @override
  String get convertedToInventory => 'Added to inventory';

  @override
  String get shoppingConvertNote =>
      'Review this purchased batch and confirm its printed date. Saving adds the food and marks this shopping item as purchased in one transaction.';

  @override
  String get restockTitle => 'Buy again';

  @override
  String get restockNote =>
      'Consumed products with no available batch and no unpurchased shopping entry. Suggestions are never added automatically.';

  @override
  String get deleteShoppingTitle => 'Delete shopping item?';

  @override
  String get deleteShoppingBody =>
      'This removes the shopping entry. An already converted food batch remains in inventory.';

  @override
  String get shoppingSaved => 'Added to your shopping list';

  @override
  String get recipeSearch => 'Search recipes or ingredients';

  @override
  String get recipeFavorites => 'Favorites';

  @override
  String get recipeAll => 'All recipes';

  @override
  String get recipeQuick => '20 minutes or less';

  @override
  String get recipeBreakfast => 'Breakfast';

  @override
  String get recipeMain => 'Main dishes';

  @override
  String get recipeSalad => 'Salads';

  @override
  String get recipeSoup => 'Soups';

  @override
  String get recipeSnack => 'Snacks';

  @override
  String get recipeIngredients => 'Ingredients';

  @override
  String get recipeSteps => 'Method';

  @override
  String get recipeMissing => 'Missing';

  @override
  String get recipeEnough => 'Enough in inventory';

  @override
  String get recipePartial => 'Some available; more needed';

  @override
  String get recipeUnmeasured => 'Name found; unit cannot be compared';

  @override
  String get recipeMatchingNote =>
      'Matches use known ingredient names and compatible units. Check identity, amounts, allergies and food condition yourself. Past-date batches are excluded; a date match does not guarantee safety. Water and other staples are listed too; confirm what you have.';

  @override
  String get recipeRankNote =>
      'Sorted to use matching ingredients nearest their printed date first.';

  @override
  String get recipeNoResults => 'No recipes match these filters.';

  @override
  String get recipeFavoriteAdd => 'Save recipe to favorites';

  @override
  String get recipeFavoriteRemove => 'Remove recipe from favorites';

  @override
  String get recipeLibraryNote =>
      '12 original recipes + 20 fitness recipes · available offline · nutrition is estimated per serving';

  @override
  String get recipeAddMissing => 'Add missing amount to shopping';

  @override
  String get recipeReviewAmount => 'Review the required amount';

  @override
  String get recipeStockUnavailable =>
      'Inventory is unavailable. Ingredient matches cannot be calculated until it reloads.';

  @override
  String expiryNotificationBody(String name, String date, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          '$name — package date $date. $days days remaining; review the package and food condition.',
      one:
          '$name — package date $date. Review tomorrow’s date and the food’s condition.',
      zero: '$name — package date $date. Review this batch today.',
    );
    return '$_temp0';
  }

  @override
  String reminderCount(int count, int total) {
    return 'Scheduled reminders: $count of $total';
  }

  @override
  String recipeMeta(int minutes, int servings) {
    return '$minutes min · Serves $servings';
  }

  @override
  String recipeMatchCount(int count, int total) {
    return 'Enough in stock: $count of $total ingredients';
  }

  @override
  String daysBeforeDate(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days before',
      one: '1 day before',
      zero: 'On the printed date',
    );
    return '$_temp0';
  }

  @override
  String get saveShopping => 'Save item';

  @override
  String get deleteShopping => 'Delete item';

  @override
  String get statsIntro => 'Your food, over time';

  @override
  String get statsMethod =>
      'Each batch counts once in its latest used or discarded state. Restoring reverses it; deleting keeps its history. Counts are batches, not quantities.';

  @override
  String get statsUsed => 'Used batches';

  @override
  String get statsDiscarded => 'Discarded batches';

  @override
  String get statsWeek => 'Weekly';

  @override
  String get statsMonth => 'Monthly';

  @override
  String get statsTrend => 'Last six periods';

  @override
  String get statsAll => 'All recorded time';

  @override
  String get statsEmpty => 'Your story starts with your next batch';

  @override
  String get statsEmptyBody =>
      'Mark a batch as used or discarded in inventory to see real trends here. No outcomes have been recorded yet.';

  @override
  String get statsRangeEmpty =>
      'No outcomes in these six periods. Older outcomes remain in the all-time totals.';

  @override
  String get statsValue => 'Estimated batch value';

  @override
  String get statsValueNote =>
      'Sum of entered total batch prices only, in your own monetary unit. No currency conversion or guaranteed savings. Use one currency consistently. Missing prices are excluded.';

  @override
  String get statsNoPrice => 'No entered prices';

  @override
  String get statsPriced => 'Priced batches';

  @override
  String get statsData => 'Chart data and dates';

  @override
  String get statsInvalid =>
      'Some incomplete history could not be counted. Export your data for review.';

  @override
  String get privacyTools => 'Data and privacy';

  @override
  String get privacyDetail =>
      'Inventory, events, shopping, personal recipes, cooking timers and preferences are stored on this device. Barcode lookup contacts Open Food Facts; loading product photos contacts its image service. Date recognition runs on-device. There are no active ads or subscriptions.';

  @override
  String get exportData => 'Export JSON data';

  @override
  String get exportNote =>
      'Choose where to save a readable snapshot of inventory, history, consumption, shopping, favorites, personal recipes, timers and reminder settings. Photos and private file paths are excluded. Keep the file private. This is an export, not a restore feature.';

  @override
  String get exportDone => 'Export saved';

  @override
  String get exportCancelled => 'Export cancelled';

  @override
  String get deleteLocal => 'Delete personal data';

  @override
  String get deleteLocalNote =>
      'Permanently removes inventory and history, shopping, favorites, personal recipes and photos, cooking timers, cached products, food photos and reminders. Language, appearance and the 12 bundled recipes remain. Exported files remain. This cannot be undone.';

  @override
  String get deleteAcknowledge =>
      'I understand that my personal data will be permanently deleted';

  @override
  String get deleteDone => 'Personal data deleted';

  @override
  String get dataBusy => 'Working on your local data…';

  @override
  String get dataError =>
      'Could not finish. Retry; some cleanup may still be pending.';

  @override
  String get retryAction => 'Retry';
}
