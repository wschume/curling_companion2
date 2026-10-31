# Privacy declaration: operator review before publication

The `/privacy` page and the English/German snapshots are **drafts**, not a
completed legal compliance assessment. Do not deploy this change until the
operator has reviewed both translations and confirmed the points below.

## Decisions and facts requiring operator confirmation

- Confirm that Florin Zepernick is the controller and that the address, email
  and telephone copied from Impressum are still correct.
- Supply the applicable legal bases for hosting/security, account operation,
  public community content, technical browser storage/SDK heartbeats, and
  retention of terms-acceptance evidence. Document any legitimate interests and
  the handling of objections. Acknowledging the notice supplies no legal basis.
  Add the confirmed explanations to both translations before publication.
- Verify the actual contracting Google entity, applicable data-processing
  agreement, service regions, subprocessors and international transfer
  safeguards. Do not infer EU-only processing from a Firestore region.
- Define actual retention periods/criteria for profiles, content, uploaded
  images, orphaned records, terms receipts, logs and backups; document how
  deletion requests will be fulfilled and add the confirmed periods/criteria
  to both translations. Provider-specific periods must be checked against the
  deployed services and agreements rather than invented.
- Confirm the competent supervisory authority and provide its current contact
  or complaint-page link. Confirm whether additional contact/DPO details apply.
- Assess terminal storage/heartbeat requirements separately from the notice.
  This feature provides information and acknowledgement, not an opt-in gate.
  If prior consent is required for any processing, this implementation does not
  supply it: that processing would need a separately designed control.

## Current behavior that the draft deliberately discloses

Firebase initializes before the app renders. Auth persistence is not overridden.
Signing out does not delete the account. Account deletion currently removes only
the Firebase Authentication user and is blocked while owned tournaments or
marketplace listings remain. Profile documents, terms receipts, player/team
searches and stored image files are not all automatically removed. These are
facts to disclose and review, not deletion guarantees to add to the policy.

The acknowledgement stores only a version in `privacy_notice_version` via
shared_preferences (web local storage). It is per browser/origin, not per user;
it is not uploaded to Firestore. Switching locale/accounts or signing out does
not reset it. Cleared storage or a new version shows the notice again. Failed
reads show the notice; failed writes still dismiss it for the current session.
A browser restart/reload may show it again. No analytics SDK is included.

## Technical sources checked on 2026-10-31

- Firebase service processing and privacy information:
  https://firebase.google.com/support/privacy
- Firebase browser authentication persistence:
  https://firebase.google.com/docs/auth/web/auth-state-persistence
- Heartbeat collection and payload construction (SDK/platform information and
  UTC dates; not a personal account ID):
  https://github.com/firebase/firebase-js-sdk/blob/main/packages/app/src/heartbeatService.ts
- Heartbeat IndexedDB key uses Firebase app name and app ID:
  https://github.com/firebase/firebase-js-sdk/blob/main/packages/app/src/indexeddb.ts
- Authentication request headers can include app ID and encoded heartbeat data:
  https://github.com/firebase/firebase-js-sdk/blob/main/packages/auth/src/core/auth/auth_impl.ts

The installed firebase_core_web implementation selects Firebase JS SDK 12.15.0
unless overridden. Its actual release files were also inspected:
https://www.gstatic.com/firebasejs/12.15.0/firebase-app.js and
https://www.gstatic.com/firebasejs/12.15.0/firebase-auth.js. They confirm the
heartbeat IndexedDB store and authentication heartbeat/app-ID headers. This is
source verification, not a captured production network trace.
Before publication, verify actual browser traffic/storage with the release build
and record any configuration-dependent differences. The draft therefore uses
“can” and does not claim that app ID is itself part of the heartbeat payload.

## Review and release procedure

1. Resolve the facts and legal decisions above with the operator, and amend both
   ARB translations and `docs/privacy/2026-10-31.*.md` snapshots together.
2. Remove the visible draft designation only after approval; retain review
   evidence in this document. Bump `currentPrivacyVersion` for material changes.
3. Run Flutter analysis, all tests and a release web build. Verify keyboard and
   screen-reader operation, DE/EN text, and browser storage/network behavior.
4. Publish the reviewed app through the normal Firebase Hosting deployment.
   No Firestore migration, rules change or Cloud Function deployment is needed.
