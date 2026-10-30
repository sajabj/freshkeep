
# 🥬 FreshKeep

### Smart Food Inventory & Expiry Management

FreshKeep is a Flutter mobile application designed to help users manage food inventory, track expiration dates, organize recipes, and reduce food waste.

The application combines local SQLite storage, barcode scanning, inventory management, meal planning, and smart ingredient consumption in a bilingual mobile experience.

## ✨ Features

### 📦 Food Inventory Management
- Add, edit, search, and delete food products.
- Track quantities, categories, and storage locations.
- Monitor expiration dates.
- Organize products using list and grid views.
- Track consumed and discarded products.

### 📷 Barcode Scanning
- Scan supported product barcodes using the camera.
- Retrieve available product information.
- Review product details before saving.
- Manually edit scanned information.

### 🍽️ Recipes & Meal Planning
- Browse recipes organized by category.
- Create and manage personal recipes.
- Plan breakfast, lunch, and dinner.
- View ingredients and preparation instructions.
- Use integrated cooking timers.

### 🧠 Smart Inventory Consumption
- Deduct ingredient quantities from inventory.
- Adjust recipe servings before consumption.
- Prioritize products approaching expiration.
- Distribute consumption across inventory batches.
- Support compatible unit conversions.
- Prevent invalid quantities and partial database updates.

### 📊 Statistics & Data Management
- View inventory and consumption statistics.
- Visualize data using charts.
- Export inventory data.
- Manage locally stored information.

### 🌍 User Experience
- Arabic and English language support.
- Right-to-left and left-to-right layouts.
- Light and dark themes.
- Food storage guidance.
- Responsive Flutter interface.

## 🛠️ Tech Stack

| Category | Technology |
|---|---|
| Framework | Flutter |
| Language | Dart |
| Local Database | SQLite |
| Data Visualization | fl_chart |
| Barcode Scanning | Camera and barcode scanning integration |
| Product Information | Open Food Facts API |
| Platform | Android |


## 🚀 Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- Android emulator or physical device

### Installation

Clone the repository:

```bash
git clone https://github.com/sajabj/freshkeep.git
cd freshkeep
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

## 🔐 Data & Privacy

FreshKeep uses local SQLite storage for inventory and application data.

Barcode-based product lookups may communicate with an external product information service.

Sensitive configuration files, signing credentials, and private user data should not be committed to the repository.

## 🎯 Engineering Highlights

- Local database integration and CRUD operations.
- Inventory quantity validation and batch management.
- Transaction-based database updates.
- Integration with barcode scanning and product APIs.
- Multilingual UI development.
- Modular Flutter application development.

## 👩‍💻 Developer

**Saja Bani Jami**

Computer Science Graduate | Software Developer

[GitHub Profile](https://github.com/sajabj)
