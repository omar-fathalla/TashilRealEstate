import 'package:cloud_functions/cloud_functions.dart';

/// What a failed Cloud Function call said: the Firebase error code and the server's own message.
class CallableErrorInfo {
  final String code;
  final String message;
  const CallableErrorInfo(this.code, this.message);

  /// "code: message", for places that show the raw reason (for example a snackbar for an admin).
  String get text => message.isEmpty ? code : '$code: $message';
}

CallableErrorInfo describeCallableError(Object error) {
  if (error is FirebaseFunctionsException) {
    return CallableErrorInfo(error.code, error.message ?? '');
  }
  return CallableErrorInfo('unknown', error.toString());
}
