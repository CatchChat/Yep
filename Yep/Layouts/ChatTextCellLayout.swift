//
//  ChatTextCellLayout.swift
//  Yep
//
//  Created by NIX on 16/6/1.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import YepKit

typealias ChatTextCellLayoutCache = (textContentTextViewWidth: CGFloat, textContentTextViewFrame: CGRect?, update: (_ textContentTextViewFrame: CGRect) -> Void)

class ChatTextCellLayout {

    static let sharedLayout = ChatTextCellLayout()

    fileprivate init() {
    }

    class func layoutCacheOfMessage(_ message: Message, textContentTextViewMaxWidth: CGFloat) -> ChatTextCellLayoutCache {

        let layoutCache = ChatTextCellLayoutCache(
            textContentTextViewWidth: sharedLayout.textContentTextViewWidthOfMessage(message, textContentTextViewMaxWidth: textContentTextViewMaxWidth),
            textContentTextViewFrame: sharedLayout.textContentTextViewFrameOfMessage(message),
            update: { textContentTextViewFrame in
                sharedLayout.updateTextContentTextViewFrame(textContentTextViewFrame, forMessage: message)
            }
        )

        return layoutCache
    }

    fileprivate var textContentTextViewWidths = [String: CGFloat]()
    fileprivate func textContentTextViewWidthOfMessage(_ message: Message, textContentTextViewMaxWidth: CGFloat) -> CGFloat {

        let key = message.messageID

        if !key.isEmpty {
            if let textContentLabelWidth = textContentTextViewWidths[key] {
                return textContentLabelWidth
            }
        }

        let rect = message.textContent.boundingRect(with: CGSize(width: textContentTextViewMaxWidth, height: CGFloat(FLT_MAX)), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: YepConfig.ChatCell.textAttributes, context: nil)

        let width = ceil(rect.width)

        if !key.isEmpty {
            textContentTextViewWidths[key] = width
        }

        return width
    }
    class func updateTextContentTextViewWidth(_ width: CGFloat, forMessage message: Message) {

        let key = message.messageID

        if !key.isEmpty {
            sharedLayout.textContentTextViewWidths[key] = width
        }
    }

    fileprivate var textContentTextViewFrames = [String: CGRect]()
    fileprivate func textContentTextViewFrameOfMessage(_ message: Message) -> CGRect? {

        let key = message.messageID
        return textContentTextViewFrames[key]
    }
    fileprivate func updateTextContentTextViewFrame(_ frame: CGRect, forMessage message: Message) {

        let key = message.messageID

        if !key.isEmpty {
            textContentTextViewFrames[key] = frame
        }
    }
    class func textContentTextViewFrameOfMessage(_ message: Message) -> CGRect? {

        return sharedLayout.textContentTextViewFrameOfMessage(message)
    }
}

