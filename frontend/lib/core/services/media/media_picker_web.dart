import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'media_picker_service.dart';

@JS('tashilPickImages')
external void _tashilPickImages(JSFunction onImagesSelected);

MediaPickerPlatform getMediaPickerPlatform() => WebMediaPicker();

class WebMediaPicker implements MediaPickerPlatform {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<List<String>> pickImages() async {
    final completer = Completer<List<String>>();

    void onSelected(JSString jsonStr) {
      try {
        final dartStr = jsonStr.toDart;
        final decoded = jsonDecode(dartStr);
        if (decoded is List) {
          completer.complete(decoded.map((e) => e.toString()).toList());
          return;
        }
      } catch (e) {
        debugPrint('Error parsing picked web images: $e');
      }
      completer.complete([]);
    }

    try {
      _tashilPickImages(onSelected.toJS);
      return await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => [],
      );
    } catch (e) {
      debugPrint('Web JS file picker exception, falling back to ImagePicker: $e');
      try {
        final picked = await _picker.pickMultiImage(
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 72,
        );
        final results = <String>[];
        for (final file in picked) {
          final bytes = await file.readAsBytes();
          final mime = file.mimeType ?? 'image/jpeg';
          results.add('data:$mime;base64,${base64Encode(bytes)}');
        }
        return results;
      } catch (err) {
        debugPrint('ImagePicker fallback failed: $err');
        return [];
      }
    }
  }
}
