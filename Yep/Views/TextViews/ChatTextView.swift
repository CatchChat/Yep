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

/*

// MARK: ChatTextStorage

class ChatTextStorage: NSTextStorage {

    static let detectionTypeName = "ChatTextStorage.detectionTypeName"

    enum DetectionType: String {
        case Mention
    }

    private var backingStore: NSMutableAttributedString = NSMutableAttributedString()

    var mentionRanges = [NSRange]()
    var mentionForegroundColor: UIColor = UIColor.redColor()


    override var string: String {
        return backingStore.string
    }

    override func attributesAtIndex(index: Int, effectiveRange range: NSRangePointer) -> [String : AnyObject] {
        return backingStore.attributesAtIndex(index, effectiveRange: range)
    }

    override func replaceCharactersInRange(range: NSRange, withString str: String) {
        beginEditing()
        backingStore.replaceCharactersInRange(range, withString: str)
        edited([.EditedCharacters, .EditedAttributes], range: range, changeInLength: (str as NSString).length - range.length)
        endEditing()
    }

    override func setAttributes(attrs: [String : AnyObject]!, range: NSRange) {
        beginEditing()
        backingStore.setAttributes(attrs, range: range)
        edited(.EditedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    override func addAttributes(attrs: [String : AnyObject], range: NSRange) {
        beginEditing()
        backingStore.addAttributes(attrs, range: range)
        edited(.EditedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    override func processEditing() {

        let paragraphRange = (self.string as NSString).paragraphRangeForRange(self.editedRange)

        //For Mention

        mentionRanges.removeAll()

        let mentionPattern = "@[^\\s:：,，@]+$?"

        let mentionExpression = try? NSRegularExpression(pattern: mentionPattern, options: NSRegularExpressionOptions())

        if let mentionExpression = mentionExpression {
            mentionExpression.enumerateMatchesInString(self.string, options: NSMatchingOptions(), range: paragraphRange, usingBlock: { result, flags, stop in

                if let result = result {
                    let textAttributes: [String: AnyObject] = [
                        NSForegroundColorAttributeName: self.mentionForegroundColor,
                        ChatTextStorage.detectionTypeName: DetectionType.Mention.rawValue,
                    ]

                    self.addAttributes(textAttributes, range: result.range )

                    self.mentionRanges.append(result.range)
                }
            })
        }

        super.processEditing()
    }
}

// MARK: ChatTextView

class ChatTextView: UITextView {

    var tapMentionAction: ((username: String) -> Void)?

    var chatTextStorage: ChatTextStorage {
        return self.textStorage as! ChatTextStorage
    }

    required init?(coder aDecoder: NSCoder) {

        let layoutManager = NSLayoutManager()

        let textContainer = NSTextContainer()
        textContainer.widthTracksTextView = true
        textContainer.heightTracksTextView = true

        layoutManager.addTextContainer(textContainer)

        let textStorage = ChatTextStorage()
        textStorage.addLayoutManager(layoutManager)

        super.init(frame: CGRectZero, textContainer: textContainer)
    }

    var linkTapGestureRecognizer: UITapGestureRecognizer?

    var linkTapEnabled: Bool = false {
        willSet {

            func tryRemoveLinkTapGestureRecognizer() {
                if let linkTapGestureRecognizer = self.linkTapGestureRecognizer {
                    self.removeGestureRecognizer(linkTapGestureRecognizer)
                }
            }

            func addLinkTapGestureRecognizer() {
                let linkTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "linkTapped:")
                linkTapGestureRecognizer.delegate = self
                self.addGestureRecognizer(linkTapGestureRecognizer)

                self.linkTapGestureRecognizer = linkTapGestureRecognizer
            }

            if newValue {
                tryRemoveLinkTapGestureRecognizer()

                addLinkTapGestureRecognizer()

            } else {
                tryRemoveLinkTapGestureRecognizer()
            }
        }
    }

    @objc private func linkTapped(sender: UITapGestureRecognizer) {
        println("linkTapped")

        let location = sender.locationInView(self)

        enumerateLinkRangesContainingLocation(location) { range in

            guard let detectionTypeName = self.attributedText.attribute(ChatTextStorage.detectionTypeName, atIndex: range.location, effectiveRange: nil) as? String, detectionType = ChatTextStorage.DetectionType(rawValue: detectionTypeName) else {
                return
            }

            let text = (self.text as NSString).substringWithRange(range)

            self.hangleTapText(text, withDetectionType: detectionType)
        }
    }

    private func hangleTapText(text: String, withDetectionType detectionType: ChatTextStorage.DetectionType) {

        println("hangleTapText: \(text), \(detectionType)")

        let username = text.substringFromIndex(text.startIndex.advancedBy(1))

        if !username.isEmpty {
            tapMentionAction?(username: username)
        }
    }

    private func enumerateLinkRangesContainingLocation(location: CGPoint, complete: (NSRange) -> Void) {

        var found = false

        self.attributedText.enumerateAttribute(ChatTextStorage.detectionTypeName, inRange: NSMakeRange(0, attributedText.length), options: [], usingBlock: { value, range, stop in

            if let _ = value {

                self.enumerateViewRectsForRanges([NSValue(range: range)]) { rect, range, stop in

                    if !found {
                        if CGRectContainsPoint(rect, location) {
                            self.drawRoundedCornerForRange(range, rect: rect)

                            found = true

                            complete(range)
                        }

                    } else {
                        println("Found")
                    }
                }
            }
        })
    }

    private func enumerateViewRectsForRanges(ranges: [NSValue], complete: (rect: CGRect, range: NSRange, stop: Bool) -> Void) {

        for rangeValue in ranges {

            let range = rangeValue.rangeValue

            let glyphRange = layoutManager.glyphRangeForCharacterRange(range, actualCharacterRange: nil)

            layoutManager.enumerateEnclosingRectsForGlyphRange(glyphRange, withinSelectedGlyphRange: NSMakeRange(NSNotFound, 0), inTextContainer: textContainer, usingBlock: { rect, stop in
                var rect = rect

                rect.origin.x += self.textContainerInset.left
                rect.origin.y += self.textContainerInset.top
                //rect = UIEdgeInsetsInsetRect(rect, self.tapAreaInsets)

                complete(rect: rect, range: range, stop: true)
            })
        }

        return
    }

    private func drawRoundedCornerForRange(range: NSRange, rect: CGRect) {

        let layer = CALayer()
        layer.frame = rect
        layer.backgroundColor = chatTextStorage.mentionForegroundColor.colorWithAlphaComponent(0.5).CGColor
        layer.cornerRadius = 3.0
        layer.masksToBounds = true

        self.layer.addSublayer(layer)

        delay(0.2) {
            layer.removeFromSuperlayer()
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

extension ChatTextView: UIGestureRecognizerDelegate {

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

*/
