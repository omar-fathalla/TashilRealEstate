# Multilingual UI & RTL/LTR Guidelines

This rule ensures that any code written or modified in Tashil Real Estate strictly complies with the centralized multilingual PropTech standards.

---

## 1. RTL & LTR Directionality Rules
- **Arabic (`ar`)** MUST be rendered in **Right-to-Left (RTL)**.
  - Logo and brand headers must be placed on the **Right** (Start in RTL).
  - Navigation actions, language switcher, and login buttons must be on the **Left** (End in RTL).
  - Search input icons, filter chips, and card specs must flow from **Right to Left**.
- **English (`en`) & Hindi (`hi`)** MUST be rendered in **Left-to-Right (LTR)**.
  - Logo and brand headers are on the **Left** (Start in LTR).
  - Navigation actions and login buttons are on the **Right** (End in LTR).
- **Directional Spacing:**
  - Always use `EdgeInsetsDirectional.only(start: ..., end: ...)` instead of hardcoded `left:` and `right:`.
  - Always use `CrossAxisAlignment.start` or `MainAxisAlignment.start` which automatically mirror based on `Directionality`.

---

## 2. Dynamic Typography Hierarchy
- **Arabic (`ar`):** `GoogleFonts.cairoTextTheme()`
- **English (`en`):** `GoogleFonts.interTextTheme()`
- **Hindi (`hi`):** `GoogleFonts.notoSansDevanagariTextTheme()`

---

## 3. String Centralization & Zero Language Mixing (معيار النقاء اللغوي)
- Every user-visible text string MUST be accessed via `AppLocalizations.of(context).tr('key')` or `property.getTitle(lang)`.
- **Zero Hardcoded Strings:** Never write raw text strings in widget trees.
- **Zero Language Mixing:** Never combine English words/parentheses into Arabic dictionary keys (e.g. ❌ `الوكالة (Agency)` -> ✅ `وكالة عقارية`), and never mix Arabic into English or Hindi strings.
- **Mandatory Tri-Language Parity:** Every new feature/page that adds dictionary keys MUST supply the translations for all 3 languages (`'ar'`, `'en'`, `'hi'`) simultaneously in `app_localizations.dart`.

---

## 4. UI Reactivity Protocol
- Any screen containing localized text must listen to `LocaleController.currentLocale` (e.g. via `ValueListenableBuilder<Locale>`) so that selecting a new language updates all labels, cards, and buttons instantaneously.

---

## 5. Material Design 3 Button Guidelines
- Never combine an `Icon` widget with an emoji in button labels.
- Maximum of 1 single icon per button.
