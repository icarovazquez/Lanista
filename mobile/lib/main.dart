import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/di/injection.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  // In development, use placeholder values until Supabase project is created
  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://yfyutdbxfwqajzsejenz.supabase.co',
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmeXV0ZGJ4ZndxYWp6c2VqZW56Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzOTE4NTgsImV4cCI6MjA4Njk2Nzg1OH0.o_6HsgASe0toPcuaoijhhlP6WgsZN2T9LmONDKMEATg',
    ),
  );

  // Initialize dependency injection
  await configureDependencies();

  runApp(const LanistaApp());
}
