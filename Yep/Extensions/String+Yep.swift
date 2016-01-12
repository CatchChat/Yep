//
//  String+Yep.swift
//  Yep
//
//  Created by kevinzhow on 15/4/2.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation

extension String {
    
    func toDate() -> NSDate? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        
        if let date = dateFormatter.dateFromString(self) {
            return date
        } else {
            return nil
        }
    }
}

extension String {

    enum TrimmingType {
        case Whitespace
        case WhitespaceAndNewline
    }

    func trimming(trimmingType: TrimmingType) -> String {
        switch trimmingType {
        case .Whitespace:
            return stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        case .WhitespaceAndNewline:
            return stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        }
    }
}

extension String {

    func wordInIndex(index: Int) -> (string: String, range: Range<Index>)? {

        guard index > 0 else {
            return nil
        }

        let index = startIndex.advancedBy(index)

        var wordString: String?
        var wordRange: Range<Index>?

        self.enumerateSubstringsInRange(Range<Index>(start: startIndex, end: endIndex), options: [.ByWords, .Reverse]) { (substring, substringRange, enclosingRange, stop) -> () in

            println("substring: \(substring)")
            println("substringRange: \(substringRange)")
            println("enclosingRange: \(enclosingRange)")

            if substringRange.contains(index) {
                wordString = substring
                wordRange = enclosingRange
                stop = true
            }
        }

        guard let _wordString = wordString, _wordRange = wordRange else {
            return nil
        }

        return (_wordString, _wordRange)
    }
}


