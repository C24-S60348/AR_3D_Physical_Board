package io.carius.lars.ar_flutter_plugin.Serialization

import com.google.ar.core.HitResult
import com.google.ar.core.Plane
import com.google.ar.core.Point
import com.google.ar.core.Pose

fun serializeHitResult(hitResult: HitResult): HashMap<String, Any> {
    val result = HashMap<String, Any>()
    result["type"] = when {
        hitResult.trackable is Plane &&
            (hitResult.trackable as Plane).isPoseInPolygon(hitResult.hitPose) -> 1
        hitResult.trackable is Point -> 2
        else -> 0
    }
    result["distance"]       = hitResult.distance.toDouble()
    result["worldTransform"] = serializePose(hitResult.hitPose)
    return result
}

fun serializePose(pose: Pose): DoubleArray {
    val mat = FloatArray(16)
    pose.toMatrix(mat, 0)
    return DoubleArray(16) { mat[it].toDouble() }
}
