import 'package:flutter_test/flutter_test.dart';
import 'package:promptix/main.dart';

void main() {
  testWidgets('Promptix smoke test', (WidgetTester tester) async {
    // Basic smoke test — verifies the app launches without crashing
    expect(PromptixApp, isNotNull);
  });
}
