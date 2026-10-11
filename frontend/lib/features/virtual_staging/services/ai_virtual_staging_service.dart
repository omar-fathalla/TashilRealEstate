import '../models/virtual_staging_model.dart';

class AiVirtualStagingService {
  static final AiVirtualStagingService _instance =
      AiVirtualStagingService._internal();
  factory AiVirtualStagingService() => _instance;
  AiVirtualStagingService._internal();

  /// Available Virtual Staging Styles
  List<VirtualStagingStylePreset> get availableStyles => const [
        VirtualStagingStylePreset(
          style: VirtualStagingStyle.modernLuxury,
          name: {
            'ar': 'مودرن فاخر',
            'en': 'Modern Luxury',
            'hi': 'आधुनिक लक्जरी',
          },
          description: {
            'ar': 'أثاث إيطالي أنيق، إضاءات مخفية، وتدرجات ألوان دافئة راقية',
            'en': 'Sleek Italian furniture, ambient LED lighting, and refined neutral palette',
            'hi': 'चिकना इतालवी फर्नीचर, परिवेश एलईडी प्रकाश व्यवस्था और परिष्कृत तटस्थ पैलेट',
          },
          iconEmoji: '🛋️',
          sampleThumbnailUrl:
              'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=400&q=80',
        ),
        VirtualStagingStylePreset(
          style: VirtualStagingStyle.classicArabesque,
          name: {
            'ar': 'كلاسيك أرابيسك',
            'en': 'Classic Arabesque',
            'hi': 'क्लासिक अरेबेस्क',
          },
          description: {
            'ar': 'ثريات فاخرة، زخارف شرقية عصرية، وأقمشة مخملية فخمة',
            'en': 'Gilded accents, modern oriental motifs, and rich velvet fabrics',
            'hi': 'शानदार झूमर, आधुनिक प्राच्य रूपांकन और समृद्ध मखमली कपड़े',
          },
          iconEmoji: '🏛️',
          sampleThumbnailUrl:
              'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=400&q=80',
        ),
        VirtualStagingStylePreset(
          style: VirtualStagingStyle.scandinavian,
          name: {
            'ar': 'سكندنافي دافئ',
            'en': 'Warm Scandinavian',
            'hi': 'गर्म स्कैंडिनेवियाई',
          },
          description: {
            'ar': 'أخشاب بلوط طبيعية، نباتات داخلية، وأقمشة كتان مريحة',
            'en': 'Light natural oak wood, lush indoor greenery, and cozy linen fabrics',
            'hi': 'हल्की प्राकृतिक ओक लकड़ी, हरे-भरे इनडोर पौधे और आरामदायक लिनन कपड़े',
          },
          iconEmoji: '🪵',
          sampleThumbnailUrl:
              'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=400&q=80',
        ),
        VirtualStagingStylePreset(
          style: VirtualStagingStyle.minimalistExecutive,
          name: {
            'ar': 'مينيماليست عملي',
            'en': 'Minimalist Executive',
            'hi': 'न्यूनतम कार्यकारी',
          },
          description: {
            'ar': 'خطوط هندسية نقية، مكتب عمل ذكي، واستغلال مثالي للمساحات',
            'en': 'Clean geometric lines, smart workspace desk, and optimized open floor plan',
            'hi': 'स्वच्छ ज्यामितीय रेखाएं, स्मार्ट कार्यक्षेत्र डेस्क और अनुकूलित ओपन स्पेस',
          },
          iconEmoji: '🏢',
          sampleThumbnailUrl:
              'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=400&q=80',
        ),
        VirtualStagingStylePreset(
          style: VirtualStagingStyle.coastalMarine,
          name: {
            'ar': 'ساحلي صيفي',
            'en': 'Coastal Marine',
            'hi': 'तटीय समुद्री',
          },
          description: {
            'ar': 'تدرجات الأبيض والأزرق البحري، أثاث بامبو، وإضاءة شمسية مشرقة',
            'en': 'Crisp white & oceanic blues, rattan furniture, and airy sunlit vibe',
            'hi': 'सफेद और समुद्री नीले रंग, रतन फर्नीचर और हवादार धूप का माहौल',
          },
          iconEmoji: '🏖️',
          sampleThumbnailUrl:
              'https://images.unsplash.com/photo-1613977257363-707ba9348227?w=400&q=80',
        ),
      ];

