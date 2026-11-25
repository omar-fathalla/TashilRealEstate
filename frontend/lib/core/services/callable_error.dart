import 'package:cloud_functions/cloud_functions.dart';

/// What a failed Cloud Function call said: the Firebase error code, the server's own message and,
/// when the server sent one, the machine-readable `details.reason` (for example
/// `property_already_leased`).
class CallableErrorInfo {
  final String code;
  final String message;
  final String reason;
  const CallableErrorInfo(this.code, this.message, {this.reason = ''});

  /// "code: message", for places that show the raw reason (for example a snackbar for an admin).
  String get text => message.isEmpty ? code : '$code: $message';
}

CallableErrorInfo describeCallableError(Object error) {
  if (error is FirebaseFunctionsException) {
    final details = error.details;
    final reason = details is Map && details['reason'] is String ? details['reason'] as String : '';
    return CallableErrorInfo(error.code, error.message ?? '', reason: reason);
  }
  return CallableErrorInfo('unknown', error.toString());
}
