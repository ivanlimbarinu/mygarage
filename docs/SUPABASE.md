# Attivare il backend Supabase

Il client Flutter implementa registrazione, login, conferma email, recupero password, ripristino sessione, logout e dati personali online. Senza configurazione rimangono disponibili il garage locale e la demo.

1. Apri Supabase → SQL Editor. Esegui il contenuto di `supabase/migrations/202611120001_garage.sql`. Lo script può essere rieseguito e conserva le righe presenti. Se hai aggiunto altre policy permissive, controllale: le policy PostgreSQL si combinano e una policy aggiuntiva troppo aperta può consentire accessi indesiderati.
2. In Authentication → Providers abilita Email e conferma email. Configura SMTP per inviare le email.
3. In Authentication → URL Configuration imposta Site URL e un Redirect URL a `mygarage://login-callback/`. Per template email e verifica completa vedi [EMAIL_CONFIRMATION.md](EMAIL_CONFIRMATION.md). Android e iOS hanno il collegamento configurato. Per web imposta invece l'URL HTTPS dell'app anche in AUTH_REDIRECT_URL e autorizzalo nel dashboard. Il ritorno dalle email su desktop richiede la registrazione del protocollo nel pacchetto distribuito; il normale login email/password non richiede callback.
4. Copia `config/supabase.example.json` in `config/supabase.json`. Inserisci Project URL e chiave pubblica publishable (oppure anon legacy) dal pannello Connect/API. Non usare service_role o chiavi segrete. Il file personale è ignorato da Git; la chiave pubblica resta comunque visibile nell'app e la protezione dipende dalle policy del database.
5. Esegui:

```powershell
flutter pub get
flutter run --dart-define-from-file=config/supabase.json
```

Su Windows attiva la Modalità sviluppatore nelle impostazioni di sistema se Flutter segnala che manca il supporto ai symlink.

## Dati salvati

`garage_profiles` contiene la configurazione iniziale. `garage_states` conserva auto, chilometri, scadenze e totali di carburante, manutenzione e rifornimenti. Ogni riga appartiene all'utente autenticato; le policy RLS impediscono accessi tra account. I dati locali precedenti non vengono importati automaticamente.

Se un salvataggio fallisce appare un avviso con Riprova: completa il salvataggio prima di chiudere o uscire. Non esiste una coda offline persistente. Su due dispositivi che modificano contemporaneamente il garage prevale l'ultimo salvataggio dell'intero stato. Grafici e alcuni indicatori restano illustrativi: non è implementato uno storico delle singole spese.

## Verifica reale

Registra due account, conferma le email e inserisci dati diversi. Verifica ripristino dopo riavvio, aggiornamenti, rifornimento, manutenzione e logout. Con il token del secondo account prova a leggere/modificare la riga del primo: letture vuote e scritture negate sono il risultato atteso. Verifica password errata, recupero password e rete assente.

I test Flutter includono richieste simulate al client Supabase e propagazione degli errori. Non sostituiscono la verifica delle policy nel tuo progetto. Finché URL, chiave e migrazione non sono configurati, il servizio online non è attivo.

Documentazione: https://supabase.com/docs/guides/getting-started/quickstarts/flutter e https://supabase.com/docs/guides/auth/passwords.
