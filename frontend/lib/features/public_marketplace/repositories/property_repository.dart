import 'package:flutter/foundation.dart';
import 'package:tashil_real_estate/core/config/demo_data.dart';
import '../models/property_item.dart';
import '../../../core/utils/search_tokenizer.dart';
import '../../../core/services/firestore_service.dart';

class PaginatedResult {
  final List<PropertyItem> items;
  final bool hasMore;
  final int totalCount;

  const PaginatedResult({
    required this.items,
    required this.hasMore,
    required this.totalCount,
  });
}

class PropertyRepository {
  static final PropertyRepository _instance = PropertyRepository._internal();
  factory PropertyRepository() => _instance;
  PropertyRepository._internal() {
    _loadFromFirestore();
  }

  Future<void> _loadFromFirestore() async {
    try {
      final cloudProps = await FirestoreService().getMarketplaceProperties();
      if (cloudProps.isNotEmpty) {
        for (final prop in cloudProps) {
          final list = _countryCache.putIfAbsent(prop.countryCode, () => []);
          list.removeWhere((p) => p.id == prop.id);
          list.insert(0, prop);
        }
        updatesNotifier.value++;
      }
    } catch (e) {
      debugPrint('Marketplace hydration note: $e');
    }
  }

  final ValueNotifier<int> updatesNotifier = ValueNotifier<int>(0);

  // In-Memory Country Caches for instant sub-millisecond retrieval
  final Map<String, List<PropertyItem>> _countryCache = {
    'EG': DemoData.enabled
        ? PropertyItem.sampleProperties.where((p) => p.countryCode == 'EG').toList()
        : <PropertyItem>[],
    'AE': DemoData.enabled
        ? PropertyItem.sampleProperties.where((p) => p.countryCode == 'AE').toList()
        : <PropertyItem>[],
  };

  /// Retrieves cached properties for a specific country
  List<PropertyItem> getPropertiesByCountry(String countryCode) {
    return _countryCache[countryCode] ?? [];
  }

  /// Retrieves a specific property by ID
  PropertyItem? getPropertyById(String id) {
    for (final list in _countryCache.values) {
      for (final p in list) {
        if (p.id == id) return p;
      }
    }
    return null;
  }

  /// Adds a newly published property to the top of the repository
  void addProperty(PropertyItem property) {
    final list = _countryCache.putIfAbsent(property.countryCode, () => []);
    list.removeWhere((p) => p.id == property.id);
    list.insert(0, property);
    updatesNotifier.value++;
  }

  /// Updates an existing property
  void updateProperty(PropertyItem property) {
    addProperty(property);
  }

  /// Removes a property from the marketplace (e.g. when rented, unpublished, or deleted)
  void removeProperty(String id) {
    bool removed = false;
    for (final list in _countryCache.values) {
      final initialLen = list.length;
      list.removeWhere((p) => p.id == id);
      if (list.length != initialLen) removed = true;
    }
    if (removed) updatesNotifier.value++;
  }

  /// Paginated and filtered property query
  PaginatedResult queryProperties({
    required String countryCode,
    required String langCode,
    String searchQuery = '',
    String cityCode = 'all',
    String typeCode = 'all',
    double maxPrice = 200000,
    bool onlyFurnished = false,
    bool onlyFeatured = false,
    int page = 1,
    int pageSize = 6,
  }) {
    final allProperties = getPropertiesByCountry(countryCode);

    final filtered = allProperties.where((prop) {
      final matchesQuery = searchQuery.isEmpty ||
          prop.titles.values.any((text) => SearchTokenizer.matches(text, searchQuery)) ||
          prop.locations.values.any((text) => SearchTokenizer.matches(text, searchQuery));

      final matchesCity = cityCode == 'all' || prop.cityCode == cityCode;
      final matchesType = typeCode == 'all' || prop.propertyTypeCode == typeCode;
      final matchesPrice = prop.pricePerMonth <= maxPrice;
      final matchesFurnished = !onlyFurnished || prop.isFurnished;
      final matchesFeatured = !onlyFeatured || prop.isFeatured;

      return matchesQuery && matchesCity && matchesType && matchesPrice && matchesFurnished && matchesFeatured;
    }).toList();

    final startIndex = (page - 1) * pageSize;
    if (startIndex >= filtered.length) {
      return PaginatedResult(
        items: [],
        hasMore: false,
        totalCount: filtered.length,
      );
    }

    final endIndex = (startIndex + pageSize).clamp(0, filtered.length);
    final pageItems = filtered.sublist(0, endIndex); // Accumulative for infinite scrolling

    return PaginatedResult(
      items: pageItems,
      hasMore: endIndex < filtered.length,
      totalCount: filtered.length,
    );
  }
}
