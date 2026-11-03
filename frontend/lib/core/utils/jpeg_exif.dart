import 'dart:typed_data';

/// Removes the JPEG APP1 segment, which is where EXIF and GPS live.
///
/// Other segments are kept. Bytes that are not a JPEG, or that cannot be
/// parsed, are returned unchanged.
Uint8List stripJpegExif(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
    return bytes;
  }
  final out = BytesBuilder(copy: false);
  out.addByte(0xFF);
  out.addByte(0xD8);
  var i = 2;
  while (i + 3 < bytes.length) {
    if (bytes[i] != 0xFF) {
      return bytes;
    }
    final marker = bytes[i + 1];
    if (marker == 0xDA || marker == 0xD9) {
      out.add(bytes.sublist(i));
      return out.toBytes();
    }
    if (marker == 0x00 || marker == 0x01 || (marker >= 0xD0 && marker <= 0xD8)) {
      out.addByte(0xFF);
      out.addByte(marker);
      i += 2;
      continue;
    }
    final length = (bytes[i + 2] << 8) | bytes[i + 3];
    if (length < 2 || i + 2 + length > bytes.length) {
      return bytes;
    }
    final isExif = marker == 0xE1;
    if (!isExif) {
      out.add(bytes.sublist(i, i + 2 + length));
    }
    i += 2 + length;
  }
  return bytes;
}
