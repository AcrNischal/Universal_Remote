import 'package:flutter_test/flutter_test.dart';

import 'package:universal_remote/main.dart';

void main() {
  testWidgets('Universal Remote app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const UniversalRemoteApp());

    // Verify splash screen appears.
    expect(find.text('Universal Remote'), findsOneWidget);
  });
}
