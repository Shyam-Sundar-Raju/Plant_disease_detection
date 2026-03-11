# TensorFlow Lite keep and dontwarn rules
-dontwarn org.tensorflow.lite.**
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }

# Image cropping and video thumbnail plugins
-dontwarn com.yalantis.ucrop.**
-keep class com.yalantis.ucrop.** { *; }
-dontwarn xyz.justsoft.video_thumbnail.**
-keep class xyz.justsoft.video_thumbnail.** { *; }

# Passkeys and Corbado
-dontwarn com.corbado.**
-keep class com.corbado.** { *; }
