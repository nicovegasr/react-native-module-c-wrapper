import Foundation
import Caesar

// Shim @objc para que CaesarRn.mm (Obj-C++) pueda llamar a la API Swift del
// paquete `Caesar`. El enum Swift no es expuesto a Obj-C por defecto; esta
// clase lo envuelve sin tocar el paquete original.
@objc(CaesarRnSwiftBridge)
public final class CaesarRnSwiftBridge: NSObject {
    @objc public static func cipher(_ text: String, shift: Int32) -> String {
        Caesar.cipher(text, shift: shift)
    }

    @objc public static func decipher(_ text: String, shift: Int32) -> String {
        Caesar.decipher(text, shift: shift)
    }
}
