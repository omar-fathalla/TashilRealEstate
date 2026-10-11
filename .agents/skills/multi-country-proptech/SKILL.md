---
name: multi-country-proptech
description: Architecture standards, Firestore schema hierarchy, and UI guidelines for multi-country PropTech operations across Egypt (EG) and the UAE (AE).
---

# Multi-Country PropTech Architecture Skill

This skill defines the technical standards, Firestore data schemas, localization taxonomies, and UI patterns for supporting multiple real estate markets — currently **Egypt (EG)** and **United Arab Emirates (UAE)** — across Tashil Real Estate.

---

## 1. Core Supported Countries & Markets

| Metric | Egypt (`EG` 🇪🇬) | UAE (`AE` 🇦🇪) |
| :--- | :--- | :--- |
| **ISO Code** | `EG` | `AE` |
| **Currency** | `EGP` (`ج.م`) | `AED` (`د.إ`) |
| **Primary Cities** | Cairo (New Cairo, Maadi, Zayed, October), Alexandria, North Coast | Dubai, Abu Dhabi, Sharjah, Ajman, Ras Al Khaimah |
| **Key Regulatory Authorities** | Commercial Register / Real Estate Registry | Real Estate Regulatory Authority (**RERA**), **Ejari** |
| **Rent Payment Frequency** | Monthly / Quarterly / Annual Cash or Bank Transfer | 1, 2, 4, or 6 Cheques / Direct Debit |
| **Typical Monthly Rent Ranges** | 5,000 – 150,000+ EGP | 3,000 – 60,000+ AED |

---

## 2. Multi-Country Hierarchy & Data Scoping (Firestore)

### Document Field Convention:
1. **Mandatory `country_code` field:**
   Every entity in Firestore (`Properties`, `Agencies`, `Owners`, `Tenants`, `Leases`, `MaintenanceRequests`) MUST contain a string field `country_code: 'EG' | 'AE'`.
2. **Indexed Firestore Queries:**
   All public listing queries must filter by country:
   ```dart
   FirebaseFirestore.instance
       .collection('Properties')
       .where('country_code', isEqualTo: activeCountryCode)
       .where('status', isEqualTo: 'vacant')
   ```

---

## 3. UI State Management (`CountryController`)
- Use `CountryController.currentCountry` (`ValueNotifier<String>`) for reactive country switching across Flutter widgets.
- Use `CountrySwitcher` M3 dropdown component in headers.
- Always use `CountryController.getCurrency(lang)` rather than hardcoding currency strings.

---

## 4. Trilingual City & Taxonomy Consistency
All city and property type keys must exist in `AppLocalizations`:
- Egyptian Cities: `city_new_cairo`, `city_sheikh_zayed`, `city_alexandria`, `city_maadi`, `city_north_coast`, `city_october`.
- UAE Cities: `city_dubai`, `city_abu_dhabi`, `city_sharjah`, `city_ajman`, `city_ras_al_khaimah`.
- Currencies: `currency_eg` (`ج.م` / `EGP`), `currency_ae` (`د.إ` / `AED`).
