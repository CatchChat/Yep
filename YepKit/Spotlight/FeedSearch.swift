//
//  FeedSearch.swift
//  Yep
//
//  Created by NIX on 16/3/29.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import CoreSpotlight
import MobileCoreServices.UTType

@available(iOS 9.0, *)
public extension Feed {

    public var attributeSet: CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        attributeSet.title = creator?.nickname
        attributeSet.contentDescription = body

        if kind == FeedKind.Image.rawValue, let attachment = attachments.first.map({ DiscoveredAttachment(metadata: $0.metadata, URLString: $0.URLString, image: nil) }), thumbnailImageData = attachment.thumbnailImageData {
            attributeSet.thumbnailData = thumbnailImageData

        } else {
            attributeSet.thumbnailData = creator?.avatar?.roundMini
        }

        return attributeSet
    }
}

