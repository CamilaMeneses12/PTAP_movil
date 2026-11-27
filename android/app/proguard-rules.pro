# Reglas para la versión final (release), que reduce el código con R8.

# Clases opcionales que referencian ML Kit (alfabetos que la app no usa) y MediaPipe
# (perfilador); no vienen en la app y R8 no debe exigirlas.
-dontwarn com.google.mediapipe.proto.CalculatorProfileProto$CalculatorProfile
-dontwarn com.google.mediapipe.proto.GraphTemplateProto$CalculatorGraphTemplate
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# TensorFlow Lite (lector de medidores) y MediaPipe (asistente dentro del celular)
# se cargan desde código nativo: R8 no debe quitarlos ni renombrarlos.
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**
-keep class com.google.mediapipe.** { *; }