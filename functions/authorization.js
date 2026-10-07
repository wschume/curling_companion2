function requireVerifiedEmail(request, HttpsError) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in to upload images.");
  }
  if (request.auth.token.email_verified !== true) {
    throw new HttpsError("permission-denied", "Verify your email to upload images.");
  }
}

module.exports = {requireVerifiedEmail};
