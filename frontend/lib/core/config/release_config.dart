// Plately — Project Showcase & Ecosystem Capabilities Configuration
// =================================================================
// Centralized feature flags and demo indicators governing the public showcase.
// Enables the full ecosystem (Cook, Order, Feeds, Social, Kitchen OS) in a labeled demo state.

class ReleaseConfig {
  /// Whether this build operates as a labeled interactive project showcase.
  static const bool isDemoShowcase = true;

  /// Label shown to clarify that Plately is demonstrating its capabilities prior to commercial rollout.
  static const String demoBannerText =
      'PROJECT SHOWCASE & DEMO • Demonstrating full Plately ecosystem capabilities (Pre-Launch)';

  /// Whether B2C restaurant ordering, delivery tracking, and cart are enabled in public UI.
  /// Enabled for full capabilities demonstration.
  static const bool enableOrderMode = true;

  /// Whether Social Feeds, Reels, and public story posting are enabled.
  /// Enabled for full capabilities demonstration.
  static const bool enableSocialFeeds = true;

  /// Whether Creator studio, recipe monetization, and tips/paywalls are visible in showcase mode.
  static const bool enableCreatorMonetization = true;

  /// Whether Simulated IoT sensors (smart fridge, RFID, weight scales) are enabled for demo.
  static const bool enableIotSensors = true;

  /// Daily Fair-Use Limits for Server-Side AI calls.
  /// Generous allocation for demo testing.
  static const int dailyScanQuota = 10;
  static const int dailyRecipeGenQuota = 10;

  /// Disclaimers for user transparency
  static const String nutritionDisclaimer =
      'Nutritional values and calories are estimated by AI models for guidance only. '
      'Verify details before relying on them for specific dietary or medical needs.';

  static const String demoProjectDisclaimer =
      'Plately is an interactive project showcase demonstrating full consumer pantry AI, '
      'dining, and restaurant operating capabilities. We have not yet officially launched commercial services.';
}
