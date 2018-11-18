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
            assertEqual(hash, "94fdc97bd46b7804")

            assertThrowsError(try OpenSubtitles.calculateHash(
                forFileAtPath: Path(#file).string)) { error in
                    let error = error as? OpenSubtitles.Hash.Error
                    assertEqual(error, .fileIsToSmall)
            }
        }
    }
}
