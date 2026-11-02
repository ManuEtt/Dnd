package de.aetheria.lebendiger_spielleiter

import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.InputStream
import java.io.InterruptedIOException
import java.io.OutputStream
import java.util.Arrays
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Assert.assertThrows
import org.junit.Test

class JsonBackupIoTest {
    @Test
    fun safeNamesAcceptBasenamesAndRejectTraversalOrControlCharacters() {
        listOf("save.json", "Arescan - Silberhain.json", "Ätheria.json").forEach {
            assertTrue(it, JsonBackupIo.isSafeName(it))
        }
        listOf(
            "", ".json", "../save.json", "..\\save.json", "/tmp/save.json",
            " save.json", "save.json ", "save.txt", "save.JSON", "file\u0000.json",
            "line\n.json", "line\r.json", "line\u007f.json", "a:b.json", "a?b.json",
            "a*b.json", "a|b.json", "a<b.json", "a>b.json", "a\"b.json",
            "a".repeat(124) + ".json",
        ).forEach {
            assertFalse(it, JsonBackupIo.isSafeName(it))
        }
        assertTrue(JsonBackupIo.isSafeName("a".repeat(123) + ".json"))
    }

    @Test
    fun safeNamesRejectInvisibleUnicodeControlsAndUnpairedSurrogates() {
        val malicious = listOf(
            "save\u202Egpj.json", // right-to-left override
            "save\u202A.json", // left-to-right embedding
            "save\u2066.json", // left-to-right isolate
            "save\u2069.json", // pop directional isolate
            "save\u200F.json", // right-to-left mark
            "save\u200D.json", // zero-width joiner
            "save\u00AD.json", // soft hyphen
            "save${String(Character.toChars(0xE0001))}.json", // supplementary format tag
            "save\uD800.json", // isolated high surrogate
            "save\uDC00.json", // isolated low surrogate
        )
        malicious.forEach {
            assertFalse("unsafe filename: ${it.length} UTF-16 units", JsonBackupIo.isSafeName(it))
        }

        // Visible non-ASCII characters must remain valid.
        assertTrue(JsonBackupIo.isSafeName("Ätheria 🐉.json"))
        assertTrue(JsonBackupIo.isSafeName("E\u0301cho.json"))
    }

    @Test
    fun safeNamesRejectUnicodeLineBreaksButPreserveVisibleSpaces() {
        // U+2028/U+2029 are Unicode separator categories, not ISO controls or
        // Unicode FORMAT characters; they previously bypassed isSafeName.
        listOf(
            "save\u2028hidden.json", // Unicode line separator inside basename
            "save\u2029hidden.json", // Unicode paragraph separator inside basename
            "save\u2028.json", // line break immediately before extension
            "\u2029save.json", // paragraph break at filename start
            "save\u0085hidden.json", // next-line: already an ISO control
        ).forEach { name ->
            assertFalse("line break must not reach SAF picker", JsonBackupIo.isSafeName(name))
        }
        listOf(
            "Arescan - Silberhain.json", // ordinary spaces unchanged
            "Grüße aus dem Norden.json",
            "Ätheria 🐉.json",
            "E\u0301cho.json", // decomposed accent remains valid
        ).forEach { name ->
            assertTrue("visible Unicode filename should remain allowed", JsonBackupIo.isSafeName(name))
        }
    }

    @Test
    fun payloadSizeRequiresContentAndAcceptsTheExactBoundary() {
        assertFalse(JsonBackupIo.isValidPayload(byteArrayOf()))
        assertTrue(JsonBackupIo.isValidPayload(byteArrayOf(1)))
        assertTrue(JsonBackupIo.isValidPayload(ByteArray(JsonBackupIo.MAX_BYTES)))
        assertFalse(JsonBackupIo.isValidPayload(ByteArray(JsonBackupIo.MAX_BYTES + 1)))
    }

    @Test
    fun readsExactBoundaryAndClosesWithoutTrustingAnInflatedAvailableSize() {
        val input = TrackingInput(JsonBackupIo.MAX_BYTES, Int.MAX_VALUE)
        val bytes = JsonBackupIo.read(input)
        assertEquals(JsonBackupIo.MAX_BYTES, bytes.size)
        assertEquals(42.toByte(), bytes.first())
        assertEquals(42.toByte(), bytes.last())
        assertTrue(input.closed)
    }

