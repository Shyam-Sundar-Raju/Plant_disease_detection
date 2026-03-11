# TensorFlow Lite keep rules
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }

# Image cropping and video thumbnail plugins
-keep class com.yalantis.ucrop.** { *; }
-keep class xyz.justsoft.video_thumbnail.** { *; }

# Passkeys and Corbado
-keep class com.corbado.** { *; }
