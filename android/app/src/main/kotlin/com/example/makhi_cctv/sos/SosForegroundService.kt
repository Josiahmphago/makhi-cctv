package com.example.makhi_cctv.sos

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import com.example.makhi_cctv.R

class SosForegroundService : Service() {

    private var engine: FlutterEngine? = null
    private val CHANNEL_ID = "sos_channel"

    override fun onCreate() {
        super.onCreate()
        createNotificationChannelIfNeeded()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Start as foreground right away
        startForeground(1, buildNotification())

        try {
            // Initialize Flutter runtime & get bundle path
            val loader = FlutterLoader()
            loader.startInitialization(applicationContext)
            loader.ensureInitializationComplete(applicationContext, null)
            val appBundlePath = loader.findAppBundlePath()

            // Spin up a headless engine and execute our entrypoint
            engine = FlutterEngine(this)
            engine!!.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(appBundlePath, "sosBackgroundEntryPoint")
            )

        } catch (e: Exception) {
            e.printStackTrace()
            stopSelf()
            return START_NOT_STICKY
        }

        // Safety: stop service after ~20s if Dart side doesn't stop us earlier
        Thread {
            try { Thread.sleep(20000) } catch (_: Exception) {}
            stopSelf()
        }.start()

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        engine?.destroy()
        engine = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannelIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                CHANNEL_ID, "SOS Alerts", NotificationManager.IMPORTANCE_LOW
            )
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val builder =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(this, CHANNEL_ID)
            } else {
                Notification.Builder(this)
            }

        return builder
            .setContentTitle("Sending SOS")
            .setContentText("Makhi is sending your emergency alert")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .build()
    }
}
