/// Build-time configuration for values that must never be hardcoded into
/// the app (final-pass production-hardening requirement): the contact
/// email and the external URLs referenced by the Privacy Policy / Terms &
/// Conditions screens. All three intentionally default to a documentation
/// placeholder rather than a real production domain -- set them via
/// `--dart-define` when a real domain/mailbox exists:
///
/// ```
/// flutter build web \
///   --dart-define=CONTACT_EMAIL=privacy@yourdomain.com \
///   --dart-define=PRIVACY_POLICY_URL=https://yourdomain.com/privacy \
///   --dart-define=TERMS_URL=https://yourdomain.com/terms \
///   --dart-define=DATA_DELETION_URL=https://yourdomain.com/data-deletion
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
    defaultValue: 'support@example.com',
  );

  static const String privacyPolicyUrl = String.fromEnvironment('PRIVACY_POLICY_URL');
  static const String termsUrl = String.fromEnvironment('TERMS_URL');
  static const String dataDeletionUrl = String.fromEnvironment('DATA_DELETION_URL');

  static bool get hasPrivacyPolicyUrl => privacyPolicyUrl.isNotEmpty;
  static bool get hasTermsUrl => termsUrl.isNotEmpty;
  static bool get hasDataDeletionUrl => dataDeletionUrl.isNotEmpty;
}
