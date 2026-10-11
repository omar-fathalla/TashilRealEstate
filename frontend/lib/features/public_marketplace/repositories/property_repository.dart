import 'package:flutter/foundation.dart';
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
    'EG': PropertyItem.sampleProperties.where((p) => p.countryCode == 'EG').toList(),
    'AE': PropertyItem.sampleProperties.where((p) => p.countryCode == 'AE').toList(),
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
      final title = prop.getTitle(langCode);
      final location = prop.getLocation(langCode);

      final matchesQuery = searchQuery.isEmpty ||
          SearchTokenizer.matches(title, searchQuery) ||
          SearchTokenizer.matches(location, searchQuery);

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
