//
//  ChatLoadingCellNode.swift
//  Yep
//
//  Created by NIX on 16/7/7.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class ChatLoadingCellNode: ASCellNode {

    var isLoading: Bool = false {
        didSet {
            if isLoading {
                indicator.startAnimating()
            } else {
                indicator.stopAnimating()
            }
        }
    }

    private lazy var indicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        view.hidesWhenStopped = true
        return view
    }()

    override init() {
        super.init()

        selectionStyle = .None
        
        self.view.addSubview(indicator)
    }

    override func calculateSizeThatFits(constrainedSize: CGSize) -> CGSize {

        return CGSize(width: constrainedSize.width, height: 30)
    }

    override func layout() {
        super.layout()

        indicator.center = self.view.center
    }
}

