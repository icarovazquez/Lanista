import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isSpanish => locale.languageCode == 'es';

  // Auth
  String get signIn => isSpanish ? 'Iniciar Sesión' : 'Sign In';
  String get signUp => isSpanish ? 'Registrarse' : 'Sign Up';
  String get email => isSpanish ? 'Correo Electrónico' : 'Email';
  String get password => isSpanish ? 'Contraseña' : 'Password';
  String get forgotPassword =>
      isSpanish ? '¿Olvidaste tu contraseña?' : 'Forgot Password?';
  String get continueWithGoogle =>
      isSpanish ? 'Continuar con Google' : 'Continue with Google';
  String get continueWithApple =>
      isSpanish ? 'Continuar con Apple' : 'Continue with Apple';
  String get dontHaveAccount =>
      isSpanish ? '¿No tienes cuenta? ' : "Don't have an account? ";
  String get alreadyHaveAccount =>
      isSpanish ? '¿Ya tienes cuenta? ' : 'Already have an account? ';
  String get firstName => isSpanish ? 'Nombre' : 'First Name';
  String get lastName => isSpanish ? 'Apellido' : 'Last Name';
  String get createAccount =>
      isSpanish ? 'Crear Cuenta' : 'Create Account';

  // Role Selection
  String get whoAreYou => isSpanish ? '¿Quién eres?' : 'Who are you?';
  String get selectYourRole =>
      isSpanish ? 'Selecciona tu rol para comenzar' : 'Select your role to get started';
  String get iAmAPlayer =>
      isSpanish ? 'Soy Jugador/a' : 'I am a Player';
  String get iAmAParent =>
      isSpanish ? 'Soy Padre/Tutor' : 'I am a Parent / Guardian';
  String get iAmACoach =>
      isSpanish ? 'Soy Entrenador Universitario' : 'I am a College Coach';
  String get iAmAMentor =>
      isSpanish ? 'Soy Mentor / Entrenador de Club' : 'I am a Mentor / Club Coach';
  String get playerDescription =>
      isSpanish
          ? 'Busca programas universitarios y obtén tu hoja de ruta personalizada'
          : 'Find college programs and get your personalized development roadmap';
  String get parentDescription =>
      isSpanish
          ? 'Apoya a tu hijo/a en su camino al fútbol universitario'
          : 'Support your child on their path to college soccer';
  String get coachDescription =>
      isSpanish
          ? 'Gestiona tu plantilla y descubre los mejores prospectos'
          : 'Manage your roster and discover top prospects';
  String get mentorDescription =>
      isSpanish
          ? 'Guía a tus jugadores hacia sus metas universitarias'
          : 'Guide your players toward their college goals';

  // Navigation
  String get dashboard => isSpanish ? 'Panel' : 'Dashboard';
  String get matches => isSpanish ? 'Coincidencias' : 'Matches';
  String get roadmap => isSpanish ? 'Hoja de Ruta' : 'Roadmap';
  String get search => isSpanish ? 'Buscar' : 'Search';
  String get messages => isSpanish ? 'Mensajes' : 'Messages';
  String get profile => isSpanish ? 'Perfil' : 'Profile';
  String get rosterMap => isSpanish ? 'Mapa de Plantilla' : 'Roster Map';
  String get pipeline => isSpanish ? 'Pipeline' : 'Pipeline';

  // Common
  String get loading => isSpanish ? 'Cargando...' : 'Loading...';
  String get error => isSpanish ? 'Error' : 'Error';
  String get retry => isSpanish ? 'Reintentar' : 'Retry';
  String get save => isSpanish ? 'Guardar' : 'Save';
  String get cancel => isSpanish ? 'Cancelar' : 'Cancel';
  String get next => isSpanish ? 'Siguiente' : 'Next';
  String get back => isSpanish ? 'Atrás' : 'Back';
  String get done => isSpanish ? 'Listo' : 'Done';
  String get signOut => isSpanish ? 'Cerrar Sesión' : 'Sign Out';
  String get comingSoon => isSpanish ? 'Próximamente' : 'Coming Soon';
  String get lanistaTagline =>
      isSpanish
          ? 'Conectando jugadores élite con entrenadores universitarios'
          : 'Connecting elite players with college coaches';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
