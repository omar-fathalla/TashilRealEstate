/// Trakheesi advertising-permit checks.
///
/// Dubai listings must carry a numeric permit. Other emirates may leave it blank.
/// A filled value is still checked so a mistyped number is not published.
class AdvertisingPermit {
  static final RegExp pattern = RegExp(r'^[0-9]{6,15}$');

  static bool isRequiredFor(String? cityCode) => cityCode == 'dubai';

  /// Returns a localization key when the value cannot be saved, or null when it can.
  static String? errorKey({
    required String value,
    required String? cityCode,
  }) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return isRequiredFor(cityCode) ? 'adPermitRequired' : null;
    }
    if (!pattern.hasMatch(trimmed)) return 'adPermitInvalid';
    return null;
  }
}
