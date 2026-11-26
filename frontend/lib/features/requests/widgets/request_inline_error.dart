import 'package:flutter/material.dart';

/// An error shown inside a sheet or dialog, next to the control that failed. A snackbar from the
/// root ScaffoldMessenger is drawn under a modal sheet, so errors of the request flows are
/// rendered here instead (TAQ-132). [message] must be a translated, generic text: it never carries
/// anything the server or the user typed.
class RequestInlineError extends StatelessWidget {
  final String message;
  const RequestInlineError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsetsDirectional.all(12),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, size: 20, color: scheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Scrolls the error under [key] into view after the next frame, so it is not left behind the
/// keyboard on a small screen. The scrollable around it must end above the keyboard.
void revealInlineError(GlobalKey key) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = key.currentContext;
    if (context != null && context.mounted) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.25,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  });
}
