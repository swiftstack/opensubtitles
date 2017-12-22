public enum Language {
    case eng
    case other(String)
}

extension Language {
    var rawValue: String {
        switch self {
        case .eng: return "eng"
        case .other(let language): return language
        }
    }

    init(rawValue: String) {
        switch rawValue {
        case "eng": self = .eng
        default: self = .other(rawValue)
        }
    }
}
