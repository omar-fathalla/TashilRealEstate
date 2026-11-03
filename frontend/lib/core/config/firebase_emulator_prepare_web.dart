import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Must match `supportedFirebaseJsSdkVersion` in firebase_core_web.
const String _firebaseJsSdkVersion = '12.18.0';

/// Connects the Auth emulator before FlutterFire's first `onAuthStateChanged`.
///
/// `Firebase.initializeApp` restores a persisted user inside
/// `ensurePluginInitialized`, which is too late for a later `useAuthEmulator`.
/// Wrapping `initializeAuth` calls `connectAuthEmulator` before that listener.
Future<void> prepareAuthEmulatorBeforeInit(String origin) async {
  if (!_isLoopbackOrigin(origin)) {
    throw StateError(
      'Refusing to point Auth at a non-loopback emulator origin.',
    );
  }
  globalContext['flutterfire_web_sdk_version'] = _firebaseJsSdkVersion.toJS;
  web.window.sessionStorage.setItem('[DEFAULT]-firebaseEmulatorOrigin', origin);

  await _loadModule(
    'https://www.gstatic.com/firebasejs/$_firebaseJsSdkVersion/firebase-app.js',
    'firebase_core',
  );
  await _loadModule(
    'https://www.gstatic.com/firebasejs/$_firebaseJsSdkVersion/firebase-auth.js',
    'firebase_auth',
  );

  final authNs = globalContext['firebase_auth'];
  if (authNs == null || authNs.isUndefinedOrNull) {
    throw StateError('Firebase Auth JS SDK did not load.');
  }
  final namespace = authNs as JSObject;
  if (namespace['__tashilEmulatorWrapped'] == true.toJS) return;

  final original = namespace['initializeAuth'] as JSFunction;
  final connect = namespace['connectAuthEmulator'] as JSFunction;
  JSAny? wrapped(JSAny? app, JSAny? options) {
    final auth = original.callAsFunction(namespace, app, options);
    connect.callAsFunction(namespace, auth, origin.toJS);
    return auth;
  }

  namespace['initializeAuth'] = wrapped.toJS;
  namespace['__tashilEmulatorWrapped'] = true.toJS;
}

bool _isLoopbackOrigin(String origin) {
  final uri = Uri.tryParse(origin);
  if (uri == null || uri.scheme != 'http') return false;
  final host = uri.host.toLowerCase();
  return host == 'localhost' || host == '::1' || host.startsWith('127.');
}

Future<void> _loadModule(String src, String windowVar) async {
  if (globalContext[windowVar] != null) return;
  final script = web.document.createElement('script') as web.HTMLScriptElement;
  final trigger = 'ff_trigger_$windowVar';
  script.text = '''
    window.$trigger = async (callback) => {
      callback(await import("$src"));
    };
  ''';
  web.document.head!.appendChild(script);
  final completer = Completer<void>();
  globalContext.callMethod(
    trigger.toJS,
    ((JSAny module) {
      globalContext[windowVar] = module;
      globalContext.delete(trigger.toJS);
      if (!completer.isCompleted) completer.complete();
    }).toJS,
  );
  await completer.future;
}
