//
//  BaseSearchViewController.swift
//  Yep
//
//  Created by NIX on 16/9/2.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import KeypathObserver

class BaseSearchViewController: SegueViewController {

    private var searchBarCancelButtonEnabledObserver: KeypathObserver<UIButton, Bool>?
    @IBOutlet weak var searchBar: UISearchBar! {
        didSet {
            searchBar.placeholder = NSLocalizedString("Search", comment: "")
            searchBar.setSearchFieldBackgroundImage(UIImage.yep_searchbarTextfieldBackground, forState: .Normal)
            searchBar.returnKeyType = .Done
        }
    }
    @IBOutlet weak var searchBarBottomLineView: HorizontalLineView! {
        didSet {
            searchBarBottomLineView.lineColor = UIColor(white: 0.68, alpha: 1.0)
        }
    }
    @IBOutlet weak var searchBarTopConstraint: NSLayoutConstraint!
}
