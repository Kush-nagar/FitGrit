/// Running History Screen
/// Displays list of running activities from Strava
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../services/strava_auth_service.dart';
import '../../services/strava_service.dart';
import '../../services/deep_link_service.dart';
import '../../models/strava_activity.dart';

class RunningHistoryScreen extends StatefulWidget {
  const RunningHistoryScreen({super.key});

  @override
  State<RunningHistoryScreen> createState() => _RunningHistoryScreenState();
}

class _RunningHistoryScreenState extends State<RunningHistoryScreen> {
  final _authService = StravaAuthService();
  late final StravaService _stravaService;
  late final DeepLinkService _deepLinkService;
  StreamSubscription? _authSubscription;

  bool _isLoading = true;
  bool _isAuthenticated = false;
  List<StravaActivity> _activities = [];
  String? _errorMessage;
  StravaAthleteStats? _stats;

  // Rate limiting
  DateTime? _lastRefreshTime;
  static const _minRefreshInterval =
      Duration(minutes: 2); // Minimum 2 minutes between refreshes
  int _requestCount = 0;
  DateTime? _requestCountResetTime;

  @override
  void initState() {
    super.initState();
    _stravaService = StravaService(_authService);
    _deepLinkService = DeepLinkService(_authService);
    _setupDeepLinkListener();
    _checkAuthAndLoadData();
  }

  void _setupDeepLinkListener() {
    _authSubscription = _deepLinkService.startAuthListener().listen((success) {
      if (success) {
        // Authentication successful, reload data
        _checkAuthAndLoadData();
      } else {
        // Authentication failed
        setState(() {
          _errorMessage = 'Failed to connect to Strava';
          _isLoading = false;
        });
      }
    });
  }

  void _checkAndResetRequestCount() {
    final now = DateTime.now();
    if (_requestCountResetTime == null ||
        now.difference(_requestCountResetTime!) > const Duration(minutes: 15)) {
      _requestCount = 0;
      _requestCountResetTime = now;
    }
  }

  String _getTimeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _deepLinkService.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndLoadData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isAuth = await _authService.isAuthenticated();
      setState(() => _isAuthenticated = isAuth);

