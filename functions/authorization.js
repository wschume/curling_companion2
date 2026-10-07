function requireVerifiedEmail(request, HttpsError) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in to upload images.");
  }
  if (request.auth.token.email_verified !== true) {
    throw new HttpsError("permission-denied", "Verify your email to upload images.");
  }
}

const currentTermsVersion = '2026-10-07';
async function requireTermsAcceptance(request, db, HttpsError) {
  requireVerifiedEmail(request, HttpsError);
  const record = await db.doc(`users/${request.auth.uid}/termsAcceptances/${currentTermsVersion}`).get();
  const data = record.data();
  if (!record.exists || data?.accepted !== true || data?.version !== currentTermsVersion || !data?.acceptedAt) {
    throw new HttpsError('permission-denied', 'Accept the terms before uploading images.');
  }
}
module.exports = {requireVerifiedEmail, requireTermsAcceptance, currentTermsVersion};
