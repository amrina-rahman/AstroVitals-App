import '../models/astro_vitals_user.dart';

abstract interface class AccountRepository {
  Future<void> register({
    required AstroVitalsUser user,
    required String password,
  });

  Future<AstroVitalsUser?> signIn({
    required String email,
    required String password,
  });
}

class AccountAlreadyExistsException implements Exception {
  const AccountAlreadyExistsException(this.field);

  final String field;
}

class InMemoryAccountRepository implements AccountRepository {
  final Map<String, _AccountRecord> _accountsByEmail = {};
  final Set<String> _astronautIds = {};

  @override
  Future<void> register({
    required AstroVitalsUser user,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(user.email);
    final normalizedId = user.astronautId.trim().toLowerCase();

    if (_accountsByEmail.containsKey(normalizedEmail)) {
      throw const AccountAlreadyExistsException('Email');
    }
    if (_astronautIds.contains(normalizedId)) {
      throw const AccountAlreadyExistsException('Astronaut ID');
    }

    _accountsByEmail[normalizedEmail] = _AccountRecord(
      user: user,
      password: password,
    );
    _astronautIds.add(normalizedId);
  }

  @override
  Future<AstroVitalsUser?> signIn({
    required String email,
    required String password,
  }) async {
    final account = _accountsByEmail[_normalizeEmail(email)];
    if (account == null || account.password != password) return null;
    return account.user;
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();
}

class _AccountRecord {
  const _AccountRecord({required this.user, required this.password});

  final AstroVitalsUser user;
  final String password;
}
