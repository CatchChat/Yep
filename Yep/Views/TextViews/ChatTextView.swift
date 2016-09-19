//
//  ChatTextView.swift
//  Yep
//
//  Created by NIX on 15/6/26.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class ChatTextView: UITextView {

    var tapMentionAction: ((_ username: String) -> Void)?
    var tapFeedAction: ((_ feed: DiscoveredFeed?) -> Void)?

    fileprivate static let detectionTypeName = "ChatTextStorage.detectionTypeName"

    fileprivate static let mentionRegularExpressions: [NSRegularExpression] = {
        let patterns = [
            "([@＠][A-Za-z0-9_]{4,16})$",
            "([@＠][A-Za-z0-9_]{4,16})\\s",
            "([@＠][A-Za-z0-9_]{4,16})[^A-Za-z0-9_\\.]",
        ]
        return patterns.map { try! NSRegularExpression(pattern: $0, options: []) }
    }()

    fileprivate enum DetectionType: String {
        case Mention
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        self.delegate = self

        isEditable = false
        dataDetectorTypes = [.link, .phoneNumber, .calendarEvent]
    }

    func createAttributedStringWithString(_ string: String) -> NSAttributedString {

        let plainText = string

        let attributedString = NSMutableAttributedString(string: plainText)

        let textRange = NSMakeRange(0, (plainText as NSString).length)

        attributedString.addAttribute(NSForegroundColorAttributeName, value: textColor!, range: textRange)
        attributedString.addAttribute(NSFontAttributeName, value: font!, range: textRange)

        // mention link

        func addMentionAttributes(withRange range: NSRange) {

            let textValue = (plainText as NSString).substring(with: range)

            let textAttributes: [String: AnyObject] = [
                NSLinkAttributeName: textValue as AnyObject,
                ChatTextView.detectionTypeName: DetectionType.Mention.rawValue as AnyObject,
            ]

            attributedString.addAttributes(textAttributes, range: range)
        }

        ChatTextView.mentionRegularExpressions.forEach {
            let matches = $0.matches(in: plainText, options: [], range: textRange)
            for match in matches {
                let range = match.rangeAt(1)
                addMentionAttributes(withRange: range)
            }
        }

        return attributedString
    }

    func setAttributedTextWithMessage(_ message: Message) {

        let key = message.messageID

        if let attributedString = AttributedStringCache.valueForKey(key) {
            self.attributedText = attributedString

        } else {
            let attributedString = createAttributedStringWithString(message.textContent)

            self.attributedText = attributedString

            AttributedStringCache.setValue(attributedString, forKey: key)
        }
    }

    // MARK: 点击链接 hack

    override var canBecomeFirstResponder : Bool {
        return false
    }

    override func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {

        // iOS 9 以上，强制不添加文字选择长按手势，免去触发选择文字
        // 共有四种长按手势，iOS 9 正式版里分别加了两次：0.1 Reveal，0.12 tap link，0.5 selection， 0.75 press link
        if let longPressGestureRecognizer = gestureRecognizer as? UILongPressGestureRecognizer {
            if longPressGestureRecognizer.minimumPressDuration == 0.5 {
                return
            }
        }

        super.addGestureRecognizer(gestureRecognizer)
    }
}

extension ChatTextView: UITextViewDelegate {

    fileprivate func tryMatchSharedFeedWithURL(_ URL: Foundation.URL) -> Bool {

        let matched = URL.yep_matchSharedFeed { [weak self] feed in
            self?.tapFeedAction?(feed: feed)
        }

        return matched
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {

        if let detectionTypeName = self.attributedText.attribute(ChatTextView.detectionTypeName, at: characterRange.location, effectiveRange: nil) as? String, let detectionType = DetectionType(rawValue: detectionTypeName) {

            let text = (self.text as NSString).substring(with: characterRange)
            self.hangleTapText(text, withDetectionType: detectionType)

            return false

        } else if tryMatchSharedFeedWithURL(URL) {
            return false

        } else {
            return true
        }
    }

    fileprivate func hangleTapText(_ text: String, withDetectionType detectionType: DetectionType) {

        println("hangleTapText: \(text), \(detectionType)")

        let username = text.substring(from: text.characters.index(text.startIndex, offsetBy: 1))

        if !username.isEmpty {
            tapMentionAction?(username)
        }
    }
}

