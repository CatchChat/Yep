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

    // iTunes

    var yep_iTunesArtworkID: String? {

        if let artworkID = queryItemForKey("i")?.value {
            return artworkID

        } else {
            if let artworkID = lastPathComponent?.stringByReplacingOccurrencesOfString("id", withString: "") {
                return artworkID
            }
        }

        return nil
    }

}

