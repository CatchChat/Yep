//
//  DiscoverCollectionView.swift
//  Yep
//
//  Created by NIX on 16/3/11.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

final class DiscoverCollectionView: UICollectionView {

    // ref http://stackoverflow.com/questions/19483511/uirefreshcontrol-with-uicollectionview-in-ios7
    override var contentInset: UIEdgeInsets {
        didSet {
            if isTracking {
                let diff = contentInset.top - oldValue.top
                var translation = panGestureRecognizer.translation(in: self)
                translation.y -= diff * 3 / 2
                panGestureRecognizer.setTranslation(translation, in: self)
            }
        }
    }
}
