//
//  ChatTextNode.swift
//  Yep
//
//  Created by NIX on 16/7/12.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import AsyncDisplayKit

class ChatTextNode: ASTextNode {

    override init() {
        super.init()

        self.delegate = self
        self.userInteractionEnabled = true
        self.linkAttributeNames = ["TextLinkAttributeName"]
        self.passthroughNonlinkTouches = true
    }

    func setText(text: String, withTextAttributes textAttributes: [String: AnyObject], linkAttributes: [String: AnyObject]) {

        let attributedText = NSMutableAttributedString(string: text, attributes: textAttributes)

        let textRange = NSMakeRange(0, (text as NSString).length)

        // mention

        let mentionPattern = "[@＠]([A-Za-z0-9_]{4,16})"
        if let mentionExpression = try? NSRegularExpression(pattern: mentionPattern, options: NSRegularExpressionOptions()) {

            mentionExpression.enumerateMatchesInString(text, options: NSMatchingOptions(), range: textRange, usingBlock: { result, flags, stop in

                guard let result = result else {
                    return
                }
                
                var linkAttributes = linkAttributes
                let mentionUsername: NSString = (text as NSString).substringWithRange(result.range)
                let username = mentionUsername.substringFromIndex(1)
                linkAttributes["TextLinkAttributeName"] = NSURL(string: "https://soyep.com/\(username)")

                attributedText.addAttributes(textAttributes, range: result.range)
            })
        }

        // link

        if let urlDetector = try? NSDataDetector(types: NSTextCheckingType.Link.rawValue) {

            urlDetector.enumerateMatchesInString(text, options: [], range: textRange, usingBlock: { (result, flags, stop) in

                guard let result = result else {
                    return
                }

                if result.resultType == NSTextCheckingType.Link {

                    var linkAttributes = linkAttributes
                    if let urlString = result.URL?.absoluteString {
                        linkAttributes["TextLinkAttributeName"] = NSURL(string: urlString)
                    }

                    attributedText.addAttributes(linkAttributes, range: result.range)
                }
            })
        }

        self.attributedText = attributedText
    }
}

extension ChatTextNode: ASTextNodeDelegate {

    func textNode(textNode: ASTextNode, shouldHighlightLinkAttribute attribute: String, value: AnyObject, atPoint point: CGPoint) -> Bool {

        return true
    }

    func textNode(textNode: ASTextNode, tappedLinkAttribute attribute: String, value: AnyObject, atPoint point: CGPoint, textRange: NSRange) {

        print("tappedLinkAttribute: \(attribute), \(value)")
    }
}

