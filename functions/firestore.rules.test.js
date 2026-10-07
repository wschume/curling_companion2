const {test, before, after} = require('node:test');
const {readFileSync} = require('node:fs');
const {join} = require('node:path');
const {currentTermsVersion} = require('./authorization');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, setDoc, updateDoc, deleteDoc, getDoc, Timestamp, serverTimestamp} = require('firebase/firestore');
let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-curling-verification',
    firestore: {host: '127.0.0.1', port: 8080, rules: readFileSync(join(__dirname, '../firestore.rules'), 'utf8')},
  });
});
after(async () => { if (env) await env.cleanup(); });
const collections = {
  marketplaceListings: 'ownerId',
  tournaments: 'organizerId',
  playerAvailability: 'userId',
  teamPlayerSearches: 'ownerId',
  playerTeamSearches: 'ownerId',
};
for (const [collection, ownerField] of Object.entries(collections)) {
  test(`${collection}: verified writes, public reads, owner deletion`, async () => {
    const owner = `owner-${collection}`;
    const data = {[ownerField]: owner, title: 'Original', endDate: Timestamp.fromDate(new Date('2099-01-01'))};
    const verified = env.authenticatedContext(owner, {email_verified: true}).firestore();
    const unverified = env.authenticatedContext(owner, {email_verified: false}).firestore();
    const anonymous = env.unauthenticatedContext().firestore();
    const stranger = env.authenticatedContext('stranger', {email_verified: true}).firestore();
    const path = `${collection}/test`;
    await assertFails(setDoc(doc(anonymous, path), data));
    await assertFails(setDoc(doc(unverified, path), data));
    await assertFails(setDoc(doc(stranger, path), data));
    await assertFails(setDoc(doc(verified, path), data));
    const acceptancePath = `users/${owner}/termsAcceptances/${currentTermsVersion}`;
    const acceptance = {version: currentTermsVersion, accepted: true, acceptedAt: serverTimestamp(), language: 'en'};
    await assertSucceeds(setDoc(doc(unverified, acceptancePath), acceptance));
    await assertSucceeds(setDoc(doc(verified, path), data));
    await assertSucceeds(getDoc(doc(anonymous, path)));
    await assertFails(updateDoc(doc(anonymous, path), {title: 'Changed'}));
    await assertFails(updateDoc(doc(unverified, path), {title: 'Changed'}));
    await assertFails(updateDoc(doc(stranger, path), {title: 'Changed'}));
    await assertFails(updateDoc(doc(verified, path), {[ownerField]: 'stranger'}));
    await assertSucceeds(updateDoc(doc(verified, path), {title: 'Changed'}));
    await assertFails(deleteDoc(doc(stranger, path)));
    await assertFails(deleteDoc(doc(anonymous, path)));
    await assertSucceeds(deleteDoc(doc(unverified, path)));
  });
}
test('unverified users can manage only their own profile', async () => {
  const db = env.authenticatedContext('owner', {email_verified: false}).firestore();
  await assertSucceeds(setDoc(doc(db, 'users/owner'), {language: 'de'}));
  await assertSucceeds(getDoc(doc(db, 'users/owner')));
  await assertFails(setDoc(doc(db, 'users/stranger'), {language: 'de'}));
});

test('terms acceptance requires own UID, current version and server timestamp; records are immutable', async () => {
  const owner = env.authenticatedContext('terms-user', {email_verified: false}).firestore();
  const other = env.authenticatedContext('other', {email_verified: true}).firestore();
  const anonymous = env.unauthenticatedContext().firestore();
  const path = `users/terms-user/termsAcceptances/${currentTermsVersion}`;
  const data = {version: currentTermsVersion, accepted: true, acceptedAt: serverTimestamp(), language: 'de'};
  await assertFails(setDoc(doc(anonymous, path), data));
  await assertFails(setDoc(doc(other, path), data));
  await assertFails(setDoc(doc(owner, path), {...data, accepted: false}));
  await assertFails(setDoc(doc(owner, path), {...data, version: 'old'}));
  await assertFails(setDoc(doc(owner, path), {...data, acceptedAt: Timestamp.fromDate(new Date('2000-01-01'))}));
  await assertFails(setDoc(doc(owner, path), {...data, language: 'invalid'}));
  await assertFails(setDoc(doc(owner, path), {...data, extra: true}));
  await assertFails(setDoc(doc(owner, 'users/terms-user/termsAcceptances/old'), {...data, version: 'old'}));
  await assertSucceeds(setDoc(doc(owner, path), data));
  const saved = await assertSucceeds(getDoc(doc(owner, path)));
  if (!saved.data().acceptedAt.toMillis()) throw new Error('Missing server timestamp');
  await assertFails(getDoc(doc(other, path)));
  await assertFails(updateDoc(doc(owner, path), {accepted: false}));
  await assertFails(deleteDoc(doc(owner, path)));
});
test('an editable profile acceptance flag cannot grant content access', async () => {
  const db = env.authenticatedContext('profile-bypass', {email_verified: true}).firestore();
  await assertSucceeds(setDoc(doc(db, 'users/profile-bypass'), {acceptedTerms: true, termsVersion: currentTermsVersion}));
  await assertFails(setDoc(doc(db, 'marketplaceListings/profile-bypass'), {ownerId: 'profile-bypass'}));
});

test('tournament deletion accepts app ISO dates and enforces ownership', async () => {
  const owner = env.authenticatedContext('iso-owner', {email_verified: false}).firestore();
  const other = env.authenticatedContext('iso-other', {email_verified: true}).firestore();
  const anonymous = env.unauthenticatedContext().firestore();
  const path = 'tournaments/iso-date-event';
  await env.withSecurityRulesDisabled(async context => {
    await setDoc(doc(context.firestore(), path), {
      organizerId: 'iso-owner',
      startDate: '2099-01-01T00:00:00.000',
      endDate: '2099-01-03T00:00:00.000',
    });
  });
  await assertFails(deleteDoc(doc(anonymous, path)));
  await assertFails(deleteDoc(doc(other, path)));
  await assertSucceeds(deleteDoc(doc(owner, path)));
});
