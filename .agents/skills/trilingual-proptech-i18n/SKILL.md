---
name: trilingual-proptech-i18n
description: Authoritative guide for building, translating, and styling trilingual Real Estate applications (Arabic RTL, English LTR, and Hindi LTR) with Material Design 3.
---

# Trilingual PropTech i18n Skill (Arabic, English, Hindi)

This skill provides comprehensive instructions, terminology glossaries, architecture standards, and best practices for developing multilingual PropTech & Real Estate features for Tashil Real Estate.

---

## 1. Supported Languages & Directionality Matrix

| Language | Code | Direction | Primary Font | Use Case / Target Audience |
| :--- | :--- | :--- | :--- | :--- |
| **العربية (Arabic)** | `ar` | **RTL** | `GoogleFonts.cairoTextTheme()` | Primary / Default language (Egypt & GCC) |
| **English** | `en` | **LTR** | `GoogleFonts.interTextTheme()` | International investors & expats |
| **हिंदी (Hindi)** | `hi` | **LTR** | `GoogleFonts.notoSansDevanagariTextTheme()` | UAE & regional Indian expatriates |

---

## 2. Strict Zero-Mixing & Pure Language Standard (معيار النقاء اللغوي التام)

Whenever an AI Agent or developer adds or edits dictionary strings:
1. **100% Pure Arabic in `'ar'`:**
   - ❌ **Forbidden:** `الوكالة (Agency)`, `المالك (Owner)`, `(Demo Accounts) حسابات تجريبية`
   - ✅ **Correct:** `وكالة عقارية`, `مالك العقار`, `حسابات تجريبية سريعة للتجربة:`
2. **100% Pure English in `'en'`:**
   - ❌ **Forbidden:** `Agency Admin (وكالة)`, `Explore (استكشف)`
   - ✅ **Correct:** `Agency Admin`, `Explore Units`, `Quick Demo Accounts:`
3. **100% Pure Hindi in `'hi'`:**
   - ❌ **Forbidden:** `रियल एस्टेट (Real Estate)`, `एजेंसी (Agency)`
   - ✅ **Correct:** `रियल एस्टेट एजेंसी`, `त्वरित डेमो खाते:`

---

## 3. Mandatory Tri-Language Parity (التكافؤ التام بين اللغات الثلاث)
- Every user-facing string key added to `frontend/lib/core/localization/app_localizations.dart` MUST be added simultaneously to all 3 languages: `'ar'`, `'en'`, and `'hi'`.
- Naming convention: camelCase descriptive keys (e.g. `loginToPortal`, `roleAgency`, `exploreUnits`, `maxRent`).
- Never hardcode raw display strings in widgets. Always use `AppLocalizations.of(context).tr('key')`.

---

## 4. UI Reactivity & Instant Screen Rebuild Protocol
To ensure that switching the language re-renders the screen immediately in `<1ms` without requiring a page reload:
- Wrap top-level screens or dynamic cards in `ValueListenableBuilder<Locale>`:
```dart
return ValueListenableBuilder<Locale>(
  valueListenable: LocaleController.currentLocale,
  builder: (context, locale, child) {
    final loc = AppLocalizations.of(context);
    final lang = locale.languageCode;
    return Scaffold(...);
  },
);
```

---

## 5. PropTech Terminology Glossary

| English Key | Arabic (AR - RTL) | English (EN - LTR) | Hindi (HI - LTR) |
| :--- | :--- | :--- | :--- |
| `appName` | Tashil Real Estate | Tashil Real Estate | ताशिल रियल एस्टेट |
| `appSlogan` | تسهيل لإدارة وعرض العقارات | Smart PropTech Rental Management | स्मार्ट प्रोपटेक रेंटल प्रबंधन |
| `apartment` | شقة | Apartment | अपार्टमेंट |
| `villa` | فيلا | Villa | विला |
| `studio` | ستوديو | Studio | स्टूडियो |
| `duplex` | دوبلكس | Duplex | डुप्लेक्स |
| `chalet` | شاليه | Chalet | शैले |
| `monthly_rent` | إيجار شهري | Monthly Rent | मासिक किराया |
| `security_deposit` | تأمين إيجاري | Security Deposit | सुरक्षा जमा |
| `bedrooms` | غرف نوم | Bedrooms | बेडरूम |
| `bathrooms` | حمامات | Bathrooms | बाथरूम |
| `area_sqm` | المساحة بالمتر المربع | Area in SqM | वर्ग मीटर में क्षेत्रफल |
| `furnished` | مفروش بالكامل | Fully Furnished | पूरी तरह सुसज्जित |
| `vacant` | متاح للإيجار | Available / Vacant | उपलब्ध |
| `rented` | مؤجر | Rented | किराये पर दिया गया |
| `request_viewing` | طلب معاينة | Request Viewing | विज़िट का अनुरोध करें |
| `maintenance_request`| طلب صيانة | Maintenance Request | रखरखाव अनुरोध |
| `lease_agreement` | عقد إيجار | Lease Agreement | पट्टा समझौता |
| `roleAgency` | وكالة عقارية | Agency Admin | रियल एस्टेट एजेंसी |
| `roleOwner` | مالك العقار | Property Owner | संपत्ति मालिक |
| `roleTenant` | مستأجر | Tenant | किरायेदार |
| `roleSuperAdmin` | مدير المنصة | Super Admin | सुपर व्यवस्थापक |

---

## 6. RTL/LTR Directionality Implementation Rules
- Use `EdgeInsetsDirectional` for start/end insets:
  ```dart
  padding: const EdgeInsetsDirectional.only(start: 16, end: 16, top: 12, bottom: 12)
  ```
- Use `AlignmentDirectional.centerStart` and `CrossAxisAlignment.start` which automatically mirror in RTL.
- In Arabic (`ar`), navigation items and back arrows naturally mirror to the right.
