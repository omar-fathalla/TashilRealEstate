# Property owner registry: production backfill (TAQ-125, TAQ-126)

Property docs created before the registry (`PropertyOwners/{propertyId}`) have no entry. Until the
backfill registers them, leases and payments on those ids fail closed (`property_not_registered`).
This runbook is for the person with production access. Nothing here deploys or writes by itself, and
nothing in the repo holds the production project id: use the `prod` alias of `.firebaserc`.

## Order of the production rollout

Run the steps in this order and do not leave a gap between 2 and 3.

1. Deploy Firestore indexes: `firebase deploy --only firestore:indexes --project prod`. The new
   collection-group index on `properties.id` must be built before the functions use it (TAQ-126).
2. Deploy functions: `firebase deploy --only functions --project prod`.
3. Run the backfill right away: dry run, review the report, then `--write` (below). Until it ends,
   the sync trigger refuses to claim an id that another owner already holds privately, so the window
   cannot be used to take over a legacy id; it only leaves old ids unregistered.
4. Deploy Firestore and Storage rules: `firebase deploy --only firestore:rules,storage --project prod`.
5. Deploy hosting: `firebase deploy --only hosting --project prod`.

## Running the backfill

Run from `backend/`, with application default credentials for the production project. The dry run only
reads (`roles/datastore.viewer` is enough). `--write` also needs permission to create documents in
`PropertyOwners` (for example `roles/datastore.user`). No Firebase Auth access is needed: roles come
from the `Users/{uid}` profile docs.

```bash
# 1. dry run: prints the target project first, then a summary and the full JSON report
BACKFILL_PROD_OK=<prod project id> node scripts/backfill_property_owners.js --prod --project <prod project id>

# 2. write, only after the report was reviewed
BACKFILL_PROD_OK=<prod project id> node scripts/backfill_property_owners.js --prod --project <prod project id> --write
```

Guard: the production project needs `--prod`, `BACKFILL_PROD_OK` equal to the project id, and `--write`
to write. Without them the script exits with code 2 before reading anything. `--prod` is refused on
any other project. Dev and demo projects (`tashil-aqar-dev`, `demo-*`) run without `--prod`.

The script is idempotent (it creates entries with `create`, never overwrites one), never deletes,
and writes in batches of `--batch-size` (default 100, at most 400). Every batch prints its cursor. If a
run fails, resume with `--cursor <last printed id>`; ids already registered are skipped anyway.

## Reading the report

| Field | Meaning | Action |
| --- | --- | --- |
| `toRegister` | One landlord holds the id and no public listing names someone else | Registered by `--write` |
| `multipleOwners` | The id exists under more than one landlord | Never auto-assigned; needs an override |
| `idConflictCandidates` | Private docs that would be flagged `id_conflict` (multiple owners, or registered to another owner) | Review by hand |
| `registeredToOther` | Already registered to a uid that is not a landlord holder of the id | REVIEW; never touched |
| `registeredToHolder` | Registered to one of several landlord holders, as an override leaves it (`claimed_by` shows how) | Expected after an override; the other holders are `id_conflict` candidates |
| `publicOwnerMismatch` | The public listing names another owner than the holder | Review; never registered |
| `nonLandlordOwner` | No landlord holds the id; only a Tenant or Investor does | Never registered |
| `flaggedHolders` | Docs already flagged `id_conflict` | Never count as holders, so a squatter's flagged copy does not block the owner |
| `nonLandlordHolders` | Tenant or Investor docs beside a landlord's doc | Never count as holders |
| `holdersWithoutProfile` | Holders with no `Users/{uid}` profile | Counted as landlords (claims-only admins have no profile role); check who they are |
| `overridden` | Ids resolved by the overrides file | Registered with `claimed_by: backfill-override` |
| `idFieldIssues` | Private docs whose `id` field is missing or differs from the doc id | Must be 0 before `--write`; fix with `--fix-id-fields --write` |

The report holds counts and ids only.

## Private docs without a matching `id` field (TAQ-128)

The sync trigger finds the other holders of an id through the `id` field of their private docs. A
legacy doc with no `id` field, or one that differs from the doc id, is invisible to that check, so
another owner could claim its id while it is unregistered. The dry run lists such docs under
`idFieldIssues`, and `--write` refuses to register anything until that list is empty. To fix them:

```bash
BACKFILL_PROD_OK=<prod project id> node scripts/backfill_property_owners.js --prod --project <prod project id> --fix-id-fields --write
```

This sets `id` to the doc id on the listed docs and changes nothing else. It registers nothing.
Each update fires the sync trigger like any edit of the doc. Run the dry run again afterwards; it must
show `idFieldIssues: 0`.

## Ids held by more than one owner

Seed data such as `prop-ae-101`, `prop-ae-102` and `prop-eg-101` to `prop-eg-104` can exist under two
accounts (for example an agency admin and a super admin). The backfill leaves them unregistered, so
leases and payments on them stay refused until someone decides. To resolve one, pass an explicit
overrides file naming the holder, a JSON object of `propertyId: ownerUid`:

```json
{ "prop-ae-101": "<uid of the real owner>" }
```

```bash
BACKFILL_PROD_OK=<prod project id> node scripts/backfill_property_owners.js --prod --project <prod project id> --overrides overrides.json
```

An override is refused when the id is not shared by two or more landlords, when the named uid is not a
holder, when it is a Tenant or Investor or its doc is flagged `id_conflict`, or when the public listing
belongs to another holder. A bad file is refused before any write. Do not commit the
overrides file.

## Tests

`backend/test/registry_scripts.test.js` covers the guard, the dry run, the conflict report and the
batched write on the fake project id `qa-fake-prod-xyz`; `backend/test/property_owners.test.js` covers
the claim refusal and leases and payments after the backfill on the emulator. No test uses the real
production project id.
