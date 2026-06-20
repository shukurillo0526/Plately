// Plately — Auth Screen
// =====================
// Localized login screen with language picker, Google OAuth, and Guest login.
// Uses a unified "Continue" flow that auto-detects sign-in vs sign-up
// to eliminate user confusion between the two modes.
// Uses Supabase Auth for all flows.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:google_sign_in/google_sign_in.dart';
import 'package:plately_app/core/services/auth_helper.dart';
import 'package:plately_app/core/services/app_settings.dart';
import 'package:plately_app/l10n/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Unified "Continue" flow: tries sign-in first, then sign-up if credentials are invalid.
  /// This eliminates the confusing Sign In / Sign Up toggle entirely.
  Future<void> _continueWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final l10n = AppLocalizations.of(context);

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = l10n?.auth_enterBoth ?? 'Please enter both email and password.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Step 1: Try signing in with existing credentials
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // Success — AuthGate will handle navigation
      if (mounted) setState(() => _loading = false);
    } on AuthException catch (signInError) {
      // Step 2: If "Invalid login credentials", auto-attempt sign-up
      if (signInError.message.contains('Invalid login credentials') ||
          signInError.message.contains('invalid_credentials')) {
        try {
          final signUpResult = await Supabase.instance.client.auth.signUp(
            email: email,
            password: password,
          );

          if (mounted) {
            setState(() => _loading = false);
            // If identities is empty, the email already exists in Supabase.
            // This means the original sign-in failed due to wrong password,
            // NOT because the user doesn't exist.
            if (signUpResult.user?.identities?.isEmpty == true) {
              // Email exists but password was wrong — clear error message
              setState(() => _error = 'Incorrect password. Please try again or reset your password.');
            } else if (signUpResult.session == null) {
              // Genuine new sign-up — needs email verification
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n?.auth_checkEmail ?? 'Please check your email to verify your account.'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        } on AuthException catch (signUpError) {
          if (mounted) {
            setState(() {
              _error = signUpError.message;
              _loading = false;
            });
          }
        }
      } else {
        // Other sign-in errors (network, etc.)
        if (mounted) {
          setState(() {
            _error = signInError.message;
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context)?.auth_unexpectedError ??
              'An unexpected error occurred. Please try again.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final l10n = AppLocalizations.of(context);
    if (email.isEmpty) {
      setState(() => _error = l10n?.auth_enterBoth ?? 'Please enter your email address first.');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.auth_resetSent ?? 'Password reset email sent. Check your inbox.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to send reset email. Please try again.');
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (kIsWeb) {
        // Web: Use OAuth redirect (existing behavior)
        final redirectUrl = Uri.base.toString().replaceAll(RegExp(r'[#?].*'), '');
        await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: redirectUrl,
        );
      } else {
        // Mobile: Use native Google Sign-In for reliability
        final GoogleSignIn googleSignIn = GoogleSignIn(
          serverClientId: '194605188460-5dd926tsovdm29mc23enqqdupbnkcaf7.apps.googleusercontent.com',
        );
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          // User cancelled
          if (mounted) setState(() => _loading = false);
          return;
        }
        final googleAuth = await googleUser.authentication;
        final idToken = googleAuth.idToken;
        final accessToken = googleAuth.accessToken;

        if (idToken == null) {
          throw Exception('No ID token received from Google.');
        }

        await Supabase.instance.client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        // Initialize profile
        await ensureUserInitialized();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final l10n = AppLocalizations.of(context);
          _error = l10n?.auth_googleFailed ?? 'Google sign\u2011in failed. Please try again.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _signInAsGuest() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Each guest gets a unique anonymous UUID in Supabase.
      // Their data is isolated and can be migrated when they
      // later sign up with email or Google (via identity linking).
      await Supabase.instance.client.auth.signInAnonymously();

      // Initialize profile rows for this anonymous user
      await ensureUserInitialized();
    } catch (e) {
      if (mounted) {
        setState(() {
          final l10n = AppLocalizations.of(context);
          _error = l10n?.auth_guestFailed ?? 'Guest sign‑in failed. Please try email or Google instead.';
          _loading = false;
        });
      }
    }
  }

  /// Show language picker bottom sheet — identical to profile's language picker
  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final settings = AppSettings();
        final currentLocaleStr = settings.locale.scriptCode != null
            ? '${settings.locale.languageCode}_${settings.locale.scriptCode}'
            : settings.locale.languageCode;

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)?.settingsLanguage ?? 'Language',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ...AppSettings.supportedLanguages.entries.map((entry) {
                final code = entry.key;
                final name = entry.value['name']!;
                final flag = entry.value['flag']!;
                final isSelected = code == currentLocaleStr;

                return ListTile(
                  leading: Text(flag, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  selected: isSelected,
                  onTap: () {
                    settings.setLocale(AppSettings.parseLocale(code));
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ── Background Gradient ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.4),
                  radius: 1.2,
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                ),
              ),
            ),
          ),

          // ── Language Picker Button (top-right) ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showLanguagePicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.language,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${AppSettings().currentLanguageFlag} ${AppSettings().currentLanguageName}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Animated Logo ──
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, child) {
                        final scale =
                            1.0 + _pulseController.value * 0.05;
                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🧊',
                              style: TextStyle(fontSize: 56)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Title ──
                    Text(
                      'Plately',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n?.auth_tagline ?? 'Zero‑Waste, Maximum Taste.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // ── Email & Password Fields ──
                    _TextField(
                      controller: _emailController,
                      hintText: l10n?.auth_email ?? 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _TextField(
                      controller: _passwordController,
                      hintText: l10n?.auth_password ?? 'Password',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          size: 22,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Helper text — explains auto-detection ──
                    Text(
                      l10n?.auth_autoDetectHint ?? 'New here? We\'ll create your account automatically.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _resetPassword,
                        child: Text(
                          l10n?.auth_forgotPassword ?? 'Forgot Password?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Unified "Continue" Button ──
                    _AuthButton(
                      onPressed: _loading ? null : _continueWithEmail,
                      icon: Icons.arrow_forward,
                      label: l10n?.auth_continue ?? 'Continue',
                      isPrimary: true,
                    ),

                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(child: Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(l10n?.auth_or ?? 'OR', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                        ),
                        Expanded(child: Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2))),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ── Google Sign In ──
                    _AuthButton(
                      onPressed: _loading ? null : _signInWithGoogle,
                      icon: Icons.g_mobiledata,
                      label: l10n?.auth_continueGoogle ?? 'Continue with Google',
                      isPrimary: false,
                    ),

                    const SizedBox(height: 14),

                    // ── Guest ──
                    _AuthButton(
                      onPressed: _loading ? null : _signInAsGuest,
                      icon: Icons.person_outline,
                      label: l10n?.auth_continueGuest ?? 'Continue as Guest',
                      isPrimary: false,
                    ),

                    if (_loading) ...[
                      const SizedBox(height: 28),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],

                    if (_error != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.redAccent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 48),

                    Text(
                      l10n?.auth_subtitle ?? 'Your kitchen, intelligently managed.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Auth Button ────────────────────────────────────────────────

class _AuthButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool isPrimary;

  const _AuthButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: isPrimary
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 28),
              label: Text(label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 24,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
              label: Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
    );
  }
}

// ── Stylish Text Field ──────────────────────────────────────────

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;

  const _TextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), size: 22),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}
