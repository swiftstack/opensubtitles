import HTTP

extension Request {
    convenience init(url: URL, xml: String) {
        self.init(url: url, method: .post)
        self.contentType = .xml
        self.string = xml
    }
}
