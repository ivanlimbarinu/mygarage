import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_garage/services/profile_store.dart';

void main() {
  test(
    'remote profile uses authenticated owner and propagates failures',
    () async {
      const owner = '11111111-1111-4111-8111-111111111111';
      Map<String, dynamic>? stored;
      var fail = false;
      final client = SupabaseClient(
        'https://example.supabase.co',
        'public-test-key',
        httpClient: MockClient((request) async {
          if (request.url.path == '/auth/v1/token') {
            return http.Response(
              jsonEncode({
                'access_token': 'test-token',
                'refresh_token': 'test-refresh',
                'expires_in': 3600,
                'token_type': 'bearer',
                'user': {
                  'id': owner,
                  'aud': 'authenticated',
                  'email': 'test@example.com',
                  'created_at': '2026-01-01T00:00:00Z',
                  'app_metadata': {},
                  'user_metadata': {},
                },
              }),
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }
          expect(request.headers['Authorization'], 'Bearer test-token');
          if (fail) {
            return http.Response(
              '{"message":"unavailable"}',
              503,
              request: request,
            );
          }
          if (request.method == 'POST') {
            stored = jsonDecode(request.body) as Map<String, dynamic>;
            expect(stored!['user_id'], owner);
            return http.Response('', 201, request: request);
          }
          expect(request.url.queryParameters['user_id'], 'eq.$owner');
          return http.Response(
            jsonEncode(stored == null ? [] : [stored]),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      await client.auth.signInWithPassword(
        email: 'test@example.com',
        password: 'password123',
      );
      final store = ProfileStore(remote: true, client: client);
      expect(await store.load('another-user'), isNull);
      final profile = GarageProfile(
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
        lastReview: DateTime(2025, 1, 31),
      );
      await store.save('another-user', profile);
      expect((await store.load('another-user'))!.toJson(), profile.toJson());
      final state = {
        'vehicles': [profile.toJson()],
        'deadlines': [],
        'fuelCost': 20,
        'maintenance': 30,
        'refills': 1,
      };
      await store.saveState(state);
      expect(await store.loadState(), state);
      fail = true;
      await expectLater(
        store.saveState(state),
        throwsA(isA<PostgrestException>()),
      );
      await expectLater(
        store.load('another-user'),
        throwsA(isA<PostgrestException>()),
      );
    },
  );
}
