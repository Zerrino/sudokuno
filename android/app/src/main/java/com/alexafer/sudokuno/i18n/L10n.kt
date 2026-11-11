package com.alexafer.sudokuno.i18n

import android.content.Context
import org.json.JSONObject
import java.util.Locale

/** Langues proposées dans les réglages (mêmes que sur iOS). */
enum class AppLanguage(val code: String) {
    SYSTEM("system"), FR("fr"), EN("en"), NL("nl"), PT("pt-PT"), ZH("zh-Hans");

    val nativeName: String
        get() = when (this) {
            SYSTEM -> L("Langue de l'appareil")
            FR -> "Français"
            EN -> "English"
            NL -> "Nederlands"
            PT -> "Português"
            ZH -> "简体中文"
        }

    companion object {
        fun fromCode(code: String?) = entries.firstOrNull { it.code == code } ?: SYSTEM
    }
}

/**
 * Traductions partagées avec iOS : la clé est le texte français (comme la fonction L en Swift),
 * les valeurs viennent de assets/i18n.json, généré par tools/translations.py.
 */
object L10n {
    private var tables: Map<String, JSONObject> = emptyMap()
    var code: String = "fr"
        private set
    var locale: Locale = Locale.FRENCH
        private set

    fun load(context: Context) {
        if (tables.isNotEmpty()) return
        val json = JSONObject(context.assets.open("i18n.json").bufferedReader().use { it.readText() })
        tables = json.keys().asSequence().associateWith { json.getJSONObject(it) }
    }

    fun apply(language: AppLanguage) {
        code = if (language == AppLanguage.SYSTEM) resolveSystem() else language.code
        locale = Locale.forLanguageTag(code)
    }

    /** Première langue gérée parmi les langues préférées du téléphone ; sinon l'anglais. */
    private fun resolveSystem(): String {
        val list = android.os.LocaleList.getDefault()
        for (i in 0 until list.size()) {
            supported(list[i].language)?.let { return it }
        }
        return "en"
    }

    fun supported(language: String): String? = when (language) {
        "fr" -> "fr"
        "en" -> "en"
        "nl" -> "nl"
        "pt" -> "pt-PT"
        "zh" -> "zh-Hans"
        else -> null
    }

    /** Règle de pluriel : français 0 et 1 au singulier ; anglais, néerlandais, portugais 1 ; chinois aucun. */
    private fun pluralCategory(n: Long): String = when (code) {
        "fr" -> if (n == 0L || n == 1L) "one" else "other"
        "zh-Hans" -> "other"
        else -> if (n == 1L) "one" else "other"
    }

    private val formatRegex = Regex("%(\\d+\\$)?(0?\\d*)lld")
    private val objectRegex = Regex("%(\\d+\\$)?@")

    /** Formats Apple → Java, comme dans tools/translations.py. */
    fun toJava(key: String): String = key
        .replace(formatRegex) { "%" + it.groupValues[1] + it.groupValues[2] + "d" }
        .replace(objectRegex) { "%" + it.groupValues[1] + "s" }

    fun lookup(key: String, count: Long?): String {
        val jkey = toJava(key)
        val entry = tables[code]?.opt(jkey) ?: tables["fr"]?.opt(jkey)
        return when (entry) {
            is String -> entry
            is JSONObject -> {
                val cat = if (count != null) pluralCategory(count) else "other"
                entry.optString(cat, entry.optString("other", jkey))
            }
            else -> jkey
        }
    }
}

/** Texte traduit. */
fun L(key: String): String = L10n.lookup(key, null)

/** Texte traduit avec paramètres ; le premier entier choisit la forme du pluriel. */
fun L(key: String, vararg args: Any): String {
    val count = args.firstOrNull { it is Int || it is Long }?.let { (it as Number).toLong() }
    return String.format(L10n.locale, L10n.lookup(key, count), *args)
}
