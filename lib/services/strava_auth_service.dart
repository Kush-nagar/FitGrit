/// Strava authentication service using OAuth 2.0
/// Handles authentication flow, token storage, and token refresh
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

class StravaAuthService {
  // Strava API credentials from https://www.strava.com/settings/api
  static const String clientId = '192689';
  static const String clientSecret = 'df76a4b8de7ced04bd3ad7094069cfd485f6bfcc';
  static const String redirectUrl = 'presapp://strava/callback';

  final _storage = const FlutterSecureStorage();
  late final Dio _dio;

  static const String _tokenUrl = 'https://www.strava.com/oauth/token';
  static const String _authUrl = 'https://www.strava.com/oauth/authorize';

  // Storage keys
  static const String _accessTokenKey = 'strava_access_token';
  static const String _refreshTokenKey = 'strava_refresh_token';
  static const String _expiresAtKey = 'strava_expires_at';
  static const String _athleteIdKey = 'strava_athlete_id';  

  StravaAuthService() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ));
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null;
  }

  /// Get current access token
  Future<String?> getAccessToken() async {
    final expiresAtStr = await _storage.read(key: _expiresAtKey);

    if (expiresAtStr != null) {
      final expiresAt = int.tryParse(expiresAtStr) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // If token is expired, refresh it
      if (expiresAt <= now) {
        await refreshToken();
      }
    }

    return await _storage.read(key: _accessTokenKey);
  }

  /// Get athlete ID
  Future<String?> getAthleteId() async {
    return await _storage.read(key: _athleteIdKey);
  }

  /// Start OAuth authentication flow
  Future<bool> authenticate({
    List<String> scopes = const [
      'read',
      'activity:read',
      'activity:read_all',
    ],
  }) async {
    try {
      // Build authorization URL
      final params = {
        'client_id': clientId,
        'redirect_uri': redirectUrl,
        'response_type': 'code',
        'approval_prompt': 'auto',
        'scope': scopes.join(','),
      };

      final uri = Uri.parse(_authUrl).replace(queryParameters: params);

      // Launch browser for authorization
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        return launched;
      } else {
        throw Exception('Could not launch authorization URL');
      }
    } catch (e) {
      print('Strava authentication error: $e');
      return false;
    }
  }

  /// Complete authentication with authorization code
  Future<bool> completeAuthentication(String authorizationCode) async {
    try {
      final response = await _dio.post(
        _tokenUrl,
        data: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': authorizationCode,
          'grant_type': 'authorization_code',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        await _saveTokensFromResponse(response.data);
        return true;
      }
      return false;
    } catch (e) {
      print('Error completing authentication: $e');
      return false;
    }
  }

  /// Refresh access token
  Future<void> refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await _dio.post(
        _tokenUrl,
        data: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        await _saveTokensFromResponse(response.data);
      }
    } catch (e) {
      print('Error refreshing token: $e');
      // Token refresh failed, user needs to re-authenticate
      await logout();
      rethrow;
    }
  }

  /// Save authentication tokens from API response
  Future<void> _saveTokensFromResponse(Map<String, dynamic> data) async {
    if (data['access_token'] != null) {
      await _storage.write(
        key: _accessTokenKey,
        value: data['access_token'],
      );
    }

    if (data['refresh_token'] != null) {
      await _storage.write(
        key: _refreshTokenKey,
        value: data['refresh_token'],
      );
    }

    if (data['expires_at'] != null) {
      await _storage.write(
        key: _expiresAtKey,
        value: data['expires_at'].toString(),
      );
    }

    if (data['athlete'] != null && data['athlete']['id'] != null) {
      await _storage.write(
        key: _athleteIdKey,
        value: data['athlete']['id'].toString(),
      );
    }
  }

  /// Manually save tokens (for testing or manual setup)
  Future<void> saveManualTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresAt,
    String? athleteId,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken.trim());
    await _storage.write(key: _refreshTokenKey, value: refreshToken.trim());
    await _storage.write(key: _expiresAtKey, value: expiresAt.toString());
    if (athleteId != null) {
      await _storage.write(key: _athleteIdKey, value: athleteId);
    }
  }

  /// Quick connect with tokens from Strava API settings page
  /// This validates the tokens and refreshes if needed
  Future<bool> quickConnectWithTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      print('Starting quick connect...');

      // Calculate expiration time (default to current time to force refresh)
      final expiresAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Save the tokens
      await saveManualTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
      );

      print('Tokens saved, attempting refresh...');

      // Immediately try to refresh to get fresh tokens and validate
      // Use a timeout to prevent hanging
      await this.refreshToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Token refresh timed out after 10 seconds');
        },
      );

      print('Token refresh successful!');

      return true;
    } catch (e) {
      print('Quick connect error: $e');
      await logout();
      return false;
    }
  }

  /// Logout and clear stored tokens
  Future<void> logout() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiresAtKey);
    await _storage.delete(key: _athleteIdKey);
  }
}
