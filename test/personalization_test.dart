import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_garage/main.dart';
import 'package:my_garage/photo_editor.dart';
import 'package:my_garage/services/appearance.dart';
import 'package:my_garage/services/profile_store.dart';

void main() {
  testWidgets(
    'grey theme updates visible screen without restarting navigation',
    (tester) async {
      Appearance.grey.value = false;
      addTearDown(() => Appearance.grey.value = false);
      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Bentornato'), findsOneWidget);
      Appearance.grey.value = true;
      await tester.pumpAndSettle();
      final context = tester.element(find.text('Bentornato'));
      expect(
        Theme.of(context).scaffoldBackgroundColor,
        const Color(0xFFF3F4F6),
      );
      expect(Theme.of(context).colorScheme.surface, Colors.white);
      expect(Theme.of(context).brightness, Brightness.light);
      expect(Theme.of(context).colorScheme.onSurface, const Color(0xFF202127));
      expect(find.byType(SplashPage), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test(
    'old profiles load without photos, new photo references survive JSON',
    () {
      final p = GarageProfile(
        name: 'Test',
        brand: 'Fiat',
        model: 'Panda',
        plate: 'AB123CD',
        year: '2020',
        fuel: 'Benzina',
        km: 50000,
        serviceKm: 40000,
        serviceMonths: 12,
        serviceIntervalKm: 15000,
        reviewMonths: 24,
      );
      final legacy = p.toJson()
        ..remove('avatarPhoto')
        ..remove('carPhoto');
      expect(GarageProfile.fromJson(legacy).carPhoto, isNull);
      p.carPhoto = 'storage:owner/car.jpeg';
      p.avatarPhoto = 'storage:owner/avatar.png';
      final restored = GarageProfile.fromJson(
        jsonDecode(jsonEncode(p.toJson())),
      );
      expect(restored.carPhoto, p.carPhoto);
      expect(restored.avatarPhoto, p.avatarPhoto);
      expect(
        () => PhotoStore.contentType(Uint8List.fromList(utf8.encode('<svg/>'))),
        throwsFormatException,
      );
    },
  );

  testWidgets('home renders user photo rather than demo asset', (tester) async {
    const pixel =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aL1kAAAAASUVORK5CYII=';
    final car = Vehicle(
      'Fiat',
      'Panda',
      'AB123CD',
      '2020',
      50000,
      'Benzina',
      photo: 'data:image/png;base64,$pixel',
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: carPhoto(car))));
    await tester.pumpAndSettle();
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<MemoryImage>());
    expect(tester.takeException(), isNull);
  });
}
