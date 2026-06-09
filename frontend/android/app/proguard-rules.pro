# ── Plately ProGuard Rules ──────────────────────────────
# Keep Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Supabase / GoTrue
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Keep Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Keep share_plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# Keep url_launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Keep Hive (offline cache)
-keep class com.crazecoder.openfile.** { *; }

# Keep geolocator
-keep class com.baseflow.geolocator.** { *; }

# General: keep annotations
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable

# Prevent R8 from stripping error info
-keepattributes Exceptions

# Ignore missing Play Core classes referenced by Flutter Play Store split library
-dontwarn com.google.android.play.core.**

