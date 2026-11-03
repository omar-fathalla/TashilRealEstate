import 'package:flutter_web_plugins/url_strategy.dart';

/// Use real paths (`/login`) so Firebase email links and deep links resolve.
/// Hosting already rewrites every path to `index.html` in `firebase.json`.
void configureUrlStrategy() => usePathUrlStrategy();
