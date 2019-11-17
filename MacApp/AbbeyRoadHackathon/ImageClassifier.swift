import Foundation
import Cocoa
import Vision

struct ImageFile {
    let url: URL
    let thumbnail: NSImage?
    let name: String
    let categories: [String: VNConfidence]

    init(url: URL) {
        // generate thumbnail
        var thumbnail: NSImage?
        let imageSource = CGImageSourceCreateWithURL(url.absoluteURL as CFURL, nil)
        if let imageSource = imageSource, CGImageSourceGetType(imageSource) != nil {
            let options: [String: Any] = [String(kCGImageSourceCreateThumbnailFromImageIfAbsent): true,
                                           String(kCGImageSourceThumbnailMaxPixelSize): 256]
            if let thumbnailRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) {
                thumbnail = NSImage(cgImage: thumbnailRef, size: NSSize.zero)
            }
        }
        self.thumbnail = thumbnail
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
    private var imageCategories = [String]()
    private var searchResults: [String]?

    var categories = [String]()

    func categoriseImage(inputURL: URL,
                  reportTotal: @escaping (Int) -> Void,
                  reportProgress: @escaping (Int) -> Void,
                  completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {

            let imageFile = ImageFile(url: inputURL)
            self.categories.removeAll()
            self.categories = Array(imageFile.categories.keys)

            if self.categories.isEmpty {
                self.categories = ["other"]
            }

            completion()
        }
    }
}
