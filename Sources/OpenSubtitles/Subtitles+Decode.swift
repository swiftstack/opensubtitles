import XMLRPC
import Base64
import DCompression

extension Array where Element == Subtitles {
    static func decode(from items: [RPCValue]) async throws -> Self {
        var subtitles = [Subtitles]()
        for item in items {
            guard let values = [String: RPCValue](item) else {
                throw Subtitles.DecodeError.invalidStructValue(item)
            }
            subtitles.append(try await Subtitles.decode(from: values))
        }
        return subtitles
    }
}

fileprivate extension Dictionary where Key == String, Value == RPCValue {
    func decode<T: RPCValueInitializable>(
        _ key: String, as: T.Type
    ) throws -> T {
        guard let value = self[key] else {
            throw Subtitles.DecodeError.keyNotFound(key)
        }
        guard let result = T(value) else {
            throw Subtitles.DecodeError.invalidValue(
                key: key, value: value, expectedType: "\(T.self)")
        }
        return result
    }
}

extension Subtitles {
    public enum DecodeError: Error {
        case invalidData
        case invalidEncoding
        case keyNotFound(String)
        case invalidValue(key: String, value: RPCValue, expectedType: String)
        case invalidStructValue(RPCValue)
    }

    static func decode(
        from values: [String: RPCValue]
    ) async throws -> Subtitles {
        let id = try values.decode("idsubtitlefile", as: String.self)
        let base64 = try values.decode("data", as: String.self)

        guard let bytes = [UInt8](decodingBase64: base64) else {
            throw DecodeError.invalidData
        }
        let decoded = try await GZip.decode(bytes: bytes)
        let string = String(decoding: decoded, as: UTF8.self)

        return .init(id: id, content: string)
    }
}
