import Test
import FileSystem
@testable import OpenSubtitles

test.case("Hash") {
    let path = try Path(#file)
        .deletingLastComponent
        .appending("test_hash")
    let hash = try await OpenSubtitles.calculateHash(forFileAt: path)
    expect(hash == "94fdc97bd46b7804")

    await expect(throws: OpenSubtitles.Hash.Error.fileIsToSmall) {
        try await OpenSubtitles.calculateHash(forFileAt: Path(#file))
    }
}

test.run()
