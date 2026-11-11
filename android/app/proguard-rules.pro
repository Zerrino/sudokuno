# kotlinx.serialization : garder les sérialiseurs générés
-keepattributes *Annotation*, InnerClasses
-keepclassmembers class **$$serializer { *; }
-keepclasseswithmembers class com.alexafer.sudokuno.** { kotlinx.serialization.KSerializer serializer(...); }
-keep,includedescriptorclasses class com.alexafer.sudokuno.**$$serializer { *; }
