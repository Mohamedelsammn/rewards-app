/// Client-side phone handling that mirrors the server's `fn_normalize_phone`
/// (strip everything but digits, prefix '+', require 7-15 digits overall) as
/// a floor, but is stricter on top of it: the *national* number (everything
/// after the dial code) must also match the selected country's own expected
/// digit count, so e.g. Egypt can't be typed/submitted with 11 digits just
/// because the combined length still happens to fall in the generic 7-15
/// range (implementation-plan.md §17 / tasks.md T09-02).
class PhoneUtil {
  const PhoneUtil._();

  /// Returns the normalized E.164-ish string, or null if invalid for
  /// [dialCode]'s country-specific national-number length.
  static String? normalize(String rawLocalNumber, String dialCode) {
    final country = countryForDialCode(dialCode);
    final localDigits = rawLocalNumber.replaceAll(RegExp(r'[^0-9]'), '');
    // A local number is conventionally entered/displayed with a leading
    // trunk '0' (e.g. Egypt "01012345678") that is dropped once the dial
    // code is prefixed -- strip exactly one, never more, so a genuine
    // leading '0' that's part of the actual subscriber number elsewhere
    // isn't eaten too.
    final withoutTrunkZero = localDigits.startsWith('0') ? localDigits.substring(1) : localDigits;

    if (country != null) {
      if (withoutTrunkZero.length < country.minNationalDigits ||
          withoutTrunkZero.length > country.maxNationalDigits) {
        return null;
      }
      return '+${country.dialCode}$withoutTrunkZero';
    }

    // No metadata for this dial code (shouldn't happen with kCountries, but
    // never crash on it) -- fall back to the server's own generic floor.
    final digits = dialCode + withoutTrunkZero;
    if (digits.length < 7 || digits.length > 15) return null;
    return '+$digits';
  }

  static bool isValidLocalNumber(String rawLocalNumber, String dialCode) {
    return normalize(rawLocalNumber, dialCode) != null;
  }

  static Country? countryForDialCode(String dialCode) {
    for (final c in kCountries) {
      if (c.dialCode == dialCode) return c;
    }
    return null;
  }
}

class Country {
  const Country({
    required this.name,
    required this.iso2,
    required this.dialCode,
    required this.flagEmoji,
    required this.minNationalDigits,
    required this.maxNationalDigits,
  });

  final String name;
  final String iso2;
  final String dialCode;
  final String flagEmoji;

  /// The expected length range of the national significant number (the
  /// local number *without* the leading trunk '0' and without the dial
  /// code) for this country's mobile numbers. Most countries use a single
  /// fixed length (min == max); a few (e.g. Germany) genuinely vary.
  final int minNationalDigits;
  final int maxNationalDigits;

  /// Convenience for the common fixed-length case, used to drive input
  /// formatters (e.g. `LengthLimitingTextInputFormatter`).
  int get maxNationalDigitsForInput => maxNationalDigits;
}

/// A pragmatic subset of countries (not the full ISO list) covering common
/// markets. Sufficient for the registration flow's country picker; can grow
/// without any schema or server change since country_code is a free text
/// column. National-number lengths are standard mobile-number lengths for
/// each country (the significant number, excluding a leading trunk '0' and
/// the dial code).
const List<Country> kCountries = [
  Country(
    name: 'United States',
    iso2: 'US',
    dialCode: '1',
    flagEmoji: '🇺🇸',
    minNationalDigits: 10,
    maxNationalDigits: 10,
  ),
  Country(
    name: 'United Kingdom',
    iso2: 'GB',
    dialCode: '44',
    flagEmoji: '🇬🇧',
    minNationalDigits: 10,
    maxNationalDigits: 10,
  ),
  Country(
    name: 'Canada',
    iso2: 'CA',
    dialCode: '1',
    flagEmoji: '🇨🇦',
    minNationalDigits: 10,
    maxNationalDigits: 10,
  ),
  Country(
    name: 'Australia',
    iso2: 'AU',
    dialCode: '61',
    flagEmoji: '🇦🇺',
    minNationalDigits: 9,
    maxNationalDigits: 9,
  ),
  Country(
    name: 'Egypt',
    iso2: 'EG',
    dialCode: '20',
    flagEmoji: '🇪🇬',
    minNationalDigits: 10,
    maxNationalDigits: 10,
  ),
  Country(
    name: 'Saudi Arabia',
    iso2: 'SA',
    dialCode: '966',
    flagEmoji: '🇸🇦',
    minNationalDigits: 9,
    maxNationalDigits: 9,
  ),
  Country(
    name: 'United Arab Emirates',
    iso2: 'AE',
    dialCode: '971',
    flagEmoji: '🇦🇪',
    minNationalDigits: 9,
    maxNationalDigits: 9,
  ),
  Country(
    name: 'India',
    iso2: 'IN',
    dialCode: '91',
    flagEmoji: '🇮🇳',
    minNationalDigits: 10,
    maxNationalDigits: 10,
  ),
  Country(
    name: 'Germany',
    iso2: 'DE',
    dialCode: '49',
    flagEmoji: '🇩🇪',
    minNationalDigits: 10,
    maxNationalDigits: 11,
  ),
  Country(
    name: 'France',
    iso2: 'FR',
    dialCode: '33',
    flagEmoji: '🇫🇷',
    minNationalDigits: 9,
    maxNationalDigits: 9,
  ),
];
