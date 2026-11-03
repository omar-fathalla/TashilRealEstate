import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/utils/jpeg_exif.dart';

void main() {
  test('stripJpegExif removes the APP1 segment and keeps the scan', () {
    final bytes = Uint8List.fromList([
      0xFF, 0xD8,
      0xFF, 0xE1, 0x00, 0x08, 0x45, 0x78, 0x69, 0x66, 0x00, 0x00,
      0xFF, 0xDA, 0x00, 0x02, 0x00, 0xFF, 0xD9,
    ]);

    final stripped = stripJpegExif(bytes);

    expect(stripped.sublist(0, 2), [0xFF, 0xD8]);
    expect(stripped.contains(0xE1), isFalse);
    expect(stripped.contains(0xDA), isTrue);
    expect(stripped.last, 0xD9);
  });

  test('stripJpegExif leaves non-JPEG bytes alone', () {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    expect(stripJpegExif(bytes), bytes);
  });
}
