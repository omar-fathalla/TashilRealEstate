import 'dart:typed_data';

enum ModerationStatus {
  analyzing,
  approved,
  rejected,
  flagged,
}

enum RealEstateCategory {
  livingRoom,
  bedroom,
  bathroom,
  kitchen,
  balcony,
  exteriorFacade,
  buildingEntrance,
  poolGarden,
  floorplan,
  aerialDrone,
  nonRealEstate,
  other,
}

class ImageModerationItem {
  final String id;
  final String? imagePathOrUrl;
  final Uint8List? imageBytes;
  final String fileName;
  
  ModerationStatus status;
  RealEstateCategory category;
  
  // Policy checklist flags
  final bool containsPersonsOrFaces;
  final bool isAppropriateContent;
  final bool isRealEstateRelated;
  final bool isHighQuality;
  
  // Metrics (0.0 - 1.0)
  final double relevanceScore;
  final double safetyScore;
  final double qualityScore;
  
  // Localization dictionary key for rejection explanation
  final String? rejectionReasonKey;
  final String? customExplanation;
  final List<String> detectedFeatures;
  final DateTime analyzedAt;

  ImageModerationItem({
    required this.id,
    this.imagePathOrUrl,
    this.imageBytes,
    required this.fileName,
    this.status = ModerationStatus.analyzing,
    this.category = RealEstateCategory.other,
    this.containsPersonsOrFaces = false,
    this.isAppropriateContent = true,
    this.isRealEstateRelated = true,
    this.isHighQuality = true,
    this.relevanceScore = 0.95,
    this.safetyScore = 1.0,
    this.qualityScore = 0.90,
    this.rejectionReasonKey,
    this.customExplanation,
    this.detectedFeatures = const [],
    DateTime? analyzedAt,
  }) : analyzedAt = analyzedAt ?? DateTime.now();

  bool get isApproved => status == ModerationStatus.approved;
  bool get isRejected => status == ModerationStatus.rejected;
  bool get isAnalyzing => status == ModerationStatus.analyzing;

  factory ImageModerationItem.fromJson(Map<String, dynamic> json, {String? id, String? fileName, String? imageUrl}) {
    final statusStr = json['status'] as String? ?? 'approved';
    final categoryStr = json['category'] as String? ?? 'living_room';

    ModerationStatus status = ModerationStatus.approved;
    if (statusStr == 'rejected') status = ModerationStatus.rejected;
    if (statusStr == 'flagged') status = ModerationStatus.flagged;
    if (statusStr == 'analyzing') status = ModerationStatus.analyzing;

    RealEstateCategory category = _parseCategory(categoryStr);

    final containsPersons = json['contains_persons'] as bool? ?? false;
    final isAppropriate = json['is_appropriate'] as bool? ?? true;
    final isRealEstate = json['is_real_estate'] as bool? ?? true;
    final isHighQuality = json['is_high_quality'] as bool? ?? true;

    final relevance = (json['relevance_score'] as num?)?.toDouble() ?? (isRealEstate ? 0.95 : 0.20);
    final safety = (json['safety_score'] as num?)?.toDouble() ?? (isAppropriate ? 1.0 : 0.10);
    final quality = (json['quality_score'] as num?)?.toDouble() ?? 0.90;

    final rejectionKey = json['rejection_reason_key'] as String?;
    final customExplanation = json['rejection_explanation'] as String?;
    final features = (json['detected_features'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    return ImageModerationItem(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      imagePathOrUrl: imageUrl,
      fileName: fileName ?? 'property_image.jpg',
      status: status,
      category: category,
      containsPersonsOrFaces: containsPersons,
      isAppropriateContent: isAppropriate,
      isRealEstateRelated: isRealEstate,
      isHighQuality: isHighQuality,
      relevanceScore: relevance,
      safetyScore: safety,
      qualityScore: quality,
      rejectionReasonKey: rejectionKey,
      customExplanation: customExplanation,
      detectedFeatures: features,
      analyzedAt: DateTime.now(),
    );
  }

  static RealEstateCategory _parseCategory(String key) {
    switch (key.toLowerCase()) {
      case 'living_room':
        return RealEstateCategory.livingRoom;
      case 'bedroom':
        return RealEstateCategory.bedroom;
      case 'bathroom':
        return RealEstateCategory.bathroom;
      case 'kitchen':
        return RealEstateCategory.kitchen;
      case 'balcony':
        return RealEstateCategory.balcony;
      case 'exterior_facade':
      case 'architecture':
        return RealEstateCategory.exteriorFacade;
      case 'building_entrance':
        return RealEstateCategory.buildingEntrance;
      case 'pool_garden':
      case 'garden':
      case 'pool':
        return RealEstateCategory.poolGarden;
      case 'floorplan':
        return RealEstateCategory.floorplan;
      case 'aerial_drone':
        return RealEstateCategory.aerialDrone;
      case 'non_real_estate':
        return RealEstateCategory.nonRealEstate;
      default:
        return RealEstateCategory.other;
    }
  }

  String get categoryKey {
    switch (category) {
      case RealEstateCategory.livingRoom:
        return 'categoryLivingRoom';
      case RealEstateCategory.bedroom:
        return 'categoryBedroom';
      case RealEstateCategory.bathroom:
        return 'categoryBathroom';
      case RealEstateCategory.kitchen:
        return 'categoryKitchen';
      case RealEstateCategory.balcony:
        return 'categoryBalcony';
      case RealEstateCategory.exteriorFacade:
        return 'categoryExteriorFacade';
      case RealEstateCategory.buildingEntrance:
        return 'categoryBuildingEntrance';
      case RealEstateCategory.poolGarden:
        return 'categoryPoolGarden';
      case RealEstateCategory.floorplan:
        return 'categoryFloorplan';
      case RealEstateCategory.aerialDrone:
        return 'categoryAerialDrone';
      case RealEstateCategory.nonRealEstate:
        return 'categoryNonRealEstate';
      case RealEstateCategory.other:
        return 'categoryOtherRealEstate';
    }
  }
}
