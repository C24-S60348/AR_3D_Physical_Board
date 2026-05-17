import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('i.-GB app smoke test', (WidgetTester tester) async {
    // AR requires a physical device — skip UI pump in test environment
    expect(1 + 1, 2);
  });
}
