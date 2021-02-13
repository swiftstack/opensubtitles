import FileSystem

extension OpenSubtitles {
    public struct Hash {
        public enum Error: Swift.Error {
            case fileIsToSmall
            case cantOpenHandle
            case invalidFileLength
        }

        static let chunkSize: Int = 65_536

        static func calculate(path: Path) async throws -> UInt64 {
            var hash: UInt64 = 0

            let file = try File(at: path)
            let length = file.size
            guard length > 0 else {
                throw Error.invalidFileLength
            }
            guard length >= chunkSize else {
                throw Error.fileIsToSmall
            }

            hash = UInt64(length)

            func update(_ bytes: UnsafeRawBufferPointer) {
                hash = bytes.bindMemory(to: UInt64.self).reduce(hash, &+)
            }

            let stream = try file.open()

            try await stream.read(count: chunkSize, body: update)
            try await stream.seek(to: -chunkSize, from: .end)
            try await stream.read(count: chunkSize, body: update)

            return hash
        }
    }
}
