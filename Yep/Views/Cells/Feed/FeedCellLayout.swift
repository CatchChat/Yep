//
//  FeedCellLayout.swift
//  Yep
//
//  Created by nixzhu on 15/12/17.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import Foundation

struct FeedCellLayout {

    struct BasicLayout {

        let avatarImageViewFrame: CGRect
        let nicknameLabelFrame: CGRect
        let skillButtonFrame: CGRect

        let messageTextViewFrame: CGRect

        let leftBottomLabelFrame: CGRect
        let messageCountLabelFrame: CGRect
        let discussionImageViewFrame: CGRect
    }
    let basicLayout: BasicLayout

    struct BiggerImageLayout {
        let biggerImageViewFrame: CGRect
    }
    let biggerImageLayout: BiggerImageLayout?

    struct NormalImagesLayout {

        let imageView1Frame: CGRect
        let imageView2Frame: CGRect
        let imageView3Frame: CGRect
    }
    let normalImagesLayout: NormalImagesLayout?

    struct AnyImagesLayout {

        let mediaCollectionView: CGRect
    }
    let anyImagesLayout: AnyImagesLayout?
}

