import 'auth_api.dart';
import 'package:flutter/services.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

class PasskeyAuthService {
  PasskeyAuthService({AuthApi? authApi, PasskeyAuthenticator? authenticator})
    : _authApi = authApi ?? AuthApi(),
      _authenticator = authenticator ?? PasskeyAuthenticator();

  final AuthApi _authApi;
  final PasskeyAuthenticator _authenticator;

  Future<Map<String, dynamic>> registerPasskey({
    required String username,
  }) async {
    try {
      final options = await _authApi.beginPasskeyRegistration(
        username: username,
      );

      final request = RegisterRequestType.fromJson(options);
      final credential = await _authenticator.register(request);

      return _authApi.finishPasskeyRegistration(
        username: username,
        credential: credential.toJson(),
      );
    } catch (error) {
      throw _friendlyPasskeyError(error);
    }
  }

  Future<Map<String, dynamic>> loginWithPasskey({
    required String username,
  }) async {
    try {
      final options = await _authApi.beginPasskeyLogin(username: username);

      final request = AuthenticateRequestType.fromJson(options);
      final credential = await _authenticator.authenticate(request);

      return _authApi.finishPasskeyLogin(
        username: username,
        credential: credential.toJson(),
      );
    } catch (error) {
      throw _friendlyPasskeyError(error);
    }
  }

  Exception _friendlyPasskeyError(Object error) {
    final lower = error.toString().toLowerCase();
    final isRpIdValidationError =
        lower.contains('rp id cannot be validated') ||
        lower.contains('type_data_error') ||
        lower.contains('type_create_public_key_credential_dom_exception');

    if (error is PlatformException && isRpIdValidationError) {
      return Exception(
        'Android passkey setup failed because RP ID is not valid for this app. '
        'Use a real HTTPS domain (not localhost/IP) for WEBAUTHN_RP_ID and '
        'configure /.well-known/assetlinks.json for your Android package.',
      );
    }

    if (isRpIdValidationError) {
      return Exception(
        'Passkey RP ID validation failed. Configure a real HTTPS domain RP ID '
        '(not localhost/IP) and Android Digital Asset Links.',
      );
    }

    if (error is Exception) {
      return error;
    }

    return Exception(error.toString());
  }
}
