import XCTest
@testable import Caesar

final class CaesarTests: XCTestCase {
    func test_cipher_shiftsLowercase() {
        XCTAssertEqual(Caesar.cipher("abc", shift: 3), "def")
    }

    func test_cipher_shiftsUppercase() {
        XCTAssertEqual(Caesar.cipher("ABC", shift: 3), "DEF")
    }

    func test_cipher_wrapsLowercaseAroundAlphabet() {
        XCTAssertEqual(Caesar.cipher("xyz", shift: 3), "abc")
    }

    func test_cipher_wrapsUppercaseAroundAlphabet() {
        XCTAssertEqual(Caesar.cipher("XYZ", shift: 3), "ABC")
    }

    func test_cipher_preservesNonLetters() {
        XCTAssertEqual(Caesar.cipher("Hello, World!", shift: 3), "Khoor, Zruog!")
    }

    func test_cipher_withNegativeShiftReversesDirection() {
        XCTAssertEqual(Caesar.cipher("def", shift: -3), "abc")
    }

    func test_decipher_shiftsBackwards() {
        XCTAssertEqual(Caesar.decipher("def", shift: 3), "abc")
    }

    func test_decipher_reversesCipher() {
        let original = "The quick brown fox jumps over the lazy dog"
        let ciphered = Caesar.cipher(original, shift: 7)
        XCTAssertEqual(Caesar.decipher(ciphered, shift: 7), original)
    }

    func test_emptyString() {
        XCTAssertEqual(Caesar.cipher("", shift: 5), "")
        XCTAssertEqual(Caesar.decipher("", shift: 5), "")
    }
}
