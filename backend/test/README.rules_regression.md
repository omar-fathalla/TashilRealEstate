# Rules regression suites for handoff (TAQ-58)
Files (in backend/test/; they follow backend/test/rules.test.js conventions):
- backend/test/rules_regression_adv.test.js    (90 tests; TAQ-8/9/10/11 + probes)
- backend/test/rules_regression_retest.test.js (37 tests; TAQ-46..50 + probes)
Changes vs. the QA originals (/workspace/taqar-021227b/harness/rules.{adv,retest}.test.js):
- package requires instead of absolute node_modules paths; rules read from ../../firestore.rules
- projectId = process.env.GCLOUD_PROJECT || "demo-tashil-test"; emulator host from FIRESTORE_EMULATOR_HOST (set by `firebase emulators:exec`)
- 8 owner/agency direct /Properties write assertions (in 6 tests) flipped to assertFails (TAQ-51)
- retest fixture Properties/pub made a valid listing (titles + pricePerMonth) so the SuperAdmin moderation assertion still expects success
No secrets, no prod project ids; all data fake. Verified at 2d0a140: 90/90 and 37/37.

Run: `cd backend && npm run test:core` (the `test:unit` glob `test/*.test.js` picks both suites up under the Firestore emulator with the demo-tashil-test project).
