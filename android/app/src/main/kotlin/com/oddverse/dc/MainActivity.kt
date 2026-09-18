package com.oddverse.dc

import android.content.ContentUris
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Size
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.oddverse.dc/media_store"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "queryAudioFiles") {
                Thread {
                    try {
                        val audioList = mutableListOf<Map<String, Any?>>()
                        val projection = arrayOf(
                            MediaStore.Audio.Media._ID,
                            MediaStore.Audio.Media.TITLE,
                            MediaStore.Audio.Media.ARTIST,
                            MediaStore.Audio.Media.ALBUM,
                            MediaStore.Audio.Media.DURATION,
                            MediaStore.Audio.Media.DATA,
                            MediaStore.Audio.Media.DATE_MODIFIED,
                            MediaStore.Audio.Media.ALBUM_ID
                        )

                        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0 OR ${MediaStore.Audio.Media.DURATION} > 5000"
                        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"

                        val cursor = contentResolver.query(
                            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                            projection,
                            selection,
                            null,
                            sortOrder
                        )

                        val artDir = File(cacheDir, "local_art")
                        if (!artDir.exists()) {
                            artDir.mkdirs()
                        }

                        cursor?.use { c ->
                            val idCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
                            val titleCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
                            val artistCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
                            val albumCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
                            val durationCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
                            val dataCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
                            val dateCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_MODIFIED)
                            val albumIdCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)

                            while (c.moveToNext()) {
                                val id = c.getLong(idCol)
                                val title = c.getString(titleCol) ?: "Unknown"
                                val artist = c.getString(artistCol) ?: "Unknown Artist"
                                val album = c.getString(albumCol) ?: "Device Audio"
                                val duration = c.getLong(durationCol)
                                val data = c.getString(dataCol) ?: ""
                                val date = c.getLong(dateCol)
                                val albumId = c.getLong(albumIdCol)

                                var artFilePath = ""
                                val artFile = File(artDir, "art_${albumId}_${id}.jpg")
                                
                                if (artFile.exists() && artFile.length() > 0) {
                                    artFilePath = artFile.absolutePath
                                } else {
                                    val songUri = ContentUris.withAppendedId(
                                        MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                                        id
                                    )

                                    // Method 1: ContentUri MediaMetadataRetriever
                                    try {
                                        val mmr = MediaMetadataRetriever()
                                        mmr.setDataSource(applicationContext, songUri)
                                        val artBytes = mmr.embeddedPicture
                                        mmr.release()
                                        if (artBytes != null && artBytes.isNotEmpty()) {
                                            FileOutputStream(artFile).use { fos ->
                                                fos.write(artBytes)
                                            }
                                            artFilePath = artFile.absolutePath
                                        }
                                    } catch (_: Exception) {}

                                    // Method 2: Android 10+ loadThumbnail
                                    if (artFilePath.isEmpty() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                        try {
                                            val bitmap = contentResolver.loadThumbnail(
                                                songUri,
                                                Size(256, 256),
                                                null
                                            )
                                            FileOutputStream(artFile).use { fos ->
                                                bitmap.compress(Bitmap.CompressFormat.JPEG, 85, fos)
                                            }
                                            artFilePath = artFile.absolutePath
                                        } catch (_: Exception) {}
                                    }

                                    // Method 3: Direct file path MediaMetadataRetriever
                                    if (artFilePath.isEmpty() && data.isNotEmpty() && File(data).exists()) {
                                        try {
                                            val mmr = MediaMetadataRetriever()
                                            mmr.setDataSource(data)
                                            val artBytes = mmr.embeddedPicture
                                            mmr.release()
                                            if (artBytes != null && artBytes.isNotEmpty()) {
                                                FileOutputStream(artFile).use { fos ->
                                                    fos.write(artBytes)
                                                }
                                                artFilePath = artFile.absolutePath
                                            }
                                        } catch (_: Exception) {}
                                    }

                                    // Method 4: Legacy ContentResolver stream
                                    if (artFilePath.isEmpty() && albumId > 0) {
                                        try {
                                            val albumArtUri = ContentUris.withAppendedId(
                                                Uri.parse("content://media/external/audio/albumart"),
                                                albumId
                                            )
                                            val stream: InputStream? = contentResolver.openInputStream(albumArtUri)
                                            stream?.use { input ->
                                                FileOutputStream(artFile).use { output ->
                                                    input.copyTo(output)
                                                }
                                                if (artFile.length() > 0) {
                                                    artFilePath = artFile.absolutePath
                                                }
                                            }
                                        } catch (_: Exception) {}
                                    }
                                }

                                val item = mapOf(
                                    "id" to id.toString(),
                                    "title" to title,
                                    "artist" to artist,
                                    "album" to album,
                                    "duration" to (duration / 1000).toInt(),
                                    "path" to data,
                                    "date" to (date * 1000),
                                    "albumId" to albumId.toString(),
                                    "artUri" to artFilePath
                                )
                                audioList.add(item)
                            }
                        }

                        runOnUiThread {
                            result.success(audioList)
                        }
                    } catch (e: Exception) {
                        runOnUiThread {
                            result.error("QUERY_ERROR", e.message, null)
                        }
                    }
                }.start()
            } else {
                result.notImplemented()
            }
        }
    }
}
