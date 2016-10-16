//
//  BaseSearchViewController.swift
//  Yep
//
//  Created by NIX on 16/9/2.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import KeypathObserver

class BaseSearchViewController: SegueViewController, SearchActionRepresentation {

    var originalNavigationControllerDelegate: UINavigationControllerDelegate?
    var searchTransition: SearchTransition?

    fileprivate var searchBarCancelButtonEnabledObserver: KeypathObserver<UIButton, Bool>?
    @IBOutlet weak var searchBar: UISearchBar! {
        didSet {
            let image = UIImage.yep_searchbarTextfieldBackground
            searchBar.setSearchFieldBackgroundImage(image, for: .normal)
            searchBar.returnKeyType = .done
        }
    }
    @IBOutlet weak var searchBarBottomLineView: HorizontalLineView! {
        didSet {
            searchBarBottomLineView.lineColor = UIColor(white: 0.68, alpha: 1.0)
        }
    }
    @IBOutlet weak var searchBarTopConstraint: NSLayoutConstraint!

    fileprivate var isFirstAppear = true

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: true)

        if isFirstAppear {
            _ = delay(0.3) { [weak self] in
                self?.searchBar.becomeFirstResponder()
            }
            _ = delay(0.4) { [weak self] in
                self?.searchBar.setShowsCancelButton(true, animated: true)

                self?.searchBarCancelButtonEnabledObserver = self?.searchBar.yep_makeSureCancelButtonAlwaysEnabled()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        recoverSearchTransition()

        moveUpSearchBar()
        
        isFirstAppear = false
    }
    
    deinit {
        searchBarCancelButtonEnabledObserver = nil
    }
}

