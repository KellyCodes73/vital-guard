package com.vitalguard.vital_guard

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createAlertChannel()
    }

    /**
     * Canal de alta prioridad para las alertas de Vital Guard: suena como alarma, vibra y aparece
     * como ventana emergente, incluso con la pantalla bloqueada. Crear un canal que ya existe no
     * tiene efecto, así que es seguro hacerlo en cada inicio.
     */
    private fun createAlertChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return

        val sound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

        val channel = NotificationChannel(
            ALERT_CHANNEL_ID,
            "Alertas de Vital Guard",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Avisos cuando una persona vinculada podría necesitar ayuda"
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 600, 300, 600, 300, 900)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            setSound(
                sound,
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            )
        }
        manager.createNotificationChannel(channel)
    }

    companion object {
        const val ALERT_CHANNEL_ID = "vital_guard_alerts"
    }
}
