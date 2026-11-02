// Plately — Public Focused Release Configuration
// ===============================================
// Centralized feature flags and fair-use quotas governing the public launch.
// Unused or advanced multi-surface capabilities (Order mode, Social feeds, Creator paywalls,
// IoT simulations) are safely gated here without deleting underlying code.

class ReleaseConfig {
  /// Whether B2C restaurant ordering, delivery tracking, and cart are enabled in public UI.
  /// Set to false to focus on the zero-waste smart pantry & cooking companion.
  static const bool enableOrderMode = false;

  /// Whether Social Feeds, Reels, and public story posting are enabled.
  /// Set to false for the focused utility launch.
  static const bool enableSocialFeeds = false;

  /// Whether Creator studio, recipe monetization, and tips/paywalls are enabled.
  /// Set to false; the focused public consumer launch is 100% free with no paywalls.
  static const bool enableCreatorMonetization = false;

  /// Whether Simulated IoT sensors (smart fridge, RFID, weight scales) are enabled.
  /// Set to false to avoid confusing simulated mocks with real hardware.
  static const bool enableIotSensors = false;

  /// Daily Fair-Use Limits for Server-Side AI calls.
  /// Aligned with the engineering fair-use allowance ($10/mo shared allocation).
  static const int dailyScanQuota = 3;
  static const int dailyRecipeGenQuota = 2;

  /// Disclaimers for user transparency
  static const String nutritionDisclaimer =
      'Nutritional values and calories are estimated by AI models for guidance only. '
      'Verify details before relying on them for specific dietary or medical needs.';
}