      if (isAuth) {
        // Check if we can refresh (rate limiting)
        if (!forceRefresh && _lastRefreshTime != null) {
          final timeSinceRefresh = DateTime.now().difference(_lastRefreshTime!);
          if (timeSinceRefresh < _minRefreshInterval) {
            final waitTime = _minRefreshInterval - timeSinceRefresh;
            setState(() {
              _isLoading = false;
              _errorMessage =
                  'Please wait ${waitTime.inSeconds} seconds before refreshing again.\n'
                  'This prevents hitting Strava\'s rate limits.';
            });
            return;
          }
        }

        // Check request count (max 10 per 15 minutes)
        _checkAndResetRequestCount();
        if (_requestCount >= 10) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Too many requests. Please wait 15 minutes before trying again.\n'
                'This prevents hitting Strava\'s rate limit of 100 requests per 15 minutes.';
          });
          return;
        }

        _requestCount++;
        await _loadActivities();
        await _loadStats();
        _lastRefreshTime = DateTime.now();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadActivities() async {
    try {
      final activities = await _stravaService.getActivities(perPage: 30);
      setState(() {
        _activities = activities;
      });
    } catch (e) {
      setState(() {
        if (e.toString().contains('429')) {
          _errorMessage = 'Rate limit exceeded. Strava allows:\n'
              '• 100 requests per 15 minutes\n'
              '• 1,000 requests per day\n\n'
              'Please wait a few minutes and try again.';
        } else if (e.toString().contains('401')) {
          _errorMessage = 'Authentication failed. Please reconnect to Strava.';
        } else {
          _errorMessage = 'Error loading activities: $e';
        }
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _stravaService.getAthleteStats();
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      // Don't show stats errors prominently, just log them
      if (e.toString().contains('429')) {
        print('Rate limit hit while loading stats');
      } else {
        print('Error loading stats: $e');
      }
    }
  }

  Future<void> _handleConnect() async {
    // Show simplified dialog with manual token entry as primary option
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect to Strava'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose how to connect to Strava:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '📋 Manual Token Entry (Recommended)',
              style: TextStyle(fontSize: 14),
            ),
            Text(
              'Enter tokens from Strava API settings page',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 12),
            Text(
              '🌐 OAuth Browser Flow',
              style: TextStyle(fontSize: 14),
            ),
            Text(
              'Authorize through browser (requires real device)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'oauth'),
            child: const Text('OAuth'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'manual'),
            child: const Text('Manual Entry'),
          ),
        ],
      ),
    );

    if (choice == 'manual') {
      _showManualTokenDialog();
    } else if (choice == 'oauth') {
      _startOAuthFlow();
    }
  }

  Future<void> _startOAuthFlow() async {
    // Start OAuth flow
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('OAuth Authorization'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You will be redirected to Strava to authorize access. '
              'After authorization, you will be automatically returned to the app.',
            ),
            SizedBox(height: 12),
            Text(
              'Note: OAuth requires a real device or emulator with browser support.',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Start authentication
    final launched = await _authService.authenticate();

    if (!launched) {
      // URL launch failed (emulator without browser)
      if (mounted) {
        final useManual = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Browser Not Available'),
            content: const Text(
              'Could not open browser for Strava authorization. '
              'This is common on emulators.\n\n'
              'Would you like to use manual token entry instead?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Manual Entry'),
              ),
            ],
          ),
        );

        if (useManual == true) {
          _showManualTokenDialog();
        }
      }
      return;
    }

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Waiting for authorization...'),
              SizedBox(height: 8),
              Text(
                'Complete the authorization in your browser, '
                'then return to the app.',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Wait a bit and then check authentication
    await Future.delayed(const Duration(seconds: 2));

    // Close loading dialog
    if (mounted) Navigator.pop(context);

    // Check if authentication succeeded
    _checkAuthAndLoadData();
  }

  Future<void> _showManualTokenDialog() async {
    final accessTokenController = TextEditingController();
    final refreshTokenController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Strava Tokens'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 20, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'How to get your tokens:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '⚠️ The default tokens have wrong scope!',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '1. Click "Copy OAuth Link" button below',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '2. Paste link in browser and authorize',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '3. Get code from URL (after redirect)',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '4. Exchange code for tokens (see guide)',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              const oauthUrl =
                                  'https://www.strava.com/oauth/authorize?client_id=192689&response_type=code&redirect_uri=http://localhost&approval_prompt=force&scope=read,activity:read,activity:read_all';
                              Clipboard.setData(
                                  const ClipboardData(text: oauthUrl));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'OAuth link copied! Paste in browser to authorize.'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade700,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.link,
                                      size: 14, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Copy OAuth Link',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: accessTokenController,
                decoration: const InputDecoration(
                  labelText: 'Access Token *',
                  border: OutlineInputBorder(),
                  hintText: 'Paste your access token here',
                  helperText: 'Required',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: refreshTokenController,
                decoration: const InputDecoration(
                  labelText: 'Refresh Token *',
                  border: OutlineInputBorder(),
                  hintText: 'Paste your refresh token here',
                  helperText: 'Required',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final accessToken = accessTokenController.text.trim();
              final refreshToken = refreshTokenController.text.trim();

              if (accessToken.isEmpty || refreshToken.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Both tokens are required'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              // Show connecting dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Connecting to Strava...'),
                      SizedBox(height: 8),
                      Text(
                        'Validating and refreshing your tokens',
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );

              try {
                // Use quick connect which validates and refreshes tokens
                final success = await _authService
                    .quickConnectWithTokens(
                  accessToken: accessToken,
                  refreshToken: refreshToken,
                )
                    .timeout(
                  const Duration(seconds: 15),
                  onTimeout: () {
                    return false;
                  },
                );

                // Close dialog safely
                if (mounted && Navigator.canPop(context)) {
                  Navigator.pop(context); // Close connecting dialog
                }

                // Show result
                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Connected to Strava successfully!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                    _checkAuthAndLoadData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Failed to connect. Check your tokens and internet connection.'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                }
              } catch (e) {
                // Close dialog safely
                if (mounted && Navigator.canPop(context)) {
                  Navigator.pop(context); // Close connecting dialog
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: Check tokens'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDisconnect() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Strava'),
        content: const Text(
          'Are you sure you want to disconnect your Strava account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      _checkAuthAndLoadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        variant: CustomAppBarVariant.standard,
        title: 'Running',
        centerTitle: false,
        actions: [
          if (_isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleDisconnect,
              tooltip: 'Disconnect Strava',
            ),
        ],
      ),
      body: _buildBody(theme),
      bottomNavigationBar: CustomBottomBar(
        currentRoute: '/running-history-screen',
        onNavigate: (route) {
          if (route != '/running-history-screen') {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorView(theme);
    }

    if (!_isAuthenticated) {
      return _buildConnectView(theme);
    }

    return _buildActivitiesView(theme);
  }

  Widget _buildConnectView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_run,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Connect to Strava',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'View all your running activities, track your progress, and analyze your performance.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _handleConnect,
              icon: const Icon(Icons.link),
              label: const Text('Connect Strava Account'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _checkAuthAndLoadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesView(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () => _checkAuthAndLoadData(forceRefresh: true),
      child: CustomScrollView(
        slivers: [
          if (_stats != null) _buildStatsSection(theme),
          if (_activities.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No running activities found',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final activity = _activities[index];
                    return _buildActivityCard(activity, theme);
                  },
                  childCount: _activities.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(ThemeData theme) {
    final stats = _stats!;
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Stats',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_lastRefreshTime != null)
                  Text(
                    'Updated ${_getTimeAgo(_lastRefreshTime!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (stats.ytdRunTotals != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'This Year',
                    '${stats.ytdRunTotals!.distanceKm} km',
                    Icons.calendar_today,
                    theme,
                  ),
                  _buildStatItem(
                    'Runs',
                    '${stats.ytdRunTotals!.count}',
                    Icons.directions_run,
                    theme,
                  ),
                  _buildStatItem(
                    'Elevation',
                    '${stats.ytdRunTotals!.elevationGain.toInt()} m',
                    Icons.terrain,
                    theme,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(StravaActivity activity, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/running-details-screen',
            arguments: activity.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.directions_run,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${activity.dateFormatted} • ${activity.timeFormatted}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric(
                    'Distance',
                    '${activity.distanceKm} km',
                    Icons.straighten,
                    theme,
                  ),
                  _buildMetric(
                    'Duration',
                    activity.durationFormatted,
                    Icons.timer,
                    theme,
                  ),
                  _buildMetric(
                    'Pace',
                    '${activity.paceMinPerKm}/km',
                    Icons.speed,
                    theme,
                  ),
                ],
              ),
              if (activity.totalElevationGain != null &&
                  activity.totalElevationGain! > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.terrain,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Elevation: ${activity.totalElevationGain!.toInt()} m',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
