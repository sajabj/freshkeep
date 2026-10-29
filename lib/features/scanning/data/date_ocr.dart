import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

final dateOcrProvider = Provider<DateOcr>((ref) => DateOcr());

class DateOcr {
  Future<String?> pickAndRead(ImageSource source) async {
    final image = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 95,
    );
    if (image == null) return null;
    return readPath(image.path);
  }

  Future<String> readPath(String path) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      return (await recognizer.processImage(InputImage.fromFilePath(path)))
          .text;
    } finally {
      await recognizer.close();
    }
  }
}
