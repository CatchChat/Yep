//
//  DiscoverFlowLayout.swift
//  Yep
//
//  Created by zhowkevin on 15/10/10.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class DiscoverFlowLayout: UICollectionViewFlowLayout {

    enum Mode {
        case Normal
        case Card
    }

    var mode: Mode?
    
//    override func prepareLayout() {
//        switch userMode! {
//        case .Normal:
//            self.itemSize = CGSize(width: collectionView!.frame.width, height: 80)
//        case .Card:
//            self.itemSize = CGSize(width: (collectionView!.frame.width - (10 + 10 + 10))/2.0, height: 280)
//        }
//    }

}
