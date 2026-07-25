import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/user_model.dart';
import '../repository/auth_repository.dart';
import '../../../core/network/sync_manager.dart';
import '../../../core/storage/session_cleanup.dart';

// ==========================================
// Auth Events
// ==========================================
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckStatus extends AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  final bool rememberMe;

  const LoginSubmitted({
    required this.email,
    required this.password,
    required this.rememberMe,
  });

  @override
  List<Object?> get props => [email, password, rememberMe];
}

class LogoutRequested extends AuthEvent {}

/// Internal: session killed by 401 / forced cleanup.
class AuthSessionExpired extends AuthEvent {}

// ==========================================
// Auth States
// ==========================================
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserModel user;

  const Authenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ==========================================
// Auth BLoC
// ==========================================
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<void>? _forcedLogoutSub;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthCheckStatus>(_onAuthCheckStatus);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthSessionExpired>(_onSessionExpired);

    _forcedLogoutSub = SessionCleanup.onForcedLogout.listen((_) {
      if (!isClosed) add(AuthSessionExpired());
    });
  }

  @override
  Future<void> close() async {
    await _forcedLogoutSub?.cancel();
    return super.close();
  }

  Future<void> _onAuthCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final isAuth = await _authRepository.isAuthenticated();
      if (isAuth) {
        final user = await _authRepository.getProfile();
        emit(Authenticated(user: user));
      } else {
        emit(Unauthenticated());
      }
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.login(
        event.email,
        event.password,
        event.rememberMe,
      );
      try {
        await SyncManager().performStartupSync();
        SyncManager().isSyncCompleted = true;
      } catch (syncErr) {
        // Sync failure must not leave prior-user data; session was already cleared.
        // Keep flag false so splash/shell force a sync before trusting local DB.
        SyncManager().isSyncCompleted = false;
        // ignore: avoid_print
        print('⚠️ [LOGIN SYNC WARNING] Startup sync failed during login: $syncErr');
      }
      emit(Authenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.logout();
    } catch (_) {}
    emit(Unauthenticated());
  }

  Future<void> _onSessionExpired(
    AuthSessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await SessionCleanup.clearLocalSession(clearToken: true);
    } catch (_) {}
    emit(Unauthenticated());
  }
}
