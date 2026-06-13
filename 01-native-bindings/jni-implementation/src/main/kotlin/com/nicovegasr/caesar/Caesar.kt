package com.nicovegasr.caesar

/**
 * Wrapper Kotlin sobre la librería C `libcaesar`. Expone el cifrado César
 * con la misma API que el lado Swift (`Caesar.cipher` / `Caesar.decipher`)
 * para que un futuro bridge React Native pueda delegar en ambos sin
 * conocer JNI ni Swift.
 *
 * Garantías:
 *  - Sin estado mutable y thread-safe: para un mismo `text` y `shift`
 *    siempre devuelve el mismo resultado.
 *  - Preserva caracteres no alfabéticos (puntuación, dígitos, espacios).
 *  - No lanza excepciones de dominio. Solo puede lanzar `OutOfMemoryError`
 *    si la JVM se queda sin memoria al reservar el buffer del bridge JNI.
 *
 * Implementación en dos saltos:
 *  1. `cipher` / `decipher` delegan en `encryptNative` / `decryptNative`.
 *  2. Esos `external fun` los resuelve la JVM en `libcaesar-jni.so`
 *     (el bridge JNI), que a su vez llama a `encrypt`/`decrypt` de
 *     `libcaesar.so` (la librería C original).
 */
object Caesar {

    private const val JNI_BRIDGE_LIBRARY_NAME = "caesar-jni"

    init {
        System.loadLibrary(JNI_BRIDGE_LIBRARY_NAME)
    }

    /**
     * Cifra [text] desplazando cada letra [shift] posiciones en el alfabeto.
     * Un [shift] negativo equivale a descifrar.
     */
    fun cipher(text: String, shift: Int): String =
        encryptNative(text, shift)

    /**
     * Inverso de [cipher]. Equivalente a `cipher(text, -shift)`.
     */
    fun decipher(text: String, shift: Int): String =
        decryptNative(text, shift)

    /*
     * Los nombres `encryptNative` y `decryptNative` son CONTRACTUALES con
     * el bridge JNI: deben coincidir con los símbolos C
     * `Java_com_nicovegasr_caesar_Caesar_<nombre>` exportados desde
     * `caesar_jni.c`. No renombres aquí sin actualizar también el C —
     * y viceversa.
     */
    @JvmStatic private external fun encryptNative(text: String, shift: Int): String
    @JvmStatic private external fun decryptNative(text: String, shift: Int): String
}
