import Test
import File
@testable import OpenSubtitles

class OpenSubtitlesTests: TestCase {
    func testHash() {
        scope {
            let path = Path(#file)
                .deletingLastComponent
                .appending("test_hash")
            let hash = try OpenSubtitles.calculateHash(forFileAtPath: path.string)
            expect(hash == "94fdc97bd46b7804")

            expect(throws: OpenSubtitles.Hash.Error.fileIsToSmall) {
                try OpenSubtitles.calculateHash(forFileAtPath: Path(#file).string)
            }
        }
    }
}
