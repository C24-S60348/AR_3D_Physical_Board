package io.carius.lars.ar_flutter_plugin.Serialization

import kotlin.math.sqrt

/**
 * Decomposes a column-major 4×4 transform matrix (16 Doubles) into
 * (scale xyz, position xyz, quaternion xyzw).
 *
 * Quaternion layout matches what Flutter / SceneView expect (x, y, z, w).
 */
fun deserializeMatrix4(
    transform: ArrayList<Double>
): Triple<FloatArray, FloatArray, FloatArray> {

    // Scale: length of each column's rotation component
    val sx = sqrt(transform[0].sq() + transform[1].sq() + transform[2].sq()).toFloat()
    val sy = sqrt(transform[4].sq() + transform[5].sq() + transform[6].sq()).toFloat()
    val sz = sqrt(transform[8].sq() + transform[9].sq() + transform[10].sq()).toFloat()

    val scale    = floatArrayOf(sx, sy, sz)
    val position = floatArrayOf(
        transform[12].toFloat(),
        transform[13].toFloat(),
        transform[14].toFloat()
    )

    // Normalised rotation matrix (row-wise for quaternion extraction)
    val r = floatArrayOf(
        (transform[0]  / sx).toFloat(), (transform[4]  / sy).toFloat(), (transform[8]  / sz).toFloat(),
        (transform[1]  / sx).toFloat(), (transform[5]  / sy).toFloat(), (transform[9]  / sz).toFloat(),
        (transform[2]  / sx).toFloat(), (transform[6]  / sy).toFloat(), (transform[10] / sz).toFloat()
    )

    // Convert 3×3 rotation matrix to quaternion (Shepperd method)
    val trace = r[0] + r[4] + r[8]
    val qx: Float; val qy: Float; val qz: Float; val qw: Float
    if (trace > 0f) {
        val s = sqrt((trace + 1.0).toDouble()).toFloat() * 2f  // s = 4w
        qw = s / 4f
        qx = (r[7] - r[5]) / s
        qy = (r[2] - r[6]) / s
        qz = (r[3] - r[1]) / s
    } else if (r[0] > r[4] && r[0] > r[8]) {
        val s = sqrt((1.0 + r[0] - r[4] - r[8]).toDouble()).toFloat() * 2f  // s = 4x
        qw = (r[7] - r[5]) / s
        qx = s / 4f
        qy = (r[1] + r[3]) / s
        qz = (r[2] + r[6]) / s
    } else if (r[4] > r[8]) {
        val s = sqrt((1.0 + r[4] - r[0] - r[8]).toDouble()).toFloat() * 2f  // s = 4y
        qw = (r[2] - r[6]) / s
        qx = (r[1] + r[3]) / s
        qy = s / 4f
        qz = (r[5] + r[7]) / s
    } else {
        val s = sqrt((1.0 + r[8] - r[0] - r[4]).toDouble()).toFloat() * 2f  // s = 4z
        qw = (r[3] - r[1]) / s
        qx = (r[2] + r[6]) / s
        qy = (r[5] + r[7]) / s
        qz = s / 4f
    }

    val rotation = floatArrayOf(qx, qy, qz, qw)
    return Triple(scale, position, rotation)
}

private fun Double.sq() = this * this
