//
//  String+OpenGraph.swift
//  Yep
//
//  Created by NIX on 16/5/20.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

extension String {

    enum TrimmingType {
        case whitespace
        case whitespaceAndNewline
    }

    func opengraph_trimming(_ trimmingType: TrimmingType) -> String {
        switch trimmingType {
        case .whitespace:
            return trimmingCharacters(in: CharacterSet.whitespaces)
        case .whitespaceAndNewline:
            return trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
    }

    var opengraph_removeAllWhitespaces: String {
        return self.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: " ", with: "")
    }

    var opengraph_removeAllNewLines: String {
        return self.components(separatedBy: CharacterSet.newlines).joined(separator: "")
    }
}

extension String {

    var opengraph_embeddedURLs: [URL] {

        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }

        var URLs = [URL]()

        detector.enumerateMatches(in: self, options: [], range: NSMakeRange(0, (self as NSString).length)) { result, flags, stop in

            if let URL = result?.url {
                URLs.append(URL)
            }
        }

        return URLs
    }

    var opengraph_firstImageURL: URL? {

        let urls = opengraph_embeddedURLs

        guard !urls.isEmpty else {
            return nil
        }

        let imageExtentions = [
            "png",
            "jpg",
            "jpeg",
        ]

        for url in urls {
            let pathExtension = url.pathExtension.lowercased()
            if imageExtentions.contains(pathExtension) {
                return url
            }
        }
        
        return nil
    }
}

