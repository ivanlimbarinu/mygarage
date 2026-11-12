import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/weather_service.dart';
import 'services/profile_store.dart';
import 'onboarding.dart';
import 'auth_page.dart';
import 'services/backend.dart';
import 'services/appearance.dart';
import 'photo_editor.dart';

const coral = Color(0xFFFF443B),
    panel = Color(0xFF17171C),
    muted = Color(0xFF777783),
    green = Color(0xFF22D656),
    amber = Color(0xFFFFAC00);
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Backend.initialize();
  await Appearance.load();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: Appearance.grey,
    builder: (context, grey, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyGarage',
      theme: ThemeData(
        brightness: grey ? Brightness.light : Brightness.dark,
        scaffoldBackgroundColor: grey
            ? const Color(0xFFF3F4F6)
            : const Color(0xFF0B0B0F),
        colorScheme: grey
            ? const ColorScheme.light(
                primary: coral,
                surface: Colors.white,
                onSurface: Color(0xFF202127),
              )
            : const ColorScheme.dark(primary: coral, surface: panel),
        fontFamily: 'Roboto',
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: grey ? Colors.white : panel,
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide(
              color: grey ? const Color(0xFFDBDDE3) : const Color(0xFF29292F),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: coral,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      home: const SplashPage(),
    ),
  );
}

class Logo extends StatelessWidget {
  final double size;
  const Logo({super.key, this.size = 64});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: coral,
      borderRadius: BorderRadius.circular(size * .28),
    ),
    child: Icon(Icons.speed, size: size * .55, color: Colors.white),
  );
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashState();
}

class _SplashState extends State<SplashPage> {
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                Backend.configured ? const AuthPage() : const LoginPage(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Theme.of(context).brightness == Brightness.light
                  ? [const Color(0xFFFFE9E6), const Color(0xFFF3F4F6)]
                  : [const Color(0xFF290C0D), const Color(0xFF0B0B0F)],
            ),
          ),
        ),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (final size in [390.0, 285.0])
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: coral.withValues(alpha: .5)),
                  ),
                ),
              const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Logo(size: 98),
                  SizedBox(height: 24),
                  Text(
                    'MyGarage',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tutta la tua auto,\nin un posto solo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, height: 1.5),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Text(
            'Versione 1.0',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginState();
}

