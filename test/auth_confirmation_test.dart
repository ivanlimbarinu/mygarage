import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_garage/auth_page.dart';
import 'package:my_garage/services/auth_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemoryPkceStorage extends GotrueAsyncStorage {
  final values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => values[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    values.remove(key);
  }
}

void main() {
  testWidgets(
    'Google opens OAuth with PKCE and callback without requiring email fields',
    (tester) async {
      final created = await tester.runAsync(
        () async => SupabaseClient(
          'https://example.supabase.co',
          'test-public-key',
          authOptions: AuthClientOptions(
            authFlowType: AuthFlowType.pkce,
            pkceAsyncStorage: MemoryPkceStorage(),
            autoRefreshToken: false,
          ),
        ),
      );
      final client = created!;
      addTearDown(() => tester.runAsync(client.dispose));
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      final launched = <MethodCall>[];
      var canOpen = true;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        launched.add(call);
        return canOpen;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(MaterialApp(home: AuthPage(client: client)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('google_sign_in')));
      await tester.pumpAndSettle();
      expect(launched, hasLength(1));
      final args = launched.single.arguments as Map;
      final uri = Uri.parse(args['url'] as String);
      expect(uri.path, '/auth/v1/authorize');
      expect(uri.queryParameters['provider'], 'google');
      expect(uri.queryParameters['redirect_to'], AuthConfig.mobileCallback);
      expect(uri.queryParameters['code_challenge'], isNotEmpty);
      expect(uri.queryParameters['code_challenge_method'], 's256');
      expect(uri.queryParameters['prompt'], 'select_account');
      expect(args['useWebView'], false);
      expect(client.auth.currentSession, isNull);
      expect(find.text('Inserisci una email valida.'), findsNothing);
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('google_sign_in')),
            )
            .onPressed,
        isNotNull,
      );
      canOpen = false;
      await tester.tap(find.byKey(const ValueKey('google_sign_in')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Impossibile aprire Google'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('google_sign_in')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  test('native callback matches Android, iOS and build configuration', () {
    expect(AuthConfig.redirectUrl, 'mygarage://login-callback/');
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(
      manifest,
      contains(
        'android:scheme="mygarage" android:host="login-callback" android:path="/"',
      ),
    );
    expect(
      manifest,
      contains(
        'android:name="flutter_deeplinking_enabled" android:value="false"',
      ),
    );
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('<string>mygarage</string>'));
    final config = jsonDecode(
      File('config/supabase.example.json').readAsStringSync(),
    );
    expect(config['AUTH_REDIRECT_URL'], AuthConfig.mobileCallback);
  });

  testWidgets(
    'signup awaits confirmation, blocked login explains verification, resend uses callback',
    (tester) async {
      final requests = <http.Request>[];
      final created = await tester.runAsync(
        () async => SupabaseClient(
          'https://example.supabase.co',
          'public-test-key',
          authOptions: AuthClientOptions(
            authFlowType: AuthFlowType.pkce,
            pkceAsyncStorage: MemoryPkceStorage(),
            autoRefreshToken: false,
          ),
          httpClient: MockClient((request) async {
            requests.add(request);
            if (request.url.path.endsWith('/signup')) {
              return http.Response(
                jsonEncode({
                  'id': '11111111-1111-4111-8111-111111111111',
                  'aud': 'authenticated',
                  'email': 'test@example.com',
                  'created_at': '2026-01-01T00:00:00Z',
                  'app_metadata': {},
                  'user_metadata': {},
                }),
                200,
                request: request,
                headers: {'content-type': 'application/json'},
              );
            }
            if (request.url.path.endsWith('/resend')) {
              return http.Response(
                '{}',
                200,
                request: request,
                headers: {'content-type': 'application/json'},
              );
            }
            return http.Response(
              jsonEncode({
                'code': 'email_not_confirmed',
                'error_code': 'email_not_confirmed',
                'msg': 'Email not confirmed',
              }),
              400,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      );
      final client = created!;
      addTearDown(() => tester.runAsync(client.dispose));
      await tester.pumpWidget(MaterialApp(home: AuthPage(client: client)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Crea un account'));
      await tester.tap(find.text('Crea un account'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.ensureVisible(find.text('Registrati'));
      await tester.tap(find.text('Registrati'));
      await tester.pumpAndSettle();
      expect(
        requests.single.url.queryParameters['redirect_to'],
        AuthConfig.mobileCallback,
      );
      expect(client.auth.currentSession, isNull);
      expect(find.textContaining('Controlla la tua email'), findsOneWidget);
      expect(find.text('Accedi al tuo garage'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.ensureVisible(find.text('Accedi'));
      await tester.tap(find.text('Accedi'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Conferma prima'), findsOneWidget);
      await tester.ensureVisible(find.text('Invia di nuovo la conferma email'));
      await tester.tap(find.text('Invia di nuovo la conferma email'));
      await tester.pumpAndSettle();
      final resend = requests.last;
      expect(resend.url.path, endsWith('/resend'));
      expect(
        resend.url.queryParameters['redirect_to'],
        AuthConfig.mobileCallback,
      );
      expect(jsonDecode(resend.body)['type'], 'signup');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
