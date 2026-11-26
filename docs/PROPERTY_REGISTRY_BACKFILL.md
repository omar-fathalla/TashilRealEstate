# Property owner registry: production backfill (TAQ-125, TAQ-126, TAQ-128, TAQ-129, TAQ-130)

Property docs created before the registry (`PropertyOwners/{propertyId}`) have no entry. Until the
backfill registers them, leases and payments on those ids fail closed (`property_not_registered`).
This runbook is for the person with production access. Nothing here deploys or writes by itself. The
production project id is not secret and is in the repo (`.firebaserc` under `prod`, the native
Firebase configs and `frontend/lib/firebase_options.dart`), so read it from the `prod` alias of
`.firebaserc` rather than copying it into docs, scripts or tests.

**Running any step on production needs Mohamed's explicit OK.** Rehearse the same steps on the dev
project first. The Firebase CLI accepts the alias (`--project dev`), but the backfill script wants the
real project id, `tashil-aqar-dev`, and refuses the alias. No `--prod` and no `BACKFILL_PROD_OK` for dev:

```bash
cd backend
node scripts/backfill_property_owners.js --project tashil-aqar-dev                       # dry run
node scripts/backfill_property_owners.js --project tashil-aqar-dev --fix-id-fields --write  # only if idFieldIssues is not 0
node scripts/backfill_property_owners.js --project tashil-aqar-dev --overrides overrides.json --write
```

The commands below use `P` for the production project id, set in your shell only:

```bash
P=<prod project id>   # never commit it
```

## Order of the production rollout

Run the steps in this order, each one only after the previous one finished.

1. **Indexes, then wait until every index is READY.**

   ```bash
   firebase deploy --only firestore:indexes --project prod
   ```

   If the CLI offers to delete indexes that are not in `firestore.indexes.json`, answer **No**. Then
   check the state until nothing is building. Both commands must show `READY` only:

   ```bash
   # composite indexes: must print nothing (every index is READY)
   gcloud firestore indexes composite list --project="$P" --filter="state!=READY" \
     --format="table(name.basename(),queryScope,state)"
   # the collection-group field index on properties.id (TAQ-126): every row READY
   gcloud firestore indexes fields describe id --collection-group=properties --project="$P" \
     --flatten=indexConfig.indexes --format="table(indexConfig.indexes.queryScope,indexConfig.indexes.state)"
   ```

   The sync trigger's rival-holder check queries `properties.id` across all owners. If the index is
   still building, that query fails and the trigger fails closed: no private-doc create is claimed or
   synced until the index is ready. So the functions must not go out before the index is READY.

2. **Functions and rules together**, in one command:

   ```bash
   firebase deploy --only functions,firestore:rules,storage --project prod
   ```

   Rules ship with the functions, not after the backfill. With the old rules still live, a client can
   create a private doc on an id that is already registered, and write or clear `id_conflict`, so a
   gap between the two deploys is a window for taking over ids. The new claim check in the sync
   trigger runs only when a private doc is created; docs that already existed before this deploy are
   not re-checked by it. The backfill report (step 3) is what catches those.

