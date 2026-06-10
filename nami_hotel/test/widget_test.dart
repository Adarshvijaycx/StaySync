import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nami_hotel/main.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: NamiHotelApp()),
    );

    // The app should at minimum render something
    // (splash screen while checking auth)
    await tester.pump();
    expect(find.byType(NamiHotelApp), findsOneWidget);
  });
}
