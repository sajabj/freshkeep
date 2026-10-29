import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Override in tests so visual baselines never depend on wall-clock time.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
