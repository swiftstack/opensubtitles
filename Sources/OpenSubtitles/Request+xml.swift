import HTTP

extension ContentType {
    static let xml = ContentType(mediaType: .text(.xml))!
}

extension Request {
    init(url: URL, xml: String) {
        var request = Request(method: .post, url: url)
        request.contentType = .xml
        request.rawBody = [UInt8](xml.utf8)
        self = request
    }
}
