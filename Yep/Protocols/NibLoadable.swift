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

extension NibLoadable where Self: UIView {

    static var nibName: String {
        return String(Self)
    }
}

extension UITableViewCell: NibLoadable {
}

extension UICollectionReusableView: NibLoadable {
}

