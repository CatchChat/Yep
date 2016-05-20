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
        case Whitespace
        case WhitespaceAndNewline
    }

    func opengraph_trimming(trimmingType: TrimmingType) -> String {
        switch trimmingType {
        case .Whitespace:
            return stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        case .WhitespaceAndNewline:
            return stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        }
    }

    var opengraph_removeAllWhitespaces: String {
        return self.stringByReplacingOccurrencesOfString(" ", withString: "").stringByReplacingOccurrencesOfString(" ", withString: "")
    }

    var opengraph_removeAllNewLines: String {
        return self.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet()).joinWithSeparator("")
    }
}

extension String {

    var opengraph_embeddedURLs: [NSURL] {

        guard let detector = try? NSDataDetector(types: NSTextCheckingType.Link.rawValue) else {
            return []
        }

        var URLs = [NSURL]()

        detector.enumerateMatchesInString(self, options: [], range: NSMakeRange(0, (self as NSString).length)) { result, flags, stop in

            if let URL = result?.URL {
                URLs.append(URL)
            }
        }

        return URLs
    }

    var opengraph_firstImageURL: NSURL? {

        let URLs = opengraph_embeddedURLs

        guard !URLs.isEmpty else {
            return nil
        }

        let imageExtentions = [
            "png",
            "jpg",
            "jpeg",
        ]

        for URL in URLs {
            if let pathExtension = URL.pathExtension?.lowercaseString {
                if imageExtentions.contains(pathExtension) {
                    return URL
                }
            }
        }
        
        return nil
    }
}

