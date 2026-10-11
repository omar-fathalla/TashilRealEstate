---
name: multi-tenant-data-isolation
description: Mandatory standards and code patterns for preventing cross-tenant data leakage, enforcing subcollection isolation, query scoping, and safe marketplace data sanitization.
---

# Multi-Tenant Data Isolation & Security Leakage Prevention Skill

This skill defines the definitive architecture, design patterns, and coding protocols to guarantee **zero cross-tenant data leakage** across the Tashil Real Estate ecosystem.

---

## 1. Architectural Tenancy Model

Tashil Real Estate operates on a strict multi-tenant boundary model consisting of four principal actor types:

```text
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│   SuperAdmin    │       │   AgencyAdmin   │       │      Owner      │
│  Global Audits  │       │  Agency Branch  │       │  Private Silo   │
└────────┬────────┘       └────────┬────────┘       └────────┬────────┘
         │                         │                         │
         ▼                         ▼                         ▼
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│ Platform-Wide   │       │ /Agencies/{id}  │       │  /Users/{uid}   │
│ Cross-Tenant    │       │ Staff & Leases  │       │   /properties   │
└─────────────────┘       └─────────────────┘       └────────┬────────┘
                                                             │ (Sanitized Fan-out)
                                                             ▼
                                                    ┌─────────────────┐
                                                    │   /Properties   │
                                                    │  (Public Mkt)   │
                                                    └─────────────────┘
```

---

## 2. Path Scoping Standards

### A. Private Owner Silo (Zero External Read Access)
- **Path:** `Users/{ownerId}/properties/{propertyId}`
- **Contents:** Complete physical unit details, private lease terms, tenant identity (`tenantName`, `tenantPhone`), active payment schedules, and rent collection records (`installments`).
- **Security Rule Requirement:**
  ```javascript
  match /Users/{userId}/properties/{propertyId} {
    allow read, write: if isSuperAdmin() || (isAuthenticated() && request.auth.uid == userId);
  }
  ```

### B. Public Marketplace Catalog (Sanitized Read-Only for Public)
- **Path:** `Properties/{propertyId}`
- **Security Rule Requirement:**
  ```javascript
  match /Properties/{propertyId} {
    allow read: if resource.data.status == 'vacant' || resource.data.is_published == true || isAuthenticated();
    // Only Admin or Cloud Function should write to public catalog
    allow write: if isSuperAdmin() || (isAuthenticated() && resource.data.owner_id == request.auth.uid);
  }
  ```

---

## 3. Data Sanitization Protocol (Stripping Private Fields)

Whenever an owner property document is synced to the public catalog, the transformation function **MUST** strictly discard private landlord and tenant information.

### Sanitization Table:
| Property Field | Owner Silo (`Users/.../properties`) | Public Catalog (`/Properties`) | Rationale |
| :--- | :--- | :--- | :--- |
| `id` | ✅ Stored | ✅ Stored | Unique property identifier |
| `titles` (AR/EN/HI) | ✅ Stored | ✅ Stored | Public listing title |
| `descriptions` (AR/EN/HI) | ✅ Stored | ✅ Stored | Public marketing text |
| `pricePerMonth` | ✅ Stored | ✅ Stored | Listed asking rental rate |
| `imageUrls` | ✅ Stored | ✅ Stored | Gallery photos |
| `bedrooms`, `bathrooms`, `areaSqM` | ✅ Stored | ✅ Stored | Unit physical specs |
| `cityCode`, `countryCode` | ✅ Stored | ✅ Stored | Geographic search keys |
| `unitNumber` | ✅ Stored | ❌ **FORBIDDEN** | Security & tenant anti-harassment |
| `tenantName` | ✅ Stored | ❌ **FORBIDDEN** | Severe GDPR / PII breach |
| `tenantPhone` | ✅ Stored | ❌ **FORBIDDEN** | Severe privacy violation |
| `installments` | ✅ Stored | ❌ **FORBIDDEN** | Landlord private financial accounts |
| `leaseStartDate` / `EndDate` | ✅ Stored | ❌ **FORBIDDEN** | Private contract specifics |

---

## 4. Query Scoping Checklist for Agents

Before writing ANY Firestore query in Flutter (`FirestoreService` or repositories) or backend scripts:

1. **Is this query targeting a shared root collection?**
   - If querying `Leases`, `Maintenance`, `Transactions`, or `Agencies`:
   - 🛑 **STOP:** You MUST include an equality filter for the actor's ID:
     ```dart
     // Correct:
     _db.collection('Leases').where('owner_id', isEqualTo: currentUserId);
     
     // STRICTLY FORBIDDEN:
     // _db.collection('Leases').get(); // Leaks everyone's leases!
     ```

2. **Is this query fetching an owner's properties?**
   - Query directly inside the owner's subcollection:
     ```dart
     _db.collection('Users').doc(ownerId).collection('properties').snapshots();
     ```

3. **Is this query retrieving public marketplace items?**
   - Ensure you only filter by published and available listings:
     ```dart
     _db.collection('Properties')
       .where('is_published', isEqualTo: true)
       .where('status', isEqualTo: 'vacant');
     ```

---

## 5. Automated Serverless Background Sync Pattern

To prevent client devices from failing halfway during dual-writes, sync is executed via Cloud Functions:

```javascript
// backend/index.js
const { onDocumentWritten } = require("firebase-functions/v2/firestore");

exports.syncOwnerPropertyToMarketplace = onDocumentWritten(
  "Users/{ownerId}/properties/{propertyId}",
  async (event) => {
    // 1. Handle Deletions
    if (!event.data.after.exists) {
      await admin.firestore().collection("Properties").doc(propertyId).delete();
      return;
    }
    
    // 2. Handle Creation & Updates
    const data = event.data.after.data();
    if (data.isPublished && data.rentalStatus === "available") {
      // 3. Strip sensitive fields
      const sanitized = sanitizeForMarketplace(data, ownerId);
      await admin.firestore().collection("Properties").doc(propertyId).set(sanitized, { merge: true });
    } else {
      // 4. Conceal from public marketplace
      await admin.firestore().collection("Properties").doc(propertyId).set({
        is_published: false,
        status: data.rentalStatus === "rented" ? "rented" : "unavailable",
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }
  }
);
```
