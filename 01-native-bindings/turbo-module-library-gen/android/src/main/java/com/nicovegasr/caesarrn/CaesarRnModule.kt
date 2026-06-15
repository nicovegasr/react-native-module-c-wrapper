package com.nicovegasr.caesarrn

import com.facebook.react.bridge.ReactApplicationContext
import com.nicovegasr.caesar.Caesar

// TurboModule de RN: cable fino entre la spec generada por Codegen
// (NativeCaesarRnSpec) y la API Kotlin del AAR (`com.nicovegasr.caesar.Caesar`).
// No reimplementa JNI ni carga libcaesar.so — eso vive en el AAR.
class CaesarRnModule(reactContext: ReactApplicationContext) :
  NativeCaesarRnSpec(reactContext) {

  override fun cipher(text: String, shift: Double): String =
    Caesar.cipher(text, shift.toInt())

  override fun decipher(text: String, shift: Double): String =
    Caesar.decipher(text, shift.toInt())

  companion object {
    const val NAME = NativeCaesarRnSpec.NAME
  }
}
