//
//  ContactsSearchController.swift
//  Yep
//
//  Created by NIX on 16/3/11.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class ContactsSearchController: UISearchController {

    override var active: Bool {
        didSet {
            guard active != oldValue else {
                return
            }

            searchResultsController?.navigationController?.setNavigationBarHidden(true, animated: true)

            if active {
                searchBar.becomeFirstResponder()
            } else {
                searchBar.resignFirstResponder()
                searchResultsController?.navigationController?.setNavigationBarHidden(false, animated: true)
            }
        }
    }
}
