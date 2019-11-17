import Foundation
import Cocoa
import Vision

struct ImageFile {
    let url: URL
    let name: String
    let categories: [String: VNConfidence]

    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent

        // Classify the images
        let handler = VNImageRequestHandler(url: url, options: [:])
        let request = VNClassifyImageRequest()
        try? handler.perform([request])

        // Process classification results
        guard let observations = request.results as? [VNClassificationObservation] else {
            categories = [:]
            return
        }
        categories = observations
            .filter { $0.hasMinimumRecall(0.01, forPrecision: 0.9) }
            .reduce(into: [String: VNConfidence]()) { dict, observation in dict[observation.identifier] = observation.confidence }
    }
}

class ImageClassifier {
    static func categoriseImage(inputURL: URL, completion: @escaping (ImageFile) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let imageFile = ImageFile(url: inputURL)
            completion(imageFile)
        }
    }
}
