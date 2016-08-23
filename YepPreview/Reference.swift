//
//  Reference.swift
//  Yep
//
//  Created by NIX on 16/8/22.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

public struct Reference {

    let view: UIView
    public let image: UIImage?

    var imageView: UIImageView {
        let imageView = UIImageView(frame: view.bounds)
        imageView.contentMode = .ScaleAspectFill
        imageView.image = image
        return imageView
    }

    public init(view: UIView, image: UIImage?) {
        self.view = view
        self.image = image
    }
}

