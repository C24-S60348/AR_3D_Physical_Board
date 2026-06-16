package io.carius.lars.ar_flutter_plugin

import android.app.Activity
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Rect
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import android.view.PixelCopy
import android.view.View
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.lifecycleScope
import com.google.ar.core.*
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

    // Method channels (names must match Dart side exactly)
    private val sessionManagerChannel = MethodChannel(messenger, "arsession_$id")
    private val objectManagerChannel  = MethodChannel(messenger, "arobjects_$id")
    private val anchorManagerChannel  = MethodChannel(messenger, "aranchors_$id")

    // SceneView 2.x AR view — bundles ARCore 1.44+ and Filament 1.53+ (16 KB aligned)
    private val arSceneView: ARSceneView

    // Augmented image tracking state
    private val detectedImages    = mutableSetOf<String>()
    private val imageAnchorNodes  = mutableMapOf<String, AnchorNode>()

    // Last received AR frame (used by getCameraPose)
    @Volatile private var lastFrame: Frame? = null

    // Coroutine scope — tied to Activity lifecycle when possible
    private val scope: CoroutineScope =
        (activity as? LifecycleOwner)?.lifecycleScope
            ?: CoroutineScope(Dispatchers.Main + SupervisorJob())

    // ──────────────────────────────────────────────────────────────
    // Initialisation
    // ──────────────────────────────────────────────────────────────

    init {
        val lifecycle = (activity as? LifecycleOwner)?.lifecycle

        arSceneView = ARSceneView(
            context       = context,
            sharedLifecycle = lifecycle
        )

        // Session configuration — called once by SceneView before first camera frame
        arSceneView.sessionConfiguration = { session, config ->
            config.updateMode     = Config.UpdateMode.LATEST_CAMERA_IMAGE
            config.focusMode      = Config.FocusMode.AUTO
            config.planeFindingMode = Config.PlaneFindingMode.DISABLED
            loadAugmentedImageDatabase(session, config, context)
        }

        // Frame update — called every rendered frame
        arSceneView.onSessionUpdated = { _, frame ->
            lastFrame = frame
            processAugmentedImages(frame)
        }

        arSceneView.onSessionFailed = { exception ->
            activity.runOnUiThread {
                sessionManagerChannel.invokeMethod("onError", listOf(exception.message))
            }
        }

        // Disable plane visualisation (we do image-based AR only)
        try { arSceneView.planeRenderer.isEnabled = false } catch (_: Exception) {}

        // Register method-channel handlers
        sessionManagerChannel.setMethodCallHandler(::onSessionMethod)
        objectManagerChannel.setMethodCallHandler(::onObjectMethod)
        anchorManagerChannel.setMethodCallHandler(::onAnchorMethod)
    }

    // ──────────────────────────────────────────────────────────────
    // Augmented-image database
    // ──────────────────────────────────────────────────────────────

    private fun loadAugmentedImageDatabase(session: Session, config: Config, context: Context) {
        try {
            val db     = AugmentedImageDatabase(session)
            val folder = "flutter_assets/assets/imagesscan"
            val files  = context.assets.list(folder) ?: emptyArray()
            var loaded = 0
            for (f in files) {
                try {
                    val raw = BitmapFactory.decodeStream(context.assets.open("$folder/$f"))
                        ?: continue
                    val minSize = 300
                    val scaled = if (raw.width < minSize || raw.height < minSize) {
                        val s = maxOf(minSize, maxOf(raw.width, raw.height))
                        Bitmap.createScaledBitmap(raw, s, s, true)
                    } else raw
                    // RGB_565 strips alpha which can confuse ARCore feature detection
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
            Log.d(TAG, "AugmentedImageDatabase ready ($loaded/${files.size} images)")
        } catch (e: Exception) {
            Log.w(TAG, "AugmentedImageDatabase setup failed: ${e.message}")
        }
    }

    // ──────────────────────────────────────────────────────────────
    // Per-frame augmented-image processing
    // ──────────────────────────────────────────────────────────────

    private fun processAugmentedImages(frame: Frame) {
        frame.getUpdatedTrackables(AugmentedImage::class.java).forEach { img ->
            when (img.trackingState) {
                TrackingState.TRACKING -> {
                    val existing = imageAnchorNodes[img.name]
                    if (existing != null) {
                        activity.runOnUiThread { existing.isVisible = true }
                    } else {
                        spawnModelForImage(img)
                    }
                    if (detectedImages.add(img.name)) {
                        // First detection — notify Flutter
                        activity.runOnUiThread {
                            sessionManagerChannel.invokeMethod(
                                "onImageDetected",
                                mapOf("name" to img.name)
                            )
                        }
                    }
                }
                TrackingState.PAUSED -> {
                    detectedImages.remove(img.name)
                    activity.runOnUiThread {
                        imageAnchorNodes[img.name]?.isVisible = false
                    }
                }
                TrackingState.STOPPED -> {
                    detectedImages.remove(img.name)
                    activity.runOnUiThread {
                        imageAnchorNodes.remove(img.name)?.let { node ->
                            node.anchor?.detach()
                            arSceneView.removeChildNode(node)
                        }
                    }
                }
                else -> {}
            }
        }
    }

    // ──────────────────────────────────────────────────────────────
    // 3D model placement over detected image
    // ──────────────────────────────────────────────────────────────

    private fun spawnModelForImage(img: AugmentedImage) {
        scope.launch {
            try {
                val anchor    = img.createAnchor(img.centerPose)
                val modelPath = "flutter_assets/assets/models/duck.glb"
                val instance  = arSceneView.modelLoader.loadModelInstance(modelPath) { "" }
                if (instance != null) {
                    val modelNode = ModelNode(
                        modelInstance = instance,
                        scaleToUnits  = 0.1f
                    )
                    val anchorNode = AnchorNode(
                        engine = arSceneView.engine,
                        anchor = anchor
                    )
                    anchorNode.addChildNode(modelNode)
                    withContext(Dispatchers.Main) {
                        arSceneView.addChildNode(anchorNode)
                        imageAnchorNodes[img.name] = anchorNode
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to spawn model for ${img.name}: ${e.message}")
            }
        }
    }

    // ──────────────────────────────────────────────────────────────
    // Method-channel: session
    // ──────────────────────────────────────────────────────────────

    private fun onSessionMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> {
                val showPlanes = call.argument<Boolean>("showPlanes") ?: false
                try { arSceneView.planeRenderer.isEnabled = showPlanes } catch (_: Exception) {}
                result.success(null)
            }
            "snapshot"     -> takeSnapshot(result)
            "getCameraPose" -> {
                val pose = lastFrame?.camera?.displayOrientedPose
                if (pose != null) result.success(serializePose(pose))
                else result.error("Error", "camera pose unavailable", null)
            }
            "getAnchorPose" -> {
                val anchorId   = call.argument<String>("anchorId")
                val anchorNode = anchorId?.let { imageAnchorNodes[it] }
                val anchor     = anchorNode?.anchor
                if (anchor != null) result.success(serializePose(anchor.pose))
                else result.error("Error", "anchor not found", null)
            }
            "dispose" -> { dispose(); result.success(null) }
            else -> result.notImplemented()
        }
    }

    // ──────────────────────────────────────────────────────────────
    // Method-channel: objects / nodes
    // ──────────────────────────────────────────────────────────────

    private fun onObjectMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> result.success(null)
            "addNode" -> {
                val dict = call.arguments as? HashMap<String, Any>
                if (dict != null) addNode(dict, result) else result.success(false)
            }
            "addNodeToPlaneAnchor" -> {
                val dict = call.argument<HashMap<String, Any>>("node")
                if (dict != null) addNode(dict, result) else result.success(false)
            }
            "removeNode"            -> result.success(null)
            "transformationChanged" -> result.success(null)
            else -> result.notImplemented()
        }
    }

    private fun addNode(dictNode: HashMap<String, Any>, result: MethodChannel.Result) {
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
                    if (instance != null) {
                        val node = ModelNode(modelInstance = instance, scaleToUnits = 0.1f)
                        node.name = name
                        arSceneView.addChildNode(node)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) { result.error("e", e.message, null) }
            }
        }
    }

    // ──────────────────────────────────────────────────────────────
    // Method-channel: anchors (cloud anchors not supported)
    // ──────────────────────────────────────────────────────────────

    private fun onAnchorMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "addAnchor"                -> result.success(false)
            "removeAnchor"             -> result.success(null)
            "initGoogleCloudAnchorMode" ->
                sessionManagerChannel.invokeMethod(
                    "onError", listOf("Cloud anchors not supported after SceneView migration")
                )
            else -> result.notImplemented()
        }
    }

    // ──────────────────────────────────────────────────────────────
    // Screenshot
    // ──────────────────────────────────────────────────────────────

    private fun takeSnapshot(result: MethodChannel.Result) {
        val w = arSceneView.width
        val h = arSceneView.height
        if (w == 0 || h == 0) {
            result.error("e", "AR view not ready for snapshot", null)
            return
        }
        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val thread = HandlerThread("PixelCopier").also { it.start() }
        val location = IntArray(2).also { arSceneView.getLocationInWindow(it) }
        val rect     = Rect(location[0], location[1], location[0] + w, location[1] + h)
        PixelCopy.request(activity.window, rect, bitmap, { copyResult ->
            if (copyResult == PixelCopy.SUCCESS) {
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
                result.error("e", "PixelCopy failed: $copyResult", null)
            }
            thread.quitSafely()
        }, Handler(thread.looper))
    }

    // ──────────────────────────────────────────────────────────────
    // Helpers
    // ──────────────────────────────────────────────────────────────

    private fun serializePose(pose: Pose): DoubleArray {
        val mat = FloatArray(16)
        pose.toMatrix(mat, 0)
        return DoubleArray(16) { mat[it].toDouble() }
    }

    // ──────────────────────────────────────────────────────────────
    // PlatformView contract
    // ──────────────────────────────────────────────────────────────

    override fun getView(): View = arSceneView

    override fun dispose() {
        Log.d(TAG, "dispose called")
        try {
            imageAnchorNodes.values.forEach { it.anchor?.detach() }
            imageAnchorNodes.clear()
            detectedImages.clear()
            arSceneView.destroy()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
