package com.nicovegasr.caesar

import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class CaesarTest {

    @Test
    fun cipher_shiftsLowercase() {
        assertEquals("def", Caesar.cipher("abc", 3))
    }

    @Test
    fun cipher_shiftsUppercase() {
        assertEquals("DEF", Caesar.cipher("ABC", 3))
    }

    @Test
    fun cipher_wrapsLowercaseAroundAlphabet() {
        assertEquals("abc", Caesar.cipher("xyz", 3))
    }

    @Test
    fun cipher_wrapsUppercaseAroundAlphabet() {
        assertEquals("ABC", Caesar.cipher("XYZ", 3))
    }

    @Test
    fun cipher_preservesNonLetters() {
        assertEquals("Khoor, Zruog!", Caesar.cipher("Hello, World!", 3))
    }

    @Test
    fun cipher_withNegativeShiftReversesDirection() {
        assertEquals("abc", Caesar.cipher("def", -3))
    }

    @Test
    fun decipher_shiftsBackwards() {
        assertEquals("abc", Caesar.decipher("def", 3))
    }

    @Test
    fun decipher_reversesCipher() {
        val original = "The quick brown fox jumps over the lazy dog"
        val ciphered = Caesar.cipher(original, 7)
        assertEquals(original, Caesar.decipher(ciphered, 7))
    }

    @Test
    fun emptyString() {
        assertEquals("", Caesar.cipher("", 5))
        assertEquals("", Caesar.decipher("", 5))
    }
}
