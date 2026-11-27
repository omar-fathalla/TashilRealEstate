import 'package:tashil_real_estate/features/owner_portal/models/managed_property_model.dart';
import 'package:tashil_real_estate/features/portfolio/models/portfolio_models.dart';

/// Gross rental yield (TAQ-164): the yearly rent of the active leases on properties whose owner
/// entered a value, over the sum of those values, in percent.
///
/// It is null, and so not shown, when no leased property in [countryCode] has a value: a yield
/// is never estimated or filled in from sample figures.
double? grossRentalYield(
  Iterable<PortfolioLease> leases,
  Map<String, double> propertyValues, {
  required String countryCode,
}) {
  var annualRent = 0.0;
  final valued = <String>{};
  for (final lease in leases) {
    if (!lease.isActive || lease.countryCode != countryCode) continue;
    final value = propertyValues[lease.propertyId];
    if (value == null || value <= 0) continue;
    annualRent += lease.monthlyRent * 12;
    valued.add(lease.propertyId);
  }
  final totalValue = valued.fold<double>(0, (sum, id) => sum + propertyValues[id]!);
  if (totalValue <= 0) return null;
  return annualRent / totalValue * 100;
}

/// The values the owner entered, by property id.
Map<String, double> propertyValuesOf(Iterable<ManagedPropertyModel> properties) => {
      for (final p in properties)
        if (p.propertyValue != null) p.id: p.propertyValue!,
    };
