import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'backend.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class GarageProfile {
  String? avatarPhoto, carPhoto;
  String name, brand, model, plate, year, fuel;
  int km, serviceKm, serviceMonths, serviceIntervalKm, reviewMonths;
  DateTime? lastReview, lastService, insurance, tax;
  GarageProfile({
    required this.name,
    required this.brand,
    required this.model,
    required this.plate,
    required this.year,
    required this.fuel,
    required this.km,
    required this.serviceKm,
    required this.serviceMonths,
    required this.serviceIntervalKm,
    required this.reviewMonths,
    this.lastReview,
    this.lastService,
    this.insurance,
    this.tax,
    this.avatarPhoto,
    this.carPhoto,
  });
  int get nextServiceKm => serviceKm + serviceIntervalKm;
  static DateTime addMonths(DateTime date, int months) {
    final start = DateTime(date.year, date.month + months);
    final last = DateTime(start.year, start.month + 1, 0).day;
    return DateTime(start.year, start.month, date.day > last ? last : date.day);
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'brand': brand,
    'model': model,
    'plate': plate,
    'year': year,
    'fuel': fuel,
    'km': km,
    'serviceKm': serviceKm,
    'serviceMonths': serviceMonths,
    'serviceIntervalKm': serviceIntervalKm,
    'reviewMonths': reviewMonths,
    'lastReview': lastReview?.toIso8601String(),
    'lastService': lastService?.toIso8601String(),
    'insurance': insurance?.toIso8601String(),
    'tax': tax?.toIso8601String(),
    'avatarPhoto': avatarPhoto,
    'carPhoto': carPhoto,
  };
  factory GarageProfile.fromJson(Map<String, dynamic> j) => GarageProfile(
    name: j['name'],
    brand: j['brand'],
    model: j['model'],
    plate: j['plate'],
    year: j['year'],
    fuel: j['fuel'],
    km: j['km'],
    serviceKm: j['serviceKm'],
    serviceMonths: j['serviceMonths'],
    serviceIntervalKm: j['serviceIntervalKm'],
    reviewMonths: j['reviewMonths'],
    lastReview: DateTime.tryParse(j['lastReview'] ?? ''),
    lastService: DateTime.tryParse(j['lastService'] ?? ''),
    insurance: DateTime.tryParse(j['insurance'] ?? ''),
    tax: DateTime.tryParse(j['tax'] ?? ''),
    avatarPhoto: j['avatarPhoto'] as String?,
    carPhoto: j['carPhoto'] as String?,
  );
}

class ProfileStore {
  final bool remote;
  final SupabaseClient? client;
  SupabaseClient get api => client ?? Backend.client;
  final SharedPreferencesAsync? _preferences;
  SharedPreferencesAsync get preferences =>
      _preferences ?? SharedPreferencesAsync();
  ProfileStore({this._preferences, this.remote = false, this.client});
  // Local installation profile. Replace this with the verified backend user ID after authentication.
  Future<GarageProfile?> load(String userId) async {
    if (remote) {
      final id = api.auth.currentUser!.id;
      final row = await api
          .from('garage_profiles')
          .select('profile')
          .eq('user_id', id)
          .maybeSingle();
      return row == null
          ? null
          : GarageProfile.fromJson(Map<String, dynamic>.from(row['profile']));
    }
    final raw = await preferences.getString('garage.profile.v1.$userId');
    return raw == null
        ? null
        : GarageProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(String userId, GarageProfile profile) async {
    if (remote) {
      await api.from('garage_profiles').upsert({
        'user_id': api.auth.currentUser!.id,
        'profile': profile.toJson(),
      });
      return;
    }
    await preferences.setString(
      'garage.profile.v1.$userId',
      jsonEncode(profile.toJson()),
    );
  }

  Future<Map<String, dynamic>?> loadState() async {
    if (!remote) return null;
    final row = await api
        .from('garage_states')
        .select('state')
        .eq('user_id', api.auth.currentUser!.id)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row['state']);
  }

  Future<void> saveState(Map<String, dynamic> state) async {
    if (!remote) return;
    await api.from('garage_states').upsert({
      'user_id': api.auth.currentUser!.id,
      'state': state,
    });
  }
}
