import Foundation

extension OpenSubtitles {
    public struct Hash {
        public enum Error: Swift.Error {
            case fileIsToSmall
            case cantOpenHandle
            case invalidFileLength
        }

        static let chunkSize: Int = 65_536

        static func calculate(path: String) throws -> UInt64 {
            var hash: UInt64 = 0

            let attributes = try FileManager
                .default
                .attributesOfItem(atPath: path)

            let length: UInt64
            switch attributes[FileAttributeKey.size] {
            case .some(let value as UInt64): length = value
            // Foundation on Linux is too perfect
            case .some(let value as NSNumber): length = value.uint64Value
            default: throw Error.invalidFileLength
            }

            guard length >= chunkSize else {
                throw Error.fileIsToSmall
            }
            let suffixOffset = length - UInt64(chunkSize)

            hash = length

            guard let handle = FileHandle(forReadingAtPath: path) else {
                throw Error.cantOpenHandle
            }
            defer { handle.closeFile() }

            func update(_ data: Data) {
                data.withUnsafeBytes { (pointer: UnsafePointer<UInt64>) in
                    let buffer = UnsafeBufferPointer(
                        start: pointer,
                        count: data.count / MemoryLayout<UInt64>.size)
                    hash = buffer.reduce(hash, &+)
                }
            }

            update(handle.readData(ofLength: chunkSize))
            handle.seek(toFileOffset: suffixOffset)
            update(handle.readData(ofLength: chunkSize))

            return hash
        }
    }
}
