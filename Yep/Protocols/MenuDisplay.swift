//
//  MenuDisplay.swift
//  Yep
//
//  Created by NIX on 16/7/8.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

protocol MenuDisplay {

    func targetRectInView(view: UIView) -> CGRect
}

extension ChatLeftTextCellNode: MenuDisplay {

    func targetRectInView(view: UIView) -> CGRect {
        let rect = bubbleNode.frame
        return view.convertRect(rect, toView: view)
    }
}

extension ChatRightTextCellNode: MenuDisplay {

    func targetRectInView(view: UIView) -> CGRect {
        let rect = bubbleNode.frame
        return view.convertRect(rect, toView: view)
    }
}

