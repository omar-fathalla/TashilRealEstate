---
name: material-design-3
description: Definitive, component-by-component Material Design 3 (M3) Design System standards, button taxonomy, and trilingual UI guidelines for Tashil Real Estate.
---

# Material Design 3 (M3) — Tashil Real Estate Component Standards

This skill is the **authoritative reference and design system handbook** for building, styling, and architecting all UI screens, widgets, and user flows in **Tashil Real Estate (تسهيل العقاري)**.

Whenever creating or modifying any screen, widget, form, card, button, modal, or layout, you MUST adhere strictly to these official M3 component specifications.

---

## 1. Design Philosophy & Google Ecosystem Alignment

Tashil Real Estate leverages Google's **Material Design 3 (M3)** as its core design engine, paired with a custom enterprise PropTech aesthetic:
1. **Strict M3 Enabling**: `useMaterial3: true` is mandatory across all light and dark themes.
2. **Single Seed Dynamic Palette**: Derived via `ColorScheme.fromSeed(seedColor: Color(0xFF0F172A), primary: Color(0xFF0F172A), secondary: Color(0xFF3B82F6), tertiary: Color(0xFFF59E0B))`.
3. **Surface Tiers over Hard Elevation**: M3 uses tonal surface tiers (`surfaceContainerLowest`, `surfaceContainerLow`, `surfaceContainer`, `surfaceContainerHigh`, `surfaceContainerHighest`) with subtle 1px borders (`outlineVariant`), avoiding harsh skeuomorphic drop shadows.
4. **Trilingual RTL & LTR Parity**: All components must seamlessly adapt between Arabic (RTL, Cairo font), English (LTR, Inter font), and Hindi (LTR, Noto Sans Devanagari font).

---

## 2. Component Taxonomy & Button Breakdown

### Group 1: Actions & Buttons (الأزرار والتفاعلات)

