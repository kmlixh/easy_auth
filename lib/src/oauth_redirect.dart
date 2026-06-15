import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;

/// OAuth Authorization Code + PKCE flow for Flutter consumers.
///
/// Used by `EasyAuth.loginWithRedirect`. The IdP this targets is
/// anylogin's Stage-1 /oauth endpoints (see DEVELOPMENT_PLAN.md). The flow
/// is the standard OAuth 2.0 Authorization Code with PKCE (RFC 7636) — no
/// SDK-specific custom protocol.
///
/// Why this matters: the existing `loginWithSms` / `loginWithEmail` /
/// `loginWithGoogle` paths talk directly to anylogin's /login/directLogin
/// and store an opaque token. They work end-to-end inside the Flutter app
/// but the resulting opaque token can't be presented to OAuth-protected
/// resources on consumer backends. `loginWithRedirect` produces a real
/// OAuth access token (JWT) that authing.AuthMiddleware on those backends
/// will accept transparently.

class OAuthRedirectFlow {
  /// IdP base URL, e.g. "https://auth.janyee.com". No trailing slash.
  final String issuerBaseUrl;

  /// OAuth client_id registered via adminFront's OAuth Client management
  /// page (Stage 3).
  final String clientId;

  /// Redirect URI registered for this client. For Flutter we strongly
  /// recommend an in-app URL (e.g. "myapp://oauth/cb") so the webview
  /// can intercept it without ever leaving the app — see [start].
  final String redirectUri;

  final http.Client _http;

  OAuthRedirectFlow({
    required this.issuerBaseUrl,
    required this.clientId,
    required this.redirectUri,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  /// Opens an in-app webview, drives the user through /oauth/authorize, and
  /// returns the resulting access_token + refresh_token + id_token (when
  /// scope contains openid).
  ///
  /// Throws on any error (cancelled, network, code exchange failure).
  Future<OAuthRedirectResult> start({
    required BuildContext context,
    String scope = 'openid profile email user_data',
    String? tenantId,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final pkce = _PkcePair.generate();
    final state = _randomUrlSafe(24);

    final authorizeUri = Uri.parse('$issuerBaseUrl/oauth/authorize').replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'scope': scope,
        'state': state,
        'code_challenge': pkce.challenge,
        'code_challenge_method': 'S256',
        if (tenantId != null) 'tenant_id': tenantId,
      },
    );

    final completer = Completer<_RedirectCapture>();
    Timer? timer;

    // ignore: use_build_context_synchronously
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(8),
          child: SizedBox(
            width: MediaQuery.of(dialogContext).size.width,
            height: MediaQuery.of(dialogContext).size.height * 0.85,
            child: Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(authorizeUri.toString())),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    incognito: true, // never persist the IdP cookies inside the webview
                    sharedCookiesEnabled: false,
                  ),
                  shouldOverrideUrlLoading: (controller, action) async {
                    final url = action.request.url?.toString() ?? '';
                    if (_matchesRedirectUri(url)) {
                      final cap = _RedirectCapture.parse(url, expectedState: state);
                      if (!completer.isCompleted) {
                        completer.complete(cap);
                      }
                      // Close the dialog from outside this callback to
                      // avoid double-pop issues.
                      Future.microtask(() {
                        if (Navigator.canPop(dialogContext)) {
                          Navigator.of(dialogContext).pop();
                        }
                      });
                      return NavigationActionPolicy.CANCEL;
                    }
                    return NavigationActionPolicy.ALLOW;
                  },
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      if (!completer.isCompleted) {
                        completer.completeError(StateError('user cancelled'));
                      }
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('OAuth flow timed out', timeout));
      }
    });

    final cap = await completer.future.whenComplete(() => timer?.cancel());

    return _exchangeCode(code: cap.code, verifier: pkce.verifier);
  }

  bool _matchesRedirectUri(String url) {
    if (url.isEmpty) return false;
    if (!url.startsWith(redirectUri)) return false;
    // Either exact equality (http://...com/cb) or with query/fragment
    return url.length == redirectUri.length ||
        url[redirectUri.length] == '?' ||
        url[redirectUri.length] == '#' ||
        url[redirectUri.length] == '/';
  }

  Future<OAuthRedirectResult> _exchangeCode({
    required String code,
    required String verifier,
  }) async {
    final tokenUri = Uri.parse('$issuerBaseUrl/oauth/token');
    final resp = await _http.post(
      tokenUri,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'code_verifier': verifier,
      },
    );
    if (resp.statusCode != 200) {
      throw OAuthRedirectError(
        'token exchange failed: ${resp.statusCode} ${resp.body}',
      );
    }
    final m = jsonDecode(resp.body) as Map<String, dynamic>;
    return OAuthRedirectResult(
      accessToken: m['access_token'] as String,
      refreshToken: m['refresh_token'] as String?,
      idToken: m['id_token'] as String?,
      tokenType: (m['token_type'] as String?) ?? 'Bearer',
      expiresIn: (m['expires_in'] as num?)?.toInt() ?? 3600,
      scope: m['scope'] as String?,
    );
  }

  void close() => _http.close();
}

/// PKCE verifier+challenge pair (RFC 7636).
class _PkcePair {
  final String verifier;
  final String challenge;

  _PkcePair._(this.verifier, this.challenge);

  factory _PkcePair.generate() {
    // 32 random bytes → 43-char base64url verifier.
    final v = _randomUrlSafe(43);
    final digest = sha256.convert(utf8.encode(v));
    final c = base64UrlEncode(digest.bytes).replaceAll('=', '');
    return _PkcePair._(v, c);
  }
}

/// Returns `length` URL-safe characters from the base64url alphabet.
/// Uses `Random.secure()` so it's suitable for cryptographic identifiers.
String _randomUrlSafe(int length) {
  const alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
  final r = Random.secure();
  final buf = StringBuffer();
  for (var i = 0; i < length; i++) {
    buf.writeCharCode(alphabet.codeUnitAt(r.nextInt(alphabet.length)));
  }
  return buf.toString();
}

class _RedirectCapture {
  final String code;
  final String state;
  _RedirectCapture(this.code, this.state);

  factory _RedirectCapture.parse(String url, {required String expectedState}) {
    final uri = Uri.parse(url);
    final params = {...uri.queryParameters, ...uri.fragment.isNotEmpty ? Uri.splitQueryString(uri.fragment) : <String, String>{}};
    final err = params['error'];
    if (err != null) {
      throw OAuthRedirectError(
        'IdP returned error: $err — ${params['error_description'] ?? ''}',
      );
    }
    final code = params['code'];
    final state = params['state'];
    if (code == null || code.isEmpty) {
      throw OAuthRedirectError('redirect missing `code`');
    }
    if (state == null || state != expectedState) {
      throw OAuthRedirectError(
        'state mismatch — possible CSRF (got $state, want $expectedState)',
      );
    }
    return _RedirectCapture(code, state!);
  }
}

/// Token bundle returned by [OAuthRedirectFlow.start].
class OAuthRedirectResult {
  final String accessToken;
  final String? refreshToken;
  final String? idToken;
  final String tokenType;
  final int expiresIn;
  final String? scope;

  OAuthRedirectResult({
    required this.accessToken,
    required this.refreshToken,
    required this.idToken,
    required this.tokenType,
    required this.expiresIn,
    required this.scope,
  });
}

class OAuthRedirectError implements Exception {
  final String message;
  OAuthRedirectError(this.message);
  @override
  String toString() => 'OAuthRedirectError: $message';
}
