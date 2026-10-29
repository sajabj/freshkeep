import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/storage_guide_repository.dart';
import '../domain/storage_food.dart';

final storageGuideProvider = FutureProvider<List<StorageFood>>(
  (_) => StorageGuideRepository().load(),
);
