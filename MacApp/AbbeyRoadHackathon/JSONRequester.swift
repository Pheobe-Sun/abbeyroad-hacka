import Foundation

class JSONRequester: Requester {

    func handleURLResponse<T>(
        _ urlResponse: URLResponse?,
        data: Data?,
        err: Error?,
        callback: @escaping (Result<T, Error>) -> Void
    ) {
        let response: (Result<T, Error>) = self.parseJSONResponse(data, urlResponse, err)
        callback(response)
    }

    func getRequestBody (dictionary: [String: AnyObject]?) throws -> Data? {
        if dictionary == nil {
            return nil
        }
        return try JSONSerialization.data(withJSONObject: dictionary!)
    }

    func parseJSONResponse<T>(_ data: Data?, _ urlResponse: URLResponse?, _ err: Error?) -> (Result<T, Error>) {
        guard let httpUrlResponse = urlResponse as? HTTPURLResponse else {
            return .failure(NSError())
        }

        do {
            let dictionary = try JSONSerialization.jsonObject(
                with: data!,
                options: JSONSerialization.ReadingOptions(rawValue: 0)
                ) as? T

            if httpUrlResponse.statusCode >= 400 {
                return .failure(
                    NSError()
                )
            }

            if let dictionary = dictionary {
                return .success(dictionary)
            } else {
                return .failure(NSError())
            }

        } catch {
            return .failure(NSError())
        }
    }
}
