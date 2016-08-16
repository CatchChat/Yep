//
//  Previewable.swift
//  Yep
//
//  Created by NIX on 16/7/6.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

protocol Previewable {

    var transitionView: UIView { get }
}

extension ChatLeftImageCellNode: Previewable {

    var transitionView: UIView {
        return imageNode.view
    }
}

extension ChatRightImageCellNode: Previewable {

    var transitionView: UIView {
        return imageNode.view
    }
}

