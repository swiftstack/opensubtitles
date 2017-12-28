import HTTP

extension Request {
    convenience init(url: URL, xml: String) {
        self.init(method: .post, url: url)
        self.contentType = .xml
        self.bytes = [UInt8](xml.utf8)
    }
}
