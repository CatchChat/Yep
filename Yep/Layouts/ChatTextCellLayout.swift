//
//  ChatTextCellLayout.swift
//  Yep
//
//  Created by NIX on 16/6/1.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import YepKit

typealias ChatTextCellLayoutCache = (textContentTextViewWidth: CGFloat, textContentTextViewFrame: CGRect?, update: (textContentTextViewFrame: CGRect) -> Void)

class ChatTextCellLayout {

    static let sharedLayout = ChatTextCellLayout()

    private init() {
    }

    class func layoutCacheOfMessage(message: Message, textContentTextViewMaxWidth: CGFloat) -> ChatTextCellLayoutCache {

        let layoutCache = ChatTextCellLayoutCache(
            textContentTextViewWidth: sharedLayout.textContentTextViewWidthOfMessage(message, textContentTextViewMaxWidth: textContentTextViewMaxWidth),
            textContentTextViewFrame: sharedLayout.textContentTextViewFrameOfMessage(message),
            update: { textContentTextViewFrame in
                sharedLayout.updateTextContentTextViewFrame(textContentTextViewFrame, forMessage: message)
            }
        )

        return layoutCache
    }

    private var textContentTextViewWidths = [String: CGFloat]()
    private func textContentTextViewWidthOfMessage(message: Message, textContentTextViewMaxWidth: CGFloat) -> CGFloat {

        let key = message.messageID

        if !key.isEmpty {
            if let textContentLabelWidth = textContentTextViewWidths[key] {
                return textContentLabelWidth
            }
        }

        let rect = message.textContent.boundingRectWithSize(CGSize(width: textContentTextViewMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.ChatCell.textAttributes, context: nil)

        let width = ceil(rect.width)

        if !key.isEmpty {
            textContentTextViewWidths[key] = width
        }

        return width
    }
    class func updateTextContentTextViewWidth(width: CGFloat, forMessage message: Message) {

        let key = message.messageID

        if !key.isEmpty {
            sharedLayout.textContentTextViewWidths[key] = width
        }
    }

    private var textContentTextViewFrames = [String: CGRect]()
    private func textContentTextViewFrameOfMessage(message: Message) -> CGRect? {

        let key = message.messageID
        return textContentTextViewFrames[key]
    }
    private func updateTextContentTextViewFrame(frame: CGRect, forMessage message: Message) {

        let key = message.messageID

        if !key.isEmpty {
            textContentTextViewFrames[key] = frame
        }
    }
    class func textContentTextViewFrameOfMessage(message: Message) -> CGRect? {

        return sharedLayout.textContentTextViewFrameOfMessage(message)
    }
}

