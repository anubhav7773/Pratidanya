# ==============================================================================
# PRATIDNYA LEGAL TECH (ASIVERTICALS)
# PRODUCTION R8 & PROGUARD OBFUSCATION RULES
# ==============================================================================

# Flutter Core Obfuscation
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Play Billing In-App Purchase API
-keep class com.android.vending.billing.** { *; }
-keep class com.google.android.gms.internal.play_billing.** { *; }

# Google Mobile Ads (AdMob)
-keep public class com.google.android.gms.ads.** {
   public *;
}
-keep public class com.google.ads.** {
   public *;
}

# Supabase & GoTrue / Postgrest Models
-keepattributes *Annotation*,EnclosingMethod,Signature,InnerClasses
-keepclassmembers enum * { *; }

# Audio Recording Library (Record)
-keep class com.llfbandit.record.** { *; }

# Printing & PDF Rendering Library
-keep class net.nfet.flutter.printing.** { *; }

# Suppress harmless warnings during release compilation
-dontwarn okio.**
-dontwarn javax.annotation.**
