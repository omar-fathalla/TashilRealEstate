/// Keeps the current page while a request is being sent (TAQ-190). On web, browser Back changes
/// the location instead of popping, so the router would swap the page and drop the open sheet or
/// dialog with it; PopScope can't stop that. Every app route's `onExit` refuses to leave while a
/// hold is active. Only the send itself holds, so navigation is never blocked for long.
class NavigationLock {
  NavigationLock._();

  static int _holds = 0;

  /// Whether leaving the current page is refused now.
  static bool get held => _holds > 0;

  /// Runs [action] with leaving the page refused until it finishes, successfully or not.
  static Future<T> holdWhile<T>(Future<T> Function() action) async {
    _holds++;
    try {
      return await action();
    } finally {
      _holds--;
    }
  }
}
