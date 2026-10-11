# Multi-Country Data & UI Standards

This rule governs all data models, queries, and UI components interacting with multi-country PropTech features in Tashil Real Estate.

---

## 1. Rule 1: Zero Country Leakage
- When a visitor or user selects **Egypt (`EG`)**, the UI MUST NEVER display UAE properties, UAE Dirhams (`AED`), or UAE cities.
- When a visitor or user selects **UAE (`AE`)**, the UI MUST NEVER display Egyptian properties, Egyptian Pounds (`EGP`), or Egyptian cities.

---

## 2. Rule 2: Reactive Country Switching
- Never hardcode the country code or currency in widgets.
- Always observe `CountryController.currentCountry` using `ValueListenableBuilder` or riverpod/provider when applicable.
- City dropdowns in search filters MUST dynamically reload the appropriate list of cities for the selected country and reset to `'all'` when the country changes.

---

## 3. Rule 3: Firestore Multi-Tenant Country Scoping
- All Firestore queries for listings, analytics, and agencies MUST include `country_code: 'EG' | 'AE'`.
- Composite indexes in `firestore.indexes.json` MUST include `country_code` as the leading equality filter field.
