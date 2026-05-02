import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'core/di/injection.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable edge-to-edge on Android 15+ — lets Flutter handle system bar insets
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  // Initialize Supabase
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

  // Handle OAuth deep link if app was cold-started from a redirect
  final appLinks = AppLinks();
  final initialUri = await appLinks.getInitialLink();
  if (initialUri != null) {
    await _handleDeepLink(initialUri);
  }

  // Listen for OAuth deep links while app is running
  appLinks.uriLinkStream.listen((uri) async {
    await _handleDeepLink(uri);
  });

  // Initialize dependency injection
  await configureDependencies();

  runApp(const LanistaApp());
}

Future<void> _handleDeepLink(Uri uri) async {
  if (uri.scheme == 'com.lanista.lanista' && uri.host == 'auth-callback') {
    await Supabase.instance.client.auth.getSessionFromUrl(uri);
  }
}
