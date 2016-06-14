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

extension Reuseable where Self: UITableViewCell {

    static var reuseIdentifier: String {
        return NSStringFromClass(self)
    }
}

extension Reuseable where Self: UICollectionViewCell {

    static var reuseIdentifier: String {
        return NSStringFromClass(self)
    }
}

