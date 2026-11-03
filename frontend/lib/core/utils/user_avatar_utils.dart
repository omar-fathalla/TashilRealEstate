import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Helper utility for extracting user initials and formatting profile identities
class UserAvatarUtils {
  /// Safely retrieves the current Firebase Auth user without throwing in test environments
  static User? get safeCurrentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Extracts photo URL safely from user (checking root photoURL and providerData)
  static String? getPhotoUrl(User? user) {
    if (user == null) return null;
    try {
      String? rawUrl = user.photoURL;
      if (rawUrl == null || rawUrl.trim().isEmpty) {
        for (final provider in user.providerData) {
          if (provider.photoURL != null && provider.photoURL!.trim().isNotEmpty) {
            rawUrl = provider.photoURL!.trim();
            break;
          }
        }
      }
      if (rawUrl != null && rawUrl.trim().isNotEmpty) {
        String cleanUrl = rawUrl.trim();
        if (cleanUrl.startsWith('http://')) {
          cleanUrl = 'https://${cleanUrl.substring(7)}';
        }
        // Upgrade Google profile photo resolution if standard low-res s96-c is present
        if (cleanUrl.contains('googleusercontent.com') && cleanUrl.contains('=s96-c')) {
          cleanUrl = cleanUrl.replaceAll('=s96-c', '=s256-c');
        }
        return cleanUrl;
      }
    } catch (_) {}
    return null;
  }

  /// Extracts 1 or 2 uppercase initials from a display name or email
  static String getInitials(String? name, [String fallback = 'U']) {
    if (name == null) return fallback;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return fallback;

    // Handle names with multiple words (e.g. "Mohamed Fathallah" -> "MF", "محمد فتح الله" -> "م ف")
    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      final firstChar = parts.first.characters.first;
      final secondChar = parts[1].characters.first;
      final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(firstChar) ||
          RegExp(r'[\u0600-\u06FF]').hasMatch(secondChar);
      return isArabic ? '$firstChar $secondChar' : '$firstChar$secondChar'.toUpperCase();
    } else if (parts.isNotEmpty && parts.first.isNotEmpty) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return fallback;
  }

  /// Resolves the display name for an authenticated user or falls back cleanly
  static String getDisplayName(User? user, String fallback) {
    if (user == null) return fallback;
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim();
    }
    if (user.email != null && user.email!.trim().isNotEmpty) {
      final username = user.email!.split('@').first.trim();
      if (username.isNotEmpty) return username;
    }
    return fallback;
  }

  /// Extracts first name from full name or email
  static String getFirstName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.first : '';
  }

  /// Extracts surname/last name from full name
  static String getSurname(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length > 1) {
      return parts.sublist(1).join(' ');
    }
    return '';
  }

  /// Resolves the subtitle (email if available, or fallback role description)
  static String getSubtitle(User? user, String fallbackRole) {
    if (user != null && user.email != null && user.email!.trim().isNotEmpty) {
      return user.email!.trim();
    }
    return fallbackRole;
  }

  /// Builds a standard M3 circle avatar that supports Base64 Data URIs and Google photo URLs,
  /// with a graceful fallback to user initials.
  static Widget buildAvatar({
    required BuildContext context,
    String? photoUrl,
    required String displayName,
    String fallbackInitials = 'AF',
    double radius = 24.0,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final initials = getInitials(displayName, fallbackInitials);

    Widget buildFallback() {
      return CircleAvatar(
        radius: radius,
        backgroundColor: colorScheme.primary,
        child: Text(
          initials,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold),
        ),
      );
    }

    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      final cleanUrl = photoUrl.trim();

      // Check if photo is a base64 Data URI
      if (cleanUrl.startsWith('data:image')) {
        try {
          final commaIndex = cleanUrl.indexOf(',');
          final base64String = commaIndex != -1 ? cleanUrl.substring(commaIndex + 1) : cleanUrl;
          final bytes = base64Decode(base64String.trim());
          return CircleAvatar(
            radius: radius,
            backgroundColor: colorScheme.surfaceContainerHighest,
            child: ClipOval(
              child: Image.memory(
                bytes,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => buildFallback(),
              ),
            ),
          );
        } catch (_) {
          return buildFallback();
        }
      }

      // Otherwise network URL (e.g. Google photo)
      return CircleAvatar(
        radius: radius,
        backgroundColor: colorScheme.surfaceContainerHighest,
        child: ClipOval(
          child: Image.network(
            cleanUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            headers: const {'Referrer-Policy': 'no-referrer'},
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: SizedBox(
                  width: radius * 0.7,
                  height: radius * 0.7,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: colorScheme.primary,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint('UserAvatarUtils.buildAvatar error: $error for $cleanUrl');
              return buildFallback();
            },
          ),
        ),
      );
    }

    return buildFallback();
  }
}