  /// Get or generate virtual staging pair based on room type, style, and variation index
  Future<VirtualStagingPair> generateVirtualStage({
    required String baseImageUrl,
    required StagingRoomType roomType,
    required VirtualStagingStyle style,
    int variation = 0,
  }) async {
    // Simulate high-speed Imagen 3 inference latency
    await Future.delayed(const Duration(milliseconds: 650));

    return _getStagingPresetPair(roomType, style, baseImageUrl, variation % 3);
  }

  VirtualStagingPair _getStagingPresetPair(
    StagingRoomType roomType,
    VirtualStagingStyle style,
    String baseImageUrl,
    int variation,
  ) {
    String emptyUrl;
    String stagedUrl;
    Map<String, String> name;
    Map<String, String> desc;
    List<String> elementsAr;
    List<String> elementsEn;
    List<String> elementsHi;

    switch (roomType) {
      case StagingRoomType.livingRoom:
        emptyUrl = 'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=1200&q=80';
        if (style == VirtualStagingStyle.modernLuxury) {
          if (variation == 1) {
            stagedUrl = 'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?w=1200&q=80';
            name = {'ar': 'صالة معيشة - مودرن إيطالي معاصر', 'en': 'Living Room - Contemporary Italian', 'hi': 'लिविंग रूम - समकालीन इतालवी'};
            desc = {
              'ar': 'صالون جلدي عاجي أنيق، مكتبة حائط خشب جوز، وإضاءات سبوتلايت دائرية هادئة',
              'en': 'Ivory leather lounge, walnut floating media wall, and recessed directional spotlights',
              'hi': 'आइवरी लेदर लाउंज, अखरोट की मीडिया दीवार और स्पॉटलाइट्स',
            };
            elementsAr = ['صالون جلدي عاجي', 'مكتبة حائط خشب جوز', 'إضاءة سبوتلايت دائرية', 'لوحة جدارية تجريدية'];
            elementsEn = ['Ivory Leather Sectional', 'Walnut Floating Media Wall', 'Directional Recessed Spots', 'Oversized Abstract Canvas'];
            elementsHi = ['आइवरी लेदर सेक्शनल', 'वॉलनट मीडिया वॉल', 'स्पॉटलाइट्स', 'कैनवास कला'];
          } else if (variation == 2) {
            stagedUrl = 'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?w=1200&q=80';
            name = {'ar': 'صالة معيشة - مودرن بانورامي فاخر', 'en': 'Living Room - Panoramic Modern Luxe', 'hi': 'लिविंग रूम - पैनोरमिक आधुनिक विलासिता'};
            desc = {
              'ar': 'أريكة مخملية كحلية ملكية، طاولة زجاجية وإطارات ستانلس ذهبية، وثريا مودرن معلقة',
              'en': 'Royal navy velvet sofa, smoked glass brass tables, and architectural pendant chandelier',
              'hi': 'रॉयल नेवी मखमली सोफा, ब्रास टेबल और आधुनिक पेंडेंट झूमर',
            };
            elementsAr = ['أريكة مخملية كحلية', 'طاولة زجاجية نحاسية', 'ثريا هندسية معلقة', 'ستائر حريرية عازلة'];
            elementsEn = ['Royal Navy Velvet Sofa', 'Brass Smoked Glass Table', 'Geometric Pendant Chandelier', 'Silk Insulated Curtains'];
            elementsHi = ['रॉयल नेवी मखमली सोफा', 'ब्रास ग्लास टेबल', 'पेंडेंट झूमर', 'सिल्क पर्दे'];
          } else {
            stagedUrl = 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1200&q=80';
            name = {'ar': 'صالة معيشة - مودرن فاخر', 'en': 'Living Room - Modern Luxury', 'hi': 'लिविंग रूम - आधुनिक लक्जरी'};
            desc = {
              'ar': 'أريكة زاوية إيطالية، طاولة قهوة رخامية، إضاءة ليد مخفية، وتلفزيون معلق 75 بوصة',
              'en': 'Italian sectional sofa, Calacatta marble coffee table, ambient LED coves, and 75" flush TV',
              'hi': 'इतालवी सोफा, संगमरमर कॉफी टेबल, परिवेश एलईडी प्रकाश और 75 इंच टीवी',
            };
            elementsAr = ['كنبة زاوية رمادية فاخرة', 'طاولة رخام كلكتا', 'إضاءة سقفية مخفية', 'سجادة حريرية عصرية'];
            elementsEn = ['Luxury Grey Sectional Sofa', 'Calacatta Marble Coffee Table', 'Recessed Ambient Lighting', 'Modern Silk Blend Rug'];
            elementsHi = ['लक्जरी ग्रे सेक्शनल सोफा', 'संगमरमर कॉफी टेबल', 'एंबिएंट लाइटिंग', 'सिल्क ब्लेंड गलीचा'];
          }
        } else if (style == VirtualStagingStyle.classicArabesque) {
          if (variation == 1) {
            stagedUrl = 'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?w=1200&q=80';
            name = {'ar': 'صالة معيشة - أرابيسك دمشقي عريق', 'en': 'Living Room - Damascene Arabesque', 'hi': 'लिविंग रूम - दमिश्क अरेबेस्क'};
            desc = {
              'ar': 'صالون شرقي مطعم بالصدف الطبيعي، إضاءات نحاسية أندلسية، وسجاد كاشان يدوي',
              'en': 'Mother-of-pearl inlaid seating, Andalusian brass lanterns, and handmade Kashan carpet',
              'hi': 'मोती जड़ा हुआ फर्नीचर, अंडालूसी पीतल की लालटेन और हस्तनिर्मित कशान गलीचा',
            };
            elementsAr = ['جلسة خشب زان مطعمة صدف', 'فوانيس نحاسية أندلسية', 'سجاد كاشان إيراني أصيل', 'مشربية خشبية مدمجة'];
            elementsEn = ['Inlaid Beechwood Seating', 'Andalusian Brass Lanterns', 'Authentic Kashan Rug', 'Integrated Mashrabiya Lattice'];
            elementsHi = ['जड़ी हुई लकड़ी की बैठक', 'पीतल की लालटेन', 'कशान गलीचा', 'मशरबिया जाली'];
          } else {
            stagedUrl = 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=1200&q=80';
            name = {'ar': 'صالة معيشة - كلاسيك أرابيسك', 'en': 'Living Room - Classic Arabesque', 'hi': 'लिविंग रूम - क्लासिक अरेबेस्क'};
            desc = {
              'ar': 'مجلس ملكي بأقمشة مخملية، ثريا كريستالية ذهبية، وسجاد شرقي فاخر',
              'en': 'Royal velvet seating, gilded crystal chandelier, and authentic handmade oriental carpet',
              'hi': 'रॉयल मखमली सोफा, सुनहरे क्रिस्टल झूमर और प्रामाणिक हस्तनिर्मित गलीचा',
            };
            elementsAr = ['صالون مخملي ملكي', 'ثريا كريستال مذهبة', 'طاولات خشب زان مطعمة', 'سجاد شرقي أصيل'];
            elementsEn = ['Royal Velvet Sofa Set', 'Gilded Crystal Chandelier', 'Inlaid Beechwood Tables', 'Handwoven Oriental Carpet'];
            elementsHi = ['रॉयल मखमली सोफा सेट', 'सुनहरा क्रिस्टल झूमर', 'इनलेड लकड़ी की मेज', 'हथकरघा ओरिएंटल गलीचा'];
          }
        } else if (style == VirtualStagingStyle.scandinavian) {
          if (variation == 1) {
            stagedUrl = 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=1200&q=80';
            name = {'ar': 'صالة معيشة - نورديك مينيمال هادئ', 'en': 'Living Room - Serene Nordic Minimal', 'hi': 'लिविंग रूम - शांत नॉर्डिक मिनिमल'};
            desc = {
              'ar': 'كنبة قطنية بيضاء، طاولة مستديرة من خشب الصنوبر، ووسائد صوفية مريحة',
              'en': 'White cotton sofa, circular pine wood table, and plush woolen throws',
              'hi': 'सफेद सूती सोफा, पाइन लकड़ी की गोल मेज और ऊनी कुशन',
            };
            elementsAr = ['أريكة قطنية ناصعة', 'طاولة صنوبر دائرية', 'وسائد صوفية طبيعية', 'أباجورة أرضية معدنية'];
            elementsEn = ['Crisp White Cotton Sofa', 'Circular Pine Coffee Table', 'Organic Wool Cushions', 'Minimal Arc Floor Lamp'];
            elementsHi = ['सफेद सूती सोफा', 'पाइन लकड़ी की मेज', 'ऊनी कुशन', 'आर्क फ्लोर लैंप'];
          } else {
            stagedUrl = 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=1200&q=80';
            name = {'ar': 'صالة معيشة - سكندنافي دافئ', 'en': 'Living Room - Warm Scandinavian', 'hi': 'लिविंग रूम - गर्म स्कैंडिनेवियाई'};
            desc = {
              'ar': 'كنبة قماشية بيج مريحة، طاولة خشب طبيعي، شجرة زيتون داخلية، وإضاءة طبيعية',
              'en': 'Warm beige fabric couch, solid oak coffee table, indoor olive tree, and natural linen curtains',
              'hi': 'बेज फैब्रिक सोफा, ओक कॉफी टेबल, इनडोर जैतून का पेड़ और प्राकृतिक लिनन पर्दे',
            };
            elementsAr = ['أريكة كتان بيج مريحة', 'طاولة خشب بلوط طبيعي', 'شجرة نباتية داخلية', 'إضاءة دافئة ناعمة'];
            elementsEn = ['Cozy Beige Linen Couch', 'Solid Natural Oak Table', 'Potted Indoor Olive Tree', 'Warm Ambient Floor Lamp'];
            elementsHi = ['आरामदायक लिनन सोफा', 'प्राकृतिक ओक टेबल', 'इनडोर जैतून का पौधा', 'वार्म फ्लोर लैंप'];
          }
        } else {
          stagedUrl = variation == 1
              ? 'https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=1200&q=80'
              : 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=1200&q=80';
          name = {'ar': 'صالة معيشة - مينيماليست متطور', 'en': 'Living Room - Evolved Minimalist', 'hi': 'लिविंग रूम - उन्नत न्यूनतम'};
          desc = {
            'ar': 'أثاث بسيط عالي الجودة، مساحات مفتوحة رحبة، وتوزيع ذكي للضوء الطبيعي',
            'en': 'Clean low-profile furniture, expansive open floor, and smart functional lighting',
            'hi': 'साफ सुथरा फर्नीचर, विशाल खुला स्थान और स्मार्ट कार्यात्मक प्रकाश व्यवस्था',
          };
          elementsAr = ['كنبة منخفضة رمادية', 'أرفف حائطية عائمة', 'إضاءة تراك ذكية', 'نباتات ظل مينيمال'];
          elementsEn = ['Low-profile Minimal Sofa', 'Floating Wall Shelves', 'Smart Track Lighting', 'Zen Accent Greenery'];
          elementsHi = ['लो-प्रोफाइल सोफा', 'फ्लोटिंग वॉल शेल्व्स', 'स्मार्ट ट्रैक लाइटिंग', 'ज़ेन प्लांट'];
        }
        break;

      case StagingRoomType.masterBedroom:
        emptyUrl = 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=1200&q=80';
        if (variation == 1) {
          stagedUrl = 'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?w=1200&q=80';
          name = {'ar': 'غرفة نوم ماستر - جناح إيطالي هادئ', 'en': 'Master Bedroom - Italian Serene Suite', 'hi': 'मास्टर बेडरूम - इतालवी सुइट'};
          desc = {
            'ar': 'سرير كينج مخملي رمادي، جلسة شيزلونج للاسترخاء، وثريات معلقة ناعمة بجانب السرير',
            'en': 'Grey velvet king bed, chaise lounge bench, and soft bedside pendants',
            'hi': 'ग्रे मखमली किंग बेड, लाउंज बेंच और पेंडेंट लाइट',
          };
          elementsAr = ['سرير فندقي كينج', 'بانكيت شيزلونج جلدي', 'إضاءات جانبية معلقة', 'سجاد ألياف طبيعية'];
          elementsEn = ['Hotel King Bed', 'Leather Chaise Bench', 'Hanging Bedside Pendants', 'Natural Fiber Rug'];
          elementsHi = ['होटल किंग बेड', 'लाउंज बेंच', 'पेंडेंट लाइट', 'प्राकृतिक गलीचा'];
        } else if (variation == 2) {
          stagedUrl = 'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=1200&q=80';
          name = {'ar': 'غرفة نوم ماستر - جناح فندقي فاخر', 'en': 'Master Bedroom - Luxury Hotel Suite', 'hi': 'मास्टर बेडरूम - लक्जरी होटल सुइट'};
          desc = {
            'ar': 'سرير خشب بلوط عريض، خلفية جدارية خشبية ثلاثية الأبعاد، وإضاءة ليد دافئة',
            'en': 'Wide oak king bed, 3D fluted accent wall, and integrated ambient warm LED strips',
            'hi': 'ओक किंग बेड, 3डी वॉल पैनल और परिवेश गर्म एलईडी स्ट्रिप्स',
          };
          elementsAr = ['سرير كينج خشب بلوط', 'جدار ديكوري مضلع ثلاثي الأبعاد', 'إضاءة شريطية مخفية', 'كومود عائم مدمج'];
          elementsEn = ['Solid Oak King Bed', '3D Fluted Wall Feature', 'Concealed LED Strip', 'Integrated Floating Nightstand'];
          elementsHi = ['ओक किंग बेड', '3डी दीवार पैनल', 'छिपी हुई एलईडी स्ट्रिप', 'फ्लोटिंग नाइटस्टैंड'];
        } else {
          stagedUrl = 'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?w=1200&q=80';
          name = {'ar': 'غرفة نوم ماستر - مودرن', 'en': 'Master Bedroom - Modern', 'hi': 'मास्टर बेडरूम - आधुनिक'};
          desc = {
            'ar': 'سرير كينج بظهر كابوتنيه جلدي، تسريحة معلقة بمرايا مضيئة، ودولاب ملابس مدمج',
            'en': 'King bed with padded leather headboard, floating vanity with backlit mirror, and built-in closet',
            'hi': 'किंग बेड, फ्लोटिंग वैनिटी बैकलाइट मिरर और बिल्ट-इन अलमारी',
          };
          elementsAr = ['سرير كينج بظهر مبطن', 'كومودينو معلق مزدوج', 'تسريحة بمرايا ذكية', 'ستائر بلاك آوت حريرية'];
          elementsEn = ['Upholstered King Bed', 'Dual Floating Nightstands', 'Smart LED Vanity Mirror', 'Silk Blackout Drapes'];
          elementsHi = ['किंग साइज बेड', 'नाइटस्टैंड्स', 'एलईडी वैनिटी मिरर', 'सिल्क ब्लैकआउट पर्दे'];
        }
        break;

      case StagingRoomType.diningRoom:
        emptyUrl = 'https://images.unsplash.com/photo-1600585152220-90363fe7e115?w=1200&q=80';
        if (variation == 1) {
          stagedUrl = 'https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=1200&q=80';
          name = {'ar': 'غرفة طعام وسفرة - مودرن طبيعي', 'en': 'Dining Area - Natural Modern', 'hi': 'डाइनिंग एरिया - प्राकृतिक आधुनिक'};
          desc = {
            'ar': 'طاولة طعام خشب بلوط صلب لـ 8 أشخاص، كراسي قماشية مبطنة، وثريا خطية عصرية',
            'en': 'Solid oak 8-seat dining table, upholstered dining chairs, and modern linear chandelier',
            'hi': 'ठोस ओक डाइनिंग टेबल, कुशन कुर्सियाँ और आधुनिक झूमर',
          };
          elementsAr = ['سفرة خشب بلوط لـ 8 أفراد', 'كراسي مبطنة مريحة', 'ثريا خطية مودرن', 'بوفيه طعام خشب زان'];
          elementsEn = ['8-Seat Solid Oak Table', 'Ergonomic Dining Chairs', 'Linear Modern Chandelier', 'Beechwood Sideboard'];
          elementsHi = ['ओक डाइनिंग टेबल', 'कुर्सियां', 'लीनियर झूमर', 'साइडबोर्ड'];
        } else {
          stagedUrl = 'https://images.unsplash.com/photo-1617806118233-18e1de247200?w=1200&q=80';
          name = {'ar': 'غرفة طعام وسفرة - مودرن فاخر', 'en': 'Dining Area - Modern Luxury', 'hi': 'डाइनिंग एरिया - आधुनिक'};
          desc = {
            'ar': 'طاولة طعام رخامية تتسع لـ 8 أشخاص، كراسي مخملية، ونجفة معلقة مودرن',
            'en': '8-seater polished marble dining table, velvet chairs, and contemporary pendant fixture',
            'hi': '8-सीटर मार्बल डाइनिंग टेबल, मखमली कुर्सियाँ और आधुनिक पेंडेंट लाइट',
          };
          elementsAr = ['طاولة رخام لـ 8 أفراد', 'كراسي مخملية مريحة', 'نجفة نحاسية متدلية', 'لوحة جدارية فنية'];
          elementsEn = ['8-Seat Marble Dining Table', 'Ergonomic Velvet Chairs', 'Brass Pendant Chandelier', 'Abstract Canvas Art'];
          elementsHi = ['मार्बल डाइनिंग टेबल', 'मखमली कुर्सियां', 'ब्रास पेंडेंट झूमर', 'कैनवास कला'];
        }
        break;

      case StagingRoomType.homeOffice:
        emptyUrl = 'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=1200&q=80';
        if (variation == 1) {
          stagedUrl = 'https://images.unsplash.com/photo-1593062096033-9a26b09da705?w=1200&q=80';
          name = {'ar': 'مكتب منزلي - إنتاجي متطور', 'en': 'Home Office - Smart Productivity', 'hi': 'होम ऑफिस - उत्पादक'};
          desc = {
            'ar': 'مكتب كهربائي ذكي قابل لتعديل الارتفاع، كرسي مريح لدعم العمود الفقري، وشاشة منحنية 34 بوصة',
            'en': 'Smart motorized sit-stand desk, high-end ergonomic spine chair, and 34" curved display',
            'hi': 'स्मार्ट मोटराइज्ड डेस्क, एर्गोनोमिक रीढ़ की कुर्सी और 34 इंच घुमावदार डिस्प्ले',
          };
          elementsAr = ['مكتب ذكي هيدروليك', 'كرسي طبي متطور', 'شاشة بانورامية 34 بوصة', 'إضاءة شريطية تفاعلية'];
          elementsEn = ['Motorized Sit-Stand Desk', 'Ergonomic Task Chair', '34" Curved Display', 'Interactive Bias Lighting'];
          elementsHi = ['मोटराइज्ड डेस्क', 'एर्गोनोमिक कुर्सी', 'कर्व्ड डिस्प्ले', 'बायस लाइटिंग'];
        } else {
          stagedUrl = 'https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?w=1200&q=80';
          name = {'ar': 'مكتب منزلي مريح', 'en': 'Home Office - Ergonomic', 'hi': 'होम ऑफिस - आरामदायक'};
          desc = {
            'ar': 'مكتب خشب جوز فاخر، كرسي مريح لدعم الظهر، وشاشات عرض مزدوجة للعمل عن بعد',
            'en': 'Walnut executive desk, ergonomic lumbar chair, and dual ultra-wide productivity screens',
            'hi': 'वॉलनट डेस्क, एर्गोनोमिक कुर्सी और उत्पादकता के लिए दोहरी स्क्रीन',
          };
          elementsAr = ['مكتب عمل خشب جوز', 'كرسي طبي مريح', 'إضاءة مكتبية مضادة للوهج', 'مكتبة كتب عصرية'];
          elementsEn = ['Solid Walnut Work Desk', 'Ergonomic Mesh Chair', 'Anti-Glare Task Light', 'Minimalist Bookshelf'];
          elementsHi = ['अखरोट की लकड़ी की मेज', 'एर्गोनोमिक मेश कुर्सी', 'टास्क लैंप', 'बुकशेल्फ़'];
        }
        break;

      case StagingRoomType.balconyTerrace:
        emptyUrl = 'https://images.unsplash.com/photo-1512918728675-ed5a9ecdebfd?w=1200&q=80';
        if (variation == 1) {
          stagedUrl = 'https://images.unsplash.com/photo-1583847268964-b28dc8f51f92?w=1200&q=80';
          name = {'ar': 'شرفة وتراس - واحة استرخاء عصرية', 'en': 'Terrace & Balcony - Modern Oasis', 'hi': 'छत और बालकनी - आधुनिक विश्राम स्थल'};
          desc = {
            'ar': 'أريكة زاوية خارجية مقاومة للعوامل الجوية، طاولة نار مركزية راقية، وأشجار بامبو محاطة',
            'en': 'All-weather outdoor sectional, integrated ambient fire table, and perimeter bamboo planters',
            'hi': 'ऑल-वेदर आउटडोर सोफा, फायर टेबल और बांस के पौधे',
          };
          elementsAr = ['كنبة خارجية مقاومة للشمس', 'طاولة نار دائرية راقية', 'مظلة خارجية ذكية', 'أحواض نباتات فخارية'];
          elementsEn = ['Sun-Resistant Outdoor Couch', 'Polished Fire Pit Table', 'Smart Motorized Awning', 'Terracotta Planters'];
          elementsHi = ['आउटडोर सोफा', 'फायर टेबल', 'मोटराइज्ड शामियाना', 'टेराकोटा प्लांटर्स'];
        } else {
          stagedUrl = 'https://images.unsplash.com/photo-1613977257363-707ba9348227?w=1200&q=80';
          name = {'ar': 'تراس وشرفة - جلسة خارجية', 'en': 'Terrace & Balcony - Outdoor Lounge', 'hi': 'छत और बालकनी - आउटडोर लाउंज'};
          desc = {
            'ar': 'جلسة رتان مقاومة للعوامل الجوية، نباتات زينة خضراء، وإضاءات فوانيس دافئة',
            'en': 'Weatherproof rattan lounge seating, perimeter planters, and warm solar lanterns',
            'hi': 'वेदरप्रूफ रतन लाउंज, चारों ओर हरियाली और गर्म लालटेन रोशनी',
          };
          elementsAr = ['جلسة خيزران مقاومة للمطر', 'أحواض زرع ونباتات زينة', 'طاولة قهوة خارجية', 'إضاءة فوانيس دافئة'];
          elementsEn = ['All-Weather Rattan Set', 'Decorative Planter Boxes', 'Outdoor Teak Table', 'Solar Ambient Lanterns'];
          elementsHi = ['रतन लाउंज सेट', 'सजावटी पौधे', 'टीकवुड कॉफी टेबल', 'सौर लालटेन'];
        }
        break;
    }

    return VirtualStagingPair(
      id: 'vs_${roomType.name}_${style.name}_var$variation',
      originalEmptyImageUrl: emptyUrl,
      stagedImageUrl: stagedUrl,
      style: style,
      roomType: roomType,
      styleName: name,
      styleDescription: desc,
      furnitureElementsAr: elementsAr,
      furnitureElementsEn: elementsEn,
      furnitureElementsHi: elementsHi,
    );
  }
}
