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

extension Reusable where Self: UIView {

    static var reuseIdentifier: String {
        return String(Self)
    }
}

extension UITableViewCell: Reusable {
}

extension UITableViewHeaderFooterView: Reusable {
}

extension UICollectionViewCell: Reusable {
}

extension UICollectionReusableView: Reusable {
}

