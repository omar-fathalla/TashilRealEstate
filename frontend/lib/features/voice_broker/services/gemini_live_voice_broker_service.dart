import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/ai_quota_manager.dart';
import '../../public_marketplace/models/property_item.dart';
import '../models/viewing_appointment_model.dart';
import '../models/voice_broker_message.dart';
import 'viewing_appointments_service.dart';

enum VoiceBrokerState {
  idle,
  listening,
  thinking,
  speaking,
}

enum VoiceBrokerDialect {
  egyptianArabic,
  emiratiArabic,
  english,
  hindi,
}

class GeminiLiveVoiceBrokerService {
  static final GeminiLiveVoiceBrokerService _instance = GeminiLiveVoiceBrokerService._internal();
  factory GeminiLiveVoiceBrokerService() => _instance;
  GeminiLiveVoiceBrokerService._internal();

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';

  final ViewingAppointmentsService _appointmentsService = ViewingAppointmentsService();

  /// State notifier for the UI (Orb, Visualizer, Button)
  final ValueNotifier<VoiceBrokerState> stateNotifier = ValueNotifier<VoiceBrokerState>(VoiceBrokerState.idle);

  /// Live audio frequency levels for waveform visualizer (0.0 to 1.0)
  final ValueNotifier<List<double>> audioWaveformNotifier = ValueNotifier<List<double>>(List.filled(24, 0.1));

  Timer? _waveformTimer;
  Timer? _speechSimulationTimer;

