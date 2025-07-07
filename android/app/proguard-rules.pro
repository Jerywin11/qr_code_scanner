# Flutter wrapper
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep main activity
-keep class com.example.qr_code_scanner.MainActivity { *; }

# Don't obfuscate JSON model classes (optional, if you use json_serializable or similar)
#-keep class com.example.qr_code_scanner.model.** { *; }

# Optional: Keep your Firebase/Google services configs
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Prevent obfuscation of Parcelable classes
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}
# Prevent Flutter deferred component classes from being removed
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep Flutter's internal deferred loading references
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# If you use split APKs or feature modules (deferred components)
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
