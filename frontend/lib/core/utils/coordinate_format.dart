/// Latitude then longitude, isolated as left-to-right so an Arabic
/// paragraph cannot swap the pair.
String formatLatLng(double latitude, double longitude, {int fractionDigits = 3}) {
  final lat = latitude.toStringAsFixed(fractionDigits);
  final lng = longitude.toStringAsFixed(fractionDigits);
  return '\u2066$lat, $lng\u2069';
}
