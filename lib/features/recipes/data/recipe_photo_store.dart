import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class RecipePhotoStore {
  Future<String?> pick(ImageSource source) async {
    final selected = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (selected == null) return null;
    final folder = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'recipe_photos'),
    );
    await folder.create(recursive: true);
    final ext =
        [
          '.jpg',
          '.jpeg',
          '.png',
          '.webp',
          '.heic',
        ].contains(p.extension(selected.path).toLowerCase())
        ? p.extension(selected.path).toLowerCase()
        : '.jpg';
    final target = p.join(folder.path, '${const Uuid().v4()}$ext');
    await selected.saveTo(target);
    return target;
  }

  Future<void> delete(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } on FileSystemException {
      /* Missing photos are safe. */
    }
  }
}
