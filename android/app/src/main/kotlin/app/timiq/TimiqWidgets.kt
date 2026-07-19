package app.timiq

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.BroadcastReceiver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.net.Uri
import org.json.JSONObject
import java.util.UUID
import kotlin.concurrent.thread
import kotlin.math.max

abstract class TimiqWidgetProvider(
    private val size: WidgetSize,
) : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val pendingResult = goAsync()
        thread(name = "timiq-widget-refresh") {
            try {
                PlatformSync.updateFavoriteTotals(context)
                appWidgetIds.forEach { id ->
                    appWidgetManager.updateAppWidget(
                        id,
                        PlatformSync.buildWidget(context, size),
                    )
                }
            } finally {
                pendingResult.finish()
            }
        }
    }
}

class TimiqSmallWidget : TimiqWidgetProvider(WidgetSize.SMALL)
class TimiqMediumWidget : TimiqWidgetProvider(WidgetSize.MEDIUM)
class TimiqLargeWidget : TimiqWidgetProvider(WidgetSize.LARGE)

class TimerActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pendingResult = goAsync()
        thread(name = "timiq-widget-action") {
            try {
                when (intent.action) {
                    ACTION_START -> {
                        val activityId = intent.getStringExtra(EXTRA_ACTIVITY_ID)
                        if (!activityId.isNullOrBlank()) {
                            switchActivity(context, activityId)
                        }
                    }
                    ACTION_STOP -> stopActivity(context)
                }
                PlatformSync.updateFavoriteTotals(context)
                PlatformSync.refreshSurfaces(context)
            } finally {
                pendingResult.finish()
            }
        }
    }

    private fun switchActivity(context: Context, activityId: String) {
        withWritableDatabase(context) { db ->
            db.beginTransaction()
            try {
                val now = System.currentTimeMillis()
                var newStart = now
                var sameActivity = false
                db.query(
                    "time_entries",
                    arrayOf("id", "activity_id", "start_time"),
                    "end_time IS NULL",
                    null,
                    null,
                    null,
                    null,
                    "1",
                ).use { cursor ->
                    if (cursor.moveToFirst()) {
                        val entryId = cursor.getString(0)
                        val runningActivity = cursor.getString(1)
                        val runningStart = cursor.getLong(2)
                        if (runningActivity == activityId) {
                            sameActivity = true
                        } else {
                            newStart = max(now, runningStart + 1L)
                            db.update(
                                "time_entries",
                                ContentValues().apply {
                                    put("end_time", newStart)
                                    put("updated_at", newStart)
                                },
                                "id = ?",
                                arrayOf(entryId),
                            )
                        }
                    }
                }
                if (!sameActivity && activityIsAvailable(db, activityId)) {
                    db.insertOrThrow(
                        "time_entries",
                        null,
                        ContentValues().apply {
                            put(
                                "id",
                                "entry_${System.currentTimeMillis()}_${UUID.randomUUID()}",
                            )
                            put("activity_id", activityId)
                            put("start_time", newStart)
                            putNull("end_time")
                            put("note", "")
                            put("created_at", newStart)
                            put("updated_at", newStart)
                        },
                    )
                }
                db.setTransactionSuccessful()
            } finally {
                db.endTransaction()
            }
            PlatformSync.setActive(context, readActive(db))
        }
    }

    private fun stopActivity(context: Context) {
        withWritableDatabase(context) { db ->
            db.beginTransaction()
            try {
                db.query(
                    "time_entries",
                    arrayOf("id", "start_time"),
                    "end_time IS NULL",
                    null,
                    null,
                    null,
                    null,
                    "1",
                ).use { cursor ->
                    if (cursor.moveToFirst()) {
                        val now = max(
                            System.currentTimeMillis(),
                            cursor.getLong(1) + 1L,
                        )
                        db.update(
                            "time_entries",
                            ContentValues().apply {
                                put("end_time", now)
                                put("updated_at", now)
                            },
                            "id = ?",
                            arrayOf(cursor.getString(0)),
                        )
                    }
                }
                db.setTransactionSuccessful()
            } finally {
                db.endTransaction()
            }
        }
        PlatformSync.setActive(context, null)
    }

    private fun activityIsAvailable(
        db: SQLiteDatabase,
        activityId: String,
    ): Boolean {
        db.rawQuery(
            """
            SELECT 1
            FROM activities a
            INNER JOIN categories c ON c.id = a.category_id
            WHERE a.id = ? AND a.is_archived = 0 AND c.is_archived = 0
            LIMIT 1
            """.trimIndent(),
            arrayOf(activityId),
        ).use { cursor -> return cursor.moveToFirst() }
    }

    private fun readActive(db: SQLiteDatabase): JSONObject? {
        db.rawQuery(
            """
            SELECT e.id, a.id, a.name, c.name,
                   COALESCE(a.custom_color_value, c.color_value), e.start_time
            FROM time_entries e
            INNER JOIN activities a ON a.id = e.activity_id
            INNER JOIN categories c ON c.id = a.category_id
            WHERE e.end_time IS NULL
            LIMIT 1
            """.trimIndent(),
            null,
        ).use { cursor ->
            if (!cursor.moveToFirst()) return null
            return JSONObject()
                .put("entryId", cursor.getString(0))
                .put("activityId", cursor.getString(1))
                .put("activityName", cursor.getString(2))
                .put("categoryName", cursor.getString(3))
                .put("color", cursor.getInt(4))
                .put("startTime", cursor.getLong(5))
        }
    }

    private fun withWritableDatabase(
        context: Context,
        action: (SQLiteDatabase) -> Unit,
    ) {
        val file = context.getDatabasePath("timiq.db")
        if (!file.exists()) return
        runCatching {
            SQLiteDatabase.openDatabase(
                file.absolutePath,
                null,
                SQLiteDatabase.OPEN_READWRITE,
            ).use(action)
        }
    }

    companion object {
        const val ACTION_START = "app.timiq.action.START_ACTIVITY"
        const val ACTION_STOP = "app.timiq.action.STOP_ACTIVITY"
        private const val EXTRA_ACTIVITY_ID = "activity_id"

        fun startIntent(
            context: Context,
            activityId: String,
            slot: Int,
        ): PendingIntent {
            val intent = Intent(context, TimerActionReceiver::class.java).apply {
                action = ACTION_START
                data = Uri.parse("timiq://activity/$activityId")
                putExtra(EXTRA_ACTIVITY_ID, activityId)
            }
            return PendingIntent.getBroadcast(
                context,
                100 + slot,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        fun stopIntent(context: Context): PendingIntent {
            val intent = Intent(context, TimerActionReceiver::class.java).apply {
                action = ACTION_STOP
                data = Uri.parse("timiq://timer/stop")
            }
            return PendingIntent.getBroadcast(
                context,
                99,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            val pendingResult = goAsync()
            thread(name = "timiq-boot-refresh") {
                try {
                    PlatformSync.updateFavoriteTotals(context)
                    PlatformSync.refreshSurfaces(context)
                } finally {
                    pendingResult.finish()
                }
            }
        }
    }
}
