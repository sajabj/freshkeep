import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @recipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get recipes;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @shopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping list'**
  String get shopping;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip introduction'**
  String get skip;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Enter my kitchen'**
  String get getStarted;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Make yourself at home'**
  String get chooseLanguage;

  /// No description provided for @languageIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose your language. You can change it any time in Settings.'**
  String get languageIntro;

  /// No description provided for @onboardTitle1.
  ///
  /// In en, this message translates to:
  /// **'Good food.\nLess waste.'**
  String get onboardTitle1;

  /// No description provided for @onboardBody1.
  ///
  /// In en, this message translates to:
  /// **'A little care for what is in your kitchen. Keep your food organised, and make room for less waste.'**
  String get onboardBody1;

  /// No description provided for @onboardTitle2.
  ///
  /// In en, this message translates to:
  /// **'Every date\nhas a place.'**
  String get onboardTitle2;

  /// No description provided for @onboardBody2.
  ///
  /// In en, this message translates to:
  /// **'FreshKeep is being built to scan product barcodes and printed dates. You will always review the date before saving it.'**
  String get onboardBody2;

  /// No description provided for @onboardTitle3.
  ///
  /// In en, this message translates to:
  /// **'A gentle nudge.\nAt the right time.'**
  String get onboardTitle3;

  /// No description provided for @onboardBody3.
  ///
  /// In en, this message translates to:
  /// **'Upcoming reminders will help you plan ahead. Camera and notification permissions will only be requested when you use those features.'**
  String get onboardBody3;

  /// No description provided for @onboardTitle4.
  ///
  /// In en, this message translates to:
  /// **'More from\nwhat you have.'**
  String get onboardTitle4;

  /// No description provided for @onboardBody4.
  ///
  /// In en, this message translates to:
  /// **'The next stages will connect your ingredients, recipes and shopping list. A thoughtful routine, one meal at a time.'**
  String get onboardBody4;

  /// No description provided for @localFirst.
  ///
  /// In en, this message translates to:
  /// **'Your kitchen, on your device. No account needed.'**
  String get localFirst;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'Use device setting'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @preferencesNote.
  ///
  /// In en, this message translates to:
  /// **'Your preferences are saved on this device.'**
  String get preferencesNote;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading your preferences'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'We could not read your preferences. Please try again. Your saved data has not been replaced.'**
  String get loadError;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save this change. Please try again.'**
  String get saveError;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get afternoon;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get evening;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'A little care for your kitchen.'**
  String get homeTitle;

  /// No description provided for @homeBody.
  ///
  /// In en, this message translates to:
  /// **'Everything starts with knowing what you have.'**
  String get homeBody;

  /// No description provided for @phaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Your FreshKeep foundation is ready'**
  String get phaseTitle;

  /// No description provided for @phaseBody.
  ///
  /// In en, this message translates to:
  /// **'Your inventory, smart scanning, reminders, shopping, recipes and statistics work together while your core data stays on this device.'**
  String get phaseBody;

  /// No description provided for @inventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'A place for every ingredient'**
  String get inventoryTitle;

  /// No description provided for @inventoryBody.
  ///
  /// In en, this message translates to:
  /// **'Keep every batch and its date in one place.'**
  String get inventoryBody;

  /// No description provided for @recipesTitle.
  ///
  /// In en, this message translates to:
  /// **'Let your ingredients lead'**
  String get recipesTitle;

  /// No description provided for @recipesBody.
  ///
  /// In en, this message translates to:
  /// **'A local recipe library and ingredient matching are planned for stage four. No recipe suggestions are active yet.'**
  String get recipesBody;

  /// No description provided for @statisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Small habits. A clearer picture.'**
  String get statisticsTitle;

  /// No description provided for @statisticsBody.
  ///
  /// In en, this message translates to:
  /// **'Usage and waste reports will appear once inventory tracking and statistics are implemented. There are no measured results yet.'**
  String get statisticsBody;

  /// No description provided for @shoppingTitle.
  ///
  /// In en, this message translates to:
  /// **'Bring home what you need'**
  String get shoppingTitle;

  /// No description provided for @shoppingBody.
  ///
  /// In en, this message translates to:
  /// **'Your editable shopping list and transfer to inventory are planned for stage four.'**
  String get shoppingBody;

  /// No description provided for @exploreInventory.
  ///
  /// In en, this message translates to:
  /// **'Explore my inventory'**
  String get exploreInventory;

  /// No description provided for @addFood.
  ///
  /// In en, this message translates to:
  /// **'Add food'**
  String get addFood;

  /// No description provided for @storageTitle.
  ///
  /// In en, this message translates to:
  /// **'Where your food will live'**
  String get storageTitle;

  /// No description provided for @fridge.
  ///
  /// In en, this message translates to:
  /// **'Fridge'**
  String get fridge;

  /// No description provided for @freezer.
  ///
  /// In en, this message translates to:
  /// **'Freezer'**
  String get freezer;

  /// No description provided for @pantry.
  ///
  /// In en, this message translates to:
  /// **'Pantry'**
  String get pantry;

  /// No description provided for @useFirst.
  ///
  /// In en, this message translates to:
  /// **'Use it first'**
  String get useFirst;

  /// No description provided for @useFirstBody.
  ///
  /// In en, this message translates to:
  /// **'Once food is added, the nearest confirmed dates will appear here.'**
  String get useFirstBody;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About FreshKeep'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version 0.5.10 • Smart inventory consumption'**
  String get version;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Private by design'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'Inventory and preferences are stored locally. Product lookup sends the barcode, language and IP address to Open Food Facts; product images are loaded from its image service when available. Date photos are not uploaded. No ads, analytics or accounts are active.'**
  String get privacyBody;

  /// No description provided for @reviewIntro.
  ///
  /// In en, this message translates to:
  /// **'View introduction'**
  String get reviewIntro;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @introProgress.
  ///
  /// In en, this message translates to:
  /// **'Introduction {current} of {total}'**
  String introProgress(int current, int total);

  /// No description provided for @editFood.
  ///
  /// In en, this message translates to:
  /// **'Edit food'**
  String get editFood;

  /// No description provided for @foodName.
  ///
  /// In en, this message translates to:
  /// **'Food name'**
  String get foodName;

  /// No description provided for @brandField.
  ///
  /// In en, this message translates to:
  /// **'Brand (optional)'**
  String get brandField;

  /// No description provided for @barcodeField.
  ///
  /// In en, this message translates to:
  /// **'Barcode (optional)'**
  String get barcodeField;

  /// No description provided for @quantityField.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityField;

  /// No description provided for @unitField.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitField;

  /// No description provided for @categoryField.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryField;

  /// No description provided for @storageField.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storageField;

  /// No description provided for @expiryField.
  ///
  /// In en, this message translates to:
  /// **'Recorded date'**
  String get expiryField;

  /// No description provided for @purchaseField.
  ///
  /// In en, this message translates to:
  /// **'Purchase date (optional)'**
  String get purchaseField;

  /// No description provided for @dateKindField.
  ///
  /// In en, this message translates to:
  /// **'Date type'**
  String get dateKindField;

  /// No description provided for @expiryKind.
  ///
  /// In en, this message translates to:
  /// **'Use by / expiry'**
  String get expiryKind;

  /// No description provided for @bestBeforeKind.
  ///
  /// In en, this message translates to:
  /// **'Best before'**
  String get bestBeforeKind;

  /// No description provided for @unknownKind.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get unknownKind;

  /// No description provided for @priceField.
  ///
  /// In en, this message translates to:
  /// **'Total purchase price (optional)'**
  String get priceField;

  /// No description provided for @priceHelp.
  ///
  /// In en, this message translates to:
  /// **'Use the same currency for all your food entries.'**
  String get priceHelp;

  /// No description provided for @saveFood.
  ///
  /// In en, this message translates to:
  /// **'Save food'**
  String get saveFood;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @allStorage.
  ///
  /// In en, this message translates to:
  /// **'All storage'**
  String get allStorage;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get used;

  /// No description provided for @discarded.
  ///
  /// In en, this message translates to:
  /// **'Discarded'**
  String get discarded;

  /// No description provided for @markUsed.
  ///
  /// In en, this message translates to:
  /// **'Mark as used'**
  String get markUsed;

  /// No description provided for @markDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Mark as discarded'**
  String get markDiscarded;

  /// No description provided for @restoreFood.
  ///
  /// In en, this message translates to:
  /// **'Return to inventory'**
  String get restoreFood;

  /// No description provided for @duplicateFood.
  ///
  /// In en, this message translates to:
  /// **'New batch'**
  String get duplicateFood;

  /// No description provided for @deleteFood.
  ///
  /// In en, this message translates to:
  /// **'Delete food'**
  String get deleteFood;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this batch from inventory? Its change history will remain on this device.'**
  String get deleteConfirm;

  /// No description provided for @disposalReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get disposalReason;

  /// No description provided for @discardNote.
  ///
  /// In en, this message translates to:
  /// **'This records the whole batch as discarded.'**
  String get discardNote;

  /// No description provided for @usedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Mark the whole batch as used?'**
  String get usedConfirm;

  /// No description provided for @restoreConfirm.
  ///
  /// In en, this message translates to:
  /// **'Return this batch to inventory? Recheck its recorded date.'**
  String get restoreConfirm;

  /// No description provided for @foodSaved.
  ///
  /// In en, this message translates to:
  /// **'Food saved on this device.'**
  String get foodSaved;

  /// No description provided for @inventoryError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your food. Please try again.'**
  String get inventoryError;

  /// No description provided for @operationError.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the change. Your last saved data is kept.'**
  String get operationError;

  /// No description provided for @conflictError.
  ///
  /// In en, this message translates to:
  /// **'This batch changed. Refresh and try again.'**
  String get conflictError;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredField;

  /// No description provided for @quantityError.
  ///
  /// In en, this message translates to:
  /// **'Enter a number greater than zero.'**
  String get quantityError;

  /// No description provided for @priceError.
  ///
  /// In en, this message translates to:
  /// **'Enter zero or a positive number.'**
  String get priceError;

  /// No description provided for @chooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get chooseDate;

  /// No description provided for @dateRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose and confirm the printed date.'**
  String get dateRequired;

  /// No description provided for @dateHelp.
  ///
  /// In en, this message translates to:
  /// **'Check the label and confirm the date yourself. A date alone does not guarantee food safety.'**
  String get dateHelp;

  /// No description provided for @bestBeforeNote.
  ///
  /// In en, this message translates to:
  /// **'Best before describes quality; passing it does not automatically mean the food is unsafe.'**
  String get bestBeforeNote;

  /// No description provided for @todayDate.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayDate;

  /// No description provided for @pastDate.
  ///
  /// In en, this message translates to:
  /// **'Past recorded date'**
  String get pastDate;

  /// No description provided for @soonDate.
  ///
  /// In en, this message translates to:
  /// **'Within 7 days'**
  String get soonDate;

  /// No description provided for @normalDate.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get normalDate;

  /// No description provided for @searchFood.
  ///
  /// In en, this message translates to:
  /// **'Search by food name'**
  String get searchFood;

  /// No description provided for @sortExpiry.
  ///
  /// In en, this message translates to:
  /// **'Nearest date'**
  String get sortExpiry;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortName;

  /// No description provided for @sortAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get sortAdded;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters and sorting'**
  String get filters;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get listView;

  /// No description provided for @cardView.
  ///
  /// In en, this message translates to:
  /// **'Card view'**
  String get cardView;

  /// No description provided for @emptyInventory.
  ///
  /// In en, this message translates to:
  /// **'Your kitchen starts here'**
  String get emptyInventory;

  /// No description provided for @emptyInventoryBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first food and confirm its printed date.'**
  String get emptyInventoryBody;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No food matches this view.'**
  String get noMatches;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Product photo'**
  String get photo;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get choosePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @photoError.
  ///
  /// In en, this message translates to:
  /// **'Could not open or save the photo. Check photo access in device settings and try again.'**
  String get photoError;

  /// No description provided for @clearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear purchase date'**
  String get clearDate;

  /// No description provided for @newBatchNote.
  ///
  /// In en, this message translates to:
  /// **'This is a separate batch. Confirm its own date before saving.'**
  String get newBatchNote;

  /// No description provided for @availableCount.
  ///
  /// In en, this message translates to:
  /// **'In your kitchen'**
  String get availableCount;

  /// No description provided for @soonCount.
  ///
  /// In en, this message translates to:
  /// **'Use soon'**
  String get soonCount;

  /// No description provided for @pastCount.
  ///
  /// In en, this message translates to:
  /// **'Past date'**
  String get pastCount;

  /// No description provided for @usedCount.
  ///
  /// In en, this message translates to:
  /// **'Batches used'**
  String get usedCount;

  /// No description provided for @noUrgent.
  ///
  /// In en, this message translates to:
  /// **'Nothing is due within the next 7 days.'**
  String get noUrgent;

  /// No description provided for @viewInventory.
  ///
  /// In en, this message translates to:
  /// **'View inventory'**
  String get viewInventory;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'Batch actions'**
  String get moreActions;

  /// No description provided for @dairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy'**
  String get dairy;

  /// No description provided for @vegetables.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get vegetables;

  /// No description provided for @fruit.
  ///
  /// In en, this message translates to:
  /// **'Fruit'**
  String get fruit;

  /// No description provided for @meat.
  ///
  /// In en, this message translates to:
  /// **'Meat & fish'**
  String get meat;

  /// No description provided for @bakery.
  ///
  /// In en, this message translates to:
  /// **'Bakery'**
  String get bakery;

  /// No description provided for @canned.
  ///
  /// In en, this message translates to:
  /// **'Canned food'**
  String get canned;

  /// No description provided for @drinks.
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get drinks;

  /// No description provided for @frozen.
  ///
  /// In en, this message translates to:
  /// **'Frozen food'**
  String get frozen;

  /// No description provided for @grains.
  ///
  /// In en, this message translates to:
  /// **'Grains & pulses'**
  String get grains;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @remainingDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day remaining} other{{days} days remaining}}'**
  String remainingDays(int days);

  /// No description provided for @matchingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No batches} =1{1 batch} other{{count} batches}}'**
  String matchingCount(int count);

  /// No description provided for @smartScan.
  ///
  /// In en, this message translates to:
  /// **'Smart scanning'**
  String get smartScan;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get scanBarcode;

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'Place the product barcode inside the frame.'**
  String get scanHint;

  /// No description provided for @scanPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Only the barcode is sent to Open Food Facts. Camera images stay on this device.'**
  String get scanPrivacy;

  /// No description provided for @barcodeManual.
  ///
  /// In en, this message translates to:
  /// **'Enter barcode instead'**
  String get barcodeManual;

  /// No description provided for @barcodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an 8, 12, 13 or 14 digit product barcode.'**
  String get barcodeInvalid;

  /// No description provided for @lookupProduct.
  ///
  /// In en, this message translates to:
  /// **'Look up product'**
  String get lookupProduct;

  /// No description provided for @lookingUp.
  ///
  /// In en, this message translates to:
  /// **'Looking up product…'**
  String get lookingUp;

  /// No description provided for @productMissing.
  ///
  /// In en, this message translates to:
  /// **'Product not found. Continue manually with this barcode.'**
  String get productMissing;

  /// No description provided for @lookupOffline.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect. Check your internet connection or continue manually.'**
  String get lookupOffline;

  /// No description provided for @lookupUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Product service is unavailable. Try again or continue manually.'**
  String get lookupUnavailable;

  /// No description provided for @lookupLimited.
  ///
  /// In en, this message translates to:
  /// **'Please wait before another lookup. You can continue manually.'**
  String get lookupLimited;

  /// No description provided for @cameraProblem.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable or permission denied. Allow camera access in Android settings, retry, or enter the barcode manually.'**
  String get cameraProblem;

  /// No description provided for @retryCamera.
  ///
  /// In en, this message translates to:
  /// **'Retry camera'**
  String get retryCamera;

  /// No description provided for @flashlight.
  ///
  /// In en, this message translates to:
  /// **'Toggle flashlight'**
  String get flashlight;

  /// No description provided for @reviewProduct.
  ///
  /// In en, this message translates to:
  /// **'Review product'**
  String get reviewProduct;

  /// No description provided for @productReviewNote.
  ///
  /// In en, this message translates to:
  /// **'Community data may be incomplete. Check the package, then review the form and choose this batch’s date.'**
  String get productReviewNote;

  /// No description provided for @continueWithProduct.
  ///
  /// In en, this message translates to:
  /// **'Use these details'**
  String get continueWithProduct;

  /// No description provided for @continueManually.
  ///
  /// In en, this message translates to:
  /// **'Continue manually'**
  String get continueManually;

  /// No description provided for @cachedProduct.
  ///
  /// In en, this message translates to:
  /// **'Saved product information'**
  String get cachedProduct;

  /// No description provided for @staleProduct.
  ///
  /// In en, this message translates to:
  /// **'Offline or service unavailable — showing older saved information.'**
  String get staleProduct;

  /// No description provided for @offAttribution.
  ///
  /// In en, this message translates to:
  /// **'Product data: Open Food Facts · ODbL / DbCL. Images: CC BY-SA.'**
  String get offAttribution;

  /// No description provided for @offDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Development version: Open Food Facts staging database. Coverage differs from production.'**
  String get offDevelopment;

  /// No description provided for @noProductName.
  ///
  /// In en, this message translates to:
  /// **'Name unavailable'**
  String get noProductName;

  /// No description provided for @readDate.
  ///
  /// In en, this message translates to:
  /// **'Read printed date'**
  String get readDate;

  /// No description provided for @ocrGuide.
  ///
  /// In en, this message translates to:
  /// **'Photograph the date and its label (EXP, Best Before or MFG) clearly. Review every result; nothing is applied automatically.'**
  String get ocrGuide;

  /// No description provided for @ocrArabicLimit.
  ///
  /// In en, this message translates to:
  /// **'Recognition uses ML Kit Latin text. Arabic script may not be read reliably; Arabic digits are supported by the date parser when detected.'**
  String get ocrArabicLimit;

  /// No description provided for @captureDate.
  ///
  /// In en, this message translates to:
  /// **'Take date photo'**
  String get captureDate;

  /// No description provided for @galleryDate.
  ///
  /// In en, this message translates to:
  /// **'Choose date photo'**
  String get galleryDate;

  /// No description provided for @readingDate.
  ///
  /// In en, this message translates to:
  /// **'Reading date on this device…'**
  String get readingDate;

  /// No description provided for @ocrFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read this photo. Try a clearer image or enter the date manually.'**
  String get ocrFailed;

  /// No description provided for @noDates.
  ///
  /// In en, this message translates to:
  /// **'No complete date found. Month/year alone needs manual interpretation.'**
  String get noDates;

  /// No description provided for @dateCandidates.
  ///
  /// In en, this message translates to:
  /// **'Possible dates — choose one to review'**
  String get dateCandidates;

  /// No description provided for @dateAmbiguous.
  ///
  /// In en, this message translates to:
  /// **'Day/month order is ambiguous. Check the package.'**
  String get dateAmbiguous;

  /// No description provided for @manufactureDate.
  ///
  /// In en, this message translates to:
  /// **'Manufacture date — cannot be used as expiry'**
  String get manufactureDate;

  /// No description provided for @unknownDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Unidentified printed date'**
  String get unknownDateLabel;

  /// No description provided for @confirmPrintedDate.
  ///
  /// In en, this message translates to:
  /// **'Confirm or correct date'**
  String get confirmPrintedDate;

  /// No description provided for @applyDate.
  ///
  /// In en, this message translates to:
  /// **'Confirm this date'**
  String get applyDate;

  /// No description provided for @manualDate.
  ///
  /// In en, this message translates to:
  /// **'Enter date manually'**
  String get manualDate;

  /// No description provided for @ocrLocal.
  ///
  /// In en, this message translates to:
  /// **'Date photos are processed locally and are not added to the product photo.'**
  String get ocrLocal;

  /// No description provided for @offSourceSaved.
  ///
  /// In en, this message translates to:
  /// **'This batch was filled using Open Food Facts. The saved details may have been edited.'**
  String get offSourceSaved;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Expiry reminders'**
  String get reminders;

  /// No description provided for @remindersIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose when FreshKeep reminds you to review the date on each batch.'**
  String get remindersIntro;

  /// No description provided for @enableReminders.
  ///
  /// In en, this message translates to:
  /// **'Enable reminders'**
  String get enableReminders;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTime;

  /// No description provided for @reminderOffsets.
  ///
  /// In en, this message translates to:
  /// **'Days before the printed date'**
  String get reminderOffsets;

  /// No description provided for @addOffset.
  ///
  /// In en, this message translates to:
  /// **'Add days'**
  String get addOffset;

  /// No description provided for @offsetHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose 0–365 days; 0 means the printed date. Up to 8 reminders per batch.'**
  String get offsetHelp;

  /// No description provided for @offsetError.
  ///
  /// In en, this message translates to:
  /// **'Choose 1–8 distinct reminder days between 0 and 365.'**
  String get offsetError;

  /// No description provided for @notificationDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked. Allow them in Android app settings, then try enabling reminders again.'**
  String get notificationDenied;

  /// No description provided for @reminderTimingNote.
  ///
  /// In en, this message translates to:
  /// **'Android may delay reminders because of battery, Doze or manufacturer restrictions. Exact delivery is not guaranteed. Reopen FreshKeep after changing time zones or force-stopping the app.'**
  String get reminderTimingNote;

  /// No description provided for @reminderFailure.
  ///
  /// In en, this message translates to:
  /// **'Reminder scheduling could not finish. Your saved food data is safe; retry scheduling.'**
  String get reminderFailure;

  /// No description provided for @retryReminders.
  ///
  /// In en, this message translates to:
  /// **'Refresh reminders'**
  String get retryReminders;

  /// No description provided for @reminderCap.
  ///
  /// In en, this message translates to:
  /// **'Only the earliest 400 future reminders are scheduled. Later reminders are added as space becomes available when you reopen the app.'**
  String get reminderCap;

  /// No description provided for @expiryNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'FreshKeep · Review a food date'**
  String get expiryNotificationTitle;

  /// No description provided for @addShopping.
  ///
  /// In en, this message translates to:
  /// **'Add to shopping'**
  String get addShopping;

  /// No description provided for @editShopping.
  ///
  /// In en, this message translates to:
  /// **'Edit shopping item'**
  String get editShopping;

  /// No description provided for @shoppingEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your shopping list is empty. Add what you need for your next shop.'**
  String get shoppingEmpty;

  /// No description provided for @purchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get purchased;

  /// No description provided for @toBuy.
  ///
  /// In en, this message translates to:
  /// **'To buy'**
  String get toBuy;

  /// No description provided for @allItems.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allItems;

  /// No description provided for @convertToInventory.
  ///
  /// In en, this message translates to:
  /// **'Add purchased batch to inventory'**
  String get convertToInventory;

  /// No description provided for @convertedToInventory.
  ///
  /// In en, this message translates to:
  /// **'Added to inventory'**
  String get convertedToInventory;

  /// No description provided for @shoppingConvertNote.
  ///
  /// In en, this message translates to:
  /// **'Review this purchased batch and confirm its printed date. Saving adds the food and marks this shopping item as purchased in one transaction.'**
  String get shoppingConvertNote;

  /// No description provided for @restockTitle.
  ///
  /// In en, this message translates to:
  /// **'Buy again'**
  String get restockTitle;

  /// No description provided for @restockNote.
  ///
  /// In en, this message translates to:
  /// **'Consumed products with no available batch and no unpurchased shopping entry. Suggestions are never added automatically.'**
  String get restockNote;

  /// No description provided for @deleteShoppingTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete shopping item?'**
  String get deleteShoppingTitle;

  /// No description provided for @deleteShoppingBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the shopping entry. An already converted food batch remains in inventory.'**
  String get deleteShoppingBody;

  /// No description provided for @shoppingSaved.
  ///
  /// In en, this message translates to:
  /// **'Added to your shopping list'**
  String get shoppingSaved;

  /// No description provided for @recipeSearch.
  ///
  /// In en, this message translates to:
  /// **'Search recipes or ingredients'**
  String get recipeSearch;

  /// No description provided for @recipeFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get recipeFavorites;

  /// No description provided for @recipeAll.
  ///
  /// In en, this message translates to:
  /// **'All recipes'**
  String get recipeAll;

  /// No description provided for @recipeQuick.
  ///
  /// In en, this message translates to:
  /// **'20 minutes or less'**
  String get recipeQuick;

  /// No description provided for @recipeBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get recipeBreakfast;

  /// No description provided for @recipeMain.
  ///
  /// In en, this message translates to:
  /// **'Main dishes'**
  String get recipeMain;

  /// No description provided for @recipeSalad.
  ///
  /// In en, this message translates to:
  /// **'Salads'**
  String get recipeSalad;

  /// No description provided for @recipeSoup.
  ///
  /// In en, this message translates to:
  /// **'Soups'**
  String get recipeSoup;

  /// No description provided for @recipeSnack.
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get recipeSnack;

  /// No description provided for @recipeIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get recipeIngredients;

  /// No description provided for @recipeSteps.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get recipeSteps;

  /// No description provided for @recipeMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get recipeMissing;

  /// No description provided for @recipeEnough.
  ///
  /// In en, this message translates to:
  /// **'Enough in inventory'**
  String get recipeEnough;

  /// No description provided for @recipePartial.
  ///
  /// In en, this message translates to:
  /// **'Some available; more needed'**
  String get recipePartial;

  /// No description provided for @recipeUnmeasured.
  ///
  /// In en, this message translates to:
  /// **'Name found; unit cannot be compared'**
  String get recipeUnmeasured;

  /// No description provided for @recipeMatchingNote.
  ///
  /// In en, this message translates to:
  /// **'Matches use known ingredient names and compatible units. Check identity, amounts, allergies and food condition yourself. Past-date batches are excluded; a date match does not guarantee safety. Water and other staples are listed too; confirm what you have.'**
  String get recipeMatchingNote;

  /// No description provided for @recipeRankNote.
  ///
  /// In en, this message translates to:
  /// **'Sorted to use matching ingredients nearest their printed date first.'**
  String get recipeRankNote;

  /// No description provided for @recipeNoResults.
  ///
  /// In en, this message translates to:
  /// **'No recipes match these filters.'**
  String get recipeNoResults;

  /// No description provided for @recipeFavoriteAdd.
  ///
  /// In en, this message translates to:
  /// **'Save recipe to favorites'**
  String get recipeFavoriteAdd;

  /// No description provided for @recipeFavoriteRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove recipe from favorites'**
  String get recipeFavoriteRemove;

  /// No description provided for @recipeLibraryNote.
  ///
  /// In en, this message translates to:
  /// **'12 original recipes + 20 fitness recipes · available offline · nutrition is estimated per serving'**
  String get recipeLibraryNote;

  /// No description provided for @recipeAddMissing.
  ///
  /// In en, this message translates to:
  /// **'Add missing amount to shopping'**
  String get recipeAddMissing;

  /// No description provided for @recipeReviewAmount.
  ///
  /// In en, this message translates to:
  /// **'Review the required amount'**
  String get recipeReviewAmount;

  /// No description provided for @recipeStockUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Inventory is unavailable. Ingredient matches cannot be calculated until it reloads.'**
  String get recipeStockUnavailable;

  /// No description provided for @expiryNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{{name} — package date {date}. Review this batch today.} =1{{name} — package date {date}. Review tomorrow’s date and the food’s condition.} other{{name} — package date {date}. {days} days remaining; review the package and food condition.}}'**
  String expiryNotificationBody(String name, String date, int days);

  /// No description provided for @reminderCount.
  ///
  /// In en, this message translates to:
  /// **'Scheduled reminders: {count} of {total}'**
  String reminderCount(int count, int total);

  /// No description provided for @recipeMeta.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min · Serves {servings}'**
  String recipeMeta(int minutes, int servings);

  /// No description provided for @recipeMatchCount.
  ///
  /// In en, this message translates to:
  /// **'Enough in stock: {count} of {total} ingredients'**
  String recipeMatchCount(int count, int total);

  /// No description provided for @daysBeforeDate.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{On the printed date} =1{1 day before} other{{days} days before}}'**
  String daysBeforeDate(int days);

  /// No description provided for @saveShopping.
  ///
  /// In en, this message translates to:
  /// **'Save item'**
  String get saveShopping;

  /// No description provided for @deleteShopping.
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get deleteShopping;

  /// No description provided for @statsIntro.
  ///
  /// In en, this message translates to:
  /// **'Your food, over time'**
  String get statsIntro;

  /// No description provided for @statsMethod.
  ///
  /// In en, this message translates to:
  /// **'Each batch counts once in its latest used or discarded state. Restoring reverses it; deleting keeps its history. Counts are batches, not quantities.'**
  String get statsMethod;

  /// No description provided for @statsUsed.
  ///
  /// In en, this message translates to:
  /// **'Used batches'**
  String get statsUsed;

  /// No description provided for @statsDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Discarded batches'**
  String get statsDiscarded;

  /// No description provided for @statsWeek.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get statsWeek;

  /// No description provided for @statsMonth.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get statsMonth;

  /// No description provided for @statsTrend.
  ///
  /// In en, this message translates to:
  /// **'Last six periods'**
  String get statsTrend;

  /// No description provided for @statsAll.
  ///
  /// In en, this message translates to:
  /// **'All recorded time'**
  String get statsAll;

  /// No description provided for @statsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your story starts with your next batch'**
  String get statsEmpty;

  /// No description provided for @statsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Mark a batch as used or discarded in inventory to see real trends here. No outcomes have been recorded yet.'**
  String get statsEmptyBody;

  /// No description provided for @statsRangeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No outcomes in these six periods. Older outcomes remain in the all-time totals.'**
  String get statsRangeEmpty;

  /// No description provided for @statsValue.
  ///
  /// In en, this message translates to:
  /// **'Estimated batch value'**
  String get statsValue;

  /// No description provided for @statsValueNote.
  ///
  /// In en, this message translates to:
  /// **'Sum of entered total batch prices only, in your own monetary unit. No currency conversion or guaranteed savings. Use one currency consistently. Missing prices are excluded.'**
  String get statsValueNote;

  /// No description provided for @statsNoPrice.
  ///
  /// In en, this message translates to:
  /// **'No entered prices'**
  String get statsNoPrice;

  /// No description provided for @statsPriced.
  ///
  /// In en, this message translates to:
  /// **'Priced batches'**
  String get statsPriced;

  /// No description provided for @statsData.
  ///
  /// In en, this message translates to:
  /// **'Chart data and dates'**
  String get statsData;

  /// No description provided for @statsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Some incomplete history could not be counted. Export your data for review.'**
  String get statsInvalid;

  /// No description provided for @privacyTools.
  ///
  /// In en, this message translates to:
  /// **'Data and privacy'**
  String get privacyTools;

  /// No description provided for @privacyDetail.
  ///
  /// In en, this message translates to:
  /// **'Inventory, events, shopping, personal recipes, cooking timers and preferences are stored on this device. Barcode lookup contacts Open Food Facts; loading product photos contacts its image service. Date recognition runs on-device. There are no active ads or subscriptions.'**
  String get privacyDetail;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export JSON data'**
  String get exportData;

  /// No description provided for @exportNote.
  ///
  /// In en, this message translates to:
  /// **'Choose where to save a readable snapshot of inventory, history, consumption, shopping, favorites, personal recipes, timers and reminder settings. Photos and private file paths are excluded. Keep the file private. This is an export, not a restore feature.'**
  String get exportNote;

  /// No description provided for @exportDone.
  ///
  /// In en, this message translates to:
  /// **'Export saved'**
  String get exportDone;

  /// No description provided for @exportCancelled.
  ///
  /// In en, this message translates to:
  /// **'Export cancelled'**
  String get exportCancelled;

  /// No description provided for @deleteLocal.
  ///
  /// In en, this message translates to:
  /// **'Delete personal data'**
  String get deleteLocal;

  /// No description provided for @deleteLocalNote.
  ///
  /// In en, this message translates to:
  /// **'Permanently removes inventory and history, shopping, favorites, personal recipes and photos, cooking timers, cached products, food photos and reminders. Language, appearance and the 12 bundled recipes remain. Exported files remain. This cannot be undone.'**
  String get deleteLocalNote;

  /// No description provided for @deleteAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I understand that my personal data will be permanently deleted'**
  String get deleteAcknowledge;

  /// No description provided for @deleteDone.
  ///
  /// In en, this message translates to:
  /// **'Personal data deleted'**
  String get deleteDone;

  /// No description provided for @dataBusy.
  ///
  /// In en, this message translates to:
  /// **'Working on your local data…'**
  String get dataBusy;

  /// No description provided for @dataError.
  ///
  /// In en, this message translates to:
  /// **'Could not finish. Retry; some cleanup may still be pending.'**
  String get dataError;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