class _LoginState extends State<LoginPage> {
  bool hidden = true;
  final email = TextEditingController(), password = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Logo(size: 58),
                  const SizedBox(height: 24),
                  const Text(
                    'Bentornato',
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Accedi per gestire il tuo garage.',
                    style: TextStyle(color: muted),
                  ),
                  const SizedBox(height: 32),
                  label('EMAIL'),
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      hintText: 'nome@email.it',
                    ),
                    validator: (v) =>
                        v != null && RegExp(r'^\S+@\S+\.\S+$').hasMatch(v)
                        ? null
                        : 'Inserisci una email valida',
                  ),
                  const SizedBox(height: 16),
                  label('PASSWORD'),
                  TextFormField(
                    controller: password,
                    obscureText: hidden,
                    decoration: InputDecoration(
                      hintText: '••••••••••',
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => hidden = !hidden),
                        icon: Icon(
                          hidden
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (v) => (v?.length ?? 0) >= 6
                        ? null
                        : 'Inserisci almeno 6 caratteri',
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => notice(
                        context,
                        'Il recupero password sarà disponibile collegando il backend.',
                      ),
                      child: const Text('Password dimenticata?'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      if (form.currentState!.validate()) {
                        notice(
                          context,
                          'Collega il backend per autenticare il tuo account. Puoi esplorare la demo qui sotto.',
                        );
                      }
                    },
                    child: const Text(
                      'Accedi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const PersonalGarageGate(),
                      ),
                    ),
                    child: const Text('Apri il mio garage'),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const GarageHomePage(),
                        ),
                      ),
                      child: const Text(
                        'Esplora la demo',
                        style: TextStyle(color: muted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget label(String text) => Padding(
  padding: const EdgeInsets.only(left: 3, bottom: 7),
  child: Text(text, style: const TextStyle(fontSize: 11, color: muted)),
);
void notice(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
Widget card(Widget child, {EdgeInsets padding = const EdgeInsets.all(18)}) =>
    Builder(
      builder: (context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFFE1E3E8)
                : const Color(0xFF25252D),
          ),
        ),
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );

class Vehicle {
  String brand, model, plate, year, fuel;
  int km;
  String? photo;
  Vehicle(
    this.brand,
    this.model,
    this.plate,
    this.year,
    this.km,
    this.fuel, {
    this.photo,
  });
  String get name => '$brand $model';
}

class Deadline {
  final String name;
  final DateTime date;
  final IconData icon;
  Deadline(this.name, this.date, this.icon);
  int get days => date.difference(DateUtils.dateOnly(DateTime.now())).inDays;
  Color get color => days <= 7
      ? coral
      : days <= 30
      ? amber
      : green;
}

class GarageHomePage extends StatefulWidget {
  final Future<WeatherAdvice> Function()? weatherLoader;
  final GarageProfile? profile;
  final ProfileStore? profileStore;
  final Map<String, dynamic>? initialState;
  const GarageHomePage({
    super.key,
    this.weatherLoader,
    this.profile,
    this.profileStore,
    this.initialState,
  });
  @override
  State<GarageHomePage> createState() => _GarageState();
}

class _GarageState extends State<GarageHomePage> with WidgetsBindingObserver {
  int tab = 0, filter = 0, period = 0, selected = 0, refills = 14;
  bool banner = true, loading = true;
  WeatherAdvice? weather;
  final vehicles = [
    Vehicle('Fiat', 'Panda', 'AB 123 CD', '2019', 84320, 'Benzina'),
  ];
  final deadlines = [
    Deadline('Revisione', DateTime(2026, 11, 8), Icons.task_alt),
    Deadline('Bollo', DateTime(2026, 11, 17), Icons.description_outlined),
    Deadline('Assicurazione', DateTime(2026, 12, 20), Icons.shield_outlined),
    Deadline('Tagliando', DateTime(2027, 3, 14), Icons.build_outlined),
  ];
  double fuelCost = 142, maintenance = 76.4;
  Vehicle get car => vehicles[selected];
  String? avatarPhoto;
  Future<void> changeAvatar(String value) async {
    try {
      final p = widget.profile;
      if (p != null) {
        final updated = GarageProfile.fromJson({
          ...p.toJson(),
          'avatarPhoto': value,
        });
        await (widget.profileStore ?? ProfileStore()).save('local', updated);
        p.avatarPhoto = value;
      }
      if (mounted) setState(() => avatarPhoto = value);
    } catch (_) {
      if (mounted) notice(context, 'Foto profilo non salvata. Riprova.');
    }
  }

  Future<void> changeCarPhoto(String value) async {
    final target = car;
    final primary = selected == 0;
    try {
      final p = widget.profile;
      if (primary && p != null) {
        await (widget.profileStore ?? ProfileStore()).save(
          'local',
          GarageProfile.fromJson({...p.toJson(), 'carPhoto': value}),
        );
        p.carPhoto = value;
      }
      if (!mounted) return;
      setState(() => target.photo = value);
      await persist();
    } catch (_) {
      if (mounted) notice(context, 'Foto auto non salvata. Riprova.');
    }
  }

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    avatarPhoto = p?.avatarPhoto;
    if (p != null) {
      vehicles
        ..clear()
        ..add(
          Vehicle(
            p.brand,
            p.model,
            p.plate,
            p.year,
            p.km,
            p.fuel,
            photo: p.carPhoto,
          ),
        );
      deadlines.clear();
      if (p.lastReview != null) {
        deadlines.add(
          Deadline(
            'Revisione',
            GarageProfile.addMonths(p.lastReview!, p.reviewMonths),
            Icons.task_alt,
          ),
        );
      }
      if (p.lastService != null) {
        deadlines.add(
          Deadline(
            'Tagliando',
            GarageProfile.addMonths(p.lastService!, p.serviceMonths),
            Icons.build_outlined,
          ),
        );
      }
      if (p.insurance != null) {
        deadlines.add(
          Deadline('Assicurazione', p.insurance!, Icons.shield_outlined),
        );
      }
      if (p.tax != null) {
        deadlines.add(Deadline('Bollo', p.tax!, Icons.description_outlined));
      }
      fuelCost = 0;
      maintenance = 0;
      refills = 0;
    }
    WidgetsBinding.instance.addObserver(this);
    final saved = widget.initialState;
    if (saved != null) {
      vehicles
        ..clear()
        ..addAll(
          (saved['vehicles'] as List).map(
            (v) => Vehicle(
              v['brand'],
              v['model'],
              v['plate'],
              v['year'],
              v['km'],
              v['fuel'],
              photo: v['photo'] as String?,
            ),
          ),
        );
      deadlines
        ..clear()
        ..addAll(
          (saved['deadlines'] as List).map(
            (d) => Deadline(d['name'], DateTime.parse(d['date']), Icons.event),
          ),
        );
      fuelCost = (saved['fuelCost'] as num).toDouble();
      maintenance = (saved['maintenance'] as num).toDouble();
      refills = saved['refills'] as int;
    }
    loadWeather();
  }

  Map<String, dynamic> snapshot() => {
    'vehicles': vehicles
        .map(
          (v) => {
            'brand': v.brand,
            'model': v.model,
            'plate': v.plate,
            'year': v.year,
            'km': v.km,
            'fuel': v.fuel,
            'photo': v.photo,
          },
        )
        .toList(),
    'deadlines': deadlines
        .map((d) => {'name': d.name, 'date': d.date.toIso8601String()})
        .toList(),
    'fuelCost': fuelCost,
    'maintenance': maintenance,
    'refills': refills,
  };
  Future<void> writes = Future.value();
  Future<void> persist() async {
    if (widget.profileStore?.remote != true) return;
    final state = snapshot();
    final owner = Backend.client.auth.currentUser?.id;
    try {
      final write = writes.then((_) async {
        if (owner == null || Backend.client.auth.currentUser?.id != owner) {
          throw StateError('Session changed');
        }
        await widget.profileStore!.saveState(state);
      });
      writes = write.catchError((Object _) {});
      await write;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Modifiche non salvate online. Controlla la connessione.',
            ),
            action: SnackBarAction(label: 'Riprova', onPressed: persist),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => banner = true);
      loadWeather();
    }
  }

  Future<void> loadWeather() async {
    setState(() => loading = true);
    try {
      final result =
          await (widget.weatherLoader?.call() ?? WeatherService.fetchAdvice());
      if (mounted) {
        setState(() {
          weather = result;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          weather = const WeatherAdvice(
            'Meteo non disponibile',
            'Verifica la connessione e riprova. Nessuna condizione meteo verificata.',
          );
          loading = false;
        });
      }
    }
  }

  Future<void> addCar() async {
    final result = await Navigator.of(context).push<Vehicle>(
      MaterialPageRoute(builder: (_) => AddCarPage(store: widget.profileStore)),
    );
    if (result != null) {
      setState(() {
        vehicles.add(result);
        selected = vehicles.length - 1;
      });
      await persist();
    }
  }

  Future<void> refill() async {
    final result = await Navigator.of(context)
        .push<double>(MaterialPageRoute(builder: (_) => RefillPage(car: car)));
    if (result != null) {
      setState(() {
        fuelCost += result;
        refills++;
      });
      await persist();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tab == 0) ...[
                        Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Il tuo',
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'Garage',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton.filledTonal(
                              onPressed: () => setState(() => tab = 1),
                              icon: const Icon(Icons.notifications_none),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: addCar,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (banner) weatherBanner(),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DetailPage(
                                car: car,
                                deadlines: deadlines,
                                onRefill: refill,
                              ),
                            ),
                          ),
                          child: carPhoto(car, height: 220, overlay: true),
                        ),
                        PhotoEditor(
                          key: ObjectKey(car),
                          value: car.photo,
                          store: widget.profileStore ?? ProfileStore(),
                          label: 'Modifica foto auto',
                          preview: false,
                          onChanged: changeCarPhoto,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            vehicles.length,
                            (i) => GestureDetector(
                              onTap: () => setState(() => selected = i),
                              child: Container(
                                margin: const EdgeInsets.all(3),
                                width: i == selected ? 22 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i == selected ? coral : muted,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            quick(
                              'Rifornimento',
                              Icons.water_drop_outlined,
                              coral,
                              refill,
                            ),
                            const SizedBox(width: 9),
                            quick(
                              'Manutenzione',
                              Icons.build_outlined,
                              amber,
                              addMaintenance,
                            ),
                            const SizedBox(width: 9),
                            quick(
                              'Spese',
                              Icons.bar_chart,
                              green,
                              () => setState(() => tab = 2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Prossime scadenze',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => setState(() => tab = 1),
                              child: const Text('Vedi tutte'),
                            ),
                          ],
                        ),
                        ...deadlines.take(3).map((d) => deadlineTile(d, false)),
                      ],
                      if (tab == 1) ...[
                        Row(
                          children: [
                            IconButton.filled(
                              onPressed: addDeadline,
                              icon: const Icon(Icons.add),
                            ),
                            const Spacer(),
                            title('Scadenze'),
                          ],
                        ),
                        const SizedBox(height: 18),
                        segments(
                          ['Tutte', 'Urgenti', 'Prossime'],
                          filter,
                          (i) => setState(() => filter = i),
                        ),
                        const SizedBox(height: 16),
                        ...deadlines
                            .where(
                              (d) =>
                                  filter == 0 ||
                                  (filter == 1 ? d.days <= 7 : d.days > 7),
                            )
                            .map(
                              (d) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: deadlineTile(d, true),
                              ),
                            ),
                      ],
                      if (tab == 2) ...expensePage(),
                      if (tab == 3) ...profile(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: card(
                  Row(
                    children: List.generate(
                      4,
                      (i) => Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => setState(() => tab = i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              children: [
                                Icon(
                                  [
                                    Icons.home_outlined,
                                    Icons.calendar_month_outlined,
                                    Icons.bar_chart,
                                    Icons.person_outline,
                                  ][i],
                                  color: tab == i ? coral : muted,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  ['Garage', 'Scadenze', 'Spese', 'Profilo'][i],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: tab == i ? coral : muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget title(String s) => Text(
    s,
    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
  );
  Widget weatherBanner() => Container(
    key: const ValueKey('weather_banner'),
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFCA28),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(Icons.wb_cloudy_outlined, color: Colors.black),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loading ? 'Controllo meteo…' : weather!.title,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                loading ? 'Torino · aggiornamento in corso' : weather!.message,
                style: const TextStyle(color: Colors.black87, fontSize: 12),
              ),
              const SizedBox(height: 5),
              Text(
                'Torino · Open-Meteo',
                style: const TextStyle(color: Colors.black54, fontSize: 10),
              ),
              if (!loading && weather!.title == 'Meteo non disponibile')
                TextButton(
                  onPressed: loadWeather,
                  child: const Text(
                    'Riprova',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Chiudi banner',
          onPressed: () => setState(() => banner = false),
          icon: const Icon(Icons.close, color: Colors.black, size: 19),
        ),
      ],
    ),
  );
  Widget quick(String s, IconData icon, Color c, VoidCallback tap) => Expanded(
    child: InkWell(
      onTap: tap,
      child: card(
        Column(
          children: [
            Icon(icon, color: c, size: 23),
            const SizedBox(height: 7),
            Text(
              s,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 3),
      ),
    ),
  );
  Widget deadlineTile(Deadline d, bool full) {
    final content = Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .04),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(d.icon, color: d.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    dateText(d.date),
                    style: const TextStyle(fontSize: 11, color: muted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: d.color.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                d.days < 0
                    ? 'Scaduta'
                    : d.days == 0
                    ? 'Oggi'
                    : '${d.days} giorni',
                style: TextStyle(
                  color: d.color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (full) ...[
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: (1 - d.days / 150).clamp(.1, 1),
              color: d.color,
              backgroundColor: const Color(0xFF2A2A32),
              minHeight: 5,
            ),
          ),
        ],
      ],
    );
    return full
        ? card(content, padding: const EdgeInsets.all(15))
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: content,
          );
  }

  Widget segments(List<String> names, int value, ValueChanged<int> change) =>
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFF29292F)),
        ),
        child: Row(
          children: List.generate(
            names.length,
            (i) => Expanded(
              child: GestureDetector(
                onTap: () => change(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: value == i ? coral : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    names[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: value == i ? Colors.white : muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
  List<Widget> expensePage() {
    final total = fuelCost + maintenance + 30;
    return [
      title('Spese'),
      const SizedBox(height: 16),
      segments(
        ['Mese', 'Anno', 'Totale'],
        period,
        (i) => setState(() => period = i),
      ),
      const SizedBox(height: 16),
      card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ['NOVEMBRE 2026', 'ANNO 2026', 'TUTTE LE SPESE'][period],
              style: const TextStyle(color: muted, fontSize: 11),
            ),
            Text(
              money(total),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Riepilogo dati demo',
              style: TextStyle(color: green, fontSize: 12),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(
                  6,
                  (i) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: [55.0, 80.0, 45.0, 100.0, 68.0, 125.0][i],
                            decoration: BoxDecoration(
                              color: i == 5 ? coral : const Color(0xFF35353F),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ['Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov'][i],
                            style: const TextStyle(fontSize: 11, color: muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      card(
        Column(
          children: [
            expenseRow('Carburante', fuelCost, total, coral),
            const Divider(color: Color(0xFF29292F)),
            expenseRow('Manutenzione', maintenance, total, amber),
            const Divider(color: Color(0xFF29292F)),
            expenseRow('Assicurazione', 30, total, green),
          ],
        ),
      ),
    ];
  }

  Widget expenseRow(String name, double amount, double total, Color color) =>
      Row(
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name),
                Text(
                  '${(amount / total * 100).round()}% del totale',
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
              ],
            ),
          ),
          Text(money(amount)),
        ],
      );
  List<Widget> profile() => [
    title('Profilo'),
    if (widget.profile != null)
      TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (routeContext) => SetupPage(
              initial: GarageProfile.fromJson({
                ...widget.profile!.toJson(),
                'km': vehicles.first.km,
              }),
              store: widget.profileStore ?? ProfileStore(),
              onComplete: (p) async {
                vehicles[0] = Vehicle(
                  p.brand,
                  p.model,
                  p.plate,
                  p.year,
                  p.km,
                  p.fuel,
                  photo: p.carPhoto,
                );
                deadlines.removeWhere(
                  (d) => [
                    'Revisione',
                    'Tagliando',
                    'Assicurazione',
                    'Bollo',
                  ].contains(d.name),
                );
                if (p.lastReview != null) {
                  deadlines.add(
                    Deadline(
                      'Revisione',
                      GarageProfile.addMonths(p.lastReview!, p.reviewMonths),
                      Icons.task_alt,
                    ),
                  );
                }
                if (p.lastService != null) {
                  deadlines.add(
                    Deadline(
                      'Tagliando',
                      GarageProfile.addMonths(p.lastService!, p.serviceMonths),
                      Icons.build_outlined,
                    ),
                  );
                }
                if (p.insurance != null) {
                  deadlines.add(
                    Deadline(
                      'Assicurazione',
                      p.insurance!,
                      Icons.shield_outlined,
                    ),
                  );
                }
                if (p.tax != null) {
                  deadlines.add(
                    Deadline('Bollo', p.tax!, Icons.description_outlined),
                  );
                }
                final state = snapshot();
                await persist();
                if (!routeContext.mounted || !mounted) return;
                Navigator.of(routeContext).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => widget.profileStore?.remote == true
                        ? const AuthPage()
                        : GarageHomePage(
                            profile: p,
                            profileStore: widget.profileStore,
                            initialState: state,
                          ),
                  ),
                );
              },
            ),
          ),
        ),
        child: const Text('Modifica auto e scadenze'),
      ),
    const SizedBox(height: 24),
    Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 64,
            height: 64,
            child: UserPhoto(
              value: avatarPhoto,
              store: widget.profileStore ?? ProfileStore(),
              fallback: const CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFFFF7421),
                child: Text(
                  'MG',
                  style: TextStyle(
                    fontSize: 25,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.profile?.name ?? 'Garage demo',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.profile == null
                  ? 'Account dimostrativo'
                  : 'Profilo locale',
              style: const TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ),
      ],
    ),
    PhotoEditor(
      value: avatarPhoto,
      store: widget.profileStore ?? ProfileStore(),
      label: 'Modifica foto del profilo',
      preview: false,
      onChanged: changeAvatar,
    ),
    const SizedBox(height: 20),
    Row(
      children: [
        metric('${vehicles.length}', 'auto'),
        const SizedBox(width: 8),
        metric('$refills', 'rifornimenti'),
        const SizedBox(width: 8),
        metric('${deadlines.length}', 'scadenze'),
      ],
    ),
    const SizedBox(height: 16),
    card(
      Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications_none),
            title: const Text('Notifiche'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => notice(
              context,
              'Gli avvisi meteo compaiono a ogni apertura. Le notifiche push richiedono il backend.',
            ),
          ),
          const Divider(),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.tune),
            title: Text('Unità di misura'),
            trailing: Text('km · litri', style: TextStyle(color: muted)),
          ),
          const Divider(),
          ValueListenableBuilder<bool>(
            valueListenable: Appearance.grey,
            builder: (context, grey, _) => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.palette_outlined),
              title: const Text('Tema chiaro'),
              subtitle: Text(grey ? 'Bianco e grigio chiaro' : 'Scuro'),
              value: grey,
              onChanged: (value) async {
                try {
                  await Appearance.setGrey(value);
                } catch (_) {
                  if (context.mounted) {
                    notice(context, 'Tema non salvato. Riprova.');
                  }
                }
              },
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 14),
    card(
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.logout, color: coral),
        title: const Text('Esci', style: TextStyle(color: coral)),
        onTap: () async {
          if (widget.profileStore?.remote == true) {
            try {
              await Backend.client.auth.signOut();
            } catch (_) {
              if (mounted) notice(context, 'Uscita non riuscita. Riprova.');
            }
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          }
        },
      ),
    ),
    const SizedBox(height: 12),
    Text(
      widget.profileStore?.remote == true
          ? 'Account Supabase · dati salvati online'
          : 'Modalità locale · profilo sul dispositivo, aggiunte nella sessione',
      style: const TextStyle(color: muted, fontSize: 11),
    ),
  ];
  Future<void> addDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
    );
    if (picked != null && mounted) {
      final name = await askText(context, 'Nome scadenza');
      if (name != null && name.trim().isNotEmpty) {
        setState(
          () => deadlines.add(Deadline(name.trim(), picked, Icons.event)),
        );
        await persist();
      }
    }
  }

  Future<void> addMaintenance() async {
    final amount = await askText(
      context,
      'Costo manutenzione (€)',
      numeric: true,
    );
    final value = double.tryParse((amount ?? '').replaceAll(',', '.'));
    if (value != null && value > 0) {
      setState(() => maintenance += value);
      await persist();
    }
  }
}

