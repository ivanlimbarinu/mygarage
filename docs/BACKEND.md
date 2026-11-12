# Collegare il login a un backend reale

Il client Supabase e la migrazione SQL sono implementati. Per attivare il servizio segui [SUPABASE.md](SUPABASE.md). Il contratto REST seguente descrive una possibile alternativa; senza configurazione Supabase la app resta locale.

## Contratto proposto

Implementare un server HTTPS con questi endpoint:

- POST /auth/register: email e password; crea utente e invia verifica email.
- POST /auth/login: email e password; restituisce accessToken a breve durata e refreshToken ruotabile.
- POST /auth/refresh: rinnova la sessione e invalida il vecchio refresh token.
- POST /auth/logout: revoca il refresh token sul server.
- POST /auth/forgot-password: avvia recupero con risposta generica, senza rivelare se l'email esiste.
- POST /auth/reset-password: verifica token monouso con scadenza e cambia password.
- GET /me: profilo dell'utente autenticato.
- /vehicles, /vehicles/:id/refills, /vehicles/:id/deadlines, /vehicles/:id/expenses: lettura e scrittura dei dati personali.

Esempio risposta login:

```json
{"accessToken":"...","refreshToken":"...","expiresIn":900,"user":{"id":"...","name":"Ivan","email":"..."}}
```

Il server deve derivare l'identità dal token verificato e controllare il proprietario di ogni veicolo, rifornimento e scadenza. Non fidarsi di un userId inviato dal client. Salvare hash password con una libreria Argon2id mantenuta, mai password in chiaro. Prevedere rate limiting, verifica email, revoca sessioni e log senza credenziali.

## In Flutter

1. Creare AuthRepository con il client http già presente e un URL backend configurato tramite --dart-define=API_BASE_URL=https://tuo-server.example.
2. In _LoginState sostituire il messaggio del pulsante Accedi con una chiamata POST /auth/login: corpo JSON con email/password, timeout, stato di caricamento e messaggi distinti per rete e credenziali non valide. Non registrare password o token nei log.
3. Conservare l'access token in memoria e il refresh token nello storage sicuro di piattaforma con una libreria dedicata. Non usare preferenze o file in chiaro per le credenziali. Per web, progettare preferibilmente cookie HttpOnly/Secure con protezioni CSRF nel backend.
4. Navigare a GarageHomePage solo dopo la risposta valida. All'avvio tentare il ripristino sessione tramite refresh e /me; se fallisce mostrare LoginPage.
5. Inviare Authorization: Bearer <accessToken> alle API. Su 401 eseguire un solo rinnovo condiviso tra le richieste concorrenti e riprovare una volta; se fallisce cancellare la sessione.
6. Collegare Password dimenticata a /auth/forgot-password e Esci a /auth/logout, poi eliminare token e dati utente dal dispositivo.
7. Sostituire liste e contatori demo con repository collegati agli endpoint e uno storage persistente scelto per la modalità offline.

## Controlli prima del rilascio

Verificare credenziali errate, account non verificato, server offline, token scaduto, refresh revocato, logout e isolamento tra due utenti. Configurare HTTPS, CORS per eventuale Flutter web e ambienti di sviluppo/produzione separati. Nessun segreto amministrativo va incluso nell'app.
