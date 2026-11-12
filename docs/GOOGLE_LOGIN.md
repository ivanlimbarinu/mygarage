# Accedi con Google

Premi **Continua con Google** nella schermata di accesso o registrazione. Il browser di sistema permette di scegliere l'account; Supabase verifica l'identità e riapre MyGarage tramite `mygarage://login-callback/`. Il client completa lo scambio PKCE: il garage si apre solo dopo una sessione valida. Non serve compilare email e password prima di usare il pulsante.

## Configurazione del servizio

- Google Cloud: configura consenso OAuth e client **Web application**.
- Authorized redirect URI Google: `https://bqmwafgilnjpjowwprpb.supabase.co/auth/v1/callback` (controllalo nel provider Google di Supabase).
- Supabase → Authentication → Providers → Google: abilita e inserisci Client ID e Client secret. Il secret resta in Supabase, non nell'app.
- Supabase → Authentication → URL Configuration: mantieni `mygarage://login-callback/` nei Redirect URLs.
- Se Google è in Testing, aggiungi gli account ai test users.

Il provider risulta abilitato alla verifica del 12 novembre 2026. Il consenso Google e la configurazione Cloud devono ancora essere provati con un account sul dispositivo.

Email/password restano disponibili e Confirm Email rimane attivo. Il primo accesso a un account senza profilo apre la configurazione; un account esistente recupera il suo garage. Non viene eseguita una fusione manuale dei dati degli account.

## Verifica

Avvia `flutter run --dart-define-from-file=config/supabase.json`. Premi Continua con Google, scegli l'account e verifica ritorno nell'app, riavvio e logout. Se annulli nel browser, puoi riprovare senza restare bloccato. I test verificano provider, callback, PKCE, apertura del browser e mancata apertura; non sostituiscono il consenso reale su Android/iOS.

Fonti: https://supabase.com/docs/reference/dart/auth-signinwithoauth e https://supabase.com/docs/guides/auth/social-sign-in/auth-google.
