import org.jetbrains.kotlin.gradle.dsl.JvmTarget

// Moteur Sudoku en Kotlin pur : copie EXACTE du SudokuKit Swift (ios/Packages/SudokuKit).
// Les codes de grille doivent donner la même grille sur iOS et Android : voir GoldenTest.
plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.kotlin.serialization)
}

java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

kotlin {
    compilerOptions { jvmTarget.set(JvmTarget.JVM_17) }
}

dependencies {
    implementation(libs.kotlinx.serialization.json)
    testImplementation(libs.junit)
}
