import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'core/theme/app_theme.dart';
import 'core/design_system/tokens/app_colors.dart';
import 'core/design_system/tokens/app_typography.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'core/network/sync_manager.dart';
import 'modules/config/services/config_service.dart';
import 'modules/legal/services/legal_service.dart';
import 'modules/version/presentation/update_dialogs.dart';
import 'modules/legal/presentation/legal_acceptance_popup.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String _clientVersion = "1.0.0";
  String _loadingMessage = "Initializing system...";
  bool _showRetryButton = false;
  double _progress = 0.0;
  late DateTime _startTime;
  
  final ConfigService _configService = ConfigService();
  final LegalService _legalService = LegalService();

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    _animationController.forward();
    _startInitializationSequence();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startInitializationSequence() async {
    setState(() {
      _showRetryButton = false;
      _loadingMessage = "Resolving app version...";
      _progress = 0.15;
    });

    // 1. Resolve dynamic client version safely
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _clientVersion = packageInfo.version;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _clientVersion = "1.0.0";
        });
      }
    }

    if (mounted) {
      setState(() {
        _loadingMessage = "Loading application configuration...";
        _progress = 0.35;
      });
    }

    try {
      // 2. Fetch remote configuration (or load offline cache fallback)
      final config = await _configService.fetchAppConfig();
      
      // 3. Check for maintenance mode
      if (config.maintenanceMode) {
        if (mounted) {
          setState(() {
            _loadingMessage = config.maintenanceMessage;
          });
          _showMaintenanceDialog(config.maintenanceMessage);
        }
        return;
      }

      // 4. Evaluate version status
      if (config.versionStatus == "forceUpdate") {
        if (mounted) {
          _showForceUpdateDialog(config.androidLink, config.iosLink);
        }
        return;
      } else if (config.versionStatus == "softUpdate") {
        if (mounted) {
          await _showSoftUpdateDialog(config.androidLink, config.iosLink);
        }
      }

      // 5. Check Authentication state
      if (mounted) {
        setState(() {
          _loadingMessage = "Checking authentication...";
          _progress = 0.55;
        });
      }
      
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;

      if (authState is Authenticated) {
        final userId = authState.user.id;
        
        if (mounted) {
          setState(() {
            _loadingMessage = "Checking legal compliance...";
            _progress = 0.75;
          });
        }

        // Check legal compliance
        final acceptance = await _legalService.checkUserAcceptance(userId);
        
        final latestTerms = config.latestTermsVersion;
        final latestPrivacy = config.latestPrivacyVersion;
        final acceptedTerms = acceptance['accepted_terms_version'] ?? 0;
        final acceptedPrivacy = acceptance['accepted_privacy_version'] ?? 0;

        if (acceptedTerms < latestTerms || acceptedPrivacy < latestPrivacy) {
          // Trigger legal acceptance popup
          if (mounted) {
            _showLegalAcceptancePopup(
              userId: userId,
              latestTerms: latestTerms,
              latestPrivacy: latestPrivacy,
            );
          }
          return;
        }

        // 6. Perform background synchronization
        if (mounted) {
          setState(() {
            _loadingMessage = "Synchronizing listings data...";
            _progress = 0.90;
          });
        }

        if (SyncManager().isSyncCompleted) {
          SyncManager().performStartupSync().catchError((e) {
            // Log background refresh failures but proceed
          });
          _navigateToHome();
        } else {
          // First launch blocking synchronization
          try {
            await SyncManager().performStartupSync();
            _navigateToHome();
          } catch (syncErr) {
            // If sync fails but we have cached database records, bypass
            _navigateToHome();
          }
        }
      } else {
        // Redirect unauthenticated user to Get Started page
        _navigateToGetStarted();
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingMessage = "An error occurred during initialization.";
          _showRetryButton = true;
        });
      }
    }
  }

  Future<void> _navigateToHome() async {
    if (mounted) {
      setState(() {
        _progress = 1.0;
      });
    }
    if (!mounted) return;
    await _ensureMinSplashDelay();
    if (!mounted) return;
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    if (from != null && from.isNotEmpty) {
      context.go(Uri.decodeComponent(from));
    } else {
      context.go('/dashboard');
    }
  }

  Future<void> _navigateToGetStarted() async {
    if (mounted) {
      setState(() {
        _progress = 1.0;
      });
    }
    if (!mounted) return;
    await _ensureMinSplashDelay();
    if (!mounted) return;
    context.go('/get-started');
  }

  Future<void> _ensureMinSplashDelay() async {
    final elapsed = DateTime.now().difference(_startTime);
    final minDuration = const Duration(milliseconds: 2200); // 2.2 seconds
    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }
  }

  void _showMaintenanceDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: AppColors.darkSlate,
          title: Row(
            children: [
              Icon(Icons.build_rounded, color: AppColors.brandGreenHighlight),
              const SizedBox(width: AppSpacing.s),
              const Text('Maintenance Mode', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(message, style: TextStyle(color: AppColors.textMuted)),
        ),
      ),
    );
  }

  void _showForceUpdateDialog(String androidLink, String iosLink) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: UpdateDialog(
          isForceUpdate: true,
          androidLink: androidLink,
          iosLink: iosLink,
          onDismiss: () {},
        ),
      ),
    );
  }

  Future<void> _showSoftUpdateDialog(String androidLink, String iosLink) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => UpdateDialog(
        isForceUpdate: false,
        androidLink: androidLink,
        iosLink: iosLink,
        onDismiss: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showLegalAcceptancePopup({
    required String userId,
    required int latestTerms,
    required int latestPrivacy,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: LegalAcceptancePopup(
          userId: userId,
          latestTermsVersion: latestTerms,
          latestPrivacyVersion: latestPrivacy,
          clientVersion: _clientVersion,
          onAccepted: () {
            Navigator.of(context).pop();
            _startInitializationSequence(); // re-verify flow
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final primaryColor = CRMColors.primaryOf(context);
    final textColor = CRMColors.textOf(context);
    final secondaryTextColor = CRMColors.textSecondaryOf(context);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated master logo
              Hero(
                tag: 'app_logo',
                child: Image.asset(
                  'assets/logo.png',
                  width: 120,
                  height: 120,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.apartment_rounded,
                    size: 100,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'PropKart',
                style: CRMTypography.largeDisplay.copyWith(
                  color: textColor,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Version $_clientVersion',
                style: CRMTypography.subheadline.copyWith(
                  color: secondaryTextColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              // Interactive Premium Linear Progress Bar
              Container(
                width: 250,
                height: 6,
                decoration: BoxDecoration(
                  color: CRMColors.borderOf(context).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _loadingMessage,
                  textAlign: TextAlign.center,
                  style: CRMTypography.body.copyWith(
                    color: secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
              ),
              if (_showRetryButton) ...[
                const SizedBox(height: AppSpacing.l),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry Connection'),
                  onPressed: _startInitializationSequence,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}