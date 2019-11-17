//
//  ViewController.swift
//  AbbeyRoadHackathon
//
//  Created by Josh Prewer on 09/11/2019.
//  Copyright © 2019 Josh Prewer. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet private weak var imageButton: NSButton!
    @IBOutlet private weak var sonifyButton: NSButton!
    @IBOutlet private weak var imageView: NSImageView!

    @IBOutlet weak var progressView: NSView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!

    private var categories = [String]() {
        didSet {
            getAudioURLS(categories: categories)
        }
    }

    var audioDownloaded = false {
        didSet {
            if audioDownloaded {
                sendAudioFiles()
            }
        }
    }
    var audioURLS = [URL]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        progressView.isHidden = true
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func imageButtonPushed(sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.message = "Choose images to be sonified."
        openPanel.prompt = "Choose"
        openPanel.allowedFileTypes = ["public.image"]
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false

        openPanel.beginSheetModal(for: view.window!) { (response) in
            if response == .OK {
                guard let url = openPanel.url else { return }
                openPanel.close()
                self.progressView.isHidden = false

                ImageClassifier.categoriseImage(
                inputURL: url) { (imageFile) in
                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else { return }
                        strongSelf.progressView.isHidden = true
                        let image = NSImage.init(contentsOf: imageFile.url)
                        strongSelf.imageView.image = image
                        strongSelf.categories = Array(imageFile.categories.keys)
                    }
                }
            }
        }
    }


    func getAudioURLS(categories: [String]) {
        audioURLS.removeAll()

        for category in categories {
            let path = "http://m2.audiocommons.org/api/audioclips/search?pattern=\(category)&limit=1&page=1&source=freesound"
            let url = URL(string: path)!
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let data = data, error == nil else {
                    print("error\(String(describing: error?.localizedDescription))")
                    return
                }

                do {
                    //here dataResponse received from a network request
                    let jsonResponse = try JSONSerialization.jsonObject(with:
                        data, options: [])
                    guard let jsonArray = jsonResponse as? [String: Any] else { return }
                    guard let resultArray = jsonArray["results"] as? [Any] else { return }
                    guard let result = resultArray[0] as? [String: Any] else { return }
                    guard let membersArray = result["members"] as? [Any] else { return }
                    guard let member = membersArray[0] as? [String: Any] else { return }
                    guard let content = member["content"] as? [String: Any] else { return }
                    guard let availableAs = content["availableAs"] as? [Any] else { return }

                    for data in availableAs {
                        guard let item = data as? [String: Any] else { continue }
                        guard let audioPath = item["locator"] as? String else { continue }
                        guard audioPath.hasSuffix(".mp3") else { continue }
                        guard let audioURL = URL(string: audioPath) else { continue }

                        self.audioURLS.append(audioURL)
                        break
                    }

                    if self.audioURLS.count == categories.count {
                        self.downloadAudio()
                    }

                } catch let parsingError {
                    print("Error", parsingError)
                }
            }
            task.resume()
        }
    }

    func downloadAudio() {
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: documentsDirectoryURL.path)
            for item in contents {
                let fileToRemove = documentsDirectoryURL.appendingPathComponent(item)
                try FileManager.default.removeItem(at: fileToRemove)
            }
        } catch {
            print(error.localizedDescription)
        }

        for audioURL in audioURLS {
            let destinationUrl = documentsDirectoryURL.appendingPathComponent(audioURL.lastPathComponent)
            if FileManager.default.fileExists(atPath: destinationUrl.path) {
                print("The file already exists at path")
            } else {
                URLSession.shared.downloadTask(with: audioURL, completionHandler: { (location, response, error) -> Void in
                    guard let location = location, error == nil else { return }
                    do {
                        try FileManager.default.moveItem(at: location, to: destinationUrl)
                        let contents = try FileManager.default.contentsOfDirectory(atPath: documentsDirectoryURL.path)

                        if contents.count == self.categories.count {
                            self.audioDownloaded = true
                        }
                        print("File moved to documents folder")
                    } catch let error as NSError {
                        print(error.localizedDescription)
                    }
                }).resume()
            }
        }
    }

    func sendAudioFiles() {
        let pathToAudioFiles = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let path = "http://localhost:7000"
        let url = URL(string: path)!

        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data, error == nil else {
                print("error\(String(describing: error?.localizedDescription))")
                return
            }
        }
    }
}

