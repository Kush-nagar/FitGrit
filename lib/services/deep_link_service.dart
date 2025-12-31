/// Deep link service to handle Strava OAuth callbacks
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'strava_auth_service.dart';

class DeepLinkService {
  final StravaAuthService _authService;
  final _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;
  StreamController<bool>? _authController;

  DeepLinkService(this._authService);

  /// Start listening for deep links
  Stream<bool> startAuthListener() {
    _authController = StreamController<bool>.broadcast();

    // Listen for initial deep link (when app is opened from link)
    _getInitialLink();

    // Listen for deep links when app is already running
    _listenForLinks();

    return _authController!.stream;
  }

  /// Get the initial deep link if app was opened from one
  Future<void> _getInitialLink() async {
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleDeepLink(initialUri);
      }
    } catch (e) {
      print('Error getting initial link: $e');
    }
  }

  /// Listen for incoming deep links
  void _listenForLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      print('Deep link error: $err');
      _authController?.add(false);
    });
  }

  /// Handle the deep link and extract authorization code
  Future<void> _handleDeepLink(Uri uri) async {
    if (uri.scheme == 'presapp' &&
        uri.host == 'strava' &&
        uri.path == '/callback') {
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        print('Strava authorization error: $error');
        _authController?.add(false);
        return;
      }

      if (code != null) {
        // Exchange code for tokens
        final success = await _authService.completeAuthentication(code);
        _authController?.add(success);
      }
    }
  }

  /// Stop listening
  void dispose() {
    _linkSubscription?.cancel();
    _authController?.close();
  }
}
