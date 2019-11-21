import Cocoa

public class NetworkingClient: NSObject {
    public func searchRequest(
        _ parameters: SearchRequest,
        _ completion: @escaping (Result<SearchResponse, Error>) -> Void) {
    }
}

public struct SearchResults: Decodable {
    let results: [SearchItem]
}

public struct SearchItem: Decodable {
}

public class SearchResponse: NSObject {
    public convenience init(_ response: Any) throws {
        let data: Data = try JSONSerialization.data(withJSONObject: response, options: .prettyPrinted)
        try self.init(data)
    }

    public init(_ data: Data) throws {
        self.results = try JSONDecoder().decode(SearchResults.self, from: data).results
    }

    public let results: [SearchItem]
}

public class SearchRequest: NSObject {
    let parameters: [(key: String, value: String?)]

    override init() {
        parameters = []
    }
}
