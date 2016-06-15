//
//  NibLoadable.swift
//  Yep
//
//  Created by NIX on 16/6/14.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

protocol NibLoadable {

    static var yep_nibName: String { get }
}

extension UITableViewCell: NibLoadable {

    static var yep_nibName: String {
        return String(self)
    }
}

extension UICollectionReusableView: NibLoadable {

    static var yep_nibName: String {
        return String(self)
    }
}

