# ─── Sustain release (R8) keep rules ──────────────────────────────────────────
# Most Flutter plugins ship consumer ProGuard rules that R8 applies automatically.
# These are belt-and-suspenders for the reflection / Gson-using ones, so a
# minified release behaves exactly like debug.

-keepattributes Signature, *Annotation*, InnerClasses, EnclosingMethod

# flutter_local_notifications — serializes notification details via Gson.
-keep class com.dexterous.** { *; }

# Gson (pulled in by flutter_local_notifications).
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-dontwarn com.google.gson.**

# flutter_foreground_task — the service + task handler are resolved by name.
-keep class com.pravera.flutter_foreground_task.** { *; }

# RevenueCat + Google Play Billing — purchases must not break under R8.
-keep class com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**
-keep class com.android.billingclient.** { *; }

# Drift / sqlite3.
-keep class com.simolus.drift.** { *; }
-dontwarn org.sqlite.**

# Tink / crypto (transitive, used by some plugins).
-dontwarn javax.annotation.**
-dontwarn com.google.errorprone.annotations.**

# image_cropper (uCrop) — native crop activity resolved by name.
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**
