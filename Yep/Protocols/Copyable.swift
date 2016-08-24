//
//  Copyable.swift
//  Yep
//
//  Created by NIX on 16/7/8.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

protocol Copyable {

    var text: String? { get }
}

extension ChatLeftTextCellNode: Copyable {

    var text: String? {
        return textNode.attributedText?.string
    }
}

extension ChatRightTextCellNode: Copyable {

    var text: String? {
        return textNode.attributedText?.string
    }
}

