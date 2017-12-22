import XMLRPC

extension Array where Element == SubtitlesInfo {
    init(from array: [RPCValue]) throws {
        var subtitles = [SubtitlesInfo]()
        for item in array {
            guard let values = [String : RPCValue](item) else {
                throw SubtitlesInfo.DecodeError.invalidStructValue(item)
            }
            subtitles.append(try SubtitlesInfo(from: values))
        }
        self = subtitles
    }
}

fileprivate extension Dictionary where Key == String, Value == RPCValue {
    func decode<T: RPCValueInitializable>(
        _ key: String, as: T.Type
    ) throws -> T {
        guard let value = self[key] else {
            throw SubtitlesInfo.DecodeError.keyNotFound(key)
        }
        guard let result = T(value) else {
            throw SubtitlesInfo.DecodeError.invalidValue(
                key: key, value: value, expectedType: "\(T.self)")
        }
        return result
    }
}

extension SubtitlesInfo {
    public enum DecodeError: Swift.Error {
        case keyNotFound(String)
        case invalidUserRank(String)
        case invalidSubtitlesFormat(String)
        case invalidValue(key: String, value: RPCValue, expectedType: String)
        case invalidStructValue(RPCValue)
    }

    init(from values: [String : RPCValue]) throws {
        let isHearing = try values.decode("SubHearingImpaired", as: String.self)
        let isHearingImpaired = isHearing == "1" ? true : false
        let encodingString = try values.decode("SubEncoding", as: String.self)
        let encoding = Encoding(rawValue: encodingString)
        let userRankString = try values.decode("UserRank", as: String.self)
        guard let userRank = UserRank(rawValue: userRankString) else {
            throw DecodeError.invalidUserRank(userRankString)
        }
        let id = try values.decode("IDSubtitleFile", as: String.self)
        let languageString = try values.decode("SubLanguageID", as: String.self)
        let language = Language(rawValue: languageString)
        let movieName = try values.decode("MovieName", as: String.self)
        let size = try values.decode("SubSize", as: Int.self)
        let downloadsCount = try values.decode("SubDownloadsCnt", as: Int.self)
        let seriesSeason = try values.decode("SeriesSeason", as: Int.self)
        let seriesEpisode = try values.decode("SeriesEpisode", as: Int.self)
        let formatString = try values.decode("SubFormat", as: String.self)
        guard let format = Format(rawValue: formatString) else {
            throw DecodeError.invalidSubtitlesFormat(formatString)
        }
        let downloadLink = try values.decode("SubDownloadLink", as: String.self)
        let fromTrusted = try values.decode("SubFromTrusted", as: String.self)
        let isFromTrusted = fromTrusted == "1" ? true : false

        self.isHearingImpaired = isHearingImpaired
        self.encoding = encoding
        self.userRank = userRank
        self.id = id
        self.language = language
        self.movieName = movieName
        self.size = size
        self.downloadsCount = downloadsCount
        self.seriesSeason = seriesSeason
        self.seriesEpisode = seriesEpisode
        self.format = format
        self.downloadLink = downloadLink
        self.isFromTrusted = isFromTrusted
    }
}
