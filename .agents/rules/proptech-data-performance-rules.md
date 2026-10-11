# PropTech Data, Performance & Caching Rules

This rule is mandatory for all agents performing frontend or backend operations in Tashil Real Estate.

---

## 1. Rule 1: Mandatory Indexes
- Any Firestore query containing more than one equality or inequality/sort filter MUST have a corresponding composite index in `firestore.indexes.json`.

---

## 2. Rule 2: In-Memory Caching & Offline Persistence
- Every repository must utilize in-memory caching to avoid redundant server reads.
- Always check cache before triggering remote network requests.

---

## 3. Rule 3: Memory-Constrained Image Loading
- Raw `Image.network` without decode buffer limits is forbidden in listing cards.
- Always wrap network images using `ImageUtils.cachedImage` with `cacheWidth` and `cacheHeight` specified.

---

## 4. Rule 4: Arabic Text Normalization
- All text searches in Arabic must be sanitized through `SearchTokenizer.normalizeArabic` to ensure matches regardless of Alef, Ta Marbuta, or Tashkeel differences.

---

## 5. Rule 5: Standardized Currency & Number Formatting
- Raw string concatenation like `'$price ج.م'` is forbidden.
- Always use `CurrencyFormatter.formatAmount(price, langCode: lang)` to guarantee localized thousand separators.
