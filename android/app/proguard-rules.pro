# Flutter & Dart reflection
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Cloud Firestore
-keep class com.google.firestore.** { *; }
-dontwarn com.google.firestore.**

# Background Services
-keep class dev.fluttercommunity.plus.** { *; }
-dontwarn dev.fluttercommunity.plus.**

# Prevent stripping for geolocator, connectivity, etc.
-keep class com.baseflow.** { *; }

# Kotlin coroutine internals (used by Firebase & services)
-keepclassmembers class kotlinx.coroutines.** {
    *;
}

# JSON serialization (Hive, Firebase, etc.)
-keepclassmembers class ** {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Required for camera/image_picker
-keep class com.yourpackage.** { *; }
