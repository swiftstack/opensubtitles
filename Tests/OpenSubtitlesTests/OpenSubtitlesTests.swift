import Test
import FileSystem
@testable import OpenSubtitles

class OpenSubtitlesTests: TestCase {
    func testHash() {
        scope {
            let path = try Path(#file)
                .deletingLastComponent
                .appending("test_hash")
            let hash = try OpenSubtitles.calculateHash(forFileAt: path)
            expect(hash == "94fdc97bd46b7804")

            expect(throws: OpenSubtitles.Hash.Error.fileIsToSmall) {
                try OpenSubtitles.calculateHash(forFileAt: Path(#file))
            }
        }
    }
}
