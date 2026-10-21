import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:aqi_mobile_app/main.dart';
import 'package:aqi_mobile_app/providers/aqi_provider.dart';
import 'package:aqi_mobile_app/providers/theme_provider.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AqiProvider()),
        ],
        child: const AqiMobileApp(),
      ),
    );

    // Initial frame should render AeroWatch app bar
    expect(find.text('AeroWatch'), findsOneWidget);
  });
}
