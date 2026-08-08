/// Client-side phone handling that mirrors the server's `fn_normalize_phone`
/// exactly (strip everything but digits, prefix '+', require 7-15 digits),
/// so client-side validation never diverges from the server's authoritative
/// normalization (implementation-plan.md §17 / tasks.md T09-02).
class PhoneUtil {
  const PhoneUtil._();

  /// Returns the normalized E.164-ish string, or null if invalid.
  static String? normalize(String rawLocalNumber, String dialCode) {
    final digits = (dialCode + rawLocalNumber).replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7 || digits.length > 15) return null;
    return '+$digits';
  }

  static bool isValidLocalNumber(String rawLocalNumber, String dialCode) {
    return normalize(rawLocalNumber, dialCode) != null;
  }
}

class Country {
  const Country({
    required this.name,
    required this.iso2,
    required this.dialCode,
    required this.flagEmoji,
  });

  final String name;
  final String iso2;
  final String dialCode;
  final String flagEmoji;
}

/// A pragmatic subset of countries (not the full ISO list) covering common
/// markets. Sufficient for the registration flow's country picker; can grow
/// without any schema or server change since country_code is a free text column.
const List<Country> kCountries = [
  Country(name: 'United States', iso2: 'US', dialCode: '1', flagEmoji: '🇺🇸'),
  Country(name: 'United Kingdom', iso2: 'GB', dialCode: '44', flagEmoji: '🇬🇧'),
  Country(name: 'Canada', iso2: 'CA', dialCode: '1', flagEmoji: '🇨🇦'),
  Country(name: 'Australia', iso2: 'AU', dialCode: '61', flagEmoji: '🇦🇺'),
  Country(name: 'Egypt', iso2: 'EG', dialCode: '20', flagEmoji: '🇪🇬'),
  Country(name: 'Saudi Arabia', iso2: 'SA', dialCode: '966', flagEmoji: '🇸🇦'),
  Country(name: 'United Arab Emirates', iso2: 'AE', dialCode: '971', flagEmoji: '🇦🇪'),
  Country(name: 'India', iso2: 'IN', dialCode: '91', flagEmoji: '🇮🇳'),
  Country(name: 'Germany', iso2: 'DE', dialCode: '49', flagEmoji: '🇩🇪'),
  Country(name: 'France', iso2: 'FR', dialCode: '33', flagEmoji: '🇫🇷'),
];
