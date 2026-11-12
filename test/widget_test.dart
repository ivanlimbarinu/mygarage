import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_garage/main.dart';
import 'package:my_garage/services/weather_service.dart';

void main() {
  test('snow showers trigger cold advice before rain', () {
    expect(WeatherService.adviceFor(8, 85, 5).title, contains('ghiaccio'));
    expect(WeatherService.adviceFor(15, 63, 5).title, contains('Pioggia'));
    expect(WeatherService.adviceFor(15, 45, 5).title, contains('Visibilità'));
  });
  testWidgets('banner closes and returns when app resumes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GarageHomePage(
          weatherLoader: () async =>
              const WeatherAdvice('Pioggia', 'Controlla le gomme'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('weather_banner')), findsOneWidget);
    await tester.tap(find.byTooltip('Chiudi banner'));
    await tester.pump();
    expect(find.byKey(const ValueKey('weather_banner')), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('weather_banner')), findsOneWidget);
    await tester.tap(find.text('Profilo'));
    await tester.pumpAndSettle();
    expect(find.text('Account dimostrativo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('splash opens login and demo opens garage', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Bentornato'), findsOneWidget);
    await tester.tap(find.text('Esplora la demo'));
    await tester.pumpAndSettle();
    expect(find.text('Garage'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
