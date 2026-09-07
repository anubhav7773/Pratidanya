import 'package:flutter_test/flutter_test.dart';
import 'package:pratidnya/src/features/02_case_input/data/case_repository.dart';

void main() {
  group('CAS-01: PostgREST Search Input Sanitization Tests', () {
    test('Strips commas and parentheses that break .or() syntax', () {
      const rawQuery = 'Sharma, (Lucknow)';
      final sanitized = CaseRepository.sanitizeSearchQuery(rawQuery);
      expect(sanitized, equals('Sharma  Lucknow'));
      expect(sanitized.contains(','), isFalse);
      expect(sanitized.contains('('), isFalse);
      expect(sanitized.contains(')'), isFalse);
    });

    test('Strips quotes, colons, and raw percent signs', () {
      const rawQuery = 'FIR: "124/2026"%';
      final sanitized = CaseRepository.sanitizeSearchQuery(rawQuery);
      expect(sanitized, equals('FIR 124/2026'));
      expect(sanitized.contains(':'), isFalse);
      expect(sanitized.contains('"'), isFalse);
      expect(sanitized.contains('%'), isFalse);
    });

    test('Handles normal legal case queries without alteration', () {
      const rawQuery = 'धारा 379 भादवि';
      final sanitized = CaseRepository.sanitizeSearchQuery(rawQuery);
      expect(sanitized, equals('धारा 379 भादवि'));
    });
  });
}
