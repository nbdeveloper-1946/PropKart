import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/user_model.dart';
import '../repository/users_repository.dart';

// Events
abstract class UsersEvent extends Equatable {
  const UsersEvent();

  @override
  List<Object?> get props => [];
}

class FetchUsers extends UsersEvent {
  final String? search;
  final String? roleId;
  final String? status;

  const FetchUsers({this.search, this.roleId, this.status});

  @override
  List<Object?> get props => [search, roleId, status];
}

class FetchRoles extends UsersEvent {}

class CreateUserRequested extends UsersEvent {
  final Map<String, dynamic> userData;

  const CreateUserRequested({required this.userData});

  @override
  List<Object?> get props => [userData];
}

class UpdateUserRequested extends UsersEvent {
  final String id;
  final Map<String, dynamic> userData;

  const UpdateUserRequested({required this.id, required this.userData});

  @override
  List<Object?> get props => [id, userData];
}

class ToggleUserStatusRequested extends UsersEvent {
  final String id;
  final bool isActive;

  const ToggleUserStatusRequested({required this.id, required this.isActive});

  @override
  List<Object?> get props => [id, isActive];
}

class DeleteUserRequested extends UsersEvent {
  final String id;

  const DeleteUserRequested({required this.id});

  @override
  List<Object?> get props => [id];
}

// States
abstract class UsersState extends Equatable {
  const UsersState();

  @override
  List<Object?> get props => [];
}

class UsersInitial extends UsersState {}

class UsersLoading extends UsersState {}

class UsersLoaded extends UsersState {
  final List<UserModel> users;
  final List<RoleModel> roles;

  const UsersLoaded({required this.users, required this.roles});

  @override
  List<Object?> get props => [users, roles];
}

class UsersOperationSuccess extends UsersState {
  final String message;

  const UsersOperationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class UsersError extends UsersState {
  final String message;

  const UsersError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final UsersRepository _usersRepository;
  List<RoleModel> _cachedRoles = [];

  UsersBloc({required UsersRepository usersRepository})
      : _usersRepository = usersRepository,
        super(UsersInitial()) {
    on<FetchUsers>(_onFetchUsers);
    on<FetchRoles>(_onFetchRoles);
    on<CreateUserRequested>(_onCreateUser);
    on<UpdateUserRequested>(_onUpdateUser);
    on<ToggleUserStatusRequested>(_onToggleUserStatus);
    on<DeleteUserRequested>(_onDeleteUser);
  }

  Future<void> _onFetchUsers(
    FetchUsers event,
    Emitter<UsersState> emit,
  ) async {
    emit(UsersLoading());
    try {
      if (_cachedRoles.isEmpty) {
        _cachedRoles = await _usersRepository.getRoles();
      }
      final users = await _usersRepository.getUsers(
        search: event.search,
        roleId: event.roleId,
        status: event.status,
      );
      emit(UsersLoaded(users: users, roles: _cachedRoles));
    } catch (e) {
      emit(UsersError(message: e.toString()));
    }
  }

  Future<void> _onFetchRoles(
    FetchRoles event,
    Emitter<UsersState> emit,
  ) async {
    try {
      _cachedRoles = await _usersRepository.getRoles();
    } catch (_) {}
  }

  Future<void> _onCreateUser(
    CreateUserRequested event,
    Emitter<UsersState> emit,
  ) async {
    emit(UsersLoading());
    try {
      await _usersRepository.createUser(event.userData);
      emit(const UsersOperationSuccess(message: "User created successfully."));
    } catch (e) {
      emit(UsersError(message: e.toString()));
    }
  }

  Future<void> _onUpdateUser(
    UpdateUserRequested event,
    Emitter<UsersState> emit,
  ) async {
    emit(UsersLoading());
    try {
      await _usersRepository.updateUser(event.id, event.userData);
      emit(const UsersOperationSuccess(message: "User updated successfully."));
    } catch (e) {
      emit(UsersError(message: e.toString()));
    }
  }

  Future<void> _onToggleUserStatus(
    ToggleUserStatusRequested event,
    Emitter<UsersState> emit,
  ) async {
    emit(UsersLoading());
    try {
      await _usersRepository.toggleUserStatus(event.id, event.isActive);
      emit(const UsersOperationSuccess(message: "User status updated."));
    } catch (e) {
      emit(UsersError(message: e.toString()));
    }
  }

  Future<void> _onDeleteUser(
    DeleteUserRequested event,
    Emitter<UsersState> emit,
  ) async {
    emit(UsersLoading());
    try {
      await _usersRepository.deleteUser(event.id);
      emit(const UsersOperationSuccess(message: "User deleted successfully."));
    } catch (e) {
      emit(UsersError(message: e.toString()));
    }
  }
}
