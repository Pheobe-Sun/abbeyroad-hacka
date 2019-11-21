import Foundation

@objc public enum HTTPVerb: Int {
    case get
    case put
    case post

    var string: String {

        switch self {
        case .get:
            return "GET"
        case .put:
            return "PUT"
        case .post:
            return "POST"
        }
    }
}

public struct HTTPRequestOptions {
    let URL: URL
    let verb: HTTPVerb
    let body: Data?
    let headers: [String: String]?
    let isJSONRequest: Bool

    public init(URL: URL, verb: HTTPVerb, body: Data?, headers: [String: String]?, isJSONRequest: Bool = true) {
        self.URL = URL
        self.verb = verb
        self.body = body
        self.headers = headers
        self.isJSONRequest = isJSONRequest
    }
}

public protocol Requester {
    func request<T>(
        _ requestOptions: HTTPRequestOptions,
        _ callback: @escaping (Result<T, Error>) -> Void
    )

    func handleURLResponse<T>(
        _ urlResponse: URLResponse?,
        data: Data?,
        err: Error?,
        callback: @escaping (Result<T, Error>) -> Void
    )
}

extension Requester {
    func request<T>(
        _ requestOptions: HTTPRequestOptions,
        _ callback: @escaping (Result<T, Error>) -> Void
    ) {
        let httpBody = requestOptions.body
        let httpHeaders = requestOptions.headers
        var request = URLRequest(url: requestOptions.URL)
        request.httpMethod = requestOptions.verb.string
        if httpBody != nil {
            request.httpBody = httpBody
        }
        if httpHeaders != nil {
            for (header, value) in httpHeaders! {
                request.addValue(value, forHTTPHeaderField: header)
            }
        }
        let task = URLSession.shared.dataTask(with: request) { (data, urlResponse, err) in
            self.handleURLResponse(urlResponse, data: data, err: err, callback: callback)
        }
        task.resume()
    }
}

