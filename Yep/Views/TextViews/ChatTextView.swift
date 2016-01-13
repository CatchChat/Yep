//
//  ChatTextView.swift
//  Yep
//
//  Created by NIX on 15/6/26.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

// MARK: ChatTextStorage

class ChatTextStorage: NSTextStorage {

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





