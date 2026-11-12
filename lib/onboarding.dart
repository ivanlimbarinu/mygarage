import 'package:flutter/material.dart';

import 'main.dart';
import 'services/profile_store.dart';
import 'photo_editor.dart';

class PersonalGarageGate extends StatefulWidget {
  final bool remote;
  const PersonalGarageGate({super.key, this.remote = false});
  @override
  State<PersonalGarageGate> createState() => _GateState();
}

class _GateState extends State<PersonalGarageGate> {
  late final store = ProfileStore(remote: widget.remote);
  GarageProfile? profile;
  Map<String, dynamic>? garageState;
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final saved = await store.load('local');
      final savedState = await store.loadState();
      if (mounted) {
        setState(() {
          profile = saved;
          garageState = savedState;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error = 'Impossibile leggere il profilo salvato. Riprova senza sovrascrivere i dati.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!),
              TextButton(onPressed: load, child: const Text('Riprova')),
            ],
          ),
        ),
      );
    }
    if (profile == null) {
      return SetupPage(
        onComplete: (p) => setState(() => profile = p),
        store: store,
      );
    }
    return GarageHomePage(
      profile: profile,
      profileStore: store,
      initialState: garageState,
    );
  }
}

class SetupPage extends StatefulWidget {
  final GarageProfile? initial;
  final ProfileStore store;
  final ValueChanged<GarageProfile> onComplete;
  const SetupPage({
    super.key,
    this.initial,
    required this.store,
    required this.onComplete,
  });
  @override
  State<SetupPage> createState() => _SetupState();
}

