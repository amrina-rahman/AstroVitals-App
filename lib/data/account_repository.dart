import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/astro_vitals_user.dart';

abstract interface class AccountRepository {
  Future<AstroVitalsUser?> currentUser();

  Future<AstroVitalsUser?> register({
    required AstroVitalsUser user,
    required String password,
  });

  Future<AstroVitalsUser?> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> updateProfile({
    required AstroVitalsUser currentUser,
    required AstroVitalsUser updatedUser,
  });
}

class AccountAlreadyExistsException implements Exception {
  const AccountAlreadyExistsException(this.field);

  final String field;
}

class AccountNotFoundException implements Exception {
  const AccountNotFoundException();
}

class AccountOperationException implements Exception {
  const AccountOperationException(this.message);

  final String message;
}

class SupabaseAccountRepository implements AccountRepository {
  SupabaseAccountRepository(this._client);

  final SupabaseClient _client;
  static const _tableName = 'users';

  @override
  Future<AstroVitalsUser?> currentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _loadOrCreateProfile(user);
  }

  @override
  Future<AstroVitalsUser?> register({
    required AstroVitalsUser user,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: user.email.trim(),
        password: password,
        data: _profileToMap(user),
      );
      final authUser = response.user;
      if (authUser == null) {
        throw const AccountOperationException(
          'Supabase did not return a user after registration.',
        );
      }

      if (response.session == null) return null;

      await _saveProfile(authUser.id, user);
      return user;
    } on AuthException catch (error) {
      if (_isDuplicateEmail(error)) {
        throw const AccountAlreadyExistsException('Email');
      }
      throw AccountOperationException(error.message);
    } on PostgrestException catch (error) {
      _throwProfileError(error);
    }
  }

  @override
  Future<AstroVitalsUser?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = response.user;
      if (user == null) return null;
      return await _loadOrCreateProfile(user);
    } on AuthException catch (error) {
      if (error.message.toLowerCase().contains('invalid login credentials')) {
        return null;
      }
      throw AccountOperationException(error.message);
    } on PostgrestException catch (error) {
      throw AccountOperationException(error.message);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      throw AccountOperationException(error.message);
    }
  }

  @override
  Future<void> updateProfile({
    required AstroVitalsUser currentUser,
    required AstroVitalsUser updatedUser,
  }) async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) throw const AccountNotFoundException();

    try {
      if (currentUser.email.trim().toLowerCase() !=
          updatedUser.email.trim().toLowerCase()) {
        await _client.auth.updateUser(
          UserAttributes(email: updatedUser.email.trim()),
        );
      }

      final updatedRow = await _client
          .from(_tableName)
          .update(_profileToMap(updatedUser))
          .eq('user_id', authUser.id)
          .select('user_id')
          .maybeSingle();
      if (updatedRow == null) throw const AccountNotFoundException();
    } on AuthException catch (error) {
      throw AccountOperationException(error.message);
    } on PostgrestException catch (error) {
      _throwProfileError(error);
    }
  }

  Future<AstroVitalsUser> _loadOrCreateProfile(User authUser) async {
    try {
      final profile = await _client
          .from(_tableName)
          .select()
          .eq('user_id', authUser.id)
          .maybeSingle();
      if (profile != null) return _profileFromMap(profile);

      final metadata = authUser.userMetadata;
      if (metadata == null) {
        throw const AccountOperationException(
          'Your profile is missing. Please contact the app administrator.',
        );
      }
      final recoveredProfile = _profileFromMap({
        ...metadata,
        'email': authUser.email,
      });
      await _saveProfile(authUser.id, recoveredProfile);
      return recoveredProfile;
    } on PostgrestException catch (error) {
      _throwProfileError(error);
    }
  }

  Future<void> _saveProfile(String userId, AstroVitalsUser user) async {
    try {
      await _client.from(_tableName).upsert({
        'user_id': userId,
        ..._profileToMap(user),
      }, onConflict: 'user_id');
    } on PostgrestException catch (error) {
      _throwProfileError(error);
    }
  }

  Map<String, Object?> _profileToMap(AstroVitalsUser user) => {
    'astronaut_id': user.astronautId.trim(),
    'full_name': user.fullName.trim(),
    'email': user.email.trim(),
    'date_of_birth': _dateToString(user.dateOfBirth),
    'height_cm': user.heightCm,
    'current_weight_kg': user.weightKg,
    'gender': user.gender,
  };

  AstroVitalsUser _profileFromMap(Map<String, dynamic> profile) {
    final dateOfBirth = DateTime.tryParse(
      profile['date_of_birth'] as String? ?? '',
    );
    final heightCm = _asDouble(profile['height_cm']);
    final weightKg = _asDouble(profile['current_weight_kg']);
    final astronautId = profile['astronaut_id'] as String?;
    final fullName = profile['full_name'] as String?;
    final email = profile['email'] as String?;

    if (dateOfBirth == null ||
        heightCm == null ||
        weightKg == null ||
        astronautId == null ||
        fullName == null ||
        email == null) {
      throw const AccountOperationException(
        'The profile data returned by Supabase is incomplete or invalid.',
      );
    }

    return AstroVitalsUser(
      astronautId: astronautId,
      fullName: fullName,
      email: email,
      dateOfBirth: dateOfBirth,
      heightCm: heightCm,
      weightKg: weightKg,
      gender: profile['gender'] as String?,
    );
  }

  double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _dateToString(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  bool _isDuplicateEmail(AuthException error) {
    final message = error.message.toLowerCase();
    return message.contains('already registered') ||
        message.contains('already been registered') ||
        message.contains('user already registered');
  }

  Never _throwProfileError(PostgrestException error) {
    if (error.code == '23505') {
      if (error.message.toLowerCase().contains('astronaut_id')) {
        throw const AccountAlreadyExistsException('Astronaut ID');
      }
      throw const AccountAlreadyExistsException('Profile');
    }
    throw AccountOperationException(error.message);
  }
}