String money(double n) => '€ ${n.toStringAsFixed(2).replaceAll('.', ',')}';
String dateText(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${['gen', 'feb', 'mar', 'apr', 'mag', 'giu', 'lug', 'ago', 'set', 'ott', 'nov', 'dic'][d.month - 1]} ${d.year}';
Widget metric(String value, String caption) => Expanded(
  child: card(
    Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        const SizedBox(height: 4),
        Text(caption, style: const TextStyle(color: muted, fontSize: 11)),
      ],
    ),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 3),
  ),
);
Widget carPhoto(
  Vehicle car, {
  double height = 135,
  bool overlay = false,
}) => ClipRRect(
  borderRadius: BorderRadius.circular(24),
  child: SizedBox(
    height: height,
    width: double.infinity,
    child: Stack(
      fit: StackFit.expand,
      children: [
        UserPhoto(
          value: car.photo,
          store: ProfileStore(),
          fallback: Image.asset('assets/panda.png', fit: BoxFit.cover),
        ),
        if (overlay) ...[
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent, Colors.black54],
              ),
            ),
          ),
          Positioned(
            top: 18,
            left: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  car.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${car.fuel} · ${car.year}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 18,
            left: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  left: BorderSide(color: Colors.blue, width: 10),
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                car.plate,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 22,
            right: 18,
            child: Text(
              '${car.km} km',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    ),
  ),
);
Future<String?> askText(
  BuildContext context,
  String title, {
  bool numeric = false,
}) async {
  String value = '';
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        autofocus: true,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        onChanged: (v) => value = v,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Annulla'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, value),
          child: const Text('Salva'),
        ),
      ],
    ),
  );
}

