import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Who is signed in to the agency workspace: the account and the agency it manages (TAQ-153).
class AgencyIdentity {
  final String displayName;
  final String email;
  final String agencyId;
  final String agencyName;
  final Map<String, String> agencyNames;

  /// True for an AgencyAgent (TAQ-169), false for the AgencyAdmin.
  final bool isAgent;

  const AgencyIdentity({
    this.displayName = '',
    this.email = '',
    this.agencyId = '',
    this.agencyName = '',
    this.agencyNames = const {},
    this.isAgent = false,
  });

  static const empty = AgencyIdentity();

  /// The name to show for the person: the profile name, else the email, else empty.
  String get personName {
    final name = displayName.trim();
    return name.isNotEmpty ? name : email.trim();
  }

  /// The agency name in [languageCode] when the agency has one, else its main name.
  String agencyNameFor(String languageCode) {
    final localized = agencyNames[languageCode];
    if (localized != null && localized.trim().isNotEmpty) return localized.trim();
    return agencyName.trim();
  }

  /// Up to two letters for the avatar: the first letters of the first two words of the name, or
  /// the first letter of the email. Empty when there is nothing to show.
  String get initials {
    final source = personName;
    if (source.isEmpty) return '';
    final base = source.contains('@') && !source.contains(' ') ? source.split('@').first : source;
    final words = base.split(RegExp(r'[\s._-]+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';
    final letters = words.take(2).map((w) => String.fromCharCode(w.runes.first)).join();
    return letters.toUpperCase();
  }
}

abstract class AgencyIdentitySource {
  Future<AgencyIdentity> load();

  /// Sends a password reset email to [email].
  Future<void> sendPasswordReset(String email);
}

class FirebaseAgencyIdentitySource implements AgencyIdentitySource {
  @override
  Future<AgencyIdentity> load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return AgencyIdentity.empty;
    final claims = (await user.getIdTokenResult()).claims ?? const {};
    final claimed = claims['agency_id'];
    final agencyId = claimed is String ? claimed : '';
    var agencyName = '';
    var agencyNames = <String, String>{};
    if (agencyId.isNotEmpty) {
      try {
        final data = (await FirebaseFirestore.instance.collection('Agencies').doc(agencyId).get()).data();
        if (data != null) {
          agencyName = data['name'] is String ? data['name'] as String : '';
          final names = data['names'];
          if (names is Map) {
            agencyNames = {
              for (final e in names.entries)
                if (e.key is String && e.value is String) e.key as String: e.value as String,
            };
          }
        }
      } catch (_) {
        // The name is a nicety; the tile falls back to the account.
      }
    }
    return AgencyIdentity(
      displayName: user.displayName ?? '',
      email: user.email ?? '',
      agencyId: agencyId,
      agencyName: agencyName,
      agencyNames: agencyNames,
      isAgent: claims['role'] == 'AgencyAgent',
    );
  }

  @override
  Future<void> sendPasswordReset(String email) => FirebaseAuth.instance.sendPasswordResetEmail(email: email);
}
