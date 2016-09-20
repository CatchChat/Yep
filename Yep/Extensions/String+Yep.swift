//
//  String+Yep.swift
//  Yep
//
//  Created by kevinzhow on 15/4/2.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation
import RealmSwift

extension String {
    
    func toDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        
        if let date = dateFormatter.date(from: self) {
            return date
        } else {
            return nil
        }
    }
}

extension String {

    enum TrimmingType {
        case whitespace
        case whitespaceAndNewline
    }

    func trimming(_ trimmingType: TrimmingType) -> String {
        switch trimmingType {
        case .whitespace:
            return trimmingCharacters(in: CharacterSet.whitespaces)
        case .whitespaceAndNewline:
            return trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
    }

    var yep_removeAllWhitespaces: String {
        return self.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: " ", with: "")
    }

    var yep_removeAllNewLines: String {
        return self.components(separatedBy: CharacterSet.newlines).joined(separator: "")
    }

    func yep_truncate(_ length: Int, trailing: String? = nil) -> String {
        if self.characters.count > length {
            return self.substring(to: self.characters.index(self.startIndex, offsetBy: length)) + (trailing ?? "")
        } else {
            return self
        }
    }

    var yep_truncatedForFeed: String {
        return yep_truncate(120, trailing: "...")
    }
}

extension String {

    func yep_rangeFromNSRange(_ nsRange: NSRange) -> Range<Index>? {


        let from16 = utf16.startIndex.advanced(by: nsRange.location)
        let to16 = from16.advanced(by: nsRange.length)

        guard let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self) else {
                return nil
        }

        return from ..< to
    }

    func yep_NSRangeFromRange(_ range: Range<Index>) -> NSRange {

        let utf16view = self.utf16
        let from = String.UTF16View.Index(range.lowerBound, within: utf16view)
        let to = String.UTF16View.Index(range.upperBound, within: utf16view)

        return NSMakeRange(utf16view.startIndex.distance(to: from), from.distance(to: to))
    }
}

extension String {

    func yep_mentionWordInIndex(_ index: Int) -> (wordString: String, mentionWordRange: Range<Index>)? {

        //println("startIndex: \(startIndex), endIndex: \(endIndex), index: \(index), length: \((self as NSString).length), count: \(self.characters.count)")

        guard index > 0 else {
            return nil
        }

        let nsRange = NSMakeRange(index, 0)
        guard let range = self.yep_rangeFromNSRange(nsRange) else {
            return nil
        }
        let index = range.lowerBound

        var wordString: String?
        var wordRange: Range<Index>?

        self.enumerateSubstrings(in: startIndex..<endIndex, options: [.byWords, .reverse]) { (substring, substringRange, enclosingRange, stop) -> () in

            //println("substring: \(substring)")
            //println("substringRange: \(substringRange)")
            //println("enclosingRange: \(enclosingRange)")

            if substringRange.contains(index) {
                wordString = substring
                wordRange = substringRange
                stop = true
            }
        }

        guard let _wordString = wordString, let _wordRange = wordRange else {
            return nil
        }

        guard _wordRange.lowerBound != startIndex else {
            return nil
        }

        let mentionWordRange = self.index(_wordRange.lowerBound, offsetBy: -1)..<_wordRange.upperBound

        let mentionWord = substring(with: mentionWordRange)

        guard mentionWord.hasPrefix("@") else {
            return nil
        }

        return (_wordString, mentionWordRange)
    }
}

extension String {

    var yep_embeddedURLs: [URL] {

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
}

extension String {

    func yep_hightlightSearchKeyword(_ keyword: String, baseFont: UIFont, baseColor: UIColor) -> NSAttributedString? {

        return yep_highlightKeyword(keyword, withColor: UIColor.yepTintColor(), baseFont: baseFont, baseColor: baseColor)
    }

    func yep_highlightKeyword(_ keyword: String, withColor color: UIColor, baseFont: UIFont, baseColor: UIColor) -> NSAttributedString? {

        guard !keyword.isEmpty else {
            return nil
        }

        let text = self
        let attributedString = NSMutableAttributedString(string: text)
        let textRange = NSMakeRange(0, (text as NSString).length)

        attributedString.addAttribute(NSForegroundColorAttributeName, value: baseColor, range: textRange)
        attributedString.addAttribute(NSFontAttributeName, value: baseFont, range: textRange)

        // highlight keyword

        let highlightTextAttributes: [String: AnyObject] = [
            NSForegroundColorAttributeName: color,
        ]

        let highlightExpression = try! NSRegularExpression(pattern: keyword, options: [.caseInsensitive])

        highlightExpression.enumerateMatches(in: text, options: NSRegularExpression.MatchingOptions(), range: textRange, using: { result, flags, stop in

            if let result = result {
                attributedString.addAttributes(highlightTextAttributes, range: result.range )
            }
        })

        return attributedString
    }

