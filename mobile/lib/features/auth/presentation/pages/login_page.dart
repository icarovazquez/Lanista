import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/social_auth_button.dart';

const _kEmailKey    = 'biometric_email';
const _kPasswordKey = 'biometric_password';
const _kEnabledKey  = 'biometric_enabled';

class LoginPage extends StatefulWidget {
  /// When true (e.g. after an explicit logout) Face ID auto-trigger is skipped
  /// so the user can sign in as a different account.
  final bool skipBiometrics;
  const LoginPage({super.key, this.skipBiometrics = false});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey           = GlobalKey<FormState>();
  final _emailController   = TextEditingController();
  final _passwordController = TextEditingController();
  final _localAuth         = LocalAuthentication();
  final _secureStorage     = const FlutterSecureStorage();

  bool _isLoading          = false;
  bool _obscurePassword    = true;
  String? _errorMessage;
  bool _deviceSupported    = false; // device supports ANY secure auth (PIN/face/fingerprint)
  bool _biometricAvailable = false; // biometrics actually enrolled — for auto-trigger & quick-login button
  bool _biometricEnabled   = false;
  // Suppress listener navigation when we're handling it manually (password / biometric flows)
  // Only true while waiting for Google OAuth redirect — listener navigates only then
  bool _awaitingOAuth = false;

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn && mounted && _awaitingOAuth) {
        _awaitingOAuth = false;
        context.go('/splash');
      }
    });
    _checkBiometrics();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck          = await _localAuth.canCheckBiometrics;
      final supported         = await _localAuth.isDeviceSupported();
      final enabled           = await _secureStorage.read(key: _kEnabledKey);
      if (mounted) {
        setState(() {
          _deviceSupported    = supported;                  // for showing the offer after login
          _biometricAvailable = canCheck && supported;      // for auto-trigger & quick-login button
          _biometricEnabled   = enabled == 'true';
        });
      }
      // Auto-trigger biometrics if enrolled + enabled (skip after explicit logout)
      if (_biometricAvailable && _biometricEnabled && !widget.skipBiometrics) {
        _signInWithBiometrics();
      }
    } catch (_) {}
  }

  Future<void> _signInWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Sign in to Lanista',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (!authenticated || !mounted) return;

      final email    = await _secureStorage.read(key: _kEmailKey);
      final password = await _secureStorage.read(key: _kPasswordKey);
      if (email == null || password == null) return;

      setState(() { _isLoading = true; _errorMessage = null; });
      await Supabase.instance.client.auth.signInWithPassword(
        email: email, password: password,
      );
      if (mounted) context.go('/splash');
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      // Biometric cancelled — do nothing, let user use password
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;

      // Offer to enable biometric login after first successful login
      if (_deviceSupported && !_biometricEnabled) {
        _offerBiometricSetup(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        context.go('/splash');
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'An unexpected error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _offerBiometricSetup(String email, String password) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('😊', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Enable Face ID?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in with just a glance next time — no typing required.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                await _secureStorage.write(key: _kEmailKey,    value: email);
                await _secureStorage.write(key: _kPasswordKey, value: password);
                await _secureStorage.write(key: _kEnabledKey,  value: 'true');
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted)    context.go('/splash');
              },
              child: const Text('Enable Face ID',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (mounted) context.go('/splash');
              },
              child: const Text('Not now', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    _awaitingOAuth = true;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.lanista.lanista://auth-callback/',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } on AuthException catch (e) {
      _awaitingOAuth = false;
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      _awaitingOAuth = false;
      if (mounted) setState(() => _errorMessage = 'Google sign-in failed');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                // Logo
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Text('⚽', style: TextStyle(fontSize: 24))),
                    ),
                    const SizedBox(width: 12),
                    Text('LANISTA', style: theme.textTheme.headlineLarge?.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w900, letterSpacing: 2,
                    )),
                  ],
                ),
                const SizedBox(height: 40),
                Text(l10n.signIn, style: theme.textTheme.displayMedium),
                const SizedBox(height: 8),
                Text(l10n.lanistaTagline, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 32),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                // Email field
                AuthTextField(
                  controller: _emailController,
                  label: l10n.email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Email is required';
                    if (!val.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                AuthTextField(
                  controller: _passwordController,
                  label: l10n.password,
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Password is required';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(l10n.forgotPassword, style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600,
                    )),
                  ),
                ),
                const SizedBox(height: 8),

                // Sign in button
                ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(l10n.signIn),
                ),
                const SizedBox(height: 16),

                // Face ID button — shown when biometrics are enabled
                if (_biometricAvailable && _biometricEnabled)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.face_outlined),
                    label: const Text('Sign in with Face ID',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isLoading ? null : _signInWithBiometrics,
                  ),

                if (_biometricAvailable && _biometricEnabled)
                  const SizedBox(height: 16),

                // Divider
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('or', style: theme.textTheme.bodyMedium),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 24),

                // Google
                SocialAuthButton(
                  label: l10n.continueWithGoogle,
                  iconPath: 'assets/icons/google.png',
                  onPressed: _isLoading ? null : _signInWithGoogle,
                ),
                const SizedBox(height: 32),

                // Register link
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: l10n.dontHaveAccount,
                      style: theme.textTheme.bodyMedium,
                      children: [
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => context.go('/auth/register'),
                            child: const Text('Sign up', style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            )),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
