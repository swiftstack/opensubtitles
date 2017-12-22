import Test
@testable import OpenSubtitles

import struct Foundation.URL

class OpenSubtitlesTests: TestCase {
    func testHash() {
        do {
            let url = URL(fileURLWithPath: #file)
                .deletingLastPathComponent()
                .appendingPathComponent("test_hash")
            let hash = try OpenSubtitles.calculateHash(forFileAtPath: url.path)
            assertEqual(hash, "94fdc97bd46b7804")

            assertThrowsError(try OpenSubtitles.calculateHash(
                forFileAtPath: URL(fileURLWithPath: #file).path)) { error in
                    let error = error as? OpenSubtitles.Hash.Error
                    assertEqual(error, .fileIsToSmall)
            }
        } catch {
            fail(String(describing: error))
        }
    }
}