    func yep_keywordSetOfEmphasisTags() -> Set<String> {

        let text = self
        let textRange = NSMakeRange(0, (text as NSString).length)

        let keywordExpression = try! NSRegularExpression(pattern: "<em>(.+?)</em>", options: [.caseInsensitive])

        let matches = keywordExpression.matches(in: self, options: [], range: textRange)
        let keywords: [String] = matches.map({
            let matchRange = $0.rangeAt(1)
            let keyword = (text as NSString).substring(with: matchRange)
            return keyword.lowercased()
        })

        let keywordSet = Set(keywords)
        return keywordSet
    }

    func yep_highlightWithKeywordSet(_ keywordSet: Set<String>, color: UIColor, baseFont: UIFont, baseColor: UIColor) -> NSAttributedString? {

        let text = self
        let textRange = NSMakeRange(0, (self as NSString).length)

        let attributedString = NSMutableAttributedString(string: text)

        attributedString.addAttribute(NSForegroundColorAttributeName, value: baseColor, range: textRange)
        attributedString.addAttribute(NSFontAttributeName, value: baseFont, range: textRange)

        let highlightTextAttributes: [String: AnyObject] = [
            NSForegroundColorAttributeName: color,
        ]

        keywordSet.forEach({
            if let highlightExpression = try? NSRegularExpression(pattern: $0, options: [.caseInsensitive]) {

                highlightExpression.enumerateMatches(in: text, options: NSRegularExpression.MatchingOptions(), range: textRange, using: { result, flags, stop in

                    if let result = result {
                        attributedString.addAttributes(highlightTextAttributes, range: result.range )
                    }
                })
            }
        })

        return attributedString
    }

    /*
    func yep_highlightEmphasisTagWithColor(color: UIColor, baseFont: UIFont, baseColor: UIColor) -> NSAttributedString? {

        let text = self
        let textRange = NSMakeRange(0, (text as NSString).length)

        let keywordExpression = try! NSRegularExpression(pattern: "<em>(.+?)</em>", options: [.CaseInsensitive])

        let matches = keywordExpression.matchesInString(self, options: [], range: textRange)
        let keywords: [String] = matches.map({
            let matchRange = $0.rangeAtIndex(1)
            let keyword = (text as NSString).substringWithRange(matchRange)
            return keyword.lowercaseString
        })

        guard !keywords.isEmpty else {
            return nil
        }

        let keywordSet = Set(keywords)

        println("EmphasisTag keywords: \(keywords)")
        println("EmphasisTag keywordSet: \(keywordSet)")

        guard !keywordSet.isEmpty else {
            return nil
        }

        let emphasisTagExpression = try! NSRegularExpression(pattern: "</?em>", options: [.CaseInsensitive])
        let encodedString = emphasisTagExpression.stringByReplacingMatchesInString(text, options: [], range: textRange, withTemplate: "")

        println("EmphasisTag encodedString: \(encodedString)")

        let encodedData = encodedString.dataUsingEncoding(NSUTF8StringEncoding)!
        let attributedOptions: [String: AnyObject] = [
            NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
            NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding
        ]
        guard let decodedString = try? NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil).string else {
            return nil
        }

        println("EmphasisTag decodedString: \(decodedString)")

        let decodedStringRange = NSMakeRange(0, (decodedString as NSString).length)

        let attributedString = NSMutableAttributedString(string: decodedString)

        attributedString.addAttribute(NSForegroundColorAttributeName, value: baseColor, range: decodedStringRange)
        attributedString.addAttribute(NSFontAttributeName, value: baseFont, range: decodedStringRange)

        let highlightTextAttributes: [String: AnyObject] = [
            NSForegroundColorAttributeName: color,
        ]

        keywordSet.forEach({
            if let highlightExpression = try? NSRegularExpression(pattern: $0, options: [.CaseInsensitive]) {

                highlightExpression.enumerateMatchesInString(decodedString, options: NSMatchingOptions(), range: decodedStringRange, usingBlock: { result, flags, stop in

                    if let result = result {
                        attributedString.addAttributes(highlightTextAttributes, range: result.range )
                    }
                })
            }
        })
        
        return attributedString
    }
     */
}
