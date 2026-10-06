import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthCubit extends Cubit<AuthStatus> {
  AuthCubit(this._service) : super(AuthStatus.unknown);

  final AuthService _service;

  Future<void> restore() async {
    final ok = await _service.restore();
    emit(ok ? AuthStatus.authenticated : AuthStatus.unauthenticated);
  }

  /// Throws [AuthException] on failure so the login form can show the reason.
  Future<void> login(String password) async {
    await _service.login(password);
    emit(AuthStatus.authenticated);
  }

  Future<void> logout() async {
    await _service.logout();
    emit(AuthStatus.unauthenticated);
  }
}

/// App-wide instance, shared with the router's redirect guard.
final AuthCubit authCubit = AuthCubit(AuthService.shared);
