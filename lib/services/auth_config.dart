import 'package:flutter/foundation.dart';

class AuthConfig {
  static const mobileCallback = 'mygarage://login-callback/';

  // Mobile must match the registered native URL scheme, even when an older
  // build configuration still supplies AUTH_REDIRECT_URL.
  static String get redirectUrl => kIsWeb
      ? const String.fromEnvironment(
          'AUTH_REDIRECT_URL',
          defaultValue: mobileCallback,
        )
      : mobileCallback;
}
