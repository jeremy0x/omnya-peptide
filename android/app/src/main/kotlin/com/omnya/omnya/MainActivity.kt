package com.omnya.omnya

import android.graphics.Bitmap
import android.graphics.BitmapShader
import android.graphics.BlurMaskFilter
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.PointF
import android.graphics.RectF
import android.graphics.Shader
import android.media.ExifInterface
import android.media.FaceDetector
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import kotlin.concurrent.thread

/// The Android side of `omnya/native`. Only face blur exists here; the rest is iOS-only.
class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "omnya/native").setMethodCallHandler { call, result ->
      if (call.method != "blurFaces") return@setMethodCallHandler result.notImplemented()
      val path = call.argument<String>("path") ?: ""
      thread {
        val reply = runCatching { blurFaces(path) }.getOrNull()
        Handler(Looper.getMainLooper()).post { result.success(reply) }
      }
    }
  }

  /// The photo as JPEG with every detected face blurred plus the face count, like the iOS Vision version.
  // ponytail: android.media.FaceDetector only finds fairly frontal faces; switch to ML Kit if tilted faces slip through.
  private fun blurFaces(path: String): Map<String, Any>? {
    val photo = upright(path) ?: return null

    // The detector wants RGB_565 with an even width, and is slow on full-size photos.
    val scale = minOf(1f, 1000f / maxOf(photo.width, photo.height))
    val w = (photo.width * scale).toInt() and 1.inv()
    val h = (photo.height * scale).toInt()
    val small = Bitmap.createScaledBitmap(photo, w, h, true).copy(Bitmap.Config.RGB_565, false)
    val faces = arrayOfNulls<FaceDetector.Face>(8)
    val found = FaceDetector(w, h, faces.size).findFaces(small, faces)

    val out = photo.copy(Bitmap.Config.ARGB_8888, true)
    if (found == 0) return mapOf("jpeg" to jpeg(out), "faces" to 0)
    // The blurred copy fills a soft-edged oval over each face. Blur strength follows the biggest face.
    val biggest = faces.take(found).maxOf { it!!.eyesDistance() } / scale
    val levels = maxOf(2, (Math.log(biggest / 4.0) / Math.log(2.0)).toInt())
    val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { shader = BitmapShader(blur(photo, levels), Shader.TileMode.CLAMP, Shader.TileMode.CLAMP) }
    val canvas = Canvas(out)
    val mid = PointF()
    for (face in faces.take(found)) {
      face!!.getMidPoint(mid)
      val eyes = face.eyesDistance() / scale
      val cx = mid.x / scale
      val cy = mid.y / scale + eyes * 0.3f
      // Eye spacing sizes the oval; padded so hairline and chin are covered too.
      paint.maskFilter = BlurMaskFilter(eyes * 0.5f, BlurMaskFilter.Blur.NORMAL)
      canvas.drawOval(RectF(cx - eyes * 1.4f, cy - eyes * 1.9f, cx + eyes * 1.4f, cy + eyes * 1.9f), paint)
    }
    return mapOf("jpeg" to jpeg(out), "faces" to found)
  }

  private fun jpeg(b: Bitmap) = ByteArrayOutputStream().also { b.compress(Bitmap.CompressFormat.JPEG, 90, it) }.toByteArray()

  /// Halve the photo [levels] times, then scale back up with filtering: a cheap blur.
  private fun blur(src: Bitmap, levels: Int): Bitmap {
    var b = src
    repeat(levels) { b = Bitmap.createScaledBitmap(b, maxOf(1, b.width / 2), maxOf(1, b.height / 2), true) }
    return Bitmap.createScaledBitmap(b, src.width, src.height, true)
  }

  /// Camera JPEGs carry their rotation in EXIF; the detector wants the pixels upright.
  private fun upright(path: String): Bitmap? {
    val bitmap = BitmapFactory.decodeFile(path) ?: return null
    val degrees = when (ExifInterface(path).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)) {
      ExifInterface.ORIENTATION_ROTATE_90 -> 90f
      ExifInterface.ORIENTATION_ROTATE_180 -> 180f
      ExifInterface.ORIENTATION_ROTATE_270 -> 270f
      else -> return bitmap
    }
    return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, Matrix().apply { postRotate(degrees) }, true)
  }
}
