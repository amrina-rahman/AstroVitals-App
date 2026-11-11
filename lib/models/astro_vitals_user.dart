class AstroVitalsUser {
  const AstroVitalsUser({
    required this.astronautId,
    required this.fullName,
    required this.email,
    required this.dateOfBirth,
    required this.heightCm,
    required this.weightKg,
    this.gender,
  });

  final String astronautId;
  final String fullName;
  final String email;
  final DateTime dateOfBirth;
  final double heightCm;
  final double weightKg;
  final String? gender;

  AstroVitalsUser copyWith({
    String? astronautId,
    String? fullName,
    String? email,
    DateTime? dateOfBirth,
    double? heightCm,
    double? weightKg,
    String? gender,
    bool clearGender = false,
  }) {
    return AstroVitalsUser(
      astronautId: astronautId ?? this.astronautId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      gender: clearGender ? null : gender ?? this.gender,
    );
  }
}
