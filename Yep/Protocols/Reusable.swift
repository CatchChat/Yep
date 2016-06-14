//
//  Reusable.swift
//  Yep
//
//  Created by NIX on 16/6/14.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

protocol Reusable: class {

    static var reuseIdentifier: String { get }
}

extension UITableViewCell: Reusable {

    static var reuseIdentifier: String {
        return String(self)
    }
}

extension UITableViewHeaderFooterView: Reusable {

    static var reuseIdentifier: String {
        return String(self)
    }
}

extension UICollectionViewCell: Reusable {

    static var reuseIdentifier: String {
        return String(self)
    }
}

extension UICollectionReusableView: Reusable {

    static var reuseIdentifier: String {
        return String(self)
    }
}

