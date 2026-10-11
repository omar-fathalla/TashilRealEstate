# Multi-Tenant Security & Zero-Leakage Data Standards

This rule is mandatory for all AI agents performing frontend or backend operations in Tashil Real Estate.

---

## 1. Zero-Leakage Principle (معيار انعدام تسريب البيانات التام)
Under NO circumstances may any query, service, UI screen, or Cloud Function expose or return records belonging to another owner, tenant, or agency:
- A property owner must NEVER see another owner's properties, tenants, contracts, or financial numbers.
- An agency must NEVER view properties or transactions belonging to a competitor agency.
- Public marketplace visitors must NEVER receive internal landlord data or private tenant identities.

---

## 2. Dedicated Scoped Subcollection Hierarchy (شجرة البيانات المعزولة)
Whenever reading or writing private landlord/owner assets, agents MUST use the dedicated nested tree:
```text
Users/{ownerId}/properties/{propertyId}
Users/{ownerId}/properties/{propertyId}/installments/{installmentId}
```
- **Forbidden:** Storing private rental contracts, tenant contact numbers, or internal payment logs in the public `/Properties` root collection.
- **Allowed:** Storing sanitized, marketing-ready representations in `/Properties` strictly for public discovery.

---

## 3. Mandatory Identity Scoping on Shared Collections (التقييد الإجباري للهوية)
Whenever querying any shared root collection (`Leases`, `Transactions`, `Maintenance`, `Agencies`), the query MUST contain explicit equality filters matching the authenticated actor's credentials:
- For Owners: `.where('owner_id', '==', currentUser.uid)`
- For Tenants: `.where('tenant_id', '==', currentUser.uid)`
- For Agencies: `.where('agency_id', '==', currentAgencyId)`
- **Querying without identity filters is strictly prohibited** outside of the SuperAdmin role.

---

## 4. Public Marketplace Sanitization (تطهير البيانات التسويقية)
When synchronizing a property from an owner's tree to the public marketplace collection (`/Properties`), the following fields MUST be strictly stripped and omitted:
- ❌ `tenantName`
- ❌ `tenantPhone`
- ❌ `leaseStartDate` & `leaseEndDate`
- ❌ `installments` (monthly payment history)
- ❌ `internalNotes` / landlord private notes
- ❌ `unitNumber` (exact apartment/flat number should not be publicly exposed without authorized viewing)

Only public marketing metadata (`titles`, `descriptions`, `pricePerMonth`, `currencyCode`, `cityCode`, `bedrooms`, `bathrooms`, `areaSqM`, `imageUrls`, `amenitiesMap`) may be present in `/Properties`.

---

## 5. Parity with Firestore Security Rules (تطابق قواعد الأمان)
- Every new subcollection or document field created in Flutter or Node.js MUST have an explicit rule in `firestore.rules`.
- Never rely on client-side filtering alone (`.where(...)`) without enforcing the exact same filter inside `firestore.rules`:
  ```javascript
  match /Users/{userId}/properties/{propertyId} {
    allow read, write: if isSuperAdmin() || (isAuthenticated() && request.auth.uid == userId);
  }
  ```

---

## 6. Serverless Trust Boundary (فصل حدود الثقة عبر Cloud Functions)
- Synchronization between the owner's private tree and the public marketplace should be handled or governed by background Cloud Functions using the `firebase-admin` SDK.
- The client app only writes to its authorized private path; the background worker handles sanitization and fan-out to the public catalog.
