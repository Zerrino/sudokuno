package com.alexafer.sudokuno.services

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import com.alexafer.sudokuno.MainActivity
import com.alexafer.sudokuno.R
import com.alexafer.sudokuno.i18n.L
import com.alexafer.sudokuno.i18n.L10n
import java.util.Calendar

/** Rappel local de la série (aucune donnée ne quitte l'appareil). */
object Reminder {
    private const val CHANNEL = "streak"

    fun reschedule(context: Context, enabled: Boolean, minutes: Int, streak: Int, doneToday: Boolean) {
        val am = context.getSystemService(AlarmManager::class.java)
        val pi = pending(context, streak)
        am.cancel(pi)
        if (!enabled) return
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, minutes / 60); set(Calendar.MINUTE, minutes % 60); set(Calendar.SECOND, 0)
        }
        if (doneToday || cal.timeInMillis <= System.currentTimeMillis()) cal.add(Calendar.DAY_OF_YEAR, 1)
        am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, cal.timeInMillis, pi)
    }

    private fun pending(context: Context, streak: Int): PendingIntent {
        val i = Intent(context, ReminderReceiver::class.java).putExtra("streak", streak)
        return PendingIntent.getBroadcast(context, 1, i, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    fun ensureChannel(context: Context) {
        val nm = context.getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(NotificationChannel(CHANNEL, L("Rappel de série"), NotificationManager.IMPORTANCE_DEFAULT))
    }

    fun post(context: Context, streak: Int) {
        L10n.load(context)
        ensureChannel(context)
        val open = PendingIntent.getActivity(context, 0, Intent(context, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        val text = if (streak > 0) L("Ta série de %lld jours t'attend 🔥 Le Sudoku du jour est prêt.", streak)
        else L("Le Sudoku du jour est prêt. Lance ta série 🔥")
        val n = android.app.Notification.Builder(context, CHANNEL)
            .setSmallIcon(R.mipmap.ic_launcher_monochrome)
            .setContentTitle("Sudokuno")
            .setContentText(text)
            .setContentIntent(open)
            .setAutoCancel(true)
            .build()
        if (Build.VERSION.SDK_INT < 33 ||
            context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) == android.content.pm.PackageManager.PERMISSION_GRANTED
        ) {
            context.getSystemService(NotificationManager::class.java).notify(1, n)
        }
    }
}

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val streak = intent.getIntExtra("streak", 0)
        Reminder.post(context, streak)
        // Prochain rappel demain à la même heure
        val prefs = context.getSharedPreferences("settings", Context.MODE_PRIVATE)
        Reminder.reschedule(context, prefs.getBoolean("reminderEnabled", false), prefs.getInt("reminderMinutes", 20 * 60), streak, doneToday = true)
    }
}
