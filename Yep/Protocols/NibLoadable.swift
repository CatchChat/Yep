//
//  NibLoadable.swift
//  Yep
//
//  Created by NIX on 16/6/14.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

protocol NibLoadable {

    static var nibName: String { get }
}

extension UITableViewCell: NibLoadable {

    static var nibName: String {
        return String(self)
    }
}

extension UICollectionViewCell: NibLoadable {

    static var nibName: String {
        return String(self)
    }
}

extension UICollectionReusableView: NibLoadable {

    static var nibName: String {
        return String(self)
    }
}

