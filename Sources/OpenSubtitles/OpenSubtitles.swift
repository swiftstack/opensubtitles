import Stream
import Client
import XMLRPC

import struct Foundation.Data

public class OpenSubtitles {
    let path: String
    let client: Client
    let userAgent: String
    var token: String? = nil

    public init(userAgent: String) throws {
        self.client = Client(host: "api.opensubtitles.org", port: 80)
        self.userAgent = userAgent
        self.path = "/xml-rpc"
    }

    enum Method: String {
        case login = "LogIn"
        case search = "SearchSubtitles"
        case download = "DownloadSubtitles"
    }

    public enum Error: Swift.Error {
        case emptyResponse
        case invalidResponse
        case invalidResponseEncoding

        case notLoggedIn
        case loginFailed
    }

    public static func calculateHash(
        forFileAtPath path: String
    ) throws -> String {
        let hash = try Hash.calculate(path: path)
        return String(format:"%016qx", arguments: [hash])
    }

    // TODO: Update to stream http api
    func makeRequest(_ rpcRequest: RPCRequest) throws -> RPCResponse {
        var request = Request(url: URL(path: path), xml: rpcRequest.xmlCompact)
        request.userAgent = userAgent

        let response = try client.makeRequest(request)

        guard let bytes = response.rawBody else {
            throw Error.emptyResponse
        }
        let stream = InputByteStream(bytes)
        return try RPCResponse(from: stream)
    }

    func call(
        method: Method,
        with params: [RPCValue]
    ) throws -> [String : RPCValue] {
        var params = params
        if let token = self.token {
            params.insert(.string(token), at: 0)
        }
        let request = RPCRequest(methodName: method.rawValue, params: params)
        let response = try makeRequest(request)
        guard let value = response.params.first(where: { $0.isStruct }),
            let members = [String : RPCValue](value) else {
                throw Error.invalidResponse
        }
        return members
    }

    public func login(username: String, password: String) throws {
        let result = try call(method: .login, with: [
            .string(username),
            .string(password),
            .string("en"),
            .string(userAgent)
        ])
        guard let token = String(result["token"]) else {
            throw Error.loginFailed
        }
        self.token = token
    }

    public func search(
        imdbId: Int,
        language: Language
    ) throws -> [SubtitlesInfo] {
        return try search(request: [
            "sublanguageid": .string(language.rawValue),
            "imdbid": .int(imdbId)
        ])
    }

    public func search(
        movieHash: String,
        language: Language
    ) throws -> [SubtitlesInfo] {
        return try search(request: [
            "sublanguageid": .string(language.rawValue),
            "moviehash": .string(movieHash)
        ])
    }

    private func search(request: [String: RPCValue]) throws -> [SubtitlesInfo] {
        let result = try call(method: .search, with: [
            .array([.struct(request)])
        ])
        guard let data = [RPCValue](result["data"]) else {
            throw Error.emptyResponse
        }
        return try [SubtitlesInfo](from: data)
    }

    public func download(subtitlesIds: [String]) throws -> [Subtitles] {
        let result = try call(method: .download, with: [
            .array(subtitlesIds.map({ .string($0) }))
        ])
        guard let items = [RPCValue](result["data"]) else {
            throw Error.emptyResponse
        }
        return try [Subtitles](from: items)
    }

    public func download(subtitlesId: String) throws -> Subtitles {
        let items = try download(subtitlesIds: [subtitlesId])
        guard items.count == 1 && items[0].id == subtitlesId else {
            throw Error.invalidResponse
        }
        return items[0]
    }
}

extension RPCValue {
    var isStruct: Bool {
        switch self {
        case .struct: return true
        default: return false
        }
    }
}