Ref: [https://m3.material.io/components/all-buttons](https://m3.material.io/components/all-buttons)

#### 1.1 `FilledButton` (High-Emphasis Action)
* **Visual**: Solid `primary` color fill, `onPrimary` text/icon.
* **Shape**: Rounded rectangle (`BorderRadius.circular(10)` or `12`).
* **Use Case**: The single most prominent action on a screen or card.
  * *Examples*: "تسجيل الدخول" (Sign In), "إضافة عقار جديد" (Add New Property), "توقيع العقد" (Sign Contract), "تأكيد الدفع" (Confirm Payment).
* **Code Pattern**:
  ```dart
  FilledButton.icon(
    onPressed: () => _handleSubmit(),
    icon: const Icon(Icons.check_circle_outline),
    label: Text(loc.tr('confirmBooking')),
  )
  ```

#### 1.2 `FilledButton.tonal` (Medium-High Emphasis Action)
* **Visual**: Soft `secondaryContainer` fill with `onSecondaryContainer` text/icon.
* **Shape**: Rounded rectangle (`BorderRadius.circular(10)`).
* **Use Case**: Secondary major actions that need visual weight without overpowering the primary button.
  * *Examples*: "تصدير التقرير PDF" (Export PDF), "تصفية متقدمة" (Advanced Filters), "إرسال تذكير" (Send Reminder).
* **Code Pattern**:
  ```dart
  FilledButton.tonalIcon(
    onPressed: () => _handleExport(),
    icon: const Icon(Icons.download_rounded),
    label: Text(loc.tr('exportPdf')),
  )
  ```

#### 1.3 `ElevatedButton` (Surface-Elevated Action)
* **Visual**: Surface fill with tonal shadow elevation (`elevation: 1` to `2`).
* **Use Case**: Buttons resting on dynamic, patterned, or image backgrounds (e.g. over property photo carousels or interactive maps).
* **Code Pattern**:
  ```dart
  ElevatedButton.icon(
    onPressed: () => _openGallery(),
    icon: const Icon(Icons.photo_library_outlined),
    label: Text(loc.tr('viewAllPhotos')),
  )
  ```

#### 1.4 `OutlinedButton` (Medium-Emphasis Action)
* **Visual**: Transparent fill with `outlineVariant` / `outline` 1px border.
* **Shape**: Rounded rectangle (`BorderRadius.circular(10)`).
* **Use Case**: Neutral, non-destructive secondary options.
  * *Examples*: "إلغاء" (Cancel), "تراجع" (Back), "عرض التفاصيل" (View Details), "تعديل المسودة" (Edit Draft).
* **Code Pattern**:
  ```dart
  OutlinedButton.icon(
    onPressed: () => Navigator.of(context).pop(),
    icon: const Icon(Icons.arrow_back),
    label: Text(loc.tr('cancel')),
  )
  ```

#### 1.5 `TextButton` (Low-Emphasis Inline Action)
* **Visual**: Borderless, background-less text button with hover/splash state.
* **Use Case**: Inline links, table row utilities, dialog dismissal.
  * *Examples*: "نسيت كلمة المرور؟" (Forgot Password?), "عرض المزيد" (See More), "تخطي" (Skip).
* **Code Pattern**:
  ```dart
  TextButton(
    onPressed: () => _handleForgotPassword(),
    child: Text(loc.tr('forgotPassword')),
  )
  ```

#### 1.6 `IconButton` (Standard / Filled / Tonal / Outlined)
* **Visual Variants**:
  * `IconButton` (Standard toolbar actions).
  * `IconButton.filled` (Primary circular action).
  * `IconButton.tonal` (Muted circular action).
  * `IconButton.outlined` (Bordered circular action).
* **Use Case**: Quick table row actions, favorite bookmarking (❤️), sharing (🔗), search dismiss (✕).
* **Code Pattern**:
  ```dart
  IconButton.outlined(
    onPressed: () => _toggleFavorite(),
    icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
    tooltip: loc.tr('saveProperty'),
  )
  ```

#### 1.7 `FloatingActionButton` (Hero Action)
* **Visual**: Large rounded square container (`BorderRadius.circular(16)`), floating over content.
* **Variants**: `FloatingActionButton.small`, `FloatingActionButton.extended`, `FloatingActionButton.large`.
* **Use Case**: The focal creative action of a portal (e.g. Floating "طلب صيانة" / "New Maintenance Request").
* **Code Pattern**:
  ```dart
  FloatingActionButton.extended(
    onPressed: () => _createListing(),
    icon: const Icon(Icons.add_home_work_rounded),
    label: Text(loc.tr('newListing')),
  )
  ```

#### 1.8 `TashilConnectedButtonGroup` (Official M3 Expressive Connected Button Group)
Ref: [https://m3.material.io/components/button-groups/guidelines](https://m3.material.io/components/button-groups/guidelines)
* **Status**: Replaces legacy baseline `SegmentedButton` (which is deprecated in the M3 Expressive guidelines).
* **Visual Architecture**:
  * **Outer Track**: Continuous stadium capsule (`height: 42.0`, `borderRadius: BorderRadius.circular(21)`), filled with `colorScheme.surfaceContainerHigh` (or `surfaceContainer` if tonal), padded with `3.5dp`, and bordered with subtle `colorScheme.outlineVariant.withValues(alpha: 0.4)`.
  * **Floating Active Pill**: Concentric stadium pill (`height: 35.0`, `borderRadius: BorderRadius.circular(17.5)`), filled with `colorScheme.primary` (or `secondaryContainer` if tonal), `onPrimary` text/icon, and floating elevation shadow (`BoxShadow(color: colorScheme.shadow.withValues(alpha: 0.12), blurRadius: 4, offset: Offset(0, 1.5))`).
  * **Motion Physics**: Smooth `220ms` cubic transition using `Curves.easeInOutCubic`.
  * **Inactive State**: Transparent background, `onSurfaceVariant` label/icon, and M3 hover state layer (`colorScheme.onSurface.withValues(alpha: 0.08)`).
* **Use Cases**:
  * Switching modes ("إيجار / بيع" — Rent vs Buy).
  * Country / regional scoping (🇪🇬 Egypt vs 🇦🇪 UAE vs All).
  * Switching table views, sorting criteria, and property categories.
* **Code Pattern**:
  ```dart
  TashilConnectedButtonGroup<String>(
    selectedValue: _selectedFilter,
    onSelectionChanged: (val) => setState(() => _selectedFilter = val),
    segments: [
      TashilConnectedButtonSegment<String>(
        value: 'ALL',
        label: loc.tr('allAgencies'),
        icon: Icons.domain_rounded,
      ),
      TashilConnectedButtonSegment<String>(
        value: 'EG',
        label: loc.tr('country_eg'),
        leading: const Text('🇪🇬', style: TextStyle(fontSize: 15)),
      ),
      TashilConnectedButtonSegment<String>(
        value: 'AE',
        label: loc.tr('country_ae'),
        leading: const Text('🇦🇪', style: TextStyle(fontSize: 15)),
      ),
    ],
  )
  ```
* **Shorthand Trigger Protocol ("حولهالي بنفس النمط" / "طبق الـ Connected Button Group"):** Whenever the user says "حولهالي بنفس النمط" for any filter, view switch, or choice buttons, the agent MUST immediately implement `TashilConnectedButtonGroup<T>` using this exact specification.

#### ⚠️ STRICT SINGLE-ICON RULE FOR BUTTONS:
1. Every button MUST contain at most **ONE single icon**.
2. **NEVER combine two icons** or mix a Flutter `Icon` widget with an emoji in the button's label text.
3. When using country flags or emojis in connected button segments, pass them cleanly via `leading: Text('🇪🇬', style: TextStyle(fontSize: 15))` without additional `Icon` widgets.
4. ❌ **WRONG**: `FilledButton.icon(icon: Icon(Icons.rocket_launch), label: Text('🚀 انضم الآن'))`
5. ✅ **CORRECT**: `FilledButton.icon(icon: Icon(Icons.rocket_launch), label: Text(loc.tr('joinNow')))`

---

### Group 2: Navigation & Structure (الهيكلة والتنقل)

Ref: [https://m3.material.io/components/navigation-bar](https://m3.material.io/components/navigation-bar)

* **`TopAppBar`**:
  * Uses `colorScheme.surfaceContainer` with elevation `0` and a subtle bottom border.
  * In Arabic RTL: Logo starts on the Right; actions (Language switcher, Notifications, Profile) end on the Left.
  * In English/Hindi LTR: Logo starts on the Left; actions end on the Right.
* **`NavigationBar` (Mobile Bottom Nav)**:
  * Uses pill indicator with `colorScheme.secondaryContainer`.
  * Active icon and label in `colorScheme.onSecondaryContainer`.
* **`NavigationRail` & `NavigationDrawer` (Desktop/Tablet Portals)**:
  * Role-based side navigation for `/agency`, `/owner`, `/tenant`, and `/super-admin`.
  * M3 rounded item indicators with localized icons and labels.

---

### Group 3: Containers & Cards (الحاويات والبطاقات)

Ref: [https://m3.material.io/components/cards](https://m3.material.io/components/cards)

* **`Card.outlined`**:
  * Background: `colorScheme.surface`.
  * Border: `Border.all(color: colorScheme.outlineVariant)`.
  * Radius: `BorderRadius.circular(16)`.
  * Primary use: Marketplace property cards, tenant contract overview.
* **`Card.filled`**:
  * Background: `colorScheme.surfaceContainerLowest` or `surfaceContainerLow`.
  * Radius: `BorderRadius.circular(16)`.
  * Primary use: Dashboard analytical metric cards (Total Revenue, Occupancy Rate, Maintenance Costs).
* **`ListTile` & `ExpansionTile`**:
  * M3 formatted rows with leading icon container (`surfaceContainerHighest`), title in `titleMedium`, subtitle in `bodyMedium`, and trailing badge or chevron.

---

### Group 4: Selection & Chips (الفلاتر والخيارات)

Ref: [https://m3.material.io/components/chips](https://m3.material.io/components/chips)

* **`FilterChip`**: Multi-select filters (e.g. Swimming Pool, Parking, Sea View, Furnished). Selected state fills with `colorScheme.secondaryContainer` + leading checkmark.
* **`ChoiceChip`**: Single-choice options (e.g. Bedroom count: Studio, 1, 2, 3, 4+).
* **`ActionChip`**: Quick contextual triggers (e.g. "📞 اتصل بالوكيل", "📍 عرض في الخريطة").
* **`InputChip`**: Removable tags (e.g. "Dubai Marina ✕", "Riyadh Olaya ✕").

---

### Group 5: Text Inputs & Forms (حقول الإدخال والبحث)

Ref: [https://m3.material.io/components/text-fields](https://m3.material.io/components/text-fields)

* **Filled Variant with Rounded Container**:
  * `filled: true`, `fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)`.
  * Border: `OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outlineVariant))`.
  * Focused Border: `OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 2))`.
  * Prefix/Suffix Icons: Directionality-aware (`EdgeInsetsDirectional`).
* **`SearchBar` & `SearchView`**:
  * M3 pill container (`elevation: 0`, background `surfaceContainerHigh`, border `outlineVariant`).

---

### Group 6: Dialogs & Overlays (النوافذ والتنبيهات)

Ref: [https://m3.material.io/components/dialogs](https://m3.material.io/components/dialogs)

* **`AlertDialog`**:
  * Shape: `RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))`.
  * Title in `headlineSmall`, Body in `bodyMedium`.
  * Actions: `TextButton` for dismiss, `FilledButton` or `FilledButton.tonal` for confirmation.
* **`ModalBottomSheet`**:
  * Shape: `RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24)))`.
  * Top Drag Handle enabled: `showDragHandle: true`.
* **`Badge`**:
  * Placed over `IconButton` or `NavigationDestination` with numerical count or small dot.

---

### Group 7: Trilingual Typography Tokens (الطباعة والخطوط)

| Token M3 | Size / Weight | Arabic (`ar` - Cairo) | English (`en` - Inter) | Hindi (`hi` - Noto Sans) |
| :--- | :--- | :--- | :--- | :--- |
| `displayLarge` | 40px / w800 | الأرقام البارزة وأسعار العقارات الكبرى | Hero metrics & price figures | मुख्य आंकड़े एवं संपत्ति मूल्य |
| `headlineMedium` | 24px / w700 | عناوين الصفحات والأقسام الرئيسية | Section & Screen Titles | अनुभाग और स्क्रीन शीर्षक |
| `titleMedium` | 16px / w600 | أسماء العقارات وعناوين البطاقات | Listing Names & Card Titles | संपत्ति के नाम और कार्ड शीर्षक |
| `bodyMedium` | 14px / w400 | النصوص الوصفية وفقرات العقود | Paragraphs & Contract Body | विवरण और अनुबंध पैराग्राफ |
---

### Group 8: Switches & Selection Controls (مفاتيح التبديل والاختيار)

Refs:
- [https://m3.material.io/components/switch/specs](https://m3.material.io/components/switch/specs)
- [https://m3.material.io/components/switch/guidelines](https://m3.material.io/components/switch/guidelines)

* **`TashilSwitch` (`lib/core/design_system/switches/tashil_switch.dart`)**:
  * Track dimensions: 52dp width x 32dp height, full stadium capsule shape (`Radius.circular(16)`).
  * Unselected: `surfaceContainerHighest` fill with 2dp `outline` border and 16dp `outline` handle circle.
  * Selected: Solid `primary` fill without outline border, with 24dp `onPrimary` handle circle and animated checkmark `✓` (`Icons.check_rounded`, 16dp) in `primary` color.
  * Pressed: Handle expands dynamically to 28dp.
  * State layer: 40dp circular aura centered on handle.
  * Morphing animation: Smooth 250ms `Curves.easeInOutCubic` with handle translation, size expansion, and icon scale/fade.
  * 100% Directionality Awareness: RTL moves handle right-to-left in Arabic, LTR moves left-to-right.
  * Audio & haptic feedback on toggle.
* **`TashilSwitchListTile`**:
  * Full row tap target integrating title, subtitle, leading icon, and trailing `TashilSwitch`.

---

### Group 9: Text Fields & Inputs (حقول الإدخال والنصوص)

Refs:
- [https://m3.material.io/components/text-fields/overview](https://m3.material.io/components/text-fields/overview)
- [https://m3.material.io/components/text-fields/specs](https://m3.material.io/components/text-fields/specs)

* **`TashilTextField` (`lib/core/design_system/text_fields/tashil_text_field.dart`)**:
  * Standard Container: 56dp standard height, 12dp squircle corner radius (`BorderRadius.circular(12)`).
  * Variants:
    * `outlined`: 1dp `outlineVariant` border in resting state, 1dp `onSurfaceVariant` on hover, and 2dp `primary` border on focus. Transparent container fill (or subtle surface).
    * `filled`: `surfaceContainerHighest` fill with active 2dp primary indicator line or subtle bottom border.
  * Floating Label: Animated M3 cubic transition (`Curves.easeInOutCubic`) between resting interior position (14px) and floating header position (12px bold, `primary` color on focus).
  * Interactive State Layers:
    * Resting: Level 0 elevation, subtle outline.
    * Hovered: Outline darkens to `onSurfaceVariant` or primary tint.
    * Focused: 2dp primary outline with full state layer.
    * Error: 2dp `error` outline with error text below container.
    * Read-Only / Disabled: 38% content opacity with lock icon indicator.
  * Leading & Trailing Icons: Directional 20-24dp semantic icons (`prefixIcon`, `suffixIcon`) with RTL/LTR awareness.
* **`TashilPhoneTextField` (`lib/core/design_system/text_fields/tashil_phone_text_field.dart`)**:
  * Integrated Country Selector: Direct prefix container (`🇪🇬 +20` / `🇦🇪 +971`) separated from input text by a crisp 1dp vertical divider (`TashilVerticalDivider`).
  * Pure Standalone Field Standard: Text field remains clean and dedicated strictly to phone number input (with optional verified indicator in `suffixIcon`), while action buttons like "إرسال الرمز" are placed **side-by-side** in a Row with matching 56dp height and 12dp squircle corners (`TashilButton.tonal`).
  * Verified State: Displays matching 56dp verified container with green border, light green fill, green checkmark icon, and bold "موثق" badge text.
  * Directionality: Text input is strictly `TextDirection.ltr` for phone numbers and international digits, with full RTL container placement in Arabic.

---

## 3. Checklist for Building Any New Screen in Tashil

Before writing any new screen or widget:
1. ✅ Did you enable M3 widgets (`FilledButton`, `SegmentedButton`, `Card.outlined`, `FilterChip`)?
2. ✅ Are all strings mapped in `AppLocalizations.of(context).tr('key')` across `ar`, `en`, and `hi`?
3. ✅ Are directional insets using `EdgeInsetsDirectional` (No hardcoded `left`/`right`)?
4. ✅ Does every button have at most **ONE icon** with zero emojis in its label text?
5. ✅ Are surface colors using `colorScheme.surfaceContainer...` and `outlineVariant` rather than hardcoded colors?
