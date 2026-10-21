import 'package:flutter_test/flutter_test.dart';
import 'package:rewardsapp/core/utils/phone_util.dart';

/// Covers the country-aware phone validation fix: a submitted/entered local
/// number must match the SELECTED country's own national-number length, not
/// just the generic 7-15 digit floor `fn_normalize_phone` enforces
/// server-side.
void main() {
  group('PhoneUtil.normalize -- Egypt (10 national digits)', () {
    const dialCode = '20';

    test('accepts exactly 10 digits', () {
      expect(PhoneUtil.normalize('1012345678', dialCode), '+201012345678');
    });

    test('accepts exactly 10 digits with a leading trunk 0', () {
      expect(PhoneUtil.normalize('01012345678', dialCode), '+201012345678');
    });

    test('rejects 11 digits (one more than Egypt allows)', () {
      expect(PhoneUtil.normalize('10123456789', dialCode), isNull);
    });

    test('rejects 9 digits (one fewer than Egypt requires)', () {
      expect(PhoneUtil.normalize('101234567', dialCode), isNull);
    });

    test('non-digit characters (spaces, dashes) are stripped before validating', () {
      expect(PhoneUtil.normalize('101-234-5678', dialCode), '+201012345678');
    });
  });

  group('PhoneUtil.normalize -- other countries use their own configured rules', () {
    test('United States requires exactly 10 digits', () {
      expect(PhoneUtil.normalize('2025550190', '1'), '+12025550190');
      expect(PhoneUtil.normalize('202555019', '1'), isNull); // 9 digits
      expect(PhoneUtil.normalize('20255501900', '1'), isNull); // 11 digits
    });

    test('Saudi Arabia requires exactly 9 digits', () {
      expect(PhoneUtil.normalize('512345678', '966'), '+966512345678');
      expect(PhoneUtil.normalize('5123456789', '966'), isNull); // 10 digits
    });

    test('Australia requires exactly 9 digits', () {
      expect(PhoneUtil.normalize('412345678', '61'), '+61412345678');
      expect(PhoneUtil.normalize('4123456789', '61'), isNull); // 10 digits
    });

    test('Germany accepts its wider 10-11 digit range', () {
      expect(PhoneUtil.normalize('1512345678', '49'), '+491512345678'); // 10
      expect(PhoneUtil.normalize('15123456789', '49'), '+4915123456789'); // 11
      expect(PhoneUtil.normalize('151234567', '49'), isNull); // 9 -- too short
      expect(PhoneUtil.normalize('151234567890', '49'), isNull); // 12 -- too long
    });

    test('a length that only satisfies the generic 7-15 floor but not the '
        'selected country\'s own length is still rejected', () {
      // 8 digits: within the server's generic 7-15 floor combined with the
      // dial code, but not Egypt's specific 10-digit requirement.
      expect(PhoneUtil.normalize('12345678', '20'), isNull);
    });
  });

  group('PhoneUtil.isValidLocalNumber', () {
    test('mirrors normalize -- true only when normalize would succeed', () {
      expect(PhoneUtil.isValidLocalNumber('1012345678', '20'), isTrue);
      expect(PhoneUtil.isValidLocalNumber('10123456789', '20'), isFalse);
    });
  });

  group('kCountries metadata', () {
    test('every country has a sane, non-empty national-digit range', () {
      for (final country in kCountries) {
        expect(country.minNationalDigits, greaterThan(0));
        expect(country.maxNationalDigits, greaterThanOrEqualTo(country.minNationalDigits));
      }
    });

    test('Egypt is configured for exactly 10 digits (this bug\'s explicit requirement)', () {
      final egypt = kCountries.firstWhere((c) => c.iso2 == 'EG');
      expect(egypt.minNationalDigits, 10);
      expect(egypt.maxNationalDigits, 10);
    });
  });
}
