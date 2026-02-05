#Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Prevent obfuscation of Flutter's entry point
-keep class com.appTenda.tucttx.MainActivity { *; }

# Gson (if used indirectly)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.examples.android.model.** { *; }

## FlutterFire
-keep class com.google.firebase.** { *; }

# Kotlin
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

# Coroutines
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# Device Calendar
-keep class com.builttoro.devicecalendar.** { *; }

# Add 2 Calendar
-keep class com.add_2_calendar.** { *; }

# View models / Models
-keep class com.appTenda.tucttx.domain.models.** { *; }

