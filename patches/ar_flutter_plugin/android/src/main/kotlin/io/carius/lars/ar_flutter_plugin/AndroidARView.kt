package io.carius.lars.ar_flutter_plugin

import android.app.Activity
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Rect
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import android.view.MotionEvent
import android.view.PixelCopy
import android.view.View
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.lifecycleScope
import com.google.ar.core.*
import io.carius.lars.ar_flutter_plugin.Serialization.deserializeMatrix4
import io.carius.lars.ar_flutter_plugin.Serialization.serializeHitResult
import io.github.sceneview.ar.ARSceneView
import io.github.sceneview.ar.node.AnchorNode
import io.github.sceneview.node.ModelNode
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import java.io.ByteArrayOutputStream
import java.io.IOException
import kotlinx.coroutines.*

internal class AndroidARView(
    val activity: Activity,
    context: Context,
    messenger: BinaryMessenger,
    id: Int,
    creationParams: Map<String?, Any?>?
) : PlatformView {

    private val TAG = AndroidARView::class.java.name

    private val sessionManagerChannel = MethodChannel(messenger, "arsession_$id")
    private val objectManagerChannel  = MethodChannel(messenger, "arobjects_$id")
    private val anchorManagerChannel  = MethodChannel(messenger, "aranchors_$id")

    private val arSceneView: ARSceneView

    // Image-based AR tracking
    private val detectedImages = mutableSetOf<String>()

    // Plane-tap anchor tracking (AR 3D demo)
    private val planeAnchorNodes = mutableMapOf<String, AnchorNode>()

    // Keep the augmented-image DB reference so we can re-apply on session reconfigure
    private var augmentedImageDb: AugmentedImageDatabase? = null

    @Volatile private var lastFrame: Frame? = null

    private val scope: CoroutineScope =
        (activity as? LifecycleOwner)?.lifecycleScope
            ?: CoroutineScope(Dispatchers.Main + SupervisorJob())

    // ──────────────────────────────────────────────────────────────
    // Initialisation — sessionConfiguration MUST be in the constructor
    // so it is guaranteed to fire before the first AR frame, even when
    // the Activity lifecycle is already RESUMED when the PlatformView
    // is created (which is always the case in Flutter).
    // ──────────────────────────────────────────────────────────────

    init {
        val lifecycle = (activity as? LifecycleOwner)?.lifecycle
        val ctx       = context  // safe capture for lambdas called during construction

        arSceneView = ARSceneView(
            context              = context,
            sharedLifecycle      = lifecycle,
            sessionConfiguration = { session, config ->
                config.updateMode       = Config.UpdateMode.LATEST_CAMERA_IMAGE
                config.focusMode        = Config.FocusMode.AUTO
                // Enable plane detection — scanner ignores planes visually;
                // the AR-3D demo needs them for hit-testing.
                config.planeFindingMode = Config.PlaneFindingMode.HORIZONTAL_AND_VERTICAL
                // Load every image in assets/imagesscan/ into ARCore's DB
                try {
                    val db     = AugmentedImageDatabase(session)
                    val folder = "flutter_assets/assets/imagesscan"
                    val files  = ctx.assets.list(folder) ?: emptyArray()
                    var loaded = 0
                    for (f in files) {
                        try {
                            val raw = BitmapFactory.decodeStream(ctx.assets.open("$folder/$f"))
                                ?: continue
                            val minSize = 300
                            val scaled  = if (raw.width < minSize || raw.height < minSize) {
                                val s = maxOf(minSize, maxOf(raw.width, raw.height))
                                Bitmap.createScaledBitmap(raw, s, s, true)
                            } else raw
                            // RGB_565 strips alpha that confuses ARCore feature extraction
                            val bmp  = scaled.copy(Bitmap.Config.RGB_565, false)
                            val name = f.substringBeforeLast(".")
                            db.addImage(name, bmp, 0.1f)
                            loaded++
                            Log.d(TAG, "AugmentedImage loaded: $name (${bmp.width}x${bmp.height})")
                        } catch (e: Exception) {
                            Log.w(TAG, "AugmentedImage rejected '$f': ${e.message}")
                        }
                    }
                    config.augmentedImageDatabase = db
                    augmentedImageDb = db
                    Log.d(TAG, "AugmentedImageDatabase ready ($loaded/${files.size} images)")
                } catch (e: Exception) {
                    Log.w(TAG, "AugmentedImageDatabase setup failed: ${e.message}")
                }
            },
            onSessionUpdated = { _, frame ->
                lastFrame = frame
                processAugmentedImages(frame)
            },
            onSessionFailed = { exception ->
                activity.runOnUiThread {
                    sessionManagerChannel.invokeMethod("onError", listOf(exception.message))
                }
            }
        )

        // Plane visualiser off by default; Flutter "init" call enables it for the AR-3D demo
        try { arSceneView.planeRenderer.isEnabled = false } catch (_: Exception) {}

        sessionManagerChannel.setMethodCallHandler(::onSessionMethod)
        objectManagerChannel.setMethodCallHandler(::onObjectMethod)
        anchorManagerChannel.setMethodCallHandler(::onAnchorMethod)
    }

    // ──────────────────────────────────────────────────────────────
    // Augmented-image detection
    // ──────────────────────────────────────────────────────────────

    private fun processAugmentedImages(frame: Frame) {
        frame.getUpdatedTrackables(AugmentedImage::class.java).forEach { img ->
            when (img.trackingState) {
                TrackingState.TRACKING -> {
                    if (detectedImages.add(img.name)) {
                        activity.runOnUiThread {
                            sessionManagerChannel.invokeMethod(
                                "onImageDetected", mapOf("name" to img.name)
                            )
                        }
                    }
                }
                TrackingState.PAUSED, TrackingState.STOPPED -> {
                    detectedImages.remove(img.name)
                }
                else -> {}
            }
        }
    }

    // ──────────────────────────────────────────────────────────────
    // Session method channel
    // ──────────────────────────────────────────────────────────────

    private fun onSessionMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> {
                val showPlanes      = call.argument<Boolean>("showPlanes")  ?: false
                val handleTapsArg   = call.argument<Boolean>("handleTaps")  ?: false
                val planeDetConfig  = call.argument<Int>("planeDetectionConfig") ?: 0

                try { arSceneView.planeRenderer.isEnabled = showPlanes } catch (_: Exception) {}

                // Update plane-finding mode for this session
                val planeFindingMode = when (planeDetConfig) {
                    1    -> Config.PlaneFindingMode.HORIZONTAL
                    2    -> Config.PlaneFindingMode.VERTICAL
                    3    -> Config.PlaneFindingMode.HORIZONTAL_AND_VERTICAL
                    else -> Config.PlaneFindingMode.DISABLED
                }
                arSceneView.session?.let { session ->
                    try {
                        val cfg = Config(session).apply {
                            updateMode       = Config.UpdateMode.LATEST_CAMERA_IMAGE
                            focusMode        = Config.FocusMode.AUTO
                            this.planeFindingMode = planeFindingMode
                            augmentedImageDb?.let { augmentedImageDatabase = it }
                        }
                        session.configure(cfg)
                    } catch (e: Exception) {
                        Log.w(TAG, "Session reconfigure failed: ${e.message}")
                    }
                }

                // Wire up plane/point tap → Flutter callback via ARCore Frame.hitTest
                if (handleTapsArg) {
                    arSceneView.setOnTouchListener { _, motionEvent ->
                        if (motionEvent.action == MotionEvent.ACTION_UP) {
                            val frame = lastFrame
                            if (frame != null) {
                                try {
                                    val hit = frame.hitTest(motionEvent)
                                        .firstOrNull { it.trackable is Plane || it.trackable is Point }
                                    if (hit != null) {
                                        activity.runOnUiThread {
                                            sessionManagerChannel.invokeMethod(
                                                "onPlaneOrPointTap",
                                                arrayListOf(serializeHitResult(hit))
                                            )
                                        }
                                    }
                                } catch (e: Exception) {
                                    Log.w(TAG, "hitTest failed: ${e.message}")
                                }
                            }
                        }
                        false
                    }
                }

                result.success(null)
            }
            "snapshot"       -> takeSnapshot(result)
            "getCameraPose"  -> {
                val pose = lastFrame?.camera?.displayOrientedPose
                if (pose != null) result.success(serializePose(pose))
                else result.error("Error", "camera pose unavailable", null)
            }
            "getAnchorPose"  -> {
                val id     = call.argument<String>("anchorId")
                val anchor = id?.let { planeAnchorNodes[it] }?.anchor
                if (anchor != null) result.success(serializePose(anchor.pose))
                else result.error("Error", "anchor not found", null)
            }
            "dispose"        -> { dispose(); result.success(null) }
            else             -> result.notImplemented()
        }
    }

    // ──────────────────────────────────────────────────────────────
    // Object method channel
    // ──────────────────────────────────────────────────────────────

    private fun onObjectMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> result.success(null)
            "addNode" -> {
                val dict = call.arguments as? HashMap<String, Any>
                if (dict != null) addNode(dict, parentAnchorName = null, result)
                else result.success(false)
            }
            "addNodeToPlaneAnchor" -> {
                val dictNode   = call.argument<HashMap<String, Any>>("node")
                val dictAnchor = call.argument<HashMap<String, Any>>("anchor")
                val anchorName = dictAnchor?.get("name") as? String
                if (dictNode != null && anchorName != null) addNode(dictNode, anchorName, result)
                else result.success(false)
            }
            "removeNode"            -> result.success(null)
            "transformationChanged" -> result.success(null)
            else                    -> result.notImplemented()
        }
    }

    private fun addNode(
        dictNode: HashMap<String, Any>,
        parentAnchorName: String?,
        result: MethodChannel.Result
    ) {
        val uri  = dictNode["uri"]  as? String ?: return result.success(false)
        val name = dictNode["name"] as? String ?: return result.success(false)
        scope.launch {
            try {
                val modelPath = when (dictNode["type"] as? Int ?: 1) {
                    0    -> "flutter_assets/$uri"
                    2, 3 -> activity.applicationInfo.dataDir + "/app_flutter/$uri"
                    else -> uri
                }
                val instance = arSceneView.modelLoader.loadModelInstance(modelPath) { "" }
                withContext(Dispatchers.Main) {
                    if (instance == null) { result.success(false); return@withContext }
                    val node = ModelNode(modelInstance = instance, scaleToUnits = 0.1f)
                    try { node.name = name } catch (_: Exception) {}
                    if (parentAnchorName != null) {
                        val parent = planeAnchorNodes[parentAnchorName]
                        if (parent != null) { parent.addChildNode(node); result.success(true) }
                        else result.success(false)
                    } else {
                        arSceneView.addChildNode(node)
                        result.success(true)
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) { result.error("e", e.message, null) }
            }
        }
    }

    // ──────────────────────────────────────────────────────────────
    // Anchor method channel
    // ──────────────────────────────────────────────────────────────

    private fun onAnchorMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "addAnchor" -> {
                if (call.argument<Int>("type") == 0) {
                    val transform = call.argument<ArrayList<Double>>("transformation")
                    val name      = call.argument<String>("name")
                    if (transform != null && name != null) {
                        result.success(addPlaneAnchor(transform, name))
                    } else {
                        result.success(false)
                    }
                } else {
                    result.success(false)
                }
            }
            "removeAnchor" -> {
                call.argument<String>("name")?.let { removeAnchor(it) }
                result.success(null)
            }
            "initGoogleCloudAnchorMode" ->
                sessionManagerChannel.invokeMethod(
                    "onError", listOf("Cloud anchors not supported after SceneView migration")
                )
            else -> result.notImplemented()
        }
    }

    private fun addPlaneAnchor(transform: ArrayList<Double>, name: String): Boolean {
        return try {
            val (_, position, rotation) = deserializeMatrix4(transform)
            val pose   = Pose(position, rotation)
            val anchor = arSceneView.session?.createAnchor(pose) ?: return false
            val node   = AnchorNode(engine = arSceneView.engine, anchor = anchor)
            activity.runOnUiThread {
                arSceneView.addChildNode(node)
                planeAnchorNodes[name] = node
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "addPlaneAnchor failed: ${e.message}")
            false
        }
    }

    private fun removeAnchor(name: String) {
        activity.runOnUiThread {
            planeAnchorNodes.remove(name)?.let { node ->
                node.anchor?.detach()
                arSceneView.removeChildNode(node)
            }
        }
    }

    // ──────────────────────────────────────────────────────────────
    // Screenshot
    // ──────────────────────────────────────────────────────────────

    private fun takeSnapshot(result: MethodChannel.Result) {
        val w = arSceneView.width
        val h = arSceneView.height
        if (w == 0 || h == 0) { result.error("e", "AR view not ready", null); return }
        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val thread = HandlerThread("PixelCopier").also { it.start() }
        val loc    = IntArray(2).also { arSceneView.getLocationInWindow(it) }
        val rect   = Rect(loc[0], loc[1], loc[0] + w, loc[1] + h)
        PixelCopy.request(activity.window, rect, bitmap, { res ->
            if (res == PixelCopy.SUCCESS) {
                try {
                    Handler(activity.mainLooper).post {
                        val stream = ByteArrayOutputStream()
                        bitmap.compress(Bitmap.CompressFormat.PNG, 90, stream)
                        result.success(stream.toByteArray())
                    }
                } catch (e: IOException) {
                    result.error("e", e.message, null)
                }
            } else {
                result.error("e", "PixelCopy failed: $res", null)
            }
            thread.quitSafely()
        }, Handler(thread.looper))
    }

    private fun serializePose(pose: Pose): DoubleArray {
        val mat = FloatArray(16)
        pose.toMatrix(mat, 0)
        return DoubleArray(16) { mat[it].toDouble() }
    }

    // ──────────────────────────────────────────────────────────────
    // PlatformView
    // ──────────────────────────────────────────────────────────────

    override fun getView(): View = arSceneView

    override fun dispose() {
        Log.d(TAG, "dispose called")
        try {
            planeAnchorNodes.values.forEach { it.anchor?.detach() }
            planeAnchorNodes.clear()
            detectedImages.clear()
            arSceneView.destroy()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
