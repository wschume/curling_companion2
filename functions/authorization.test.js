const {test} = require('node:test');
const assert = require('node:assert/strict');
const {requireVerifiedEmail, requireTermsAcceptance, currentTermsVersion} = require('./authorization');
class HttpsError extends Error {
  constructor(code, message) { super(message); this.code = code; }
}
test('image upload denies signed-out users', () => {
  assert.throws(() => requireVerifiedEmail({}, HttpsError), {code: 'unauthenticated'});
});
test('image upload denies unverified or missing verification claims', () => {
  for (const token of [{}, {email_verified: false}, {email_verified: 'true'}]) {
    assert.throws(() => requireVerifiedEmail({auth: {uid: 'owner', token}}, HttpsError), {code: 'permission-denied'});
  }
});
test('image upload accepts a verified Firebase token', () => {
  assert.doesNotThrow(() => requireVerifiedEmail({auth: {uid: 'owner', token: {email_verified: true}}}, HttpsError));
});

const request = {auth: {uid: 'owner', token: {email_verified: true}}};
function fakeDb(data) {
  return {doc(path) {
    assert.equal(path, `users/owner/termsAcceptances/${currentTermsVersion}`);
    return {async get() { return {exists: !!data, data: () => data}; }};
  }};
}
test('image upload requires recorded acceptance of the current terms', async () => {
  for (const data of [null, {accepted: false}, {accepted: true, version: 'old', acceptedAt: {}}, {accepted: true, version: currentTermsVersion}]) {
    await assert.rejects(requireTermsAcceptance(request, fakeDb(data), HttpsError), {code: 'permission-denied'});
  }
  await assert.doesNotReject(requireTermsAcceptance(request, fakeDb({accepted: true, version: currentTermsVersion, acceptedAt: {}}), HttpsError));
});
test('upload still requires email verification when terms have been accepted', async () => {
  await assert.rejects(requireTermsAcceptance({auth: {uid: 'owner', token: {email_verified: false}}}, fakeDb({accepted: true, version: currentTermsVersion, acceptedAt: {}}), HttpsError), {code: 'permission-denied'});
});
test('client, rules and archived terms agree on the current version', () => {
  const {readFileSync} = require('node:fs');
  const {join} = require('node:path');
  const root = join(__dirname, '..');
  assert.ok(readFileSync(join(root, 'lib/terms.dart'), 'utf8').includes(`'${currentTermsVersion}'`));
  assert.ok(readFileSync(join(root, 'firestore.rules'), 'utf8').includes(`termsAcceptances/${currentTermsVersion}`));
  for (const language of ['de', 'en']) {
    const strings = JSON.parse(readFileSync(join(root, `lib/l10n/app_${language}.arb`), 'utf8'));
    const expected = '# ' + strings.usageTermsTitle + '\n\n' + strings.usageTermsIntro + '\n\n' + strings.usageTermsProhibitions.split('\n').map(text => '- ' + text).join('\n') + '\n\n' + strings.usageTermsAcceptance + '\n\n' + strings.usageTermsLiability + '\n';
    assert.equal(readFileSync(join(root, `docs/terms/${currentTermsVersion}.${language}.md`), 'utf8'), expected);
  }
});
