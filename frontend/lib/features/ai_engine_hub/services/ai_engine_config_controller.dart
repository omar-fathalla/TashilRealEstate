import 'package:flutter/material.dart';
import '../models/ai_model_definition.dart';

/// Centralized Controller managing AI engine configurations, model switching,
/// and token/budget analytics across the Tashil Real Estate platform.
class AiEngineConfigController extends ChangeNotifier {
  static final AiEngineConfigController _instance = AiEngineConfigController._internal();
  factory AiEngineConfigController() => _instance;

  AiEngineConfigController._internal() {
    _initCatalog();
  }

  late final List<AiServiceCategory> _categories;
  final Map<AiServiceType, String> _activeModelMap = {};

  List<AiServiceCategory> get categories => List.unmodifiable(_categories);

  /// Initializes the catalog of all 6 AI services with their top 3 modern models
  void _initCatalog() {
    _categories = [
      // 1. Property Ingestion (Fast Onboarding Voice & Text)
      const AiServiceCategory(
        serviceType: AiServiceType.propertyIngestion,
        titleAr: 'استخراج وتفريغ مواصفات العقار (الصوت والنص)',
        titleEn: 'Property Ingestion & Voice Transcription',
        titleHi: 'संपत्ति निष्कर्षण और आवाज प्रतिलेखन',
        icon: Icons.mic_external_on_rounded,
        usedForAr: 'تفريغ التسجيل الصوتي واستخراج بيانات الشقة (الموقع، السعر، الغرف، المرافق) وتعبئة الحقول آلياً.',
        usedForEn: 'Transcribing voice audio, extracting property attributes (location, price, rooms), and autofilling onboarding fields.',
        usedForHi: 'आवाज ऑडियो लिखना, संपत्ति विवरण (स्थान, मूल्य, कमरे) निकालना और फ़ील्ड को स्वतः भरना।',
        locationInAppAr: 'شاشة الإضافة السريعة للعقار (Fast Property Onboarding) ومودال الإملاء الصوتي الذكي.',
        locationInAppEn: 'Fast Property Onboarding screen & AI Voice Dictation Modal.',
        locationInAppHi: 'फास्ट प्रॉपर्टी ऑनबोर्डिंग स्क्रीन और एआई वॉयस डिक्टेशन मोडल।',
        featureBadge: 'Fast Onboarding',
        top3Models: [
          AiModelOption(
            id: 'gemini-3.8-flash',
            name: 'Gemini 3.8 Flash',
            generationBadge: 'Gen 3.8 Flash',
            provider: 'Google DeepMind',
            tokenLevel: TokenConsumptionLevel.ultraLow,
            typicalTokensPerCall: 450,
            inputCostPerMillion: 0.075,
            outputCostPerMillion: 0.30,
            averageLatencySeconds: 0.28,
            contextWindow: '2M Tokens',
            badgeText: 'الأعلى سرعة ودقة وتوفيراً',
            descriptionAr: 'استخراج فوري وتحليل فائق الذكاء لمواصفات العقار بالصوت والنص وتغذية الحقول بدقة تامة.',
            descriptionEn: 'Instant extraction and ultra-intelligent parsing of property specs from audio/text into fields.',
            descriptionHi: 'ऑडियो/टेक्स्ट से संपत्ति विनिर्देशों का तत्काल निष्कर्षण और अत्यधिक बुद्धिमान विश्लेषण।',
            isRecommended: true,
          ),
          AiModelOption(
            id: 'gemini-2.5-flash',
            name: 'Gemini 2.5 Flash',
            generationBadge: 'Gen 2.5',
            provider: 'Google DeepMind',
            tokenLevel: TokenConsumptionLevel.ultraLow,
            typicalTokensPerCall: 450,
            inputCostPerMillion: 0.075,
            outputCostPerMillion: 0.30,
            averageLatencySeconds: 0.35,
            contextWindow: '1M Tokens',
            badgeText: 'الأعلى توفيراً',
            descriptionAr: 'استخراج فوري لمواصفات العقار بالصوت والنص بأقل استهلاك ممكن للتوكن.',
            descriptionEn: 'Instant extraction of property specs from audio/text with minimal token footprint.',
            descriptionHi: 'न्यूनतम टोकन उपयोग के साथ ऑडियो/टेक्स्ट से संपत्ति विनिर्देशों का तत्काल निष्कर्षण।',
          ),
          AiModelOption(
            id: 'gemini-3.8-pro',
            name: 'Gemini 3.8 Pro',
            generationBadge: 'Gen 3.8 Pro',
            provider: 'Google DeepMind',
            tokenLevel: TokenConsumptionLevel.high,
            typicalTokensPerCall: 1100,
            inputCostPerMillion: 1.25,
            outputCostPerMillion: 5.00,
            averageLatencySeconds: 0.85,
            contextWindow: '2M Tokens',
            badgeText: 'استدلال منطقي عميق',
            descriptionAr: 'تحليل دقيق واستنتاج متقدم للبيانات غير المكتملة وعقود المطورين الكبرى.',
            descriptionEn: 'Deep reasoning and advanced inference for sparse data and large property listings.',
            descriptionHi: 'अपूर्ण डेटा और बड़े डेवलपर अनुबंधों के लिए गहरा तार्किक विश्लेषण।',
          ),
        ],
      ),

      // 2. Marketing Copywriting & Listing Description
      const AiServiceCategory(
        serviceType: AiServiceType.marketingCopywriting,
        titleAr: 'صياغة الوصف التسويقي والإعلانات العقارية',
        titleEn: 'Marketing Copywriting & Ad Description',
        titleHi: 'विपणन विवरण और विज्ञापन लेखन',
        icon: Icons.auto_awesome_rounded,
        usedForAr: 'إنشاء وصف عقاري تسويقي احترافي بأسلوب راقٍ يبرز المزايا والمرافق ونقاط الجذب الاستثمارية.',
        usedForEn: 'Generating compelling marketing copy and SEO listing descriptions highlighting amenities and lifestyle.',
        usedForHi: 'सुविधाओं और जीवन शैली को उजागर करने वाले आकर्षक विपणन विवरण और विज्ञापन तैयार करना।',
        locationInAppAr: 'شاشة إدخال العقار وزر "توليد بالذكاء الاصطناعي" في قسم الوسائط والوصف.',
        locationInAppEn: 'Property creation screen & Generate with AI button in Media & Description step.',
        locationInAppHi: 'संपत्ति निर्माण स्क्रीन और मीडिया व विवरण अनुभाग में एआई जनरेट बटन।',
        featureBadge: 'Marketing Engine',
        top3Models: [
          AiModelOption(
            id: 'gemini-2.5-flash',
            name: 'Gemini 2.5 Flash',
            generationBadge: 'Gen 2.5',
            provider: 'Google DeepMind',
            tokenLevel: TokenConsumptionLevel.ultraLow,
            typicalTokensPerCall: 550,
            inputCostPerMillion: 0.075,
            outputCostPerMillion: 0.30,
            averageLatencySeconds: 0.40,
            contextWindow: '1M Tokens',
            badgeText: 'سريع واقتصادي',
            descriptionAr: 'صياغة تسويقية سريعة وجذابة متوافقة مع محركات البحث بأقل كلفة توكن.',
            descriptionEn: 'Fast and attractive copywriting aligned with SEO at ultra-low token cost.',
            descriptionHi: 'न्यूनतम लागत पर एसईओ के अनुकूल तेज़ और आकर्षक विज्ञापन लेखन।',
            isRecommended: true,
          ),
          AiModelOption(
            id: 'gemini-3.8-creative',
            name: 'Gemini 3.8 Creative Flagship',
            generationBadge: 'Gen 3.8',
            provider: 'Google DeepMind',
            tokenLevel: TokenConsumptionLevel.balanced,
            typicalTokensPerCall: 850,
            inputCostPerMillion: 0.35,
            outputCostPerMillion: 1.40,
            averageLatencySeconds: 0.65,
            contextWindow: '2M Tokens',
            badgeText: 'بلاغة تسويقية مبهرة',
            descriptionAr: 'صياغة إبداعية راقية تسلط الضوء على نقاط الجذب الاستثمارية ونمط الحياة اليومي.',
            descriptionEn: 'Eloquent creative narrative accentuating investment ROI and elevated lifestyle appeal.',
            descriptionHi: 'निवेश रिटर्न और जीवन शैली के आकर्षण को उजागर करने वाला सुरुचिपूर्ण रचनात्मक लेखन।',
          ),
          AiModelOption(
            id: 'gemini-3.8-pro',
            name: 'Gemini 3.8 Pro Narrative',
            generationBadge: 'Gen 3.8 Pro',
            provider: 'Google DeepMind',
            tokenLevel: TokenConsumptionLevel.high,
            typicalTokensPerCall: 1400,
            inputCostPerMillion: 1.25,
            outputCostPerMillion: 5.00,
            averageLatencySeconds: 0.90,
            contextWindow: '2M Tokens',
            badgeText: 'تحليل تسويقي موسّع',
            descriptionAr: 'سرد تسويقي شامل وتفصيلي يناسب الوحدات السكنية والفلل الفاخرة والمجمعات.',
            descriptionEn: 'Exhaustive luxury narrative tailored for penthouses, premium villas, and compounds.',
            descriptionHi: 'लक्जरी अपार्टमेंट और प्रीमियम विला के लिए विस्तृत विपणन विवरण।',
          ),
        ],
      ),

      // 3. Smart Valuation & Rental Comps (Zestimate)
      const AiServiceCategory(
        serviceType: AiServiceType.smartValuation,
        titleAr: 'التقييم المالي الذكي ومقارنات السوق (Zestimate)',
        titleEn: 'Smart Rental Valuation & Market Comps',
        titleHi: 'स्मार्ट किराया मूल्यांकन और बाजार तुलना',
        icon: Icons.price_check_rounded,
        usedForAr: 'تقدير القيمة الإيجارية العادلة للعقار ومقارنته بالوحدات المماثلة في أكبر المنصات العقارية المعتمدة.',
        usedForEn: 'Estimating fair market rental value and benchmarking against live certified real estate comps.',
        usedForHi: 'उचित बाजार किराया मूल्य का अनुमान लगाना और प्रमाणित वास्तविक संपत्ति से तुलना करना।',
        locationInAppAr: 'حاسبة التقييم الذكي، بطاقات العقار، ومؤشر السوق الإيجاري.',
        locationInAppEn: 'Smart Valuation Dialog, Property Cards, and Rental Market Index view.',
        locationInAppHi: 'स्मार्ट मूल्यांकन संवाद, संपत्ति कार्ड और बाजार सूचकांक।',
        featureBadge: 'Zestimate & Comps',
        top3Models: [
          AiModelOption(
            id: 'gemini-2.5-flash',
            name: 'Gemini 2.5 Flash Grounded',
            generationBadge: 'Gen 2.5',
            provider: 'Google DeepMind',
            tokenLevel: TokenConsumptionLevel.ultraLow,
            typicalTokensPerCall: 750,
            inputCostPerMillion: 0.075,
            outputCostPerMillion: 0.30,
            averageLatencySeconds: 0.50,
            contextWindow: '1M Tokens',
            badgeText: 'فحص ومقارنة سريعة',
            descriptionAr: 'تقييم فوري وتحديد القيمة الإيجارية العادلة بالاستناد لبيانات السوق.',
            descriptionEn: 'Instant valuation and fair market rental pricing grounded in active portal data.',
            descriptionHi: 'सक्रिय बाजार डेटा पर आधारित त्वरित मूल्यांकन और उचित किराया निर्धारण।',
            isRecommended: true,
          ),
          AiModelOption(
            id: 'gemini-3.8-analyst',
            name: 'Gemini 3.8 Market Analyst',
            generationBadge: 'Gen 3.8',
            provider: 'Google DeepMind',
            tokenLevel: TokenConsumptionLevel.balanced,
            typicalTokensPerCall: 1200,
            inputCostPerMillion: 0.35,
            outputCostPerMillion: 1.40,
            averageLatencySeconds: 0.80,
            contextWindow: '2M Tokens',
            badgeText: 'تحليل اقتصادي متقدم',
            descriptionAr: 'نمذجة متقدمة لعوائد الإيجار ونسب الإشغال المستقبلية ومقارنات الأحياء الدقيقة.',
            descriptionEn: 'Advanced predictive yield modeling, projected vacancy rates, and district comps.',
            descriptionHi: 'उन्नत पूर्वानुमानित प्रतिफल मॉडलिंग और सटीक जिला तुलना।',
          ),
          AiModelOption(
            id: 'gemini-3.8-pro',
            name: 'Gemini 3.8 Pro High-Reasoning',
            generationBadge: 'Gen 3.8 Pro',
            provider: 'Google DeepMind',
            tokenLevel: TokenConsumptionLevel.high,
            typicalTokensPerCall: 2100,
            inputCostPerMillion: 1.25,
            outputCostPerMillion: 5.00,
            averageLatencySeconds: 1.10,
            contextWindow: '2M Tokens',
            badgeText: 'تقييم استثماري مؤسسي',
            descriptionAr: 'تحليل عميق للمحافظ العقارية وتدفقات النقد السنوية ومخاطر تقلبات الأسعار.',
            descriptionEn: 'Institutional-grade investment cashflow analysis and volatility risk assessments.',
            descriptionHi: 'संस्थागत स्तर का निवेश नकदी प्रवाह विश्लेषण और जोखिम मूल्यांकन।',
          ),
        ],
      ),

      // 4. Semantic Search & Vector Embeddings
      const AiServiceCategory(
        serviceType: AiServiceType.semanticSearch,
        titleAr: 'البحث الدلالي الذكي والمتجهات (Vector Embeddings)',
        titleEn: 'Semantic Search & Vector Embeddings',
        titleHi: 'सिमेंटिक सर्च और वेक्टर एम्बेडिंग',
        icon: Icons.travel_explore_rounded,
        usedForAr: 'فهم المعنى الحقيقي لعبارات البحث (مثل "شقة هادئة قريبة من المترو") ومطابقتها دلالياً مع العقارات.',
        usedForEn: 'Matching natural language queries (e.g., quiet apartment near transit) via high-dimensional vector spaces.',
        usedForHi: 'प्राकृतिक भाषा प्रश्नों का मिलान उच्च-आयामी वेक्टर रिक्त स्थान के माध्यम से करना।',
        locationInAppAr: 'شريط البحث الذكي الرئيسي ومودال البحث بالصور والأنماط المعمارية.',
        locationInAppEn: 'Global M3 Search Bar & Visual Moodboard / Architectural Search Modal.',
        locationInAppHi: 'ग्लोबल एम3 सर्च बार और विजुअल मूडबोर्ड आर्किटेक्चरल सर्च।',
        featureBadge: 'Vector Engine',
        top3Models: [
          AiModelOption(
            id: 'text-embedding-004',
            name: 'Google Text-Embedding-004',
            generationBadge: '768-dim',
            provider: 'Google Cloud AI',
            tokenLevel: TokenConsumptionLevel.ultraLow,
            typicalTokensPerCall: 120,
            inputCostPerMillion: 0.02,
            outputCostPerMillion: 0.00,
            averageLatencySeconds: 0.15,
            contextWindow: '8K Tokens',
            badgeText: 'فائق السرعة وخفيف',
            descriptionAr: 'توليد فوري للمتجهات الدلالية للبحث في الفلاتر والكلمات المفتاحية بأقل تكلفة.',
            descriptionEn: 'Sub-second vector generation for keyword semantic matching at minimal cost.',
            descriptionHi: 'न्यूनतम लागत पर कीवर्ड सिमेंटिक मिलान के लिए त्वरित वेक्टर निर्माण।',
            isRecommended: true,
          ),
          AiModelOption(
            id: 'multilingual-e5-v3',
            name: 'Multilingual Embeddings V3',
            generationBadge: '1024-dim',
            provider: 'Google Cloud AI',
            tokenLevel: TokenConsumptionLevel.balanced,
            typicalTokensPerCall: 250,
            inputCostPerMillion: 0.08,
            outputCostPerMillion: 0.00,
            averageLatencySeconds: 0.28,
            contextWindow: '16K Tokens',
            badgeText: 'دقة لهجات عربية',
            descriptionAr: 'تطابق دلالي عالي الحساسية للهجات الخليجية والمصرية والمصطلحات العقارية المتنوعة.',
            descriptionEn: 'High sensitivity across regional Arab dialects and localized real estate terms.',
            descriptionHi: 'क्षेत्रीय बोलियों और स्थानीयकृत शब्दों में उच्च संवेदनशीलता।',
          ),
          AiModelOption(
            id: 'gemini-2.5-embed',
            name: 'Gemini 2.5 Deep Vector',
            generationBadge: '1536-dim',
            provider: 'Google DeepMind',
            tokenLevel: TokenConsumptionLevel.high,
            typicalTokensPerCall: 500,
            inputCostPerMillion: 0.15,
            outputCostPerMillion: 0.00,
            averageLatencySeconds: 0.45,
            contextWindow: '32K Tokens',
            badgeText: 'أعلى أبعاد دلالية',
            descriptionAr: 'تضمين متجهي فائق الأبعاد للبحث الهجين مع الصور والمواصفات المعقدة.',
            descriptionEn: 'High-dimensional embeddings supporting hybrid multi-modal search and architectural filters.',
            descriptionHi: 'मल्टी-मॉडल खोज और वास्तुशिल्प फिल्टर का समर्थन करने वाले उच्च-आयामी एम्बेडिंग।',
          ),
        ],
      ),

      // 5. Legal AI Advisor & Contract Clauses
      const AiServiceCategory(
        serviceType: AiServiceType.legalAdvisor,
        titleAr: 'المستشار القانوني وفحص بنود العقود الإيجارية',
        titleEn: 'Legal AI Advisor & Contract Clauses',
        titleHi: 'कानूनी एआई सलाहकार और अनुबंध की शर्तें',
        icon: Icons.balance_rounded,
        usedForAr: 'التدقيق القانوني لبنود العقود، التحقق من مطابقتها للقوانين (ريرا في دبي والقانون المصري)، وحماية الطرفين.',
        usedForEn: 'Auditing tenancy clauses, verifying compliance with RERA & Civil Code statutes, and resolving ambiguities.',
        usedForHi: 'किरायेदारी खंडों का ऑडिट करना, कानूनों के अनुपालन की पुष्टि करना और अस्पष्टताओं को हल करना।',
        locationInAppAr: 'منشئ العقود الرقمية (Lease Builder) ونافذة التدقيق القانوني الذكي.',
        locationInAppEn: 'Digital Lease Builder & AI Legal Clause Advisor Dialog.',
        locationInAppHi: 'डिजिटल लीज बिल्डर और एआई लीगल क्लॉज एडवाइजर डायलॉग।',
        featureBadge: 'Legal RAG',
        top3Models: [
          AiModelOption(
            id: 'gemini-3.8-flash',
            name: 'Gemini 3.8 Flash Legal',
            generationBadge: 'Gen 3.8 Flash',
            provider: 'Google DeepMind',
            tokenLevel: TokenConsumptionLevel.ultraLow,
            typicalTokensPerCall: 950,
            inputCostPerMillion: 0.075,
            outputCostPerMillion: 0.30,
            averageLatencySeconds: 0.28,
            contextWindow: '2M Tokens',
            badgeText: 'الأعلى سرعة ودقة وقانونية',
            descriptionAr: 'تدقيق قانوني فائق السرعة ولحظي لبنود العقود ومطابقتها للأنظمة الإيجارية بأقل كلفة وزمن استجابة.',
            descriptionEn: 'Ultra-fast, instant legal compliance audit of tenancy clauses with minimal latency and high precision.',
            descriptionHi: 'न्यूनतम विलंबता और उच्च सटीकता के साथ किरायेदारी खंडों का त्वरित कानूनी ऑडिट।',
            isRecommended: true,
          ),
          AiModelOption(
            id: 'gemini-3.8-flagship',
            name: 'Gemini 3.8 Legal Flagship',
            generationBadge: 'Gen 3.8',
            provider: 'Google DeepMind',
            tokenLevel: TokenConsumptionLevel.high,
            typicalTokensPerCall: 2600,
            inputCostPerMillion: 0.35,
            outputCostPerMillion: 1.40,
            averageLatencySeconds: 1.30,
            contextWindow: '2M Tokens',
            badgeText: 'استدلال نزاعات وصياغة',
            descriptionAr: 'توليد بنود حمائية متقدمة، حل التضاربات، وتحليل سيناريوهات النزاعات القضائية.',
            descriptionEn: 'Advanced protective clause generation, conflict resolution, and dispute risk modeling.',
            descriptionHi: 'उन्नत सुरक्षात्मक खंड निर्माण और विवाद जोखिम मॉडलिंग।',
          ),
          AiModelOption(
            id: 'gemini-2.5-flash',
            name: 'Gemini 2.5 Flash Legal',
            generationBadge: 'Gen 2.5',
            provider: 'Google DeepMind',
            tokenLevel: TokenConsumptionLevel.ultraLow,
            typicalTokensPerCall: 900,
            inputCostPerMillion: 0.075,
            outputCostPerMillion: 0.30,
            averageLatencySeconds: 0.45,
            contextWindow: '1M Tokens',
            badgeText: 'فحص قياسي سريع',
            descriptionAr: 'فحص أولي سريع للتحقق من عدم وجود بنود باطلة في العقود القياسية.',
            descriptionEn: 'Rapid pre-screening of standard tenancy contracts for missing clauses.',
            descriptionHi: 'अनुबंधों में छूटे हुए खंडों के लिए मानक किरायेदारी अनुबंधों की त्वरित जांच।',
          ),
        ],
      ),

      // 6. Virtual Staging & Visual AI
      const AiServiceCategory(
        serviceType: AiServiceType.virtualStaging,
        titleAr: 'الفرش الافتراضي والتوليد البصري (Visual AI)',
        titleEn: 'Virtual Staging & Visual Image Synthesis',
        titleHi: 'आभासी स्टेजिंग और विजुअल इमेज जनरेशन',
        icon: Icons.image_search_rounded,
        usedForAr: 'فرش الغرف الفارغة افتراضياً بأثاث عصري واقعي، فحص جودة الصور، والتعرف على عيوب الصيانة.',
        usedForEn: 'Room-preserving virtual staging of unfurnished spaces, photo quality moderation, and defect inspection.',
        usedForHi: 'बिना सुसज्जित स्थानों का कमरे-संरक्षण आभासी स्टेजिंग और दोष निरीक्षण।',
        locationInAppAr: 'معرض صور العقار، نافذة الفرش الافتراضي، وأداة كشف عيوب الصيانة البصرية.',
        locationInAppEn: 'Property Photo Gallery, Virtual Staging Modal, and Vision Maintenance Dialog.',
        locationInAppHi: 'संपत्ति फोटो गैलरी, वर्चुअल स्टेजिंग और विज़न मेंटेनेंस संवाद।',
        featureBadge: 'Imagen & Vision',
        top3Models: [
          AiModelOption(
            id: 'imagen-3-fast',
            name: 'Google Imagen 3 (Fast Engine)',
            generationBadge: 'Imagen 3',
            provider: 'Google Cloud AI',
            tokenLevel: TokenConsumptionLevel.balanced,
            typicalTokensPerCall: 2000,
            inputCostPerMillion: 0.030,
            outputCostPerMillion: 0.040,
            averageLatencySeconds: 1.80,
            contextWindow: 'Visual Inpaint',
            badgeText: 'فرش سريع متوازن',
            descriptionAr: 'فرش افتراضي للغرف الفارغة وتعديل الديكور بجودة عالية وتكلفة منخفضة.',
            descriptionEn: 'Photorealistic room-preserving furniture generation with swift render speeds.',
            descriptionHi: 'तेज गति के साथ यथार्थवादी कमरा-संरक्षण फर्नीचर निर्माण।',
            isRecommended: true,
          ),
          AiModelOption(
            id: 'imagen-3-ultra',
            name: 'Google Imagen 3 (Ultra 4K)',
            generationBadge: 'Imagen 3 Ultra',
            provider: 'Google Cloud AI',
            tokenLevel: TokenConsumptionLevel.high,
            typicalTokensPerCall: 4000,
            inputCostPerMillion: 0.060,
            outputCostPerMillion: 0.080,
            averageLatencySeconds: 3.20,
            contextWindow: 'Visual 4K',
            badgeText: 'واقعية سينمائية 4K',
            descriptionAr: 'إضاءة واقعية فائقة الدقة وأثاث فاخر مخصص للوحدات والفلل الراقية.',
            descriptionEn: 'Ray-traced photorealism, custom luxury textures, and ultra-high resolution rendering.',
            descriptionHi: 'अल्ट्रा-उच्च रिज़ॉल्यूशन रेंडरिंग और कस्टम लक्जरी बनावट।',
          ),
          AiModelOption(
            id: 'gemini-2.0-flash-vision',
            name: 'Gemini 2.0 Flash Vision',
            generationBadge: 'Multimodal',
            provider: 'Google DeepMind',
            tokenLevel: TokenConsumptionLevel.ultraLow,
            typicalTokensPerCall: 1200,
            inputCostPerMillion: 0.10,
            outputCostPerMillion: 0.40,
            averageLatencySeconds: 0.65,
            contextWindow: '1M Tokens',
            badgeText: 'فحص الصور والعيوب',
            descriptionAr: 'تحليل صور الغرف، التعرف على العيوب المعمارية وتوجيه عملية الفرش الافتراضي.',
            descriptionEn: 'Visual architectural flaw detection and guided geometric room layout analysis.',
            descriptionHi: 'वास्तु दोष का पता लगाना और कमरा लेआउट विश्लेषण।',
          ),
        ],
      ),
    ];

    // Set initial defaults to the recommended model for each service
    for (final cat in _categories) {
      final recommended = cat.top3Models.firstWhere(
        (m) => m.isRecommended,
        orElse: () => cat.top3Models.first,
      );
      _activeModelMap[cat.serviceType] = recommended.id;
    }
  }

