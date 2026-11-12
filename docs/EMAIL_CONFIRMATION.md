# Conferma email Android e iOS

Il callback mobile è `mygarage://login-callback/`, inclusa la barra finale. Il client lo invia in `signUp(emailRedirectTo: ...)`, reinvio conferma e recupero password. Android registra scheme, host e path; iOS registra lo scheme. Il gestore standard Flutter è disabilitato per lasciare al client Supabase la gestione del link, dello scambio PKCE e della sessione.

## Impostazioni richieste nel progetto Supabase

Queste impostazioni del servizio non si modificano tramite migrazioni SQL o con la chiave pubblica dell'app:

1. Authentication → URL Configuration → **Site URL**: `mygarage://login-callback/`. Rimuovi il fallback `http://localhost:3000` per questo progetto mobile.
2. **Redirect URLs**: aggiungi esattamente `mygarage://login-callback/`.
3. Authentication → Email → **Confirm Email**: mantienilo abilitato. La configurazione pubblica del progetto è stata verificata: `mailer_autoconfirm` è `false`.
4. Email Templates → Confirm signup: usa il link di verifica Supabase, senza sostituirlo con un semplice deep link:

```html
<a href="{{ .ConfirmationURL }}">Conferma email</a>
```

`ConfirmationURL` deve prima raggiungere Supabase per verificare il token. Supabase poi rimanda all'app tramite il callback consentito: nessuna pagina localhost o sito intermedio da implementare. Un link diretto a `SiteURL` o `RedirectTo` nel template da solo non conferma l'indirizzo.

## Comportamento e verifica

- La registrazione senza sessione mostra l'invito a controllare l'email e torna al modulo di login. La presenza di un oggetto User da signUp non implica che l'email sia confermata.
- Il client Supabase elabora automaticamente il callback. L'evento signedIn aggiorna la schermata; il garage richiede una sessione con emailConfirmedAt presente. L'app recupera anche una sessione già confermata all'avvio.
- Se il collegamento è scaduto o già utilizzato, l'app propone accesso normale o reinvio conferma. Un account già confermato può accedere con email/password senza riutilizzare il link.
- Il recupero password mantiene il proprio evento passwordRecovery e il modulo per cambiare password; non viene trattato come una normale conferma.

Ricompila e reinstalla l'app: un hot reload non aggiorna Manifest o Info.plist. Usa `flutter run --dart-define-from-file=config/supabase.json`. Richiedi una **nuova email** dopo aver cambiato URL o template: le email già inviate possono contenere il vecchio redirect.

Prova su Android e iOS con app aperta, in background e chiusa: registra un nuovo indirizzo, apri l'ultima email sullo stesso telefono e conferma; poi esci e accedi con la stessa password. Prima della conferma il login deve essere negato. Verifica anche link scaduto e reinvio. Per PKCE il flusso deve essere completato nell'installazione che ha avviato la registrazione; se la conferma viene aperta altrove, torna all'app e usa il login normale dopo la verifica.

Per provare solo l'apertura del deep link (questo **non** verifica l'email):

```sh
adb shell am start -a android.intent.action.VIEW -d "mygarage://login-callback/"
xcrun simctl openurl booted "mygarage://login-callback/"
```

Fonti: https://supabase.com/docs/guides/auth/redirect-urls e https://supabase.com/docs/guides/auth/native-mobile-deep-linking?platform=flutter.
