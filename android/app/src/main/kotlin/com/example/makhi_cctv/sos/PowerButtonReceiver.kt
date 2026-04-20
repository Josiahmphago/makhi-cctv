package com.example.makhi_cctv.sos

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.SystemClock

class PowerButtonReceiver : BroadcastReceiver() {

    companion object {
        private var lastTime: Long = 0L
        private var count: Int = 0
        private const val WINDOW_MS = 1500L  // 1.5s to detect triple press
        private const val REQUIRED = 3
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return

        if (action == Intent.ACTION_SCREEN_OFF || action == Intent.ACTION_SCREEN_ON) {
            val now = SystemClock.elapsedRealtime()
            if (now - lastTime > WINDOW_MS) {
                count = 0
            }
            count++
            lastTime = now

            if (count >= REQUIRED) {
                count = 0
                // start foreground service to run SOS
                val svc = Intent(context, SosForegroundService::class.java)
                svc.putExtra("reason", "power_triple_press")
                try {
                  context.startForegroundService(svc)
                } catch (e: Exception) {
                  // fallback pre-O
                  context.startService(svc)
                }
            }
        } else if (action == Intent.ACTION_BOOT_COMPLETED) {
            // (Optional) re-register anything needed on boot
        }
    }
}
