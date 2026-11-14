package tech.graaf.franz.ar_flutter_plugin_plus

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.ar.core.Anchor
import com.google.ar.core.Session

/** Legacy ARCore tasks are sampled on frames; Flutter delivery belongs on main. */
internal class CloudAnchorHandler(private val session: Session) {
    interface CloudAnchorListener {
        fun onCloudTaskComplete(anchorName: String?, anchor: Anchor?)
    }
    private data class Task(val name: String?, val listener: CloudAnchorListener?, var cancelled: Boolean = false)
    private val delivery = Handler(Looper.getMainLooper())
    private val tasks = mutableMapOf<Anchor, Task>()
    private var epoch = 0
    private val queued = mutableMapOf<Anchor, Task>()

    @Synchronized
    fun hostCloudAnchor(name: String, anchor: Anchor?, listener: CloudAnchorListener?) {
        tasks[session.hostCloudAnchor(anchor)] = Task(name, listener)
        Log.i("MadMapsCloud", "Hosting started")
    }

    @Synchronized
    fun hostCloudAnchorWithTtl(name: String, anchor: Anchor?, listener: CloudAnchorListener?, ttl: Int) {
        tasks[session.hostCloudAnchorWithTtl(anchor, ttl)] = Task(name, listener)
        Log.i("MadMapsCloud", "Hosting started with TTL $ttl")
    }

    @Synchronized
    fun resolveCloudAnchor(id: String?, name: String, listener: CloudAnchorListener?) {
        tasks[session.resolveCloudAnchor(id)] = Task(name, listener)
        Log.i("MadMapsCloud", "Resolution started")
    }

    @Synchronized
    fun onUpdate() {
        // Cloud state can finish without the anchor pose changing this frame.
        val iterator = tasks.iterator()
        while (iterator.hasNext()) {
            val (anchor, task) = iterator.next()
            val state = anchor.cloudAnchorState
            if (state == Anchor.CloudAnchorState.NONE || state == Anchor.CloudAnchorState.TASK_IN_PROGRESS) continue
            iterator.remove()
            queued[anchor] = task
            val taskEpoch = epoch
            Log.i("MadMapsCloud", "Cloud operation completed: $state")
            delivery.post {
                synchronized(this) {
                    queued.remove(anchor)
                    if (taskEpoch == epoch && !task.cancelled) {
                        task.listener?.onCloudTaskComplete(task.name, anchor)
                    } else {
                        anchor.detach()
                    }
                }
            }
        }
    }

    @Synchronized
    fun cancelResolve(name: String) {
        val iterator = tasks.iterator()
        while (iterator.hasNext()) {
            val (anchor, task) = iterator.next()
            if (task.name == name) {
                anchor.detach()
                iterator.remove()
            }
        }
        queued.values.filter { it.name == name }.forEach { it.cancelled = true }
    }

    @Synchronized
    fun clearListeners() {
        epoch++
        tasks.keys.forEach { it.detach() }
        tasks.clear()
        queued.keys.forEach { it.detach() }
        queued.clear()
        delivery.removeCallbacksAndMessages(null)
    }
}
