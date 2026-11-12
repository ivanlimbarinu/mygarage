# MyGarage

App Flutter per il garage personale: auto e foto, scadenze di manutenzione, assicurazione e bollo, rifornimenti, tema chiaro/scuro e meteo di Torino. Autenticazione email/password e Google tramite Supabase.

## Avvio

Usa Flutter **3.47.5** (Dart 3.13.4) o una versione successiva compatibile. Per Android serve JDK 17; per compilare iOS serve macOS con Xcode oppure un servizio come MobAI Builder.

```sh
flutter pub get
flutter run --dart-define-from-file=config/supabase.public.json
```

`config/supabase.public.json` contiene esclusivamente URL e chiave client pubblica/publishable, necessaria anche nelle build remote. La chiave pubblica è progettata per essere distribuita nell'app; l'accesso ai dati è protetto dalle policy RLS. Nessuna service_role, password o chiave di firma deve essere aggiunta a questo file. Per un altro progetto copia `config/supabase.example.json` in `config/supabase.json` (ignorato da Git) e passa quel file al comando Flutter.

## GitHub Actions

Il workflow `.github/workflows/flutter.yml` esegue analisi e test, compila un APK Android debug e una app iOS per simulatore. I risultati si scaricano dagli artifact della run. L'app iOS per simulatore non è installabile su iPhone; una build per dispositivo richiede la firma configurata in MobAI/Xcode. Le build release Android hanno attualmente la firma debug del template e non sono pronte per la pubblicazione su Play Store.

## MobAI

Apri la repository con MobAI. `mobai.json` contiene i comandi Android e iOS e include la configurazione pubblica di Supabase nelle build. Seleziona una versione Flutter compatibile e configura la firma iPhone nell'app MobAI. Le credenziali di firma restano fuori da Git.

## File mantenuti ed esclusi

Sono mantenuti `lib`, `assets`, `test`, `pubspec.yaml`, `pubspec.lock`, tutte le cartelle piattaforma, wrapper Gradle, progetti Xcode, migrazioni Supabase e workflow. Flutter rigenera i file temporanei con `flutter pub get` e la build.

Sono esclusi build, cache Dart/Gradle/Kotlin, Pods, cartelle ephemeral, impostazioni locali IDE/SDK, file `.env`, configurazione Supabase personale e chiavi/certificati di firma. Non caricare SDK Flutter, Android SDK o dipendenze scaricate.

## Backend

- [Configurazione Supabase](docs/SUPABASE.md)
- [Conferma email e deep link](docs/EMAIL_CONFIRMATION.md)
- [Accesso Google](docs/GOOGLE_LOGIN.md)

Esegui le migrazioni in `supabase/migrations` nel tuo progetto Supabase. Le foto usano un bucket privato. Il meteo usa Open-Meteo per Torino senza rilevare automaticamente la posizione. Alcuni grafici restano dimostrativi e la sincronizzazione del garage usa l'ultimo stato salvato, senza una coda offline persistente.