class DetailPage extends StatelessWidget {
  final Vehicle car;
  final List<Deadline> deadlines;
  final Future<void> Function() onRefill;
  const DetailPage({
    super.key,
    required this.car,
    required this.deadlines,
    required this.onRefill,
  });
  @override
  Widget build(BuildContext context) => EditorFrame(
    title: car.name,
    button: 'ï¼‹  Aggiungi rifornimento',
    onSave: onRefill,
    children: [
      carPhoto(car),
      const SizedBox(height: 12),
      card(
        SizedBox(
          height: 145,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              CustomPaint(size: const Size(210, 130), painter: GaugePainter()),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${car.km}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'chilometri percorsi',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          metric('5,8', 'l/100 km'),
          const SizedBox(width: 8),
          metric('€0,09', 'costo/km'),
          const SizedBox(width: 8),
          metric('€142', 'questo mese'),
        ],
      ),
      const SizedBox(height: 12),
      card(
        Column(
          children: deadlines
              .take(3)
              .map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(d.name)),
                          Text(
                            d.days < 0 ? 'Scaduta' : '${d.days} giorni',
                            style: TextStyle(color: d.color, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: (1 - d.days / 150).clamp(.1, 1),
                        color: d.color,
                        backgroundColor: Colors.white12,
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    ],
  );
}

class GaugePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(22, 12, size.width - 44, size.width - 44);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF303038);
    canvas.drawArc(rect, math.pi, math.pi, false, paint);
    paint.color = coral;
    for (int i = 0; i < 5; i++) {
      canvas.drawArc(rect, math.pi + i * math.pi / 5 + .04, .35, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EditorFrame extends StatelessWidget {
  final String title, button;
  final VoidCallback onSave;
  final List<Widget> children;
  const EditorFrame({
    super.key,
    required this.title,
    required this.button,
    required this.onSave,
    required this.children,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 24, 12),
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: children,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: FilledButton(
                  onPressed: onSave,
                  child: Text(
                    button,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class AddCarPage extends StatefulWidget {
  final ProfileStore? store;
  const AddCarPage({super.key, this.store});
  @override
  State<AddCarPage> createState() => _AddCarState();
}

class _AddCarState extends State<AddCarPage> {
  String? photo;
  bool photoBusy = false;
  final form = GlobalKey<FormState>();
  final fields = List.generate(5, (_) => TextEditingController());
  String fuel = 'Benzina';
  @override
  void dispose() {
    for (final c in fields) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => EditorFrame(
    title: 'Nuova auto',
    button: 'Aggiungi al garage',
    onSave: () {
      if (photoBusy) return;
      if (form.currentState!.validate()) {
        Navigator.pop(
          context,
          Vehicle(
            fields[0].text.trim(),
            fields[1].text.trim(),
            fields[2].text.trim().toUpperCase(),
            fields[3].text,
            int.parse(fields[4].text),
            fuel,
            photo: photo,
          ),
        );
      }
    },
    children: [
      Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhotoEditor(
              value: photo,
              store: widget.store ?? ProfileStore(),
              label: 'Scegli foto auto',
              onBusy: (busy) => setState(() => photoBusy = busy),
              onChanged: (value) => setState(() => photo = value),
            ),
            const SizedBox(height: 20),
            for (int i = 0; i < 5; i++) ...[
              label(['MARCA', 'MODELLO', 'TARGA', 'ANNO', 'KM ATTUALI'][i]),
              TextFormField(
                controller: fields[i],
                keyboardType: i >= 3
                    ? TextInputType.number
                    : TextInputType.text,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Campo obbligatorio';
                  }
                  if (i == 3) {
                    final year = int.tryParse(v);
                    if (year == null ||
                        year < 1900 ||
                        year > DateTime.now().year + 1) {
                      return 'Anno non valido';
                    }
                  }
                  if (i == 4 && (int.tryParse(v) == null || int.parse(v) < 0)) {
                    return 'Chilometraggio non valido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
            ],
            label('ALIMENTAZIONE'),
            Wrap(
              spacing: 6,
              children: ['Benzina', 'Diesel', 'Ibrida', 'Elettrica']
                  .map(
                    (f) => ChoiceChip(
                      label: Text(f),
                      selected: fuel == f,
                      onSelected: (_) => setState(() => fuel = f),
                      selectedColor: coral.withValues(alpha: .2),
                      showCheckmark: false,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    ],
  );
}

class RefillPage extends StatefulWidget {
  final Vehicle car;
  const RefillPage({super.key, required this.car});
  @override
  State<RefillPage> createState() => _RefillState();
}

class _RefillState extends State<RefillPage> {
  final form = GlobalKey<FormState>();
  final litres = TextEditingController(text: '32,4'),
      price = TextEditingController(text: '1,789');
  late final TextEditingController km;
  DateTime date = DateTime.now();
  bool full = true;
  double get total => number(litres.text) * number(price.text);
  double number(String v) => double.tryParse(v.replaceAll(',', '.')) ?? 0;
  @override
  void initState() {
    super.initState();
    km = TextEditingController(text: '${widget.car.km}');
  }

  @override
  void dispose() {
    litres.dispose();
    price.dispose();
    km.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => EditorFrame(
    title: 'Rifornimento',
    button: 'Salva rifornimento',
    onSave: () {
      if (form.currentState!.validate()) {
        widget.car.km = int.parse(km.text);
        Navigator.pop(context, total);
      }
    },
    children: [
      Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label('DATA'),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (d != null) setState(() => date = d);
              },
              child: card(
                SizedBox(width: double.infinity, child: Text(dateText(date))),
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: input('LITRI', litres)),
                const SizedBox(width: 12),
                Expanded(child: input('PREZZO €/L', price)),
              ],
            ),
            const SizedBox(height: 18),
            label('KM ATTUALI'),
            TextFormField(
              controller: km,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  int.tryParse(v ?? '') != null &&
                      int.parse(v!) >= widget.car.km
                  ? null
                  : 'Non può diminuire',
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Pieno'),
                  selected: full,
                  onSelected: (_) => setState(() => full = true),
                ),
                ChoiceChip(
                  label: const Text('Parziale'),
                  selected: !full,
                  onSelected: (_) => setState(() => full = false),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [coral.withValues(alpha: .2), panel],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  label('STIMA AUTOMATICA'),
                  Text(
                    money(total),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'totale rifornimento',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
  Widget input(String text, TextEditingController controller) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      label(text),
      TextFormField(
        controller: controller,
        onChanged: (_) => setState(() {}),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (v) => number(v ?? '') > 0 ? null : 'Valore non valido',
      ),
    ],
  );
}