3. **Backfill dry run.** It must show `idFieldIssues: 0` before any `--write` (TAQ-128):

   ```bash
   cd backend
   BACKFILL_PROD_OK="$P" node scripts/backfill_property_owners.js --prod --project "$P"
   ```

   If `idFieldIssues` is not 0, fix the fields, then repeat the dry run until it is:

   ```bash
   BACKFILL_PROD_OK="$P" node scripts/backfill_property_owners.js --prod --project "$P" --fix-id-fields --write
   ```

   `--write` refuses to register anything (exit 2) while `idFieldIssues` is not 0. Review the rest of
   the report ([Reading the report](#reading-the-report)) and get the owner decision for the shared ids
   ([Ids held by more than one owner](#ids-held-by-more-than-one-owner)).

4. **Backfill `--write`, with the overrides file.** Dry-run the overrides first, then write:

   ```bash
   # dry run with the overrides: check "overridden" and that nothing is refused
   BACKFILL_PROD_OK="$P" node scripts/backfill_property_owners.js --prod --project "$P" --overrides overrides.json
   # write: registers the single-landlord ids and the overridden ones
   BACKFILL_PROD_OK="$P" node scripts/backfill_property_owners.js --prod --project "$P" --overrides overrides.json --write
   ```

   Without an overrides file, `--write` registers only the single-landlord ids and leaves the shared
   ids unregistered (leases and payments on them stay refused). Run the dry run once more afterwards:
   `toRegister` should be 0 and the overridden ids appear under `registeredToHolder`, not
   `registeredToOther`.

5. **Hosting:**

   ```bash
   firebase deploy --only hosting --project prod
   ```

6. **Smoke check.** Read-only checks first; anything that writes uses the demo or test accounts only,
   and none of them is deleted.
   - Firebase console > Functions > Logs: no errors from `syncOwnerPropertyToMarketplace`,
     `reconcilePropertyModeration` or `revokePhotoTokensOnOffline` since the deploy, and no
     `FAILED_PRECONDITION` index errors.
   - Firestore: `AdminAlerts` has no new `PROPERTY_ID_CONFLICT` alert you cannot explain.
   - Signed out, the marketplace lists published listings and their photos load.
   - With a test owner account: create a listing; `PropertyOwners/{its id}` appears with
     `claimed_by: "create"`. Send a lease offer on a backfilled id of that account; it is not refused
     with `property_not_registered`.
   - A final backfill dry run shows `toRegister: 0`, `idFieldIssues: 0`, and no `registeredToOther`
     row you did not expect.

## Running the backfill

Run from `backend/`, with application default credentials for the production project. The dry run only
reads (`roles/datastore.viewer` is enough). `--write` also needs permission to create documents in
`PropertyOwners` and, with `--fix-id-fields`, to update `Users/{uid}/properties` docs (for example
`roles/datastore.user`). No Firebase Auth access is needed: roles come from the `Users/{uid}` profile
docs.

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
`idFieldIssues`, and `--write` refuses to register anything until that list is empty.
`--fix-id-fields --write` (step 3) sets `id` to the doc id on the listed docs and changes nothing
else. It registers nothing. Each update fires the sync trigger like any edit of the doc.

## Ids held by more than one owner

The production audit found 6 ids under two accounts each, the agency admin and the super admin:
`prop-ae-101`, `prop-ae-102`, `prop-eg-101`, `prop-eg-102`, `prop-eg-103` and `prop-eg-104`. The backfill
never picks an owner for them. **Someone who knows the data (the property owner, or Mohamed) must
decide, for each of the 6, which uid owns it.** Until then the id stays unregistered and leases and
payments on it are refused. Write the decision into an overrides file, a JSON object of
`propertyId: ownerUid`, kept outside the repo:

```json
{
  "prop-ae-101": "<uid of the real owner>",
  "prop-ae-102": "<uid of the real owner>"
}
```

Leave an id out to keep it unregistered. Apply the file with step 4 (dry run with `--overrides`, then
`--overrides ... --write`). After the write, the other holder's copy is an `id_conflict` candidate:
the next time that copy is written, the sync trigger flags it and it stops syncing. If both copies
are the same seed listing, the owner may want to delete the other copy once the override is in.

An override is refused when the id is not shared by two or more landlords, when the named uid is not a
holder, when it is a Tenant or Investor or its doc is flagged `id_conflict`, or when the public listing
belongs to another holder. A bad file is refused before any write. Do not commit the overrides file.

## Tests

`backend/test/registry_scripts.test.js` covers the guard, the dry run, the conflict report, the id
field fix, override validation and the batched write on the fake project id `qa-fake-prod-xyz`; `backend/test/property_owners.test.js` covers
the claim refusal and leases and payments after the backfill on the emulator. No test uses the real
production project id.
