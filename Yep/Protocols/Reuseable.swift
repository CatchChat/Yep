//
//  Reuseable.swift
//  Yep
//
//  Created by NIX on 16/6/14.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

protocol Reuseable: class {

    static var reuseIdentifier: String { get }
}

extension UITableViewCell: Reuseable {

    static var reuseIdentifier: String {
        return NSStringFromClass(self)
    }
}

extension UICollectionViewCell: Reuseable {

    static var reuseIdentifier: String {
        return NSStringFromClass(self)
    }
}

