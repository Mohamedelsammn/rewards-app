/// Build-time configuration for values that must never be hardcoded into
/// the app (final-pass production-hardening requirement): the contact
/// email/phone and the external URLs referenced by the Privacy Policy /
/// Terms & Conditions screens.
///
/// [contactEmail] and [adminContactPhone] are the real production values.
/// [privacyPolicyUrl] / [termsUrl] / [dataDeletionUrl] intentionally have NO
/// default (empty string) -- the hosted legal pages (see /legal/ at the
/// repo root, GitHub Pages-ready) don't have a final URL assigned yet.
/// Supply them at build time once that URL exists:
///
/// ```
/// flutter build appbundle --release \
///   --dart-define=PRIVACY_POLICY_URL=https://<user>.github.io/<repo>/privacy-policy.html \
///   --dart-define=TERMS_URL=https://<user>.github.io/<repo>/terms.html
/// ```
///
/// The in-app Privacy Policy / Terms screens hold the full real policy
/// text regardless of these being set -- they only gate the "open the
/// hosted copy" / "request deletion online" links, which are hidden
/// (falling back to the contact email) while unset.
class AppConfig {
  const AppConfig._();

  static const String contactEmail = String.fromEnvironment(
    'CONTACT_EMAIL',
    defaultValue: 'mohamed.elsamman.dev@gmail.com',
  );

  static const String privacyPolicyUrl = String.fromEnvironment('PRIVACY_POLICY_URL');
  static const String termsUrl = String.fromEnvironment('TERMS_URL');
  static const String dataDeletionUrl = String.fromEnvironment('DATA_DELETION_URL');

  static bool get hasPrivacyPolicyUrl => privacyPolicyUrl.isNotEmpty;
  static bool get hasTermsUrl => termsUrl.isNotEmpty;
  static bool get hasDataDeletionUrl => dataDeletionUrl.isNotEmpty;

  /// The single source of truth for the admin-contact WhatsApp number shown
  /// on Admin Sign Up -- both the on-screen label and the `wa.me` deep link
  /// built from it (which strips everything but digits) read this same
  /// constant, so the number is never duplicated. Override at build time:
  ///
  /// ```
  /// flutter build --dart-define=ADMIN_CONTACT_PHONE="+20 120 343 3339"
  /// ```
  static const String adminContactPhone = String.fromEnvironment(
    'ADMIN_CONTACT_PHONE',
    defaultValue: '+20 120 343 3339',
  );
}