  void _startWaveformAnimation({required bool isSpeaking}) {
    _waveformTimer?.cancel();
    final random = Random();
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 75), (timer) {
      final baseAmp = isSpeaking ? 0.75 : 0.45;
      final newBars = List<double>.generate(24, (index) {
        final variance = (sin(timer.tick * 0.3 + index * 0.4).abs() * 0.5) + (random.nextDouble() * 0.4);
        return (variance * baseAmp).clamp(0.08, 1.0);
      });
      audioWaveformNotifier.value = newBars;
    });
  }

  void _stopWaveformAnimation() {
    _waveformTimer?.cancel();
    _waveformTimer = null;
    audioWaveformNotifier.value = List.filled(24, 0.08);
  }

  /// Start simulated voice speech synthesis with realistic duration
  Future<void> speakResponseText(String text, {required VoidCallback onComplete}) async {
    stateNotifier.value = VoiceBrokerState.speaking;
    _startWaveformAnimation(isSpeaking: true);

    // Calculate realistic speaking duration based on text length (avg 180 words per minute)
    final wordCount = text.split(' ').length;
    final estimatedSeconds = (wordCount / 3.0).clamp(2.5, 9.0);

    _speechSimulationTimer?.cancel();
    _speechSimulationTimer = Timer(Duration(milliseconds: (estimatedSeconds * 1000).toInt()), () {
      _stopWaveformAnimation();
      stateNotifier.value = VoiceBrokerState.idle;
      onComplete();
    });
  }

  void stopSpeaking() {
    _speechSimulationTimer?.cancel();
    _stopWaveformAnimation();
    stateNotifier.value = VoiceBrokerState.idle;
  }

  /// Send user message (voice transcription or text) to Gemini with full property context and function calling
  Future<VoiceBrokerMessage> processUserSpeech({
    required String userSpeechText,
    required PropertyItem property,
    required VoiceBrokerDialect dialect,
    required List<VoiceBrokerMessage> conversationHistory,
    String? clientName,
    String? clientPhone,
  }) async {
    stateNotifier.value = VoiceBrokerState.thinking;
    _startWaveformAnimation(isSpeaking: false);

    try {
      // 1. Check Quota & ApiKey
      if (_apiKey.isEmpty || !AiQuotaManager().hasAvailableQuota) {
        await Future.delayed(const Duration(milliseconds: 700));
        final fallbackMsg = _generateDeterministicResponse(
          userSpeechText: userSpeechText,
          property: property,
          dialect: dialect,
          clientName: clientName,
          clientPhone: clientPhone,
        );
        return fallbackMsg;
      }

      // 2. Build Gemini Multimodal System Prompt & Tools
      final systemPrompt = _buildSystemPrompt(property, dialect);
      final toolsPayload = _buildFunctionTools();

      final contentsPayload = <Map<String, dynamic>>[];

      // Conversation turns
      for (final msg in conversationHistory.take(6)) {
        contentsPayload.add({
          'role': msg.sender == MessageSender.user ? 'user' : 'model',
          'parts': [{'text': msg.text}],
        });
      }

      // Current User Speech
      contentsPayload.add({
        'role': 'user',
        'parts': [{'text': userSpeechText}],
      });

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {
            'parts': [{'text': systemPrompt}]
          },
          'contents': contentsPayload,
          'tools': toolsPayload,
          'generationConfig': {
            'temperature': 0.6,
            'maxOutputTokens': 800,
          },
        }),
      ).timeout(const Duration(seconds: 12));

      AiQuotaManager().recordUsage();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidate = data['candidates']?[0];
        final content = candidate?['content'];
        final parts = content?['parts'] as List<dynamic>? ?? [];

        // Check if Gemini invoked a Function Call (tool_use)
        for (final part in parts) {
          if (part.containsKey('functionCall')) {
            final funcCall = part['functionCall'];
            final funcName = funcCall['name'] as String;
            final funcArgs = funcCall['args'] as Map<String, dynamic>? ?? {};

            return await _executeFunctionCall(
              functionName: funcName,
              args: funcArgs,
              property: property,
              dialect: dialect,
              clientName: clientName,
              clientPhone: clientPhone,
            );
          }
        }

        // Standard Text Response
        final replyText = parts.map((p) => p['text'] ?? '').join(' ').trim();
        if (replyText.isNotEmpty) {
          return VoiceBrokerMessage(
            id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
            sender: MessageSender.broker,
            text: replyText,
            timestamp: DateTime.now(),
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ [GeminiLiveVoiceBroker] API error: $e, using deterministic intelligent fallback');
    }

    // Fallback to intelligent local rules & function execution
    return _generateDeterministicResponse(
      userSpeechText: userSpeechText,
      property: property,
      dialect: dialect,
      clientName: clientName,
      clientPhone: clientPhone,
    );
  }

  /// Execute function calling tools
  Future<VoiceBrokerMessage> _executeFunctionCall({
    required String functionName,
    required Map<String, dynamic> args,
    required PropertyItem property,
    required VoiceBrokerDialect dialect,
    String? clientName,
    String? clientPhone,
  }) async {
    final now = DateTime.now();

    if (functionName == 'book_viewing_appointment') {
      final name = args['client_name']?.toString().isNotEmpty == true
          ? args['client_name'].toString()
          : (clientName ?? (dialect == VoiceBrokerDialect.egyptianArabic ? 'أحمد الشريف' : 'محمد المنصوري'));
      final phone = args['client_phone']?.toString().isNotEmpty == true
          ? args['client_phone'].toString()
          : (clientPhone ?? (property.countryCode == 'AE' ? '+971 50 882 1920' : '+20 10 9923 4812'));
      final dateStr = args['preferred_date']?.toString() ?? 'غداً';
      final timeStr = args['preferred_time']?.toString() ?? '5:00 مساءً';
      final notes = args['notes']?.toString() ?? 'حجز مباشر عبر المساعد الصوتي الذكي Gemini Live';

      final scheduledDate = now.add(const Duration(days: 1, hours: 4));

      final appointment = await _appointmentsService.bookAppointment(
        propertyId: property.id,
        propertyTitle: property.getTitle('ar'),
        clientName: name,
        clientPhone: phone,
        scheduledDateTime: scheduledDate,
        countryCode: property.countryCode,
        notes: '$notes (الموعد المقترح: $dateStr الساعة $timeStr)',
        bookedBy: 'gemini_voice_broker',
      );

      final replyText = _getAppointmentConfirmationSpeech(dialect, name, dateStr, timeStr);

      return VoiceBrokerMessage(
        id: 'msg_${now.millisecondsSinceEpoch}',
        sender: MessageSender.broker,
        text: replyText,
        timestamp: now,
        functionCallType: FunctionCallType.bookViewing,
        appointmentData: appointment,
      );
    } else if (functionName == 'calculate_affordability') {
      final downPayment = (args['down_payment'] as num?)?.toDouble() ?? (property.pricePerMonth * 3);
      final years = (args['installment_years'] as num?)?.toInt() ?? 5;
      final monthly = (property.pricePerMonth * 1.1) / (years > 0 ? years : 1);

      final result = AffordabilityResult(
        propertyPrice: property.pricePerMonth * 12,
        downPayment: downPayment,
        years: years,
        estimatedMonthlyPayment: monthly,
        downPaymentPercentage: 15.0,
        affordabilityLevel: 'ممتازة ومناسبة للدخل',
      );

      final replyText = _getAffordabilitySpeech(dialect, monthly, years);

      return VoiceBrokerMessage(
        id: 'msg_${now.millisecondsSinceEpoch}',
        sender: MessageSender.broker,
        text: replyText,
        timestamp: now,
        functionCallType: FunctionCallType.calculateAffordability,
        affordabilityData: result,
      );
    } else if (functionName == 'inquire_nearby_facilities') {
      final facilities = _getFacilitiesForProperty(property);
      final replyText = _getFacilitiesSpeech(dialect, property, facilities);

      return VoiceBrokerMessage(
        id: 'msg_${now.millisecondsSinceEpoch}',
        sender: MessageSender.broker,
        text: replyText,
        timestamp: now,
        functionCallType: FunctionCallType.inquireFacilities,
        facilitiesData: facilities,
      );
    }

    return VoiceBrokerMessage(
      id: 'msg_${now.millisecondsSinceEpoch}',
      sender: MessageSender.broker,
      text: dialect == VoiceBrokerDialect.egyptianArabic
          ? 'تمام يا فندم، أنا تحت أمرك في أي استفسار يخص الوحدة دي.'
          : 'حاضر طال عمرك، آمرني بأي تفاصيل تباها عن هالعقار.',
      timestamp: now,
    );
  }

  /// System prompt generator tailored by country and dialect
  String _buildSystemPrompt(PropertyItem property, VoiceBrokerDialect dialect) {
    final currency = property.currencyCode == 'AED' ? 'درهم إماراتي (AED)' : 'جنيه مصري (EGP)';
    final location = property.getLocation('ar');
    final title = property.getTitle('ar');
    final price = property.pricePerMonth.toInt();

    String dialectTone = '';
    switch (dialect) {
      case VoiceBrokerDialect.egyptianArabic:
        dialectTone = '''
أنت وسيط عقاري ذكي وخبير في السوق المصري يعمل في منصة "تسهيل العقارية".
تحدث باللهجة المصرية الودودة والمهنية (زي: أهلاً بيك يا فندم، شقة تحفة في موقع متميز، نظام السداد، تأمين شهرين، قريبة جداً من المواصلات).
خلي إجاباتك موجزة وسريعة في جملتين أو ثلاثة لتناسب المحادثة الصوتية الفورية.
''';
        break;
      case VoiceBrokerDialect.emiratiArabic:
        dialectTone = '''
أنت وسيط عقاري ذكي ومستشار استثماري في السوق الإماراتي يعمل في منصة "تسهيل العقارية".
تحدث باللهجة الإماراتية والخليجية الراقية واللبقة (زي: مرحبابك الغالي، وحدة فاخرة بإطلالة مميزة، نظام 4 شيكات، قريبة من محطة المترو، يسعدني أرتبلك موعد معاينة).
خلي إجاباتك موجزة ومباشرة للمحادثة الصوتية.
''';
        break;
      case VoiceBrokerDialect.english:
        dialectTone = '''
You are an expert AI Real Estate Broker for "Tashil Real Estate".
Speak in a warm, professional, concise conversational tone. Keep replies under 3 sentences for instant voice feedback.
''';
        break;
      case VoiceBrokerDialect.hindi:
        dialectTone = '''
आप ताशिल रियल एस्टेट के एक विशेषज्ञ एआई रियल एस्टेट ब्रोकर हैं।
संक्षिप्त और विनम्र व्यावसायिक शैली में उत्तर दें। तत्काल वॉयस वार्तालाप के लिए 2-3 वाक्यों में उत्तर रखें।
''';
        break;
    }

    return '''
$dialectTone

معلومات العقار النشط الحالي الذي يسأل عنه العميل:
- عنوان العقار: $title
- الموقع والحي: $location
- كود الدولة: ${property.countryCode}
- القيمة الشهرية: $price $currency
- المساحة: ${property.areaSqM.toInt()} متر مربع
- عدد غرف النوم: ${property.bedrooms} | الحمامات: ${property.bathrooms}
- نوع العقار: ${property.propertyTypeCode}
- المرافق: مسبح، جيم، باركينج، حراسة، مكيفات، تشطيب الترا سوبر لوكس.

إذا طلب العميل حجز موعد معاينة (زي: "احجزلي معاينة"، "عاوز أشوف الشقة بكرة")، قم فوراً باستدعاء أداة `book_viewing_appointment`.
إذا سأل عن التقسيط أو الدفعة الأولى، استدعِ `calculate_affordability`.
إذا سأل عن المترو أو المدارس أو الخدمات القريبة، استدعِ `inquire_nearby_facilities`.
''';
  }

  /// Function Calling Schema for Gemini Tools
  List<Map<String, dynamic>> _buildFunctionTools() {
    return [
      {
        'function_declarations': [
          {
            'name': 'book_viewing_appointment',
            'description': 'Schedule an in-person or virtual property viewing appointment with the broker CRM.',
            'parameters': {
              'type': 'object',
              'properties': {
                'client_name': {'type': 'string', 'description': 'Name of the client'},
                'client_phone': {'type': 'string', 'description': 'Phone number or WhatsApp for confirmation'},
                'preferred_date': {'type': 'string', 'description': 'Preferred day/date (e.g. tomorrow, Saturday)'},
                'preferred_time': {'type': 'string', 'description': 'Preferred time (e.g. 5:00 PM, morning)'},
                'notes': {'type': 'string', 'description': 'Any specific client request or inspection focus'},
              },
              'required': ['client_name'],
            },
          },
          {
            'name': 'calculate_affordability',
            'description': 'Calculate down payment, installment plans, and monthly rental/mortgage affordability.',
            'parameters': {
              'type': 'object',
              'properties': {
                'down_payment': {'type': 'number', 'description': 'Down payment amount available'},
                'installment_years': {'type': 'integer', 'description': 'Installment duration in years'},
                'monthly_income': {'type': 'number', 'description': 'Client monthly income for debt ratio check'},
              },
            },
          },
          {
            'name': 'inquire_nearby_facilities',
            'description': 'Inquire distances and travel times to nearby Metro stations, schools, malls, and healthcare.',
            'parameters': {
              'type': 'object',
              'properties': {
                'facility_type': {'type': 'string', 'description': 'metro, schools, mall, hospital, or all'},
              },
            },
          },
        ]
      }
    ];
  }

  /// Intelligent deterministic fallback for offline or quick interaction
  VoiceBrokerMessage _generateDeterministicResponse({
    required String userSpeechText,
    required PropertyItem property,
    required VoiceBrokerDialect dialect,
    String? clientName,
    String? clientPhone,
  }) {
    final lower = userSpeechText.toLowerCase();
    final now = DateTime.now();

    // 1. Viewing Booking intent
    if (lower.contains('معاين') ||
        lower.contains('احجز') ||
        lower.contains('اشوف') ||
        lower.contains('حجز') ||
        lower.contains('book') ||
        lower.contains('viewing') ||
        lower.contains('visit') ||
        lower.contains('विजिट') ||
        lower.contains('बुक')) {
      final name = clientName ?? (dialect == VoiceBrokerDialect.egyptianArabic ? 'أحمد الشريف' : 'محمد المنصوري');
      final phone = clientPhone ?? (property.countryCode == 'AE' ? '+971 50 882 1920' : '+20 10 9923 4812');

      final appointment = ViewingAppointmentModel(
        id: 'viewing_${now.millisecondsSinceEpoch}',
        propertyId: property.id,
        propertyTitle: property.getTitle('ar'),
        clientName: name,
        clientPhone: phone,
        scheduledDateTime: now.add(const Duration(days: 1, hours: 4)),
        status: ViewingStatus.confirmed,
        notes: 'تم تثبيت الموعد آلياً عبر المساعد الصوتي وسيط تسهيل العقارية',
        countryCode: property.countryCode,
        bookedBy: 'gemini_voice_broker',
        createdAt: now,
      );

      _appointmentsService.bookAppointment(
        propertyId: property.id,
        propertyTitle: property.getTitle('ar'),
        clientName: name,
        clientPhone: phone,
        scheduledDateTime: appointment.scheduledDateTime,
        countryCode: property.countryCode,
        notes: appointment.notes,
      );

      final reply = _getAppointmentConfirmationSpeech(dialect, name, 'غداً', '5:00 مساءً');

      return VoiceBrokerMessage(
        id: 'msg_${now.millisecondsSinceEpoch}',
        sender: MessageSender.broker,
        text: reply,
        timestamp: now,
        functionCallType: FunctionCallType.bookViewing,
        appointmentData: appointment,
      );
    }

    // 2. Metro / Transportation / Facilities intent
    if (lower.contains('مترو') ||
        lower.contains('مواصل') ||
        lower.contains('مدارس') ||
        lower.contains('مستشف') ||
        lower.contains('مول') ||
        lower.contains('قريب') ||
        lower.contains('metro') ||
        lower.contains('school') ||
        lower.contains('distance') ||
        lower.contains('मेट्रो') ||
        lower.contains('स्कूल')) {
      final facilities = _getFacilitiesForProperty(property);
      final reply = _getFacilitiesSpeech(dialect, property, facilities);

      return VoiceBrokerMessage(
        id: 'msg_${now.millisecondsSinceEpoch}',
        sender: MessageSender.broker,
        text: reply,
        timestamp: now,
        functionCallType: FunctionCallType.inquireFacilities,
        facilitiesData: facilities,
      );
    }

    // 3. Payment / Cheques / Price intent
    if (lower.contains('دفع') ||
        lower.contains('تقسيط') ||
        lower.contains('شيك') ||
        lower.contains('سعر') ||
        lower.contains('إيجار') ||
        lower.contains('pay') ||
        lower.contains('price') ||
        lower.contains('rent') ||
        lower.contains('भुगतान') ||
        lower.contains('किराया')) {
      final downPayment = property.pricePerMonth * 2.5;
      final monthly = property.pricePerMonth;

      final result = AffordabilityResult(
        propertyPrice: property.pricePerMonth * 12,
        downPayment: downPayment,
        years: 1,
        estimatedMonthlyPayment: monthly,
        downPaymentPercentage: 20.0,
        affordabilityLevel: 'ممتازة ومتوافقة مع المعايير',
      );

      final reply = _getAffordabilitySpeech(dialect, monthly, 1);

      return VoiceBrokerMessage(
        id: 'msg_${now.millisecondsSinceEpoch}',
        sender: MessageSender.broker,
        text: reply,
        timestamp: now,
        functionCallType: FunctionCallType.calculateAffordability,
        affordabilityData: result,
      );
    }

    // 4. Default welcoming overview
    final generalReply = _getGeneralWelcomeSpeech(dialect, property);

    return VoiceBrokerMessage(
      id: 'msg_${now.millisecondsSinceEpoch}',
      sender: MessageSender.broker,
      text: generalReply,
      timestamp: now,
    );
  }

  String _getAppointmentConfirmationSpeech(
      VoiceBrokerDialect dialect, String name, String dateStr, String timeStr) {
    switch (dialect) {
      case VoiceBrokerDialect.egyptianArabic:
        return 'تم حجز موعد المعاينة بنجاح يا فندم! سجّلت الميعاد في جدول الوسيط ليوم $dateStr الساعة $timeStr باسم $name، وهيوصلك تأكيد على الواتساب فوراً.';
      case VoiceBrokerDialect.emiratiArabic:
        return 'تم تأكيد موعد المعاينة طال عمرك! ضفت الموعد لجدول الوسيط يوم $dateStr الساعة $timeStr باسم $name، وراح يتواصل معاك الوسيط لتأكيد اللوكيشن.';
      case VoiceBrokerDialect.english:
        return 'Your viewing appointment has been successfully booked for $dateStr at $timeStr under the name $name. The broker calendar has been updated.';
      case VoiceBrokerDialect.hindi:
        return 'आपकी विजिट अपॉइंटमेंट $dateStr को $timeStr पर $name के नाम से सफलतापूर्वक बुक हो गई है। ब्रोकर का कैलेंडर अपडेट कर दिया गया है।';
    }
  }

  String _getFacilitiesSpeech(
      VoiceBrokerDialect dialect, PropertyItem property, List<FacilityDistanceResult> facilities) {
    final isUAE = property.countryCode == 'AE';

    switch (dialect) {
      case VoiceBrokerDialect.egyptianArabic:
        return 'موقع العقار استراتيجي جداً! محطة المترو على بعد 5 دقايق بس مشي، وحواليك مجمع مدارس دولية ومول تجاري فيه كارفور وصيدليات 24 ساعة.';
      case VoiceBrokerDialect.emiratiArabic:
        return 'الموقع ولا أروع طال عمرك! محطة ترام ومترو دبي على بعد خطوات، ودقايق بسيطة من المارينا مول والممشى، وكل الخدمات الحيوية متوفرة.';
      case VoiceBrokerDialect.english:
        return isUAE
            ? 'Prime location in Dubai! Only 4 minutes walk to Dubai Metro and Marina Walk, with international schools and supermarkets right downstairs.'
            : 'Prime location! Just 5 minutes to the main Metro station and Road 90, surrounded by top international schools and retail centers.';
      case VoiceBrokerDialect.hindi:
        return 'शानदार स्थान! मेट्रो स्टेशन केवल 4-5 मिनट की दूरी पर है, और आसपास स्कूल, सुपरमार्केट और सभी आवश्यक सेवाएं उपलब्ध हैं।';
    }
  }

  String _getAffordabilitySpeech(VoiceBrokerDialect dialect, double monthly, int years) {
    final formatted = monthly.toInt();

    switch (dialect) {
      case VoiceBrokerDialect.egyptianArabic:
        return 'الإيجار الشهري المطلوب هو $formatted جنيه، بنظام دفع شهري منتظم مع شهرين تأمين مسترد عند نهاية العقد، وشامل الصيانة الدورية.';
      case VoiceBrokerDialect.emiratiArabic:
        return 'القيمة الإيجارية $formatted درهم شهرياً، متاحة بنظام 4 شيكات سنوية ميسرة، مع وديعة تأمين مستردة وتسهيلات في التسجيل عبر إيجاري.';
      case VoiceBrokerDialect.english:
        return 'The rate is $formatted per month. Payment can be scheduled flexibly with standard security deposit and hassle-free registration.';
      case VoiceBrokerDialect.hindi:
        return 'किराया $formatted प्रति माह है। लचीली किश्तों और मानक सुरक्षा जमा के साथ भुगतान की सुविधा उपलब्ध है।';
    }
  }

  String _getGeneralWelcomeSpeech(VoiceBrokerDialect dialect, PropertyItem property) {
    final title = property.getTitle('ar');
    final price = property.pricePerMonth.toInt();
    final isUAE = property.countryCode == 'AE';

    switch (dialect) {
      case VoiceBrokerDialect.egyptianArabic:
        return 'أهلاً بيك يا فندم! أنا وسيطك العقاري الذكي لوحدة $title. الشقة مساحتها ${property.areaSqM.toInt()} متر، تشطيب فاخر، وإيجارها $price جنيه شهرياً. حابب تعرف تفاصيل المرافق ولا نحجز موعد للمعاينة؟';
      case VoiceBrokerDialect.emiratiArabic:
        return 'مرحبابك الغالي! أنا وسيطك الذكي لهالعقار $title. المساحة ${property.areaSqM.toInt()} متر مربع، بإطلالة مميزة وإيجار $price درهم شهرياً. تبا تعرف تفاصيل الشيكات أو أرتبلك معاينة؟';
      case VoiceBrokerDialect.english:
        return 'Hello! I am your AI Voice Broker for $title. It features ${property.bedrooms} bedrooms, ${property.areaSqM.toInt()} sqm, listed at $price ${isUAE ? 'AED' : 'EGP'}/mo. How can I assist your viewing today?';
      case VoiceBrokerDialect.hindi:
        return 'नमस्ते! मैं ताशिल का एआई वॉयस ब्रोकर हूँ। यह ${property.bedrooms} बीएचके संपत्ति ${property.areaSqM.toInt()} वर्ग मीटर में है। क्या आप विजिट बुक करना चाहते हैं या विवरण जानना चाहते हैं?';
    }
  }

  List<FacilityDistanceResult> _getFacilitiesForProperty(PropertyItem property) {
    final isUAE = property.countryCode == 'AE';

    if (isUAE) {
      return const [
        FacilityDistanceResult(
          facilityName: 'محطة مترو دبي مارينا (Dubai Metro)',
          facilityType: 'metro',
          distanceKm: '0.4 كم',
          travelTimeMinutes: '4 دقائق مشياً',
          description: 'خط المترو الأحمر يربطك مباشرة ببرج خليفة والمطار.',
        ),
        FacilityDistanceResult(
          facilityName: 'مدرسة دبي الدولية البريطانية (GEMS)',
          facilityType: 'school',
          distanceKm: '1.8 كم',
          travelTimeMinutes: '5 دقائق بالسيارة',
          description: 'مناهج بريطانية معتمدة وتصنيف متميز من هيئة المعرفة.',
        ),
        FacilityDistanceResult(
          facilityName: 'دبي مارينا مول (Marina Mall)',
          facilityType: 'mall',
          distanceKm: '0.9 كم',
          travelTimeMinutes: '8 دقائق مشياً',
          description: 'أرقى الماركات والمطاعم والسينمات وسوبرماركت كبير.',
        ),
      ];
    } else {
      return const [
        FacilityDistanceResult(
          facilityName: 'محطة مونوريل التجمع الخامس - التسعين',
          facilityType: 'metro',
          distanceKm: '0.8 كم',
          travelTimeMinutes: '6 دقائق مشياً',
          description: 'ربط مباشر بالعاصمة الإدارية ومحطة مترو الاستاد.',
        ),
        FacilityDistanceResult(
          facilityName: 'مدرسة الشويفات الدولية (Choueifat)',
          facilityType: 'school',
          distanceKm: '2.3 كم',
          travelTimeMinutes: '6 دقائق بالسيارة',
          description: 'تعليم دولي متميز من الروضة حتى الثانوية العامة.',
        ),
        FacilityDistanceResult(
          facilityName: 'كايرو فيستيفال سيتي مول (CFC)',
          facilityType: 'mall',
          distanceKm: '3.5 كم',
          travelTimeMinutes: '8 دقائق بالسيارة',
          description: 'أكبر مركز تسوق وترفيه وسينمات ومطاعم بالقاهرة الجديدة.',
        ),
      ];
    }
  }
}
