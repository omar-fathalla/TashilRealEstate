class PropertyItem {
  final String id;
  final String countryCode; // 'EG' or 'AE'
  final String currencyCode; // 'EGP' or 'AED'
  final Map<String, String> titles;
  final Map<String, String> descriptions;
  final String propertyTypeCode; // apartment, villa, studio, duplex, chalet
  final Map<String, String> locations;
  final String cityCode; // Egypt: new_cairo, sheikh_zayed, alexandria, maadi, north_coast, october | UAE: dubai, abu_dhabi, sharjah, ajman, ras_al_khaimah
  final double pricePerMonth;
  final int bedrooms;
  final int bathrooms;
  final double areaSqM;
  final List<String> imageUrls;
  final Map<String, List<String>> amenitiesMap;
  final bool isFurnished;
  final bool isFeatured;
  final Map<String, String> agencyNames;
  final String agencyPhone;
  final double rating;

  const PropertyItem({
    required this.id,
    this.countryCode = 'EG',
    this.currencyCode = 'EGP',
    required this.titles,
    required this.descriptions,
    required this.propertyTypeCode,
    required this.locations,
    required this.cityCode,
    required this.pricePerMonth,
    required this.bedrooms,
    required this.bathrooms,
    required this.areaSqM,
    required this.imageUrls,
    required this.amenitiesMap,
    this.isFurnished = false,
    this.isFeatured = false,
    required this.agencyNames,
    this.agencyPhone = '+20 100 000 0000',
    this.rating = 4.8,
  });

  String getTitle(String lang) => titles[lang] ?? titles['en'] ?? titles['ar'] ?? '';
  String getDescription(String lang) => descriptions[lang] ?? descriptions['en'] ?? descriptions['ar'] ?? '';
  String getLocation(String lang) => locations[lang] ?? locations['en'] ?? locations['ar'] ?? '';
  String getAgencyName(String lang) => agencyNames[lang] ?? agencyNames['en'] ?? agencyNames['ar'] ?? '';
  List<String> getAmenities(String lang) => amenitiesMap[lang] ?? amenitiesMap['en'] ?? amenitiesMap['ar'] ?? [];

  static List<PropertyItem> get sampleProperties => [
    // ==========================================
    // 🇪🇬 EGYPT PROPERTIES (مصر)
    // ==========================================
    const PropertyItem(
      id: 'prop-eg-1',
      countryCode: 'EG',
      currencyCode: 'EGP',
      titles: {
        'ar': 'شقة فاخرة بإطلالة مفتوحة على شارع التسعين',
        'en': 'Luxury Apartment with Open View on 90th Street',
        'hi': '90वें स्ट्रीट पर खुले दृश्य वाला लक्जरी अपार्टमेंट',
      },
      descriptions: {
        'ar': 'شقة مودرن بتشطيب ألترا سوبر لوكس، مفروشة بالكامل بأثاث راقٍ وجاهزة للسكن الفوري. قريبة من جميع الخدمات والمراكز التجارية.',
        'en': 'Modern ultra super-lux finished apartment, fully furnished with premium furniture, ready for immediate move-in. Close to all amenities and malls.',
        'hi': 'अल्ट्रा सुपर लक्स फिनिश वाला आधुनिक अपार्टमेंट, पूरी तरह से सुसज्जित, तुरंत रहने के लिए तैयार। सभी सेवाओं और मॉल के पास।',
      },
      propertyTypeCode: 'apartment',
      locations: {
        'ar': 'التجمع الخامس، القاهرة الجديدة',
        'en': '5th Settlement, New Cairo',
        'hi': '5वां सेटलमेंट, न्यू काहिरा',
      },
      cityCode: 'new_cairo',
      pricePerMonth: 28000,
      bedrooms: 3,
      bathrooms: 2,
      areaSqM: 185,
      imageUrls: [
        'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=1000&q=80',
      ],
      amenitiesMap: {
        'ar': ['مفروش بالكامل', 'تكييف مركزي', 'مصعد', 'موقف خاص', 'أمن وحراسة 24/7', 'شرفة واسعة'],
        'en': ['Fully Furnished', 'Central A/C', 'Elevator', 'Private Parking', '24/7 Security', 'Spacious Balcony'],
        'hi': ['पूरी तरह सुसज्जित', 'केंद्रीय एसी', 'लिफ्ट', 'निजी पार्किंग', '24/7 सुरक्षा', 'बड़ी बालकनी'],
      },
      isFurnished: true,
      isFeatured: true,
      agencyNames: {
        'ar': 'سكون لإدارة العقارات',
        'en': 'Sukoon Real Estate Management',
        'hi': 'सुकून रियल एस्टेट प्रबंधन',
      },
      agencyPhone: '+20 101 234 5678',
      rating: 4.9,
    ),
    const PropertyItem(
      id: 'prop-eg-2',
      countryCode: 'EG',
      currencyCode: 'EGP',
      titles: {
        'ar': 'فيلا مستقلة بحمام سباحة وحديقة خاصة في كمبوند راقٍ',
        'en': 'Standalone Villa with Private Pool & Garden in Elite Compound',
        'hi': 'एलिट कंपाउंड में निजी पूल और बगीचे के साथ स्टैंडअलोन विला',
      },
      descriptions: {
        'ar': 'فيلا راقية تقع في أرقى كمبوندات الشيخ زايد. تتميز بفيو رائع على المساحات الخضراء، حمام سباحة خاص وجراج لسيارتين.',
        'en': 'Prestigious villa in Sheikh Zayed top compounds. Features scenic green views, private swimming pool, and double garage.',
        'hi': 'शेख जायद के शीर्ष कंपाउंड में शानदार विला। सुरम्य हरे दृश्य, निजी स्विमिंग पूल और दो कारों के लिए गैरेज।',
      },
      propertyTypeCode: 'villa',
      locations: {
        'ar': 'كمبوند الياسمين، الشيخ زايد',
        'en': 'Al Yasmeen Compound, Sheikh Zayed',
        'hi': 'अल यास्मीन कंपाउंड, शेख जायद',
      },
      cityCode: 'sheikh_zayed',
      pricePerMonth: 65000,
      bedrooms: 5,
      bathrooms: 4,
      areaSqM: 420,
      imageUrls: [
        'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1000&q=80',
      ],
      amenitiesMap: {
        'ar': ['حمام سباحة خاص', 'حديقة خاصة', 'غرفة خادمة', 'تكييف مركزي', 'كاميرات مراقبة', 'موقف لسيارتين'],
        'en': ['Private Pool', 'Private Garden', "Maid's Room", 'Central A/C', 'CCTV Security', '2 Car Parking'],
        'hi': ['निजी पूल', 'निजी बगीचा', 'नौकर का कमरा', 'केंद्रीय एसी', 'सीसीटीवी', '2 कारों की पार्किंग'],
      },
      isFurnished: false,
      isFeatured: true,
      agencyNames: {
        'ar': 'الأهرام للوساطة العقارية',
        'en': 'Al Ahram Property Brokerage',
        'hi': 'अल अहराम प्रॉपर्टी ब्रोकरेज',
      },
      agencyPhone: '+20 102 345 6789',
      rating: 4.8,
    ),
    const PropertyItem(
      id: 'prop-eg-3',
      countryCode: 'EG',
      currencyCode: 'EGP',
      titles: {
        'ar': 'شاليه صف أول على البحر مباشرة في مراسي',
        'en': 'First Row Sea View Chalet in Marassi North Coast',
        'hi': 'मरासी उत्तरी तट पर पहली पंक्ति में समुद्र दृश्य वाला शैले',
      },
      descriptions: {
        'ar': 'شاليه فندقي راقٍ مفروش بالكامل بأحدث التصاميم العالمية، خطوات من الشاطئ الرملي الخاص ونادي الكلوب هاوس.',
        'en': 'Luxury beachfront serviced chalet fully furnished with designer fittings, steps from the private sandy beach and clubhouse.',
        'hi': 'डिजाइनर फिटिंग के साथ पूरी तरह सुसज्जित लक्जरी समुद्र तट पर बना शैले, निजी रेतीले समुद्र तट से कुछ कदम दूर।',
      },
      propertyTypeCode: 'chalet',
      locations: {
        'ar': 'سيدي عبد الرحمن، الساحل الشمالي',
        'en': 'Sidi Abdel Rahman, North Coast',
        'hi': 'सिदी अब्देल रहमान, उत्तरी तट',
      },
      cityCode: 'north_coast',
      pricePerMonth: 45000,
      bedrooms: 2,
      bathrooms: 2,
      areaSqM: 115,
      imageUrls: [
        'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1000&q=80',
      ],
      amenitiesMap: {
        'ar': ['إطلالة مباشرة على البحر', 'شاطئ خاص', 'مفروش بالكامل', 'ألعاب مائية', 'مطاعم وكافيهات'],
        'en': ['Direct Sea View', 'Private Beach', 'Fully Furnished', 'Water Sports', 'Restaurants & Cafes'],
        'hi': ['प्रत्यक्ष समुद्र दृश्य', 'निजी समुद्र तट', 'पूरी तरह सुसज्जित', 'जल क्रीड़ा', 'रेस्तरां'],
      },
      isFurnished: true,
      isFeatured: false,
      agencyNames: {
        'ar': 'إعمار مصر لتسويق الإيجارات',
        'en': 'Emaar Egypt Rental Hub',
        'hi': 'एमार मिस्र रेंटल हब',
      },
      agencyPhone: '+20 103 456 7890',
      rating: 4.7,
    ),
    const PropertyItem(
      id: 'prop-eg-4',
      countryCode: 'EG',
      currencyCode: 'EGP',
      titles: {
        'ar': 'دوبلكس فخم مع رووف خاص وإطلالة خضراء في المعادي',
        'en': 'Grand Duplex with Private Roof & Green Views in Maadi',
        'hi': 'मादी में निजी छत और हरे दृश्यों वाला भव्य डुप्लेक्स',
      },
      descriptions: {
        'ar': 'دوبلكس مساحة رحبة وتشطيب كلاسيكي فاخر، يضم 4 غرف نوم ورووف واسع مناسب للجلسات العائلية وحفلات الشواء.',
        'en': 'Spacious classic duplex with 4 bedrooms and large private roof terrace ideal for family gatherings and barbecue.',
        'hi': '4 बेडरूम और बड़ी निजी छत के साथ विशाल क्लासिक डुप्लेक्स, पारिवारिक समारोहों के लिए आदर्श।',
      },
      propertyTypeCode: 'duplex',
      locations: {
        'ar': 'دجلة المعادي، القاهرة',
        'en': 'Degla Maadi, Cairo',
        'hi': 'देगला मादी, काहिरा',
      },
      cityCode: 'maadi',
      pricePerMonth: 35000,
      bedrooms: 4,
      bathrooms: 3,
      areaSqM: 310,
      imageUrls: [
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1000&q=80',
      ],
      amenitiesMap: {
        'ar': ['رووف خاص', 'مطبخ مجهز', 'أرضيات باركيه', 'أمن 24 ساعة', 'قريب من المدارس الدولية'],
        'en': ['Private Roof', 'Equipped Kitchen', 'Parquet Flooring', '24/7 Security', 'Near International Schools'],
        'hi': ['निजी छत', 'सुसज्जित रसोई', 'लकड़ी का फर्श', '24/7 सुरक्षा', 'अंतर्राष्ट्रीय स्कूलों के पास'],
      },
      isFurnished: true,
      isFeatured: false,
      agencyNames: {
        'ar': 'المعادي لإدارة الأملاك',
        'en': 'Maadi Property Advisors',
        'hi': 'मादी संपत्ति सलाहकार',
      },
      agencyPhone: '+20 104 567 8901',
      rating: 4.8,
    ),

    // ==========================================
    // 🇦🇪 UAE PROPERTIES (الإمارات)
    // ==========================================
    const PropertyItem(
      id: 'prop-ae-1',
      countryCode: 'AE',
      currencyCode: 'AED',
      titles: {
        'ar': 'شقة فاخرة بإطلالة بانورامية كاملة على مارينا دبي',
        'en': 'Luxury 2BR Waterfront Apartment with Full Marina Views',
        'hi': 'मरीना के पूर्ण दृश्यों वाला लक्जरी 2बीएचके वाटरफ्रंट अपार्टमेंट',
      },
      descriptions: {
        'ar': 'شقة مؤثثة بالكامل بأثاث إيطالي فاخر في برج مارينا جيت. إطلالة مائية خلابة على اليخوت، ومسبح إنفينيتي وصالة جيم متطورة.',
        'en': 'Fully furnished with Italian designer furniture in Marina Gate Tower. Stunning marina views, infinity pool, and state-of-the-art gym.',
        'hi': 'मरीना गेट टॉवर में इतालवी डिजाइनर फर्नीचर से सुसज्जित। शानदार दृश्य, इन्फिनिटी पूल और अत्याधुनिक जिम।',
      },
      propertyTypeCode: 'apartment',
      locations: {
        'ar': 'مارينا جيت، دبي مارينا، دبي',
        'en': 'Marina Gate, Dubai Marina, Dubai',
        'hi': 'मरीना गेट, दुबई मरीना, दुबई',
      },
      cityCode: 'dubai',
      pricePerMonth: 14500,
      bedrooms: 2,
      bathrooms: 2,
      areaSqM: 130,
      imageUrls: [
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=1000&q=80',
      ],
      amenitiesMap: {
        'ar': ['إطلالة بحرية ومارينا', 'مسبح إنفينيتي', 'صالة رياضية فاخرة', 'مواقف مغطاة', 'أمن 24/7', 'قريب من المترو والترام'],
        'en': ['Full Marina View', 'Infinity Pool', 'Luxury Gym', 'Covered Parking', '24/7 Concierge', 'Near Metro & Tram'],
        'hi': ['मरीना दृश्य', 'इन्फिनिटी पूल', 'लक्जरी जिम', 'कवर्ड पार्किंग', '24/7 सुरक्षा', 'मेट्रो के पास'],
      },
      isFurnished: true,
      isFeatured: true,
      agencyNames: {
        'ar': 'دبي برايم للوساطة العقارية (RERA)',
        'en': 'Dubai Prime Real Estate (RERA Verified)',
        'hi': 'दुबई प्राइम रियल एस्टेट (रेरा सत्यापित)',
      },
      agencyPhone: '+971 4 399 0000',
      rating: 5.0,
    ),
    const PropertyItem(
      id: 'prop-ae-2',
      countryCode: 'AE',
      currencyCode: 'AED',
      titles: {
        'ar': 'دوبلكس عصري فخم مطل على برج خليفة ونافورة دبي',
        'en': 'Ultra Modern Duplex with Burj Khalifa & Fountain Views',
        'hi': 'बुर्ज खलीफा और फाउंटेन व्यू वाला अल्ट्रा मॉडर्न डुप्लेक्स',
      },
      descriptions: {
        'ar': 'دوبلكس استثنائي في قلب داون تاون دبي، على بعد خطوات من دبي مول وأوبرا دبي. تشطيبات راقية ونظام منزل ذكي متكامل.',
        'en': 'Exceptional duplex in the heart of Downtown Dubai, steps away from Dubai Mall & Dubai Opera. Smart home automation included.',
        'hi': 'डाउनटाउन दुबई के केंद्र में असाधारण डुप्लेक्स, दुबई मॉल और ओपेरा से कुछ कदम दूर। स्मार्ट होम सिस्टम।',
      },
      propertyTypeCode: 'duplex',
      locations: {
        'ar': 'داون تاون دبي، بالقرب من دبي مول',
        'en': 'Downtown Dubai, Near Dubai Mall',
        'hi': 'डाउनटाउन दुबई, दुबई मॉल के पास',
      },
      cityCode: 'dubai',
      pricePerMonth: 28000,
      bedrooms: 3,
      bathrooms: 3,
      areaSqM: 240,
      imageUrls: [
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1000&q=80',
      ],
      amenitiesMap: {
        'ar': ['إطلالة على برج خليفة', 'نظام سمارت هوم', 'خدمة صف السيارات', 'سبا ونادي صحي', 'شرفة بانورامية'],
        'en': ['Burj Khalifa View', 'Smart Home Automation', 'Valet Parking', 'Spa & Health Club', 'Panoramic Balcony'],
        'hi': ['बुर्ज खलीफा दृश्य', 'स्मार्ट होम', 'वैलेट पार्किंग', 'स्पा और हेल्थ क्लब', 'बालकनी'],
      },
      isFurnished: true,
      isFeatured: true,
      agencyNames: {
        'ar': 'إعمار للخدمات العقارية دبي',
        'en': 'Emaar Properties Dubai Hub',
        'hi': 'एमार प्रॉपर्टीज दुबई',
      },
      agencyPhone: '+971 4 367 3333',
      rating: 4.9,
    ),
    const PropertyItem(
      id: 'prop-ae-3',
      countryCode: 'AE',
      currencyCode: 'AED',
      titles: {
        'ar': 'فيلا شاطئية ملكية مع مدخل خاص لشاطئ نخلة جميرا',
        'en': 'Royal Beachfront Villa with Private Beach on Palm Jumeirah',
        'hi': 'पाम जुमेराह पर निजी समुद्र तट के साथ रॉयल बीचफ्रंट विला',
      },
      descriptions: {
        'ar': 'فيلا ساحلية فخمة على سعفة نخلة جميرا، حمام سباحة خاص وشاطئ رملي خاص، إطلالة على فندق أتلانتس ومرسى دبي.',
        'en': 'Luxury beachfront villa on the Palm Jumeirah fronds with private pool, direct beach access, and views of Atlantis The Royal.',
        'hi': 'निजी पूल, समुद्र तट और अटलांटिस के दृश्यों के साथ पाम जुमेराह पर लक्जरी बीचफ्रंट विला।',
      },
      propertyTypeCode: 'villa',
      locations: {
        'ar': 'سعفة K، نخلة جميرا، دبي',
        'en': 'Frond K, Palm Jumeirah, Dubai',
        'hi': 'फ्रोंड के, पाम जुमेराह, दुबई',
      },
      cityCode: 'dubai',
      pricePerMonth: 48000,
      bedrooms: 5,
      bathrooms: 6,
      areaSqM: 580,
      imageUrls: [
        'https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1000&q=80',
      ],
      amenitiesMap: {
        'ar': ['شاطئ خاص', 'حمام سباحة إنفينيتي', 'غرفة سائق وخادمة', 'حديقة استوائية', 'مرسى قوارب خاص'],
        'en': ['Private Beach', 'Infinity Pool', "Driver's & Maid's Room", 'Tropical Garden', 'Private Boat Dock'],
        'hi': ['निजी समुद्र तट', 'इन्फिनिटी पूल', 'ड्राइवर और नौकर का कमरा', 'उष्णकटिबंधीय बगीचा', 'निजी नाव डॉक'],
      },
      isFurnished: true,
      isFeatured: true,
      agencyNames: {
        'ar': 'نخيل لإدارة الأصول الفاخرة',
        'en': 'Nakheel Luxury Assets Management',
        'hi': 'नखील लक्जरी एसेट्स मैनेजमेंट',
      },
      agencyPhone: '+971 4 390 3333',
      rating: 5.0,
    ),
    const PropertyItem(
      id: 'prop-ae-4',
      countryCode: 'AE',
      currencyCode: 'AED',
      titles: {
        'ar': 'ستوديو تنفيذي فاخر بإطلالة على قناة دبي المائية',
        'en': 'Executive Luxury Studio overlooking Dubai Water Canal',
        'hi': 'दुबई वाटर कैनाल के दृश्य वाला कार्यकारी लक्जरी स्टूडियो',
      },
      descriptions: {
        'ar': 'ستوديو حديث ومفروش بالكامل في الخليج التجاري (Business Bay)، تصميم عملي وأنيق مجهز بكافة الأجهزة الكهربائية.',
        'en': 'Modern fully furnished studio in Business Bay, smart space optimization, and fully equipped European appliances.',
        'hi': 'बिजनेस बे में आधुनिक पूरी तरह सुसज्जित स्टूडियो, यूरोपीय उपकरणों से सुसज्जित।',
      },
      propertyTypeCode: 'studio',
      locations: {
        'ar': 'الخليج التجاري، دبي',
        'en': 'Business Bay, Dubai',
        'hi': 'बिजनेस बे, दुबई',
      },
      cityCode: 'dubai',
      pricePerMonth: 6500,
      bedrooms: 1,
      bathrooms: 1,
      areaSqM: 52,
      imageUrls: [
        'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1000&q=80',
      ],
      amenitiesMap: {
        'ar': ['مفروش بالكامل', 'إطلالة على القناة المائية', 'مسبح وصالة رياضية', 'أمن 24/7', 'قريب من محطة المترو'],
        'en': ['Fully Furnished', 'Canal View', 'Pool & Gym', '24/7 Security', 'Walking distance to Metro'],
        'hi': ['पूरी तरह सुसज्जित', 'नहर का दृश्य', 'पूल और जिम', '24/7 सुरक्षा', 'मेट्रो के पास'],
      },
      isFurnished: true,
      isFeatured: false,
      agencyNames: {
        'ar': 'داماك للوساطة العقارية',
        'en': 'DAMAC Real Estate Services',
        'hi': 'दामैक रियल एस्टेट सर्विसेज',
      },
      agencyPhone: '+971 4 373 1000',
      rating: 4.7,
    ),
    const PropertyItem(
      id: 'prop-ae-5',
      countryCode: 'AE',
      currencyCode: 'AED',
      titles: {
        'ar': 'شقة عائلية 3 غرف في جزيرة ياس بأبوظبي بالقرب من ياس مول',
        'en': 'Spacious 3BR Family Apartment on Yas Island Abu Dhabi',
        'hi': 'यास द्वीप अबू धाबी पर विशाल 3बीएचके पारिवारिक अपार्टमेंट',
      },
      descriptions: {
        'ar': 'شقة واسعة ومشرقة في جزيرة ياس، على بعد دقائق من عالم فيراري وشاطئ ياس، مرافق متكاملة ومناسبة للعائلات.',
        'en': 'Spacious and bright apartment on Yas Island, minutes away from Ferrari World & Yas Beach. Family friendly compound.',
        'hi': 'यास द्वीप पर विशाल और उज्ज्वल अपार्टमेंट, फेरारी वर्ल्ड और यास बीच से कुछ ही मिनटों की दूरी पर।',
      },
      propertyTypeCode: 'apartment',
      locations: {
        'ar': 'جزيرة ياس، أبوظبي',
        'en': 'Yas Island, Abu Dhabi',
        'hi': 'यास द्वीप, अबू धाबी',
      },
      cityCode: 'abu_dhabi',
      pricePerMonth: 12500,
      bedrooms: 3,
      bathrooms: 3,
      areaSqM: 195,
      imageUrls: [
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1000&q=80',
      ],
      amenitiesMap: {
        'ar': ['قريب من شاطئ ياس', 'مسبح عائلي', 'حدائق وملاعب أطفال', 'تكييف مركزي', 'موقفين للسيارات'],
        'en': ['Near Yas Beach', 'Family Pool', 'Parks & Playgrounds', 'Central A/C', '2 Parking Spots'],
        'hi': ['यास बीच के पास', 'पारिवारिक पूल', 'पार्क और खेल के मैदान', 'केंद्रीय एसी', '2 पार्किंग स्थल'],
      },
      isFurnished: false,
      isFeatured: false,
      agencyNames: {
        'ar': 'الدار العقارية أبوظبي',
        'en': 'Aldar Properties Abu Dhabi',
        'hi': 'अलदार प्रॉपर्टीज अबू धाबी',
      },
      agencyPhone: '+971 2 810 5555',
      rating: 4.8,
    ),
  ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'countryCode': countryCode,
      'currencyCode': currencyCode,
      'titles': titles,
      'descriptions': descriptions,
      'propertyTypeCode': propertyTypeCode,
      'locations': locations,
      'cityCode': cityCode,
      'pricePerMonth': pricePerMonth,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'areaSqM': areaSqM,
      'imageUrls': imageUrls,
      'amenitiesMap': amenitiesMap,
      'isFurnished': isFurnished,
      'isFeatured': isFeatured,
      'agencyNames': agencyNames,
      'agencyPhone': agencyPhone,
      'rating': rating,
    };
  }

  factory PropertyItem.fromMap(Map<String, dynamic> map, {String? docId}) {
    Map<String, String> parseStringMap(dynamic val, [String fallback = '']) {
      final res = <String, String>{};
      if (val is Map) {
        val.forEach((k, v) => res[k.toString()] = v.toString());
      }
      if (res.isEmpty && fallback.isNotEmpty) {
        res['ar'] = fallback;
        res['en'] = fallback;
        res['hi'] = fallback;
      }
      return res;
    }

    Map<String, List<String>> parseAmenities(dynamic val) {
      final res = <String, List<String>>{};
      if (val is Map) {
        val.forEach((k, v) {
          if (v is List) {
            res[k.toString()] = v.map((e) => e.toString()).toList();
          }
        });
      }
      return res;
    }

    List<String> parseList(dynamic val) {
      if (val is List) return val.map((e) => e.toString()).toList();
      return [];
    }

    final id = docId ?? map['id']?.toString() ?? 'prop-${DateTime.now().millisecondsSinceEpoch}';
    final fallbackTitle = map['title_ar']?.toString() ?? map['title']?.toString() ?? '';
    final fallbackDesc = map['description_ar']?.toString() ?? map['description']?.toString() ?? '';
    final fallbackLoc = map['location']?.toString() ?? '';

    return PropertyItem(
      id: id,
      countryCode: map['countryCode']?.toString() ?? map['country_code']?.toString() ?? 'EG',
      currencyCode: map['currencyCode']?.toString() ?? map['currency_code']?.toString() ?? 'EGP',
      titles: parseStringMap(map['titles'], fallbackTitle),
      descriptions: parseStringMap(map['descriptions'], fallbackDesc),
      propertyTypeCode: map['propertyTypeCode']?.toString() ?? map['property_type']?.toString() ?? 'apartment',
      locations: parseStringMap(map['locations'], fallbackLoc),
      cityCode: map['cityCode']?.toString() ?? map['city_code']?.toString() ?? 'new_cairo',
      pricePerMonth: (map['pricePerMonth'] is num)
          ? (map['pricePerMonth'] as num).toDouble()
          : (map['monthly_rent'] is num)
              ? (map['monthly_rent'] as num).toDouble()
              : 0.0,
      bedrooms: (map['bedrooms'] is num) ? (map['bedrooms'] as num).toInt() : 1,
      bathrooms: (map['bathrooms'] is num) ? (map['bathrooms'] as num).toInt() : 1,
      areaSqM: (map['areaSqM'] is num)
          ? (map['areaSqM'] as num).toDouble()
          : (map['area_sqm'] is num)
              ? (map['area_sqm'] as num).toDouble()
              : 100.0,
      imageUrls: parseList(map['imageUrls'] ?? map['photo_urls']),
      amenitiesMap: parseAmenities(map['amenitiesMap']),
      isFurnished: map['isFurnished'] == true || map['is_furnished'] == true,
      isFeatured: map['isFeatured'] == true || map['is_featured'] == true,
      agencyNames: parseStringMap(map['agencyNames'], 'شركة تسهيل لإدارة الأملاك'),
      agencyPhone: map['agencyPhone']?.toString() ?? '+20 100 000 0000',
      rating: (map['rating'] is num) ? (map['rating'] as num).toDouble() : 4.8,
    );
  }
}
