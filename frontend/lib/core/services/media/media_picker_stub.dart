import 'package:image_picker/image_picker.dart';
import 'media_picker_service.dart';

MediaPickerPlatform getMediaPickerPlatform() => StubMediaPicker();

class StubMediaPicker implements MediaPickerPlatform {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<List<String>> pickImages() async {
    try {
      final picked = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 72,
      );
      return picked.map((x) => x.path).toList();
    } catch (_) {
      return [];
    }
  }
}