    @Test
    fun rejectsActualOverrunEvenWhenProviderClaimsAnEmptyFile() {
        val input = TrackingInput(JsonBackupIo.MAX_BYTES + 1, 0)
        assertThrows(BackupTooLargeException::class.java) { JsonBackupIo.read(input) }
        assertTrue(input.closed)
    }

    @Test
    fun readerMakesProgressIfBulkReadReturnsZero() {
        val input = object : ByteArrayInputStream(byteArrayOf(1, 2, 3)) {
            var zeroReturned = false
            override fun read(bytes: ByteArray, offset: Int, length: Int): Int {
                if (!zeroReturned) {
                    zeroReturned = true
                    return 0
                }
                return super.read(bytes, offset, length)
            }
        }
        assertArrayEquals(byteArrayOf(1, 2, 3), JsonBackupIo.read(input))
    }

    @Test
    fun readFailureClosesTheStream() {
        val input = object : InputStream() {
            var closed = false
            override fun read(): Int = throw IOException("Synthetic read failure")
            override fun close() { closed = true }
        }
        assertThrows(IOException::class.java) { JsonBackupIo.read(input) }
        assertTrue(input.closed)
    }

    @Test
    fun cancelledReadClosesTheStreamBeforePropagating() {
        val input = TrackingInput(20, 20)
        assertThrows(InterruptedIOException::class.java) { JsonBackupIo.read(input) { true } }
        assertTrue(input.closed)
    }

    @Test
    fun completedWriteFlushesAndClosesTheStream() {
        val output = object : ByteArrayOutputStream() {
            var flushed = false
            var closed = false
            override fun flush() { flushed = true }
            override fun close() { closed = true }
        }
        val bytes = ByteArray(2 * 8192 + 7) { (it % 127).toByte() }
        JsonBackupIo.write(output, bytes)
        assertArrayEquals(bytes, output.toByteArray())
        assertTrue(output.flushed)
        assertTrue(output.closed)
    }

    @Test
    fun failedWriteClosesTheStream() {
        val output = object : OutputStream() {
            var closed = false
            override fun write(value: Int) { throw IOException("Synthetic write failure") }
            override fun close() { closed = true }
        }
        assertThrows(IOException::class.java) { JsonBackupIo.write(output, byteArrayOf(1, 2)) }
        assertTrue(output.closed)
    }

    @Test
    fun closeFailureIsPropagatedRatherThanReportingSuccessfulWrite() {
        val output = object : ByteArrayOutputStream() {
            override fun close() { throw IOException("Synthetic close failure") }
        }
        assertThrows(IOException::class.java) { JsonBackupIo.write(output, byteArrayOf(1)) }
    }

    @Test
    fun cancelledWriteNeverWritesAndClosesTheStream() {
        val output = object : ByteArrayOutputStream() {
            var closed = false
            override fun close() { closed = true }
        }
        assertThrows(InterruptedIOException::class.java) {
            JsonBackupIo.write(output, byteArrayOf(1)) { true }
        }
        assertEquals(0, output.size())
        assertTrue(output.closed)
    }

    @Test
    fun invalidPayloadIsRejectedBeforeWritingAndTheSuppliedStreamIsClosed() {
        val output = object : ByteArrayOutputStream() {
            var closed = false
            override fun close() { closed = true }
        }
        assertThrows(IllegalArgumentException::class.java) { JsonBackupIo.write(output, byteArrayOf()) }
        assertEquals(0, output.size())
        assertTrue(output.closed)
    }

    private class TrackingInput(length: Int, private val reportedAvailable: Int) : InputStream() {
        private var remaining = length
        var closed = false

        override fun available(): Int = reportedAvailable

        override fun read(): Int {
            if (remaining == 0) return -1
            remaining--
            return 42
        }

        override fun read(bytes: ByteArray, offset: Int, length: Int): Int {
            if (remaining == 0) return -1
            val count = minOf(remaining, length)
            Arrays.fill(bytes, offset, offset + count, 42.toByte())
            remaining -= count
            return count
        }

        override fun close() { closed = true }
    }
}
