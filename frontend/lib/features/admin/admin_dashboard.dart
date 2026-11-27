import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/chips/tashil_chips.dart';
import 'package:tashil_real_estate/core/design_system/empty_state/tashil_empty_state.dart';
import 'package:tashil_real_estate/core/design_system/loading/tashil_loading.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/services/firebase_auth_service.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/features/admin/admin_data_source.dart';

enum _AdminView { listings, users, agencies }

/// Workspace for the platform Admin role (`/admin`): moderate listings, and read users and
/// agencies. It is deliberately smaller than the SuperAdmin dashboard: no roles, payments,
/// settings or lease data. The server enforces the same limits (firestore.rules,
/// `listUsersForAdmin`), so hiding a control here is never the only protection.
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, this.dataSource, this.onSignOut});

  final AdminDataSource? dataSource;
  final Future<void> Function()? onSignOut;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late final AdminDataSource _data = widget.dataSource ?? FirebaseAdminDataSource();
  _AdminView _view = _AdminView.listings;
  final List<AdminUserRow> _users = [];
  String? _usersNext;
  bool _usersStarted = false;
  bool _usersLoading = false;
  bool _usersFailed = false;
  final Set<String> _busy = {};
  bool _canVerifyAgencies = false;

  @override
  void initState() {
    super.initState();
    _data.canVerifyAgencies().then((value) {
      if (mounted && value) setState(() => _canVerifyAgencies = true);
    }).catchError((Object _) {});
  }

  Future<void> _run(String listingId, Future<void> Function() action, AppLocalizations loc) async {
    setState(() => _busy.add(listingId));
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.tr('adminActionFailed'))));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(listingId));
    }
  }

  Future<void> _signOut() async {
    await (widget.onSignOut ?? FirebaseAuthService().signOut)();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        final loc = AppLocalizations.of(context);
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          backgroundColor: colorScheme.surfaceContainerLow,
          appBar: AppBar(
            backgroundColor: colorScheme.surfaceContainerLowest,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.tr('appName'), style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  loc.tr('adminWorkspaceTitle'),
                  style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              TashilIconButton.tonal(
                icon: Icons.logout_rounded,
                size: 38,
                iconSize: 20,
                tooltip: loc.tr('logout'),
                onPressed: _signOut,
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TashilConnectedButtonGroup<_AdminView>(
                      isFullWidth: true,
                      selectedValue: _view,
                      onSelectionChanged: (value) {
                        setState(() => _view = value);
                        if (value == _AdminView.users) _loadUsers();
                      },
                      segments: [
                        TashilConnectedButtonSegment(
                          value: _AdminView.listings,
                          label: loc.tr('adminTabListings'),
                          icon: Icons.apartment_rounded,
                        ),
                        TashilConnectedButtonSegment(
                          value: _AdminView.users,
                          label: loc.tr('adminTabUsers'),
                          icon: Icons.people_alt_outlined,
                        ),
                        TashilConnectedButtonSegment(
                          value: _AdminView.agencies,
                          label: loc.tr('adminTabAgencies'),
                          icon: Icons.business_rounded,
                        ),
                      ],
                    ),
                    if (_view != _AdminView.listings) ...[
                      const SizedBox(height: 8),
                      Text(
                        loc.tr('adminReadOnlyNote'),
                        key: const Key('admin-read-only-note'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Expanded(child: _body(loc, locale.languageCode)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body(AppLocalizations loc, String lang) {
    switch (_view) {
      case _AdminView.listings:
        return _listings(loc, lang);
      case _AdminView.users:
        return _usersList(loc);
      case _AdminView.agencies:
        return _agencies(loc, lang);
    }
  }

  Widget _loading() => const Center(child: TashilLoadingIndicator(size: 48.0));

  Widget _empty(AppLocalizations loc, IconData icon, String key) =>
      TashilEmptyState(icon: icon, title: loc.tr(key), message: '');

  Widget _error(AppLocalizations loc) =>
      TashilEmptyState(icon: Icons.error_outline_rounded, title: loc.tr('adminLoadError'), message: '');

  Widget _listings(AppLocalizations loc, String lang) {
    return StreamBuilder<List<AdminListing>>(
      stream: _data.watchListings(lang),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _error(loc);
        final items = snapshot.data;
        if (items == null) return _loading();
        if (items.isEmpty) return _empty(loc, Icons.apartment_rounded, 'adminNoListings');
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _listingCard(items[index], loc, lang),
        );
      },
    );
  }

  Widget _listingCard(AdminListing item, AppLocalizations loc, String lang) {
    final theme = Theme.of(context);
    final busy = _busy.contains(item.id);
    final price = CurrencyFormatter.formatPriceWithCurrency(
      amount: item.pricePerMonth,
      currencyCode: item.currencyCode,
      langCode: lang,
    );
    return TashilCard.outlined(
      key: Key('admin-listing-${item.id}'),
      padding: const EdgeInsetsDirectional.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          if (item.location.isNotEmpty)
            Text(item.location, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(price, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TashilAssistChip(
                label: item.hidden
                    ? loc.tr('adminStatusHidden')
                    : (item.isPublished ? loc.tr('adminStatusLive') : loc.tr('adminStatusOffline')),
                icon: item.hidden
                    ? Icons.visibility_off_outlined
                    : (item.isPublished ? Icons.public_rounded : Icons.cloud_off_outlined),
              ),
              if (item.verified) TashilAssistChip(label: loc.tr('adminStatusVerified'), icon: Icons.verified_outlined),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TashilButton.tonal(
                key: Key('admin-verify-${item.id}'),
                label: item.verified ? loc.tr('adminUnverify') : loc.tr('adminVerify'),
                icon: Icons.verified_outlined,
                isLoading: busy,
                onPressed: busy ? null : () => _run(item.id, () => _data.setVerified(item.id, !item.verified), loc),
              ),
              if (item.hidden)
                TashilButton.outlined(
                  key: Key('admin-restore-${item.id}'),
                  label: loc.tr('adminRestore'),
                  icon: Icons.visibility_outlined,
                  onPressed: busy || !item.canRestore ? null : () => _run(item.id, () => _data.restore(item), loc),
                )
              else
                TashilButton.outlined(
                  key: Key('admin-hide-${item.id}'),
                  label: loc.tr('adminHide'),
                  icon: Icons.visibility_off_outlined,
                  onPressed: busy ? null : () => _run(item.id, () => _data.hide(item), loc),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Loads the first page, or the next one after the last user already shown. Pages are appended,
  /// so the directory can be read past the server's 100-user page size.
  Future<void> _loadUsers({bool more = false}) async {
    if (_usersLoading) return;
    if (!more && _usersStarted && !_usersFailed) return;
    final startAfter = more ? _usersNext : null;
    if (more && startAfter == null) return;
    setState(() {
      _usersStarted = true;
      _usersLoading = true;
      _usersFailed = false;
    });
    try {
      final page = await _data.loadUsers(startAfter: startAfter);
      if (!mounted) return;
      setState(() {
        _users.addAll(page.users);
        _usersNext = page.nextPageToken;
      });
    } catch (_) {
      if (mounted) setState(() => _usersFailed = true);
    } finally {
      if (mounted) setState(() => _usersLoading = false);
    }
  }

  Widget _usersList(AppLocalizations loc) {
    if (!_usersStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadUsers();
      });
      return _loading();
    }
    if (_usersFailed && _users.isEmpty) return _error(loc);
    if (_users.isEmpty) return _usersLoading ? _loading() : _empty(loc, Icons.people_alt_outlined, 'adminNoUsers');
    final hasMore = _usersNext != null;
    return ListView.separated(
      itemCount: _users.length + (hasMore || _usersFailed ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == _users.length) {
          return Center(
            child: TashilButton.tonal(
              key: const Key('admin-users-load-more'),
              label: _usersFailed ? loc.tr('adminLoadError') : loc.tr('adminLoadMore'),
              icon: Icons.expand_more_rounded,
              isLoading: _usersLoading,
              onPressed: _usersLoading ? null : () => _loadUsers(more: true),
            ),
          );
        }
        final user = _users[index];
        return TashilCard.outlined(
          key: Key('admin-user-${user.uid}'),
          padding: const EdgeInsetsDirectional.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName.isEmpty ? user.email : user.fullName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    if (user.fullName.isNotEmpty) Text(user.email, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (user.effectiveRole.isNotEmpty)
                    TashilAssistChip(key: Key('admin-user-role-${user.uid}'), label: _roleLabel(loc, user.effectiveRole)),
                  if (user.rolesDiffer)
                    TashilAssistChip(
                      key: Key('admin-user-profile-role-${user.uid}'),
                      label: '${loc.tr('adminProfileRole')}: ${_roleLabel(loc, user.role)}',
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _agencies(AppLocalizations loc, String lang) {
    return StreamBuilder<List<AdminAgencyRow>>(
      stream: _data.watchAgencies(lang),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _error(loc);
        final items = snapshot.data;
        if (items == null) return _loading();
        if (items.isEmpty) return _empty(loc, Icons.business_rounded, 'adminNoAgencies');
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final agency = items[index];
            final busy = _busy.contains('agency-${agency.id}');
            final licence = [
              if (agency.orn.isNotEmpty) '${loc.tr('adminAgencyOrn')}: ${agency.orn}',
              if (agency.rera.isNotEmpty) '${loc.tr('adminAgencyRera')}: ${agency.rera}',
            ].join('  ·  ');
            return TashilCard.outlined(
              key: Key('admin-agency-${agency.id}'),
              padding: const EdgeInsetsDirectional.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(agency.name,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                            if (agency.city.isNotEmpty) Text(agency.city, style: Theme.of(context).textTheme.bodySmall),
                            if (licence.isNotEmpty)
                              Text(licence, key: Key('admin-agency-licence-${agency.id}'), style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      TashilAssistChip(
                        key: Key('admin-agency-status-${agency.id}'),
                        label: loc.tr(_licenceStatusKey(agency.licenceStatus)),
                        icon: agency.licenceStatus == 'verified'
                            ? Icons.verified_outlined
                            : (agency.licenceStatus == 'rejected' ? Icons.block_outlined : Icons.schedule_outlined),
                      ),
                    ],
                  ),
                  if (_canVerifyAgencies) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TashilButton.tonal(
                          key: Key('admin-agency-verify-${agency.id}'),
                          label: loc.tr('adminAgencyVerify'),
                          icon: Icons.verified_outlined,
                          isLoading: busy,
                          onPressed: busy || agency.licenceStatus == 'verified'
                              ? null
                              : () => _run('agency-${agency.id}', () => _data.setAgencyLicence(agency.id, 'verified'), loc),
                        ),
                        TashilButton.outlined(
                          key: Key('admin-agency-reject-${agency.id}'),
                          label: loc.tr('adminAgencyReject'),
                          icon: Icons.block_outlined,
                          onPressed: busy || agency.licenceStatus == 'rejected'
                              ? null
                              : () => _run('agency-${agency.id}', () => _data.setAgencyLicence(agency.id, 'rejected'), loc),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String _licenceStatusKey(String status) {
    switch (status) {
      case 'verified':
        return 'adminLicenceVerified';
      case 'pending':
        return 'adminLicencePending';
      case 'rejected':
        return 'adminLicenceRejected';
      default:
        return 'adminLicenceUnverified';
    }
  }

  String _roleLabel(AppLocalizations loc, String role) {
    switch (role) {
      case 'SuperAdmin':
        return loc.tr('roleSuperAdmin');
      case 'Admin':
        return loc.tr('roleAdmin');
      case 'AgencyAdmin':
        return loc.tr('roleAgency');
      case 'Owner':
        return loc.tr('roleOwner');
      case 'Tenant':
        return loc.tr('roleTenant');
      case 'Investor':
        return loc.tr('roleInvestor');
      default:
        return role;
    }
  }
}
