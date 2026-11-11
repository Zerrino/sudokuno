package com.alexafer.sudokuno.model

import android.content.Context
import android.content.SharedPreferences
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.alexafer.sudokuno.i18n.AppLanguage

enum class AppTheme(val key: String) {
    SYSTEM("system"), LIGHT("light"), DARK("dark");
    companion object { fun from(k: String?) = entries.firstOrNull { it.key == k } ?: SYSTEM }
}

/** Réglages (SharedPreferences), observables par Compose. Mêmes options que sur iOS. */
class Settings(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences("settings", Context.MODE_PRIVATE)

    private fun bool(key: String, default: Boolean) = mutableStateOf(prefs.getBoolean(key, default))

    var theme by mutableStateOf(AppTheme.from(prefs.getString("theme", null))); private set
    var language by mutableStateOf(AppLanguage.fromCode(prefs.getString("appLanguage", null))); private set

    private val _hintsEnabled = bool("hintsEnabled", true)
    private val _highlightConflicts = bool("highlightConflicts", true)
    private val _highlightSame = bool("highlightSameDigits", true)
    private val _highlightRelated = bool("highlightRelated", true)
    private val _autoRemoveNotes = bool("autoRemoveNotes", true)
    private val _showMistakes = bool("showMistakes", true)
    private val _showTimer = bool("showTimer", true)
    private val _haptics = bool("haptics", true)
    private val _reminder = bool("reminderEnabled", false)
    var reminderMinutes by mutableStateOf(prefs.getInt("reminderMinutes", 20 * 60)); private set

    var hintsEnabled: Boolean get() = _hintsEnabled.value; set(v) = put("hintsEnabled", v) { _hintsEnabled.value = it }
    var highlightConflicts: Boolean get() = _highlightConflicts.value; set(v) = put("highlightConflicts", v) { _highlightConflicts.value = it }
    var highlightSameDigits: Boolean get() = _highlightSame.value; set(v) = put("highlightSameDigits", v) { _highlightSame.value = it }
    var highlightRelated: Boolean get() = _highlightRelated.value; set(v) = put("highlightRelated", v) { _highlightRelated.value = it }
    var autoRemoveNotes: Boolean get() = _autoRemoveNotes.value; set(v) = put("autoRemoveNotes", v) { _autoRemoveNotes.value = it }
    var showMistakes: Boolean get() = _showMistakes.value; set(v) = put("showMistakes", v) { _showMistakes.value = it }
    var showTimer: Boolean get() = _showTimer.value; set(v) = put("showTimer", v) { _showTimer.value = it }
    var haptics: Boolean get() = _haptics.value; set(v) = put("haptics", v) { _haptics.value = it }
    var reminderEnabled: Boolean get() = _reminder.value; set(v) = put("reminderEnabled", v) { _reminder.value = it }

    private fun put(key: String, v: Boolean, apply: (Boolean) -> Unit) {
        prefs.edit().putBoolean(key, v).apply()
        apply(v)
    }

    fun updateTheme(t: AppTheme) { prefs.edit().putString("theme", t.key).apply(); theme = t }
    fun updateLanguage(l: AppLanguage) { prefs.edit().putString("appLanguage", l.code).apply(); language = l }
    fun updateReminderMinutes(m: Int) { prefs.edit().putInt("reminderMinutes", m).apply(); reminderMinutes = m }

    /** Tests et captures : forcer des valeurs sans toucher aux préférences enregistrées. */
    fun override(language: AppLanguage? = null, theme: AppTheme? = null) {
        language?.let { this.language = it }
        theme?.let { this.theme = it }
    }
}
