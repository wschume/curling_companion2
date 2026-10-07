const {test} = require('node:test');
const assert = require('node:assert/strict');
const {requireVerifiedEmail} = require('./authorization');
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
