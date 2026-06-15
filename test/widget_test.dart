import 'package:flutter_test/flutter_test.dart';

import 'package:personal_assistant/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PersonalAssistantApp());
    await tester.pump(const Duration(seconds: 2));
    // Verify the app builds and renders without throwing
  });
}
