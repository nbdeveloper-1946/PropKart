import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/properties/screens/properties_screen.dart';
import '../../features/properties/screens/property_detail_screen.dart';
import '../../features/properties/bloc/properties_bloc.dart';
import '../../features/users/screens/users_screen.dart';
import '../../features/requirements/screens/requirements_screen.dart';
import '../../features/clients/screens/clients_screen.dart';

import '../../features/owners/screens/owners_screen.dart';
import '../../features/builders/screens/builders_screen.dart';
import '../../splash.dart';
import '../../get_started_screen.dart';
import '../../modules/legal/presentation/terms_and_conditions_page.dart';
import '../../modules/legal/presentation/privacy_policy_page.dart';
import '../design_system/widgets/app_shell.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/audit_logs_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/properties/screens/recycle_bin_screen.dart';
import '../network/sync_manager.dart';
import '../../features/requirements/screens/share_properties_page.dart';
import '../../features/requirements/screens/public_property_detail_screen.dart';


class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  late final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/get-started',
        builder: (context, state) => const GetStartedScreen(),
      ),
      GoRoute(
        path: '/terms-and-conditions',
        builder: (context, state) => const TermsAndConditionsPage(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => CRMAppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/properties',
            builder: (context, state) {
              final openId = state.uri.queryParameters['openId'] ?? (state.extra as String?);
              return BlocProvider(
                create: (context) => PropertiesBloc(),
                child: PropertiesScreen(openPropertyId: openId),
              );
            },
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UsersScreen(),
          ),
          GoRoute(
            path: '/requirements',
            builder: (context, state) => const RequirementsScreen(),
          ),
          GoRoute(
            path: '/clients',
            builder: (context, state) => const ClientsScreen(),
          ),

          GoRoute(
            path: '/owners',
            builder: (context, state) => const OwnersScreen(),
          ),
          GoRoute(
            path: '/builders',
            builder: (context, state) => const BuildersScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/settings/audit-logs',
            builder: (context, state) => const AuditLogsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/bin',
            builder: (context, state) => const RecycleBinScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/properties/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PropertyDetailScreen(propertyId: id);
        },
      ),
      GoRoute(
        path: '/share/:sessionId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return SharePropertiesPage(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/share/:sessionId/property/:propertyId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          final propertyId = state.pathParameters['propertyId']!;
          return PublicPropertyDetailScreen(sessionId: sessionId, propertyId: propertyId);
        },
      ),
    ],
    redirect: (context, state) {
      final authState = authBloc.state;
      final loggingIn = state.matchedLocation == '/login';
      final onSplash = state.matchedLocation == '/splash';
      final onGetStarted = state.matchedLocation == '/get-started';
      final isPublicShare = state.matchedLocation.startsWith('/share/');
      final onUsers = state.matchedLocation.startsWith('/users');
      final isAuthGate = loggingIn || onSplash || onGetStarted || isPublicShare;

      if (authState is Authenticated) {
        // Defense-in-depth: employee management is Admin / Super Admin only.
        if (onUsers) {
          final role = authState.user.role;
          if (role != 'Admin' && role != 'Super Admin') {
            return '/dashboard';
          }
        }
        if (loggingIn) {
          final from = state.uri.queryParameters['from'];
          if (from != null && from.isNotEmpty) {
            return Uri.decodeComponent(from);
          }
          return '/dashboard';
        }
        if (onSplash) {
          if (!SyncManager().isSyncCompleted) {
            return null; // Stay on splash screen until sync completes
          }
          final from = state.uri.queryParameters['from'];
          if (from != null && from.isNotEmpty) {
            return Uri.decodeComponent(from);
          }
          return '/dashboard';
        }
        return null;
      }

      // AuthInitial / AuthLoading / AuthError / Unauthenticated:
      // never paint the authenticated shell with placeholder identity.
      if (authState is Unauthenticated || authState is AuthError) {
        if (!isAuthGate) {
          final target = state.uri.toString();
          return '/get-started?from=${Uri.encodeComponent(target)}';
        }
        return null;
      }

      // AuthInitial or AuthLoading — hold on splash until auth resolves.
      if (!isAuthGate) {
        final target = state.uri.toString();
        return '/splash?from=${Uri.encodeComponent(target)}';
      }
      return null;
    },
  );
}
