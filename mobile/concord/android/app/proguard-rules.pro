# Concord release R8/ProGuard rules.
#
# `isMinifyEnabled`/`isShrinkResources` are on for release builds. WebRTC
# (via livekit_client -> flutter_webrtc) talks to native code through JNI and
# reflection, so it's easy for R8 to strip classes/methods it can't see are
# used, silently breaking calls at runtime. Keep the native-bridge surface
# area for those plugins intact; let R8 shrink/obfuscate everything else.

# WebRTC (org.webrtc.*) is referenced from JNI in libwebrtc.so - keep the
# whole package so R8 doesn't strip/rename anything the native side expects.
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# flutter_webrtc's own plugin/bridge classes.
-keep class com.cloudwebrtc.webrtc.** { *; }
-dontwarn com.cloudwebrtc.webrtc.**

# livekit_client's Android bridge.
-keep class io.livekit.android.** { *; }
-dontwarn io.livekit.android.**

# mobile_scanner (QR/barcode scanning) uses ML Kit's barcode scanning model,
# which is also loaded reflectively.
-keep class com.google.mlkit.vision.barcode.** { *; }
-dontwarn com.google.mlkit.vision.barcode.**

# Keep annotation info used by Flutter plugin generated registrants.
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
