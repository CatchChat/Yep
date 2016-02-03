//
//  ChatTextView.swift
//  Yep
//
//  Created by NIX on 15/6/26.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatTextView: UITextView {

    var tapMentionAction: ((username: String) -> Void)?

    static let detectionTypeName = "ChatTextStorage.detectionTypeName"

    enum DetectionType: String {
        case Mention
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        self.delegate = self

        editable = false
        dataDetectorTypes = [.Link, .PhoneNumber, .CalendarEvent]
    }

    override var text: String! {
        didSet {
            let attributedString = NSMutableAttributedString(string: text)

            let textRange = NSMakeRange(0, (text as NSString).length)

            attributedString.addAttribute(NSForegroundColorAttributeName, value: textColor!, range: textRange)
            attributedString.addAttribute(NSFontAttributeName, value: font!, range: textRange)

            // mention link

            let mentionPattern = "[@＠]([A-Za-z0-9_]{4,16})"

            let mentionExpression = try! NSRegularExpression(pattern: mentionPattern, options: NSRegularExpressionOptions())

            mentionExpression.enumerateMatchesInString(text, options: NSMatchingOptions(), range: textRange, usingBlock: { result, flags, stop in

                if let result = result {
                    let textValue = (self.text as NSString).substringWithRange(result.range)

                    let textAttributes: [String: AnyObject] = [
                        NSLinkAttributeName: textValue,
                        ChatTextView.detectionTypeName: DetectionType.Mention.rawValue,
                    ]

                    attributedString.addAttributes(textAttributes, range: result.range )
                }
            })

            self.attributedText = attributedString
        }
    }

    // MARK: 点击链接 hack

    override func canBecomeFirstResponder() -> Bool {
        return false
    }

    override func addGestureRecognizer(gestureRecognizer: UIGestureRecognizer) {

        // iOS 9 以上，强制不添加文字选择长按手势，免去触发选择文字
        // 共有四种长按手势，iOS 9 正式版里分别加了两次：0.1 Reveal，0.12 tap link，0.5 selection， 0.75 press link
        if isOperatingSystemAtLeastMajorVersion(9) {
            if let longPressGestureRecognizer = gestureRecognizer as? UILongPressGestureRecognizer {
                if longPressGestureRecognizer.minimumPressDuration == 0.5 {
                    return
                }
            }
        }

        super.addGestureRecognizer(gestureRecognizer)
    }
}

extension ChatTextView: UITextViewDelegate {

    func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {

        guard let detectionTypeName = self.attributedText.attribute(ChatTextView.detectionTypeName, atIndex: characterRange.location, effectiveRange: nil) as? String, detectionType = DetectionType(rawValue: detectionTypeName) else {
            return true
        }

        let text = (self.text as NSString).substringWithRange(characterRange)

        self.hangleTapText(text, withDetectionType: detectionType)

        return true
    }

    private func hangleTapText(text: String, withDetectionType detectionType: DetectionType) {

        println("hangleTapText: \(text), \(detectionType)")

        let username = text.substringFromIndex(text.startIndex.advancedBy(1))

        if !username.isEmpty {
            tapMentionAction?(username: username)
        }
    }
}

