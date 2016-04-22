//
//  SearchActionRepresentation.swift
//  Yep
//
//  Created by NIX on 16/4/22.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

protocol SearchActionRepresentation: class {

    var searchBar: UISearchBar! { get }
    var searchBarTopConstraint: NSLayoutConstraint! { get }

    var originalNavigationControllerDelegate: UINavigationControllerDelegate? { get }
    var searchTransition: SearchTransition? { get set }
}

extension SearchActionRepresentation where Self: UIViewController {

    func recoverSearchTransition() {
        if let delegate = searchTransition {
            navigationController?.delegate = delegate
        }
    }

    func prepareOriginalNavigationControllerDelegate() {
        // 记录原始的 searchTransition 以便 pop 后恢复
        searchTransition = navigationController?.delegate as? SearchTransition

        println("originalNavigationControllerDelegate: \(originalNavigationControllerDelegate)")
        navigationController?.delegate = originalNavigationControllerDelegate
    }
}

extension SearchConversationsViewController: SearchActionRepresentation {

}

extension SearchContactsViewController: SearchActionRepresentation {

}

extension SearchFeedsViewController: SearchActionRepresentation {

}

