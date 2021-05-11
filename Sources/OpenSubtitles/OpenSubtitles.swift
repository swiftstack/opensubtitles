import HTTP
import Stream
import XMLRPC
import FileSystem

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
        forFileAt path: Path
    ) async throws -> String {
        let hash = try await Hash.calculate(path: path)
        return String(hash, radix: 16)
    }

    // TODO: Update to stream http api
    func makeRequest(_ rpcRequest: RPCRequest) async throws -> RPCResponse {
        let request = Request(url: URL(path: path), xml: rpcRequest.xmlCompact)
        request.userAgent = userAgent

        let response = try await client.makeRequest(request)

        guard case .input(let stream) = response.body else {
            throw Error.emptyResponse
        }
        return try await RPCResponse.decode(from: stream)
    }

    func call(
        method: Method,
        with params: [RPCValue]
    ) async throws -> [String : RPCValue] {
        var params = params
        if let token = self.token {
            params.insert(.string(token), at: 0)
        }
        let request = RPCRequest(methodName: method.rawValue, params: params)
        let response = try await makeRequest(request)
        guard let value = response.params.first(where: { $0.isStruct }),
            let members = [String : RPCValue](value) else {
                throw Error.invalidResponse
        }
        return members
    }

    public func login(username: String, password: String) async throws {
        let result = try await call(method: .login, with: [
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
    ) async throws -> [SubtitlesInfo] {
        return try await search(request: [
            "sublanguageid": .string(language.rawValue),
            "imdbid": .int(imdbId)
        ])
    }

    public func search(
        movieHash: String,
        language: Language
    ) async throws -> [SubtitlesInfo] {
        return try await search(request: [
            "sublanguageid": .string(language.rawValue),
            "moviehash": .string(movieHash)
        ])
    }

    private func search(
        request: [String: RPCValue]
    ) async throws -> [SubtitlesInfo] {
        let result = try await call(method: .search, with: [
            .array([.struct(request)])
        ])
        guard let data = [RPCValue](result["data"]) else {
            throw Error.emptyResponse
        }
        return try [SubtitlesInfo](from: data)
    }

    public func download(subtitlesIds: [String]) async throws -> [Subtitles] {
        let result = try await call(method: .download, with: [
            .array(subtitlesIds.map({ .string($0) }))
        ])
        guard let items = [RPCValue](result["data"]) else {
            throw Error.emptyResponse
        }
        return try await [Subtitles].decode(from: items)
    }

    public func download(subtitlesId: String) async throws -> Subtitles {
        let items = try await download(subtitlesIds: [subtitlesId])
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
