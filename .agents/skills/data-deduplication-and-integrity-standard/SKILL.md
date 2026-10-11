---
name: data-deduplication-and-integrity-standard
description: Mandatory standard for zero-tolerance duplicate data prevention, deterministic Firestore document IDs, pre-write unique constraints, in-memory stream deduplication, and automated database cleanup routines across Flutter & Firestore.
version: 1.0.0
---

# Data Deduplication & Integrity Standard (Zero-Tolerance Duplicate Policy)

This skill defines the **mandatory architectural and operational standard** for complete duplicate data prevention, unique integrity constraints, deterministic key generation, pre-save uniqueness validation, reactive in-stream deduplication, and automated database cleanup routines across the application.

Whenever creating, modifying, or reviewing any Firestore service, repository, UI form, AI extraction pipeline, catalog importer, receipt scanner, or data stream, you **MUST** strictly adhere to this standard.

---

## 1. Core Mandate & Directives

> [!IMPORTANT]
> **Zero-Tolerance Duplicate Rule:**
> No duplicate data may ever be stored in Firestore, rendered on screen, or created via imports/AI scanners.
> If a record already exists in the system (e.g. branch, retail chain, company, product, campaign, prize, or user), the system MUST:
> 1. Detect the existing record before writing.
> 2. Strictly **REJECT** the duplicate addition (do not create or duplicate documents).
> 3. Display an unambiguous, clear Arabic Warning Modal (`M3Feedback.showDuplicateWarning`) with an amber warning icon (⚠️) stating clearly that the record is already registered.
> 4. **NEVER** display a purple/green success checkmark (✔️) or state "تمت الإضافة" / "تم التحديث" when a duplicate is intercepted.
> 5. Automatically filter and clean duplicate records from both UI streams and backend databases.

---

## 2. Core Pillars of the Deduplication Engine

### Pillar 1: Deterministic Document IDs
**Never** use raw random Firestore document IDs (`_collection.doc().set(...)`) for entities with natural keys (like Retail Chains, Branches, Products, Companies, or Barcodes).
Always generate deterministic, normalized document IDs derived from the entity's natural attributes:

```dart
// Chains:
final chainDocId = cleanSlug.isNotEmpty ? cleanSlug : SlugUtils.slugify(chainName);

// Branches:
final branchDocId = '${chainId}_${cleanCode.isNotEmpty ? cleanCode.toLowerCase() : cleanName.replaceAll(RegExp(r'\s+'), '_')}';

// Products:
final productDocId = 'prod_${companySlug}_${barcode.isNotEmpty ? barcode : SlugUtils.slugify(productName)}';
```

Using deterministic IDs ensures that concurrent writes, re-submissions, or duplicate button clicks safely target the exact same document rather than creating orphaned duplicates.

---

### Pillar 2: Pre-Write Uniqueness Validation
Before writing a new entity to Firestore, check whether an existing record shares any of the unique natural identifiers:

```dart
// Example in RetailChainsService.addBranch:
final existingBranchesSnap = await _branchesCollection
    .where('retailChainId', isEqualTo: branch.retailChainId)
    .get();

for (final doc in existingBranchesSnap.docs) {
  final matchesCode = cleanCode.isNotEmpty && cleanCode != 'DEF' && existingCode == cleanCode;
  final matchesStoreId = storeId.isNotEmpty && existingStoreId == storeId;
  final matchesName = cleanName.isNotEmpty && existingName == cleanName;

  if (matchesCode || matchesStoreId || matchesName) {
    // Reject duplicate addition
    return true; // isDuplicate = true
  }
}
```

---

### Pillar 3: In-Memory Stream Deduplication (Defensive Layer)
All real-time Firestore streams and query methods (`getRetailChainsStream()`, `getAllBranchesStream()`, `getBranchesStreamForChain()`, `getCompanyProductsStream()`) MUST filter incoming document snapshots through an in-memory deduplication sanitizer before yielding results to UI state providers:

```dart
List<BranchModel> _deduplicateBranchList(List<BranchModel> rawList) {
  final Map<String, BranchModel> uniqueMap = {};

  for (final branch in rawList) {
    final primaryKey = branch.deduplicationKey; // Composite of chainId + code / storeId / name
    if (!uniqueMap.containsKey(primaryKey)) {
      uniqueMap[primaryKey] = branch;
    } else {
      // Retain the richest document (e.g. the one with Smart POS Receipt Signature)
      final existing = uniqueMap[primaryKey]!;
      if (existing.receiptSignature == null && branch.receiptSignature != null) {
        uniqueMap[primaryKey] = branch;
      }
    }
  }

  return uniqueMap.values.toList();
}
```

This ensures the user interface remains 100% clean and duplicate-free at all times, even while background database cleanups are in progress.

---

### Pillar 4: Automated Backend Cleanup Routines
Provide dedicated background and manual cleanup routines (`deduplicateAllBranchesInFirestore()`, `deduplicateCompanyProducts()`) that:
1. Scan entire collections.
2. Group documents by natural key.
3. Identify redundant documents.
4. Keep the single richest canonical record and delete all duplicate Firestore documents in batch.
5. Recalculate parent counter fields (e.g. `branchesCount`).

---

### Pillar 5: User-Facing Arabic Rejection Feedback (Never Show Success / Added)
Whenever a duplicate entry is intercepted during a form submission or AI receipt scan:
- **STRICT RULE:** You **MUST NEVER** display a success checkmark (✔️) or say "تمت" / "تم الحفظ" when a duplicate is submitted.
- The action **MUST BE REJECTED** and accompanied by an explicit Amber/Warning modal via `M3Feedback.showDuplicateWarning` so the user knows clearly that the item was already registered and was rejected:
  ```dart
  if (isDuplicate) {
    await M3Feedback.showDuplicateWarning(
      context,
      title: 'تم رفض الإضافة: مسجل مسبقاً ⚠️',
      message: 'هذا السجل / الفرع مسجل مسبقاً بالفعل في النظام (كود: $code). تم رفض العملية لمنع تكرار البيانات.',
    );
    return;
  }
  ```

---

## 3. Checklist for All Developers & Agents

- [ ] Does the entity have a deterministic Firestore Document ID based on natural keys?
- [ ] Is there a pre-write check verifying uniqueness by code, slug, barcode, or name?
- [ ] Are duplicate additions strictly REJECTED without creating or overwriting documents?
- [ ] Does the UI show an explicit Warning Modal (`M3Feedback.showDuplicateWarning`) with an amber warning icon rather than a success checkmark?
- [ ] Does the stream query pass raw snapshot documents through `_deduplicateList()`?
- [ ] Does the screen trigger background deduplication on mount (`initState`)?
- [ ] Is there a manual "تنظيف التكرارات" (Auto-Deduplicate) button for administrators?
- [ ] Are single M3 icons used on action buttons without Unicode emoji mixing?
