import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'main.dart';
import 'onboarding.dart';
import 'services/backend.dart';
import 'services/auth_config.dart';

class AuthPage extends StatefulWidget {
  final SupabaseClient? client;
  const AuthPage({super.key, this.client});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  SupabaseClient get client => widget.client ?? Backend.client;
  final email = TextEditingController(), password = TextEditingController();
  StreamSubscription<AuthState>? subscription;
  bool busy = false, register = false, recovery = false;
  bool googleLaunching = false;
  String? message;
  @override
  void initState() {
    super.initState();
    subscription = client.auth.onAuthStateChange.listen(
      (event) {
        if (mounted &&
            (event.event == AuthChangeEvent.signedOut ||
                event.event == AuthChangeEvent.passwordRecovery)) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        if (mounted) {
          setState(() {
            if (event.event == AuthChangeEvent.passwordRecovery) {
              recovery = true;
            } else if (event.event == AuthChangeEvent.signedOut) {
              recovery = false;
              register = false;
            } else if (event.event == AuthChangeEvent.signedIn) {
              recovery = false;
              register = false;
              message = null;
            }
          });
        }
      },
      onError: (Object _) {
        if (mounted) {
          setState(
            () => message = 'Accesso non completato o collegamento scaduto. Riprova con Google oppure accedi con email e password. Se non hai ancora confermato l’email, richiedi una nuova conferma.',
          );
        }
      },
    );
  }

  Future<void> signInWithGoogle() async {
    if (busy) return;
    setState(() {
      busy = true;
      googleLaunching = true;
      message = null;
    });
    try {
      final opened = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: AuthConfig.redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
        queryParams: const {'prompt': 'select_account'},
      );
      if (!opened && mounted) {
        setState(
          () => message = 'Impossibile aprire Google. Controlla che sia disponibile un browser e riprova.',
        );
      }
    } on AuthException catch (_) {
      if (mounted) {
        setState(
          () => message =
              'Accesso Google non disponibile. Riprova o usa email e password.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message =
              'Impossibile avviare Google. Controlla la connessione e riprova.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          googleLaunching = false;
        });
      }
    }
  }

  Future<void> submit({bool reset = false, bool resend = false}) async {
    if (busy) return;
    if (!recovery && !RegExp(r'^\S+@\S+\.\S+$').hasMatch(email.text.trim())) {
      setState(() => message = 'Inserisci una email valida.');
      return;
    }
    final minimumLength = register || recovery ? 8 : 6;
    if (!reset && !resend && password.text.length < minimumLength) {
      setState(
        () => message =
            'Inserisci almeno $minimumLength caratteri per la password.',
      );
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final auth = client.auth;
      if (resend) {
        await auth.resend(
          type: OtpType.signup,
          email: email.text.trim(),
          emailRedirectTo: AuthConfig.redirectUrl,
        );
        if (mounted) {
          setState(
            () => message = 'Se l’indirizzo è in attesa di conferma, riceverai una nuova email. Usa il collegamento più recente.',
          );
        }
      } else if (recovery) {
        await auth.updateUser(UserAttributes(password: password.text));
        await auth.signOut();
        if (mounted) {
          setState(() {
            recovery = false;
            message = 'Password aggiornata. Accedi nuovamente.';
          });
        }
      } else if (reset) {
        await auth.resetPasswordForEmail(
          email.text.trim(),
          redirectTo: AuthConfig.redirectUrl,
        );
        if (mounted) {
          setState(
            () => message = 'Se l’indirizzo è registrato riceverai una email con le istruzioni.',
          );
        }
      } else if (register) {
        await auth.signUp(
          email: email.text.trim(),
          password: password.text,
          emailRedirectTo: AuthConfig.redirectUrl,
        );
        if (mounted) {
          setState(() {
            register = false;
            message = 'Controlla la tua email e premi Conferma email. Il collegamento riaprirà MyGarage. Se hai già confermato, accedi con email e password.';
          });
        }
      } else {
        await auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
      password.clear();
    } on AuthException catch (e) {
      if (mounted) {
        setState(
          () => message = e.code == 'email_not_confirmed'
              ? 'Conferma prima il tuo indirizzo tramite l’email ricevuta. Poi accedi oppure richiedi una nuova email di conferma.'
              : e.message,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => message = 'Connessione non disponibile. Riprova.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = client.auth.currentSession;
    final user = session?.user;
    if (user != null && user.emailConfirmedAt != null && !recovery) {
      return PersonalGarageGate(key: ValueKey(user.id), remote: true);
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Logo(),
                  const SizedBox(height: 24),
                  Text(
                    recovery
                        ? 'Nuova password'
                        : register
                        ? 'Crea account'
                        : 'Accedi al tuo garage',
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(height: 24),
                  if (!recovery) ...[
                    OutlinedButton.icon(
                      key: const ValueKey('google_sign_in'),
                      onPressed: busy ? null : signInWithGoogle,
                      icon: const Icon(Icons.account_circle_outlined),
                      label: Text(
                        googleLaunching
                            ? 'Apertura Google…'
                            : 'Continua con Google',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(child: Text('oppure usa email e password')),
                    const SizedBox(height: 16),
                  ],
                  if (!recovery)
                    TextField(
                      controller: email,
                      enabled: !busy,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: password,
                    enabled: !busy,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password (almeno 8 caratteri)',
                    ),
                  ),
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(message!, semanticsLabel: message),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: busy ? null : () => submit(),
                    child: Text(
                      busy
                          ? 'Attendi…'
                          : recovery
                          ? 'Salva password'
                          : register
                          ? 'Registrati'
                          : 'Accedi',
                    ),
                  ),
                  if (!recovery) ...[
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() {
                              register = !register;
                              message = null;
                            }),
                      child: Text(
                        register
                            ? 'Hai già un account? Accedi'
                            : 'Crea un account',
                      ),
                    ),
                    TextButton(
                      onPressed: busy ? null : () => submit(reset: true),
                      child: const Text('Password dimenticata?'),
                    ),
                    if (!register)
                      TextButton(
                        onPressed: busy ? null : () => submit(resend: true),
                        child: const Text('Invia di nuovo la conferma email'),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
