---
name: firestore-performance-and-caching
description: Mandatory standards for Firestore caching, composite indexing, keyword search tokenization, cursor pagination, image optimization, and localized currency formatting.
---

# Firestore Performance, Caching & Data Optimization Skill

This skill defines the technical standards for maximizing data retrieval speed, minimizing Cloud Firestore read costs (up to 80% cost reduction), and eliminating memory leaks across the Tashil Real Estate PropTech ecosystem.

---

## 1. Firestore Composite Indexes Standard
Every multi-field query in Tashil Real Estate MUST be registered in `firestore.indexes.json`:
- Country-scoped property queries: `country_code` (ASC) + `status` (ASC) + `city_code` (ASC) + `price_monthly` (ASC/DESC).
- Featured properties: `country_code` (ASC) + `is_featured` (ASC) + `created_at` (DESC).
- Leases: `country_code` (ASC) + `tenant_id`/`owner_id`/`agency_id` (ASC) + `status` (ASC).

---

## 2. In-Memory State & Offline Caching
- **Firestore Persistence:** Enabled via `Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED)`.
- **Repository-Level Memory Caching:** `PropertyRepository` maintains in-memory country-scoped maps (`_countryCache['EG']` and `_countryCache['AE']`) to serve repeat searches in `<1ms` without making redundant network calls.

---

## 3. Search Keyword Tokenization (`SearchTokenizer`)
- Firestore does not support native substring search in Arabic.
- Whenever saving or searching property records, use `SearchTokenizer.generateKeywords(...)` and `SearchTokenizer.matches(target, query)`.
- Handles Arabic normalization:
  - `أ`, `إ`, `آ`, `ٱ` -> `ا`
  - `ة` -> `ه`
  - `ى` -> `ي`
  - Strips all Harakat/Tashkeel (`ً`, `ٌ`, `ٍ`, `َ`, `ُ`, `ِ`, `ّ`, `ْ`).

---

## 4. Cursor-Based Pagination
- Do not query entire collections into memory.
- Use `pageSize = 6` (or `12`) with `startAfterDocument(lastDoc)` for responsive, progressive scrolling.

---

## 5. Image & Memory Optimization (`ImageUtils`)
- Never use unconstrained `Image.network` in cards.
- Always use `ImageUtils.cachedImage(imageUrl, cacheWidth: 600, cacheHeight: 375)` to prevent memory bloat and browser tabs crashing.

---

## 6. Localized Currency Formatting (`CurrencyFormatter`)
- Format all prices using `CurrencyFormatter.formatAmount(...)` and `CurrencyFormatter.formatPriceWithCurrency(...)` with proper thousand separators:
  - Egypt: `٢٨,٠٠٠ ج.م` / `28,000 EGP`.
  - UAE: `١٤,٥٠٠ د.إ` / `14,500 AED`.
