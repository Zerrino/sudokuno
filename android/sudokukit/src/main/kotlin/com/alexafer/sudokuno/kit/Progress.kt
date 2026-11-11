package com.alexafer.sudokuno.kit

import kotlinx.serialization.Serializable

/** Série à la Duolingo sur la grille du jour (jours UTC). Traduction de StreakState (Progress.swift). */
@Serializable
class StreakState(
    var current: Int = 0,
    var longest: Int = 0,
    var freezes: Int = 0,
    var coveredThrough: DayStamp? = null,
    val completedDays: MutableSet<DayStamp> = mutableSetOf(),
    val frozenDays: MutableSet<DayStamp> = mutableSetOf(),
) {
    sealed interface Event {
        data class FreezesUsed(val count: Int) : Event
        data object Reset : Event
    }

    /** Consomme les gels pour les jours manqués ou remet la série à zéro. Idempotent. */
    fun refresh(today: DayStamp): Event? {
        val covered = coveredThrough ?: return null
        if (current <= 0) return null
        val missed = today.dayNumber - covered.dayNumber - 1
        if (missed <= 0) return null
        if (missed <= freezes) {
            freezes -= missed
            for (k in 1..missed) frozenDays.add(covered.adding(k))
            coveredThrough = today.adding(-1)
            return Event.FreezesUsed(missed)
        }
        current = 0
        return Event.Reset
    }

    /** Grille du jour `day` réussie le jour même. Retourne le jalon atteint, s'il y en a un. */
    fun recordCompletion(day: DayStamp): Int? {
        refresh(day)
        val covered = coveredThrough
        if (covered != null && covered >= day) {
            completedDays.add(day)
            return null
        }
        current = if (covered != null && covered.dayNumber == day.dayNumber - 1 && current > 0) current + 1 else 1
        coveredThrough = day
        completedDays.add(day)
        longest = maxOf(longest, current)
        if (current % DAYS_PER_FREEZE == 0 && freezes < MAX_FREEZES) freezes++
        return if (current in MILESTONES) current else null
    }

    fun isAtRisk(today: DayStamp) = current > 0 && coveredThrough != today
    fun isCompleted(day: DayStamp) = day in completedDays

    companion object {
        const val MAX_FREEZES = 2
        const val DAYS_PER_FREEZE = 7
        val MILESTONES = listOf(3, 7, 14, 30, 50, 100, 365)
    }
}

/** Déblocage des niveaux après N victoires au niveau précédent. */
@Serializable
class LevelProgress(val wins: MutableMap<Level, Int> = mutableMapOf()) {
    fun winCount(level: Level) = wins[level] ?: 0

    fun isUnlocked(level: Level): Boolean {
        val previous = Level.fromOrdinal(level.ordinal - 1) ?: return true
        return isUnlocked(previous) && winCount(previous) >= requirement(level)
    }

    /** (victoires au niveau précédent, victoires requises) pour un niveau verrouillé. */
    fun unlockProgress(level: Level): Pair<Int, Int>? {
        if (isUnlocked(level)) return null
        val previous = Level.fromOrdinal(level.ordinal - 1) ?: return null
        return minOf(winCount(previous), requirement(level)) to requirement(level)
    }

    /** Enregistre une victoire ; retourne le niveau nouvellement débloqué. */
    fun recordWin(level: Level): Level? {
        val before = Level.entries.filter(::isUnlocked)
        wins[level] = winCount(level) + 1
        return Level.entries.firstOrNull { isUnlocked(it) && it !in before }
    }

    companion object {
        fun requirement(level: Level) = when (level) {
            Level.FACILE -> 0
            Level.MOYEN -> 5
            Level.LEGENDE -> 5
            else -> 10
        }
    }
}
