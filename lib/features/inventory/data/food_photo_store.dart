import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class FoodPhotoStore {
  Future<String?> pick() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (file == null) return null;
    return import(file);
  }

  Future<String> import(XFile photo) async {
    final folder = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'food_photos'),
    );
    await folder.create(recursive: true);
    final extension = p.extension(photo.path).toLowerCase();
    final suffix =
        ['.jpg', '.jpeg', '.png', '.webp', '.heic'].contains(extension)
        ? extension
        : '.jpg';
    final path = p.join(folder.path, '${const Uuid().v4()}$suffix');
    await photo.saveTo(path);
    return path;
  }

  /// Only clean temporary copies created by this unsaved form. A reused photo
  /// may belong to another batch; saved files are never deleted blindly.
  Future<void> discardStaged(Iterable<String> paths) async {
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } on FileSystemException {
        /* A staging cleanup must not interrupt navigation. */
      }
    }
  }
}
