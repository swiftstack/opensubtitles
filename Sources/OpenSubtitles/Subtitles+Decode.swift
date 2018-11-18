import XMLRPC
import Compression

// FIXME: base64
import struct Foundation.Data

extension Array where Element == Subtitles {
    init(from items: [RPCValue]) throws {
        var subtitles = [Subtitles]()
        for item in items {
            guard let values = [String : RPCValue](item) else {
                throw Subtitles.DecodeError.invalidStructValue(item)
            }
            subtitles.append(try Subtitles(from: values))
        }
        self = subtitles
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

    init(from values: [String : RPCValue]) throws {
        let id = try values.decode("idsubtitlefile", as: String.self)
        let base64 = try values.decode("data", as: String.self)

        guard let encoded = Data(base64Encoded: base64) else {
            throw DecodeError.invalidData
        }
        let decoded = try GZip.decode(bytes: [UInt8](encoded))
        let string = String(decoding: decoded, as: UTF8.self)

        self.id = id
        self.content = string
    }
}
