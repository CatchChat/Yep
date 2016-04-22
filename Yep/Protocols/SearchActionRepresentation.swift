//
//  SearchActionRepresentation.swift
//  Yep
//
//  Created by NIX on 16/4/22.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

protocol SearchActionRepresentation {

    var searchBar: UISearchBar! { get }
    var searchBarTopConstraint: NSLayoutConstraint! { get }
}

extension SearchConversationsViewController: SearchActionRepresentation {

}

extension SearchContactsViewController: SearchActionRepresentation {

}

extension SearchFeedsViewController: SearchActionRepresentation {

}