  /// Returns the current active model ID for a given AI service
  String getModelName(AiServiceType type) {
    return _activeModelMap[type] ?? 'gemini-2.5-flash';
  }

  /// Returns the full model definition currently active for an AI service
  AiModelOption getActiveModel(AiServiceType type) {
    final cat = _categories.firstWhere((c) => c.serviceType == type);
    final activeId = getModelName(type);
    return cat.top3Models.firstWhere(
      (m) => m.id == activeId,
      orElse: () => cat.top3Models.first,
    );
  }

  /// Switches the active model for a specific service and notifies all listeners
  void switchModel(AiServiceType type, String modelId) {
    if (_activeModelMap[type] == modelId) return;
    _activeModelMap[type] = modelId;
    notifyListeners();
  }

  /// Calculates total estimated tokens consumed by the organization per month
  /// based on active model choices assuming ~2,500 monthly transactions
  int calculateEstimatedMonthlyTokens() {
    int total = 0;
    const monthlyRequests = 2500;
    for (final cat in _categories) {
      final active = getActiveModel(cat.serviceType);
      total += (active.typicalTokensPerCall * (monthlyRequests ~/ _categories.length));
    }
    return total;
  }

  /// Calculates estimated monthly expense in USD based on active models
  double calculateEstimatedMonthlyCost() {
    double cost = 0.0;
    const monthlyRequests = 2500;
    for (final cat in _categories) {
      final active = getActiveModel(cat.serviceType);
      cost += (active.costPerThousandCalls * ((monthlyRequests ~/ _categories.length) / 1000.0));
    }
    return double.parse(cost.toStringAsFixed(2));
  }

  /// Calculates cost savings index compared to using legacy heavy models exclusively
  int calculateEstimatedSavingsPercentage() {
    // If all services used high reasoning legacy models, cost would be ~$32/mo
    final currentCost = calculateEstimatedMonthlyCost();
    const benchmarkLegacyCost = 28.50;
    if (currentCost >= benchmarkLegacyCost) return 10;
    final savings = ((benchmarkLegacyCost - currentCost) / benchmarkLegacyCost) * 100;
    return savings.clamp(15, 88).round();
  }

  /// Resets all models across all 6 services to their recommended default settings
  void resetToDefaults() {
    for (final cat in _categories) {
      final recommended = cat.top3Models.firstWhere(
        (m) => m.isRecommended,
        orElse: () => cat.top3Models.first,
      );
      _activeModelMap[cat.serviceType] = recommended.id;
    }
    notifyListeners();
  }
}
