import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/routing/not_found_screen.dart';
import 'package:tashil_real_estate/features/public_marketplace/repositories/property_repository.dart';
import 'package:tashil_real_estate/features/public_marketplace/widgets/property_details_dialog.dart';

/// Full-screen listing used on compact widths so details are a real route.
class ListingDetailsPage extends StatelessWidget {
  final String listingId;

  const ListingDetailsPage({super.key, required this.listingId});

  @override
  Widget build(BuildContext context) {
    final item = PropertyRepository().getPropertyById(listingId);
    if (item == null) return const NotFoundScreen();
    return PropertyDetailsDialog(property: item, asPage: true);
  }
}
