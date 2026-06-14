import 'package:flutter_test/flutter_test.dart';
import 'package:my_ar_app/data/questions_data.dart';

void main() {
  group('typed answer matching', () {
    test('ignores case and repeated spaces', () {
      expect(answersAreEquivalent('  MeLAKa  ', 'melaka'), isTrue);
      expect(
        answersAreEquivalent('Bukit   St. Paul', 'bukit st. paul'),
        isTrue,
      );
    });

    test('accepts equivalent decimals and fractions', () {
      expect(answersAreEquivalent('0.5', '0.50'), isTrue);
      expect(answersAreEquivalent('1/2', '0.5'), isTrue);
      expect(answersAreEquivalent('2/4', '0.50'), isTrue);
    });

    test('rejects different answers', () {
      expect(answersAreEquivalent('1/3', '0.5'), isFalse);
      expect(answersAreEquivalent('Melaka', 'Johor'), isFalse);
    });
  });
}
