import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/design_system/tokens/app_colors.dart';
import 'core/design_system/tokens/app_shadows.dart';
import 'core/design_system/tokens/app_spacing.dart';
import 'core/design_system/tokens/app_typography.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'core/network/sync_manager.dart';
import 'core/storage/repository_coordinator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isSyncing = false;
  String? _syncError;

  @override
  void initState() {
    super.initState();
    _checkAuthAndStartSync();
  }

  void _checkAuthAndStartSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        if (SyncManager().isSyncCompleted) {
          // Warm start: trigger background refresh and enter app immediately
          SyncManager().performStartupSync().catchError((e) {
            print("Background sync error: $e");
          });
          final from = GoRouterState.of(context).uri.queryParameters['from'];
          if (from != null && from.isNotEmpty) {
            context.go(Uri.decodeComponent(from));
          } else {
            context.go('/dashboard');
          }
        } else {
          // First install: run blocking sync
          _runSync();
        }
      }
    });
  }

  Future<void> _runSync() async {
    setState(() {
      _isSyncing = true;
      _syncError = null;
    });

    try {
      await SyncManager().performStartupSync();
      if (mounted) {
        final from = GoRouterState.of(context).uri.queryParameters['from'];
        if (from != null && from.isNotEmpty) {
          context.go(Uri.decodeComponent(from));
        } else {
          context.go('/dashboard');
        }
      }
    } catch (e) {
      try {
        final lookupsCount = await RepositoryCoordinator().lookupLocal.getLookupsCount();
        if (lookupsCount > 0) {
          print("⚠️ [SPLASH SYNC] Sync failed, but found cached lookup data. Bypassing sync block.");
          if (mounted) {
            final from = GoRouterState.of(context).uri.queryParameters['from'];
            if (from != null && from.isNotEmpty) {
              context.go(Uri.decodeComponent(from));
            } else {
              context.go('/dashboard');
            }
          }
          return;
        }
      } catch (checkErr) {
        print("Error checking local lookups count: $checkErr");
      }

      setState(() {
        _isSyncing = false;
        _syncError = "Failed to synchronize setup data. Please check your internet connection and try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          if (SyncManager().isSyncCompleted) {
            final from = GoRouterState.of(context).uri.queryParameters['from'];
            if (from != null && from.isNotEmpty) {
              context.go(Uri.decodeComponent(from));
            } else {
              context.go('/dashboard');
            }
          } else {
            _runSync();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBg,
        body: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 960) {
                  return _buildLaptopLayout(context, constraints);
                } else {
                  return _buildMobileLayout(context, constraints);
                }
              },
            ),
            if (_isSyncing)
              Container(
                color: CRMColors.overlay,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.darkBg.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                      border: Border.all(color: AppColors.brandGreen.withOpacity(0.3)),
                      boxShadow: CRMShadows.floating,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.brandGreen, strokeWidth: 2.5),
                        const SizedBox(height: AppSpacing.l),
                        Text(
                          'Wait a sec...',
                          style: CRMTypography.sectionTitle.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        Text(
                          'Syncing latest data...',
                          style: CRMTypography.subheadline.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_syncError != null)
              Container(
                color: CRMColors.overlay,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.darkBg.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                      border: Border.all(color: CRMColors.danger.withOpacity(0.4)),
                      boxShadow: CRMShadows.floating,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off_rounded, color: CRMColors.danger, size: 48),
                        const SizedBox(height: AppSpacing.l),
                        Text(
                          'Sync Failed',
                          style: CRMTypography.sectionTitle.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        Text(
                          _syncError!,
                          textAlign: TextAlign.center,
                          style: CRMTypography.subheadline.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(CRMBorderRadius.xxl),
                            ),
                          ),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text('Retry Sync', style: CRMTypography.button.copyWith(color: Colors.white)),
                          onPressed: _runSync,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Beautiful Laptop/Desktop Split-Visual Layout
  Widget _buildLaptopLayout(BuildContext context, BoxConstraints constraints) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/propbg.jpg',
            fit: BoxFit.cover,
            alignment: const Alignment(0.4, 0.0),
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.darkSlate,
                child: const Center(
                  child: Icon(
                    Icons.apartment_rounded,
                    size: 150,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.darkBg,
                  AppColors.darkBg.withOpacity(0.95),
                  AppColors.darkBg.withOpacity(0.75),
                  AppColors.darkBg.withOpacity(0.0),
                ],
                stops: const [0.0, 0.4, 0.65, 1.0],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth * 0.08,
              vertical: AppSpacing.xxl,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.brandGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppBorderRadius.tag),
                        border: Border.all(
                          color: AppColors.brandGreen.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'PREMIUM REAL ESTATE',
                        style: CRMTypography.captionBold.copyWith(
                          color: AppColors.brandGreenHighlight,
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Treasure of listed\nproperties in your area',
                      style: CRMTypography.largeDisplay.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    Text(
                      'Find your dream home effortlessly. The ultimate real estate platform designed to streamline your property search and connect you with top listings.',
                      style: CRMTypography.body.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 17,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    PremiumButton(
                      label: 'Get Started',
                      width: 220,
                      onPressed: () {
                        final from = GoRouterState.of(context).uri.queryParameters['from'];
                        if (from != null && from.isNotEmpty) {
                          context.go('/login?from=${Uri.encodeComponent(from)}');
                        } else {
                          context.go('/login');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Premium Mobile Bottom-Faded Stack Layout
  Widget _buildMobileLayout(BuildContext context, BoxConstraints constraints) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/propbg.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.darkSlate,
                child: const Center(
                  child: Icon(
                    Icons.apartment_rounded,
                    size: 150,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.darkBg.withOpacity(0.2),
                  AppColors.darkBg.withOpacity(0.8),
                  AppColors.darkBg,
                ],
                stops: const [0.0, 0.5, 0.85],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brandGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppBorderRadius.tag),
                        border: Border.all(
                          color: AppColors.brandGreen.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'PREMIUM REAL ESTATE',
                        style: CRMTypography.captionBold.copyWith(
                          color: AppColors.brandGreenHighlight,
                          fontSize: 10,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      'Treasure of listed\nproperties in your area',
                      style: CRMTypography.display.copyWith(
                        color: Colors.white,
                        fontSize: 32,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      'Find your dream home effortlessly. The ultimate real estate platform designed to streamline your property search.',
                      style: CRMTypography.body.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PremiumButton(
                      label: 'Get Started',
                      onPressed: () {
                        final from = GoRouterState.of(context).uri.queryParameters['from'];
                        if (from != null && from.isNotEmpty) {
                          context.go('/login?from=${Uri.encodeComponent(from)}');
                        } else {
                          context.go('/login');
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.s),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}