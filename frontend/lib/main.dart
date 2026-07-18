// Plately — Application Entry Point
// "Zero-Waste, Maximum Taste."
//
// Dual-mode app: ORDER (eat out) and COOK (cook at home).
// The bottom navigation changes dynamically based on the active mode.

import 'dart:async';
import 'package:plately_app/core/services/location_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:plately_app/core/theme/app_theme.dart';
import 'package:plately_app/core/services/app_settings.dart';
import 'package:plately_app/core/widgets/dual_mode_nav_bar.dart';
import 'package:plately_app/features/cook/presentation/widgets/cooking_mini_player.dart';
import 'package:plately_app/core/services/cooking_notification_service.dart';
import 'package:plately_app/features/cook/providers/cooking_session_provider.dart';

// ── Screens ──────────────────────────────────────────────
// Cook mode screens (existing)
import 'package:plately_app/features/shelf/presentation/screens/living_shelf_screen.dart';
import 'package:plately_app/features/cook/presentation/screens/cook_screen.dart';
import 'package:plately_app/features/scan/presentation/screens/scan_screen.dart';
import 'package:plately_app/features/profile/presentation/screens/profile_screen.dart';

// Order mode screens (new)
import 'package:plately_app/features/order/presentation/screens/order_screen.dart';
import 'package:plately_app/features/order/presentation/screens/order_feeds_screen.dart';

// Auth
import 'package:plately_app/features/auth/presentation/screens/auth_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plately_app/l10n/app_localizations.dart';
import 'package:plately_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:plately_app/core/services/cache_service.dart';
import 'package:plately_app/core/services/tutorial_controller.dart';
import 'package:plately_app/core/widgets/tutorial_guide_overlay.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:plately_app/core/services/gamification_service.dart';
import 'package:plately_app/core/services/analytics_service.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // ── Global Error Handling ──
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[Error] ${details.exceptionAsString()}');
  };

  // ── Supabase Configuration ──
  // Pass via: --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  const envSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const envSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  final supabaseUrl = envSupabaseUrl.isNotEmpty
      ? envSupabaseUrl
      : 'https://tquyodwsyppwbpvkaunn.supabase.co';
  final supabaseAnonKey = envSupabaseAnonKey.isNotEmpty
      ? envSupabaseAnonKey
      : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRxdXlvZHdzeXBwd2JwdmthdW5uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE1NzEzOTAsImV4cCI6MjA4NzE0NzM5MH0.1o6RYfeL_7YlIeUkl4jFsCm2JCQ2mB2F9o5wLv30xWU';

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    await AppSettings().init();
    try {
      await LocationService().init();
    } catch (e) {
      debugPrint('[Main] Location init skipped: $e');
    }
    // Initialize offline cache (Hive)
    try {
      final cacheService = CacheService();
      await cacheService.initialize();
    } catch (e) {
      debugPrint('[Main] Cache init skipped: $e');
    }

    // Initialize cooking notification service
    try {
      await CookingNotificationService.instance.initialize();
      await CookingNotificationService.instance.requestPermission();
    } catch (e) {
      debugPrint('[Main] Notification init skipped: $e');
    }
  } catch (e, st) {
    debugPrint('[Main] Global init exception: $e\n$st');
  } finally {
    // Remove splash screen now that initialization is complete
    FlutterNativeSplash.remove();
  }

  // Attempt to sync offline analytics on app start
  AnalyticsService.syncQueue();

  runApp(const ProviderScope(child: PlatelyApp()));
}

class PlatelyApp extends StatefulWidget {
  const PlatelyApp({super.key});

  @override
  State<PlatelyApp> createState() => _PlatelyAppState();
}

class _PlatelyAppState extends State<PlatelyApp> {
  final AppSettings _settings = AppSettings();

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: GamificationService.navigatorKey,
      title: 'Plately',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _settings.themeMode,
      locale: _settings.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ko'),
        Locale('uz'),
        Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Cyrl'),
        Locale('ru'),
      ],
      builder: (context, child) {
        // Override ugly red error screen
        ErrorWidget.builder = (details) => Center(
          child: Container(
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7), size: 40),
                SizedBox(height: 12),
                Text('Something went wrong',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 6),
                Text(details.exceptionAsString().split('\n').first,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35), fontSize: 12),
                    textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
        return child ?? SizedBox.shrink();
      },
      home: const _AuthGate(),
    );
  }
}

/// Auth gate — routes to AuthScreen, OnboardingScreen, or AppShell.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool? _onboardingComplete;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null && _onboardingComplete == false) {
        _checkDatabaseOnboarding(session.user.id);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    });
  }

  Future<void> _checkDatabaseOnboarding(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('username, display_name')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final username = response['username'] as String?;
        final displayName = response['display_name'] as String?;
        if ((username != null && username.isNotEmpty) || (displayName != null && displayName.isNotEmpty)) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('onboarding_complete', true);
          if (mounted) {
            setState(() {
              _onboardingComplete = true;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('[AuthGate] Failed to check database onboarding: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          return const AuthScreen();
        }
        // Show onboarding for first-time users
        if (_onboardingComplete == false) {
          return OnboardingScreen(
            onComplete: () => setState(() => _onboardingComplete = true),
          );
        }
        return const AppShell();
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  APP SHELL — Dual-Mode Navigation
// ═══════════════════════════════════════════════════════════════════

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with TickerProviderStateMixin {
  final AppSettings _settings = AppSettings();
  int _currentIndex = 0;

  // ── Cook mode screens ──────────────────────────────
  static const List<Widget> _cookScreens = [
    CookScreen(),          // Recipe (left)
    ScanScreen(),          // Scan (center)
    LivingShelfScreen(),   // Inventory (right)
  ];

  // ── Order mode screens ─────────────────────────────
  static const List<Widget> _orderScreens = [
    OrderScreen(),         // Order
    OrderFeedsScreen(),    // Feeds (center)
  ];

  // ── Cook mode nav items ────────────────────────────
  List<NavItem> _cookNavItems(AppLocalizations? l10n) => [
    NavItem(
      icon: Icons.restaurant_outlined,
      activeIcon: Icons.restaurant,
      label: l10n?.tabCook ?? 'Cook',
    ),
    NavItem(
      icon: Icons.camera_alt_outlined,
      activeIcon: Icons.camera_alt,
      label: l10n?.tabScan ?? 'Scan',
      isCenter: true,
    ),
    NavItem(
      icon: CupertinoIcons.cube_box,
      activeIcon: CupertinoIcons.cube_box_fill,
      label: l10n?.tabShelf ?? 'Shelf',
    ),
  ];

  // ── Order mode nav items ───────────────────────────
  List<NavItem> _orderNavItems(AppLocalizations? l10n) => [
    NavItem(
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront,
      label: 'Order',
    ),
    NavItem(
      icon: Icons.play_circle_outline,
      activeIcon: Icons.play_circle_filled,
      label: 'Feeds',
      isCenter: true,
    ),
    NavItem(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view,
      label: 'Manage',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);

    // Wire notification action buttons to session provider
    CookingNotificationService.instance.onAction = (actionId) {
      final notifier = ref.read(cookingSessionProvider.notifier);
      switch (actionId) {
        case kActionNextStep:
          notifier.advanceStep();
          break;
        case kActionPauseTimer:
          notifier.pauseTimer();
          break;
        case kActionResumeTimer:
          notifier.resumeTimer();
          break;
        case kActionStopCooking:
          notifier.endSession();
          break;
      }
    };

  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    // Reset tab index if mode changed and index is out of bounds
    final maxIndex = _settings.appMode == AppMode.cook
        ? _cookScreens.length - 1
        : _orderScreens.length - 1;
    if (_currentIndex > maxIndex) {
      _currentIndex = 0;
    }
    setState(() {});
  }

  void _switchMode(AppMode mode) {
    if (_settings.appMode == mode) return;
    _currentIndex = 0; // Reset to first tab on mode switch
    _settings.setAppMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const isCook = true; // MVP: Always force Cook mode
    final screens = _cookScreens;
    final navItems = _cookNavItems(l10n);

    // Reactively listen to tutorial state transitions to auto-navigate tabs
    ref.listen<TutorialState>(tutorialControllerProvider, (previous, next) {
      if (next == TutorialState.shelfIntro || next == TutorialState.shelfAdded) {
        if (mounted) setState(() => _currentIndex = 2);
      } else if (next == TutorialState.scanIntro) {
        if (mounted) setState(() => _currentIndex = 1);
      } else if (next == TutorialState.roamCook) {
        if (mounted) setState(() => _currentIndex = 0);
      }
    });

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Column(
            children: [
              // ── Mode Switch Bar ─────────────────────────
              _ModeSwitchBar(
                currentMode: _settings.appMode,
                onModeChanged: _switchMode,
              ),

              // ── Screen Content ──────────────────────────
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: KeyedSubtree(
                    key: ValueKey('${AppMode.cook}_$_currentIndex'),
                    child: screens[_currentIndex],
                  ),
                ),
              ),

              // ── Cooking Mini-Player ─────────────────────
              const CookingMiniPlayer(),
            ],
          ),

          // ── Guided Tutorial Overlay ──
          const TutorialGuideOverlay(),
        ],
      ),
      bottomNavigationBar: DualModeNavBar(
        currentIndex: _currentIndex,
        items: navItems,
        mode: AppMode.cook,
        onTap: (i) {
          final tutorialState = ref.read(tutorialControllerProvider);
          if (tutorialState == TutorialState.none) {
            setState(() => _currentIndex = i);
            return;
          }

          // In interactive tutorial mode, restrict navigation to explicit guidance
          if (tutorialState == TutorialState.shelfAdded && i == 0) {
            ref.read(tutorialControllerProvider.notifier).setStep(TutorialState.roamCook);
            setState(() => _currentIndex = 0);
          } else if (tutorialState == TutorialState.clickAdd && i == 1) {
            ref.read(tutorialControllerProvider.notifier).setStep(TutorialState.scanIntro);
            setState(() => _currentIndex = 1);
          }
        },
      ),
    );
  }
}

// ── Mode Switch Bar (sits below status bar) ─────────────────────────

class _ModeSwitchBar extends StatelessWidget {
  final AppMode currentMode;
  final ValueChanged<AppMode> onModeChanged;

  const _ModeSwitchBar({
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Row(
        children: [
          // App name
          Text(
            'Plately',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          Spacer(),
          // Profile / Manage button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
