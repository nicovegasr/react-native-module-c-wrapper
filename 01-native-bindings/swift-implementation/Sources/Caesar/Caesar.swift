import CCaesar

public enum Caesar {
    public static func cipher(_ text: String, shift: Int32) -> String {
        let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: text.utf8.count + 1)
        defer { buffer.deallocate() }
        text.withCString { encrypt($0, shift, buffer) }
        return String(cString: buffer)
    }

    public static func decipher(_ text: String, shift: Int32) -> String {
        let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: text.utf8.count + 1)
        defer { buffer.deallocate() }
        text.withCString { decrypt($0, shift, buffer) }
        return String(cString: buffer)
    }
}
