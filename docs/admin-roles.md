# Admin content management

Deploy Firestore rules before deploying the updated web application. Admins can edit and delete tournaments, marketplace listings and player/team search entries. Edits require verified email and current terms acceptance. Ownership remains unchanged. Account administration and cross-owner image management are not included.

To grant access:

1. Find the account in Firebase Console → Authentication → Users and copy its UID.
2. In Firestore Database, create `adminRoles/{uid}` with the string field `role` set to `admin`.
3. Check that the signed-in account gains edit/delete controls on another user's entry. Other users must retain owner-only controls.

To revoke access, delete that role document or change its role value. The app listens for changes; Firestore rules independently enforce the current role on each operation. Client applications cannot write role documents. Existing `users/{uid}.role` fields do not grant privileges, and no email address receives automatic access.

Marketplace record deletion does not remove stored images. Admins cannot upload or remove images belonging to another user. Use the Firebase Console for storage cleanup when needed.
