package io.kbl.superduper

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class BackgroundControlSyncTest {
    private fun command(id: Int = 0xd1) = byteArrayOf(0, id.toByte(), 1, 4, 3, 0, 0, 0, 0, 0)
    private val barrier = byteArrayOf(0xfc.toByte(), 0xfc.toByte(), 0, 0, 0, 0, 0, 0, 0, 0)

    private fun inspect(sync: BackgroundControlSync, record: ByteArray): BackgroundControlSync.Action {
        assertArrayEquals(byteArrayOf(0xfc.toByte(), 0xfc.toByte()),
            (sync.start() as BackgroundControlSync.Action.Select).selector)
        assertTrue(sync.onWrite() is BackgroundControlSync.Action.Read)
        assertTrue(sync.onRead(barrier) is BackgroundControlSync.Action.Select)
        assertTrue(sync.onWrite() is BackgroundControlSync.Action.Read)
        return sync.onRead(record)
    }

    @Test
    fun markedRecordsSkipRegardlessOfCurrentPreferencesForBothProtocols() {
        for (id in listOf(0xd1, 0xc1)) {
            val record = command(id).also { it[2] = 0; it[3] = 0; it[5] = 1 }
            val result = inspect(BackgroundControlSync(command(id)), record)
            assertEquals(BackgroundControlSync.Action.Complete(false), result)
        }
    }

    @Test
    fun unmarkedNonzeroRecordsAreAppliedAndOnlyConfirmedAfterFullReadback() {
        for (id in listOf(0xd1, 0xc1)) {
            val original = command(id)
            val sync = BackgroundControlSync(original)
            val write = inspect(sync, command(id)) as BackgroundControlSync.Action.Write
            val marked = command(id).also { it[5] = 1 }
            assertArrayEquals(marked, write.command)
            assertEquals(0, original[5].toInt())
            assertTrue(sync.onWrite() is BackgroundControlSync.Action.Select)
            assertTrue(sync.onWrite() is BackgroundControlSync.Action.Read)
            // Even the expected marker is not accepted before observing the barrier.
            assertTrue(sync.onRead(marked) is BackgroundControlSync.Action.Read)
            assertTrue(sync.onRead(barrier) is BackgroundControlSync.Action.Select)
            assertTrue(sync.onWrite() is BackgroundControlSync.Action.Read)
            assertTrue(sync.onRead(command(id)) is BackgroundControlSync.Action.Read)
            val otherMarkedCommand = marked.copyOf().also { it[2] = 0 }
            assertTrue(sync.onRead(otherMarkedCommand) is BackgroundControlSync.Action.Read)
            assertEquals(BackgroundControlSync.Action.Complete(true), sync.onRead(marked))
        }
    }

    @Test
    fun aNewTransactionRecoversALostAcknowledgementWithoutRewriting() {
        val first = BackgroundControlSync(command())
        val write = inspect(first, ByteArray(10).also { it[1] = 0xd1.toByte() })
            as BackgroundControlSync.Action.Write
        val reconnect = BackgroundControlSync(command())
        assertEquals(BackgroundControlSync.Action.Complete(false), inspect(reconnect, write.command))
        val powerCycle = BackgroundControlSync(command())
        assertTrue(inspect(powerCycle, ByteArray(10).also { it[1] = 0xd1.toByte() })
            is BackgroundControlSync.Action.Write)
    }

    @Test
    fun missingBarrierFailsWithoutWritingEvenIfStaleResultHasAMarker() {
        val sync = BackgroundControlSync(command())
        sync.start()
        sync.onWrite()
        val stale = command().also { it[5] = 1 }
        var result: BackgroundControlSync.Action = sync.onRead(stale)
        repeat(30) { if (result is BackgroundControlSync.Action.Read) result = sync.onRead(stale) }
        assertTrue(result is BackgroundControlSync.Action.Failed)
    }

    @Test
    fun missingOrMalformedControlRecordsNeverAuthorizeAWrite() {
        for (record in listOf(barrier, byteArrayOf(0, 0xd1.toByte()), command(0xc1))) {
            val sync = BackgroundControlSync(command())
            var result = inspect(sync, record)
            repeat(30) { if (result is BackgroundControlSync.Action.Read) result = sync.onRead(record) }
            assertTrue(result is BackgroundControlSync.Action.Failed)
        }
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsUnknownControlPackets() {
        BackgroundControlSync(command(0xaa))
    }
}
