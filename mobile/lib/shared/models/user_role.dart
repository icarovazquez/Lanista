enum UserRole {
  player,
  parent,
  coach,
  mentor,
  admin;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.player,
    );
  }

  String get displayName {
    switch (this) {
      case UserRole.player:
        return 'Player';
      case UserRole.parent:
        return 'Parent / Guardian';
      case UserRole.coach:
        return 'College Coach';
      case UserRole.mentor:
        return 'Mentor / Club Coach';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String get displayNameEs {
    switch (this) {
      case UserRole.player:
        return 'Jugador/a';
      case UserRole.parent:
        return 'Padre / Tutor';
      case UserRole.coach:
        return 'Entrenador Universitario';
      case UserRole.mentor:
        return 'Mentor / Entrenador de Club';
      case UserRole.admin:
        return 'Administrador';
    }
  }
}
