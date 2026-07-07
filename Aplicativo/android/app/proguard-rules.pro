# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# flutter_background_service
-keep class id.flutter.flutter_background_service.** { *; }

# mqtt_client
-keep class org.dna.mqtt.** { *; }
-dontwarn javax.naming.**

# flutter_local_notifications
-keep class com.dexterous.** { *; }

# NOVO: ignora classes do Play Core (deferred components) que o projeto não usa
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication