const {test, before, after} = require('node:test');
const {readFileSync} = require('node:fs');
const {join} = require('node:path');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, setDoc, updateDoc, deleteDoc, getDoc, Timestamp} = require('firebase/firestore');
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
    const owner = 'owner';
    const data = {[ownerField]: owner, title: 'Original', endDate: Timestamp.fromDate(new Date('2099-01-01'))};
    const verified = env.authenticatedContext(owner, {email_verified: true}).firestore();
    const unverified = env.authenticatedContext(owner, {email_verified: false}).firestore();
    const anonymous = env.unauthenticatedContext().firestore();
    const stranger = env.authenticatedContext('stranger', {email_verified: true}).firestore();
    const path = `${collection}/test`;
    await assertFails(setDoc(doc(anonymous, path), data));
    await assertFails(setDoc(doc(unverified, path), data));
    await assertFails(setDoc(doc(stranger, path), data));
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