class _SetupState extends State<SetupPage> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  int step = 0;
  bool saving = false;
  bool photoBusy = false;
  String? carPhoto;
  String fuel = 'Benzina';
  DateTime? review, service, insurance, tax;
  TextEditingController field(String key) =>
      fields.putIfAbsent(key, () => TextEditingController());
  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    carPhoto = p?.carPhoto;
    final values = {
      'Nome': p?.name ?? '',
      'Marca': p?.brand ?? '',
      'Modello': p?.model ?? '',
      'Targa': p?.plate ?? '',
      'Anno': p?.year ?? '',
      'Chilometri attuali': p?.km.toString() ?? '',
      'Km ultimo tagliando': p?.serviceKm.toString() ?? '',
      'Intervallo tagliando (mesi)': (p?.serviceMonths ?? 12).toString(),
      'Intervallo tagliando (km)': (p?.serviceIntervalKm ?? 15000).toString(),
      'Intervallo revisione (mesi)': (p?.reviewMonths ?? 24).toString(),
    };
    values.forEach((k, v) => field(k).text = v);
    fuel = p?.fuel ?? 'Benzina';
    review = p?.lastReview;
    service = p?.lastService;
    insurance = p?.insurance;
    tax = p?.tax;
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget input(
    String name, {
    bool numeric = false,
    bool optional = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label(name.toUpperCase()),
        TextFormField(
          key: ValueKey(name),
          controller: field(name),
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return optional ? null : 'Campo obbligatorio';
            }
            if (numeric) {
              final n = int.tryParse(v);
              if (n == null || n < 0) return 'Inserisci un numero valido';
              if (name.contains('Intervallo') && n == 0) {
                return 'Deve essere maggiore di zero';
              }
              if (name == 'Anno' && (n < 1900 || n > DateTime.now().year + 1)) {
                return 'Anno non valido';
              }
              if (name == 'Km ultimo tagliando' &&
                  n > (int.tryParse(field('Chilometri attuali').text) ?? 0)) {
                return 'Supera i chilometri attuali';
              }
            }
            return null;
          },
        ),
      ],
    ),
  );
  Widget dateInput(
    String title,
    DateTime? value,
    ValueChanged<DateTime?> change, {
    bool future = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: card(
      Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                final today = DateUtils.dateOnly(DateTime.now());
                final picked = await showDatePicker(
                  context: context,
                  initialDate: value ?? today,
                  firstDate: future ? DateTime(2000) : DateTime(1900),
                  lastDate: future ? DateTime(2100) : today,
                );
                if (picked != null) setState(() => change(picked));
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    value == null
                        ? 'Non indicata · tocca per scegliere'
                        : dateText(value),
                    style: const TextStyle(color: muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          if (value != null)
            IconButton(
              tooltip: 'Cancella $title',
              onPressed: () => setState(() => change(null)),
              icon: const Icon(Icons.close, size: 18),
            )
          else
            const Icon(Icons.calendar_month_outlined, color: coral),
        ],
      ),
    ),
  );
  Future<void> next() async {
    if (!form.currentState!.validate()) return;
    if (step < 2) {
      setState(() => step++);
      return;
    }
    setState(() => saving = true);
    final p = GarageProfile(
      name: field('Nome').text.trim(),
      brand: field('Marca').text.trim(),
      model: field('Modello').text.trim(),
      plate: field('Targa').text.trim().toUpperCase(),
      year: field('Anno').text,
      fuel: fuel,
      km: int.parse(field('Chilometri attuali').text),
      serviceKm: int.tryParse(field('Km ultimo tagliando').text) ?? 0,
      serviceMonths: int.parse(field('Intervallo tagliando (mesi)').text),
      serviceIntervalKm: int.parse(field('Intervallo tagliando (km)').text),
      reviewMonths: int.parse(field('Intervallo revisione (mesi)').text),
      lastReview: review,
      lastService: service,
      insurance: insurance,
      tax: tax,
      carPhoto: carPhoto,
      avatarPhoto: widget.initial?.avatarPhoto,
    );
    try {
      await widget.store.save('local', p);
      if (mounted) widget.onComplete(p);
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        notice(context, 'Salvataggio non riuscito. Riprova.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving && !photoBusy,
    child: Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: form,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Logo(size: 48),
                  const SizedBox(height: 24),
                  Text(
                    widget.initial == null
                        ? 'Configura il tuo garage'
                        : 'Aggiorna il tuo garage',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Passaggio ${step + 1} di 3',
                    style: const TextStyle(color: muted),
                  ),
                  const SizedBox(height: 24),
                  if (step == 0) ...[
                    PhotoEditor(
                      value: carPhoto,
                      store: widget.store,
                      enabled: !saving,
                      label: 'Scegli foto auto',
                      onBusy: (busy) => setState(() => photoBusy = busy),
                      onChanged: (value) => setState(() => carPhoto = value),
                    ),
                    input('Nome'),
                    input('Marca'),
                    input('Modello'),
                    input('Targa'),
                    input('Anno', numeric: true),
                    input('Chilometri attuali', numeric: true),
                    DropdownButtonFormField<String>(
                      initialValue: fuel,
                      decoration: const InputDecoration(
                        labelText: 'Alimentazione',
                      ),
                      items: ['Benzina', 'Diesel', 'Ibrida', 'Elettrica']
                          .map(
                            (f) => DropdownMenuItem(value: f, child: Text(f)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => fuel = v!),
                    ),
                  ],
                  if (step == 1) ...[
                    const Text(
                      'Inserisci ultima revisione e ultimo tagliando. Se non conosci una data, puoi lasciarla vuota.',
                      style: TextStyle(color: muted),
                    ),
                    const SizedBox(height: 16),
                    dateInput('Ultima revisione', review, (v) => review = v),
                    input('Intervallo revisione (mesi)', numeric: true),
                    dateInput('Ultimo tagliando', service, (v) => service = v),
                    input(
                      'Km ultimo tagliando',
                      numeric: true,
                      optional: service == null,
                    ),
                    input('Intervallo tagliando (mesi)', numeric: true),
                    input('Intervallo tagliando (km)', numeric: true),
                    const Text(
                      'Conferma gli intervalli con i documenti del veicolo e il piano di manutenzione del costruttore.',
                      style: TextStyle(color: muted),
                    ),
                  ],
                  if (step == 2) ...[
                    dateInput(
                      'Scadenza assicurazione',
                      insurance,
                      (v) => insurance = v,
                      future: true,
                    ),
                    dateInput(
                      'Scadenza bollo',
                      tax,
                      (v) => tax = v,
                      future: true,
                    ),
                    Text(
                      widget.store.remote
                          ? 'Dati salvati nel tuo account online. Le date sconosciute non generano scadenze.'
                          : 'Dati salvati su questo dispositivo. Le date sconosciute non generano scadenze.',
                      style: const TextStyle(color: muted),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (step > 0)
                    TextButton(
                      onPressed: saving || photoBusy
                          ? null
                          : () => setState(() => step--),
                      child: const Text('Indietro'),
                    ),
                  FilledButton(
                    onPressed: saving || photoBusy ? null : next,
                    child: Text(
                      saving
                          ? 'Salvataggio…'
                          : step == 2
                          ? 'Salva il mio garage'
                          : 'Continua',
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
