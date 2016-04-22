//
//  SearchTriggerRepresentation.swift
//  Yep
//
//  Created by NIX on 16/4/22.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

protocol SearchTriggerRepresentation {

    var originalNavigationControllerDelegate: UINavigationControllerDelegate? { get }
}

extension SearchTriggerRepresentation where Self: UIViewController {

    func recoverOriginalNavigationDelegate() {
        if let originalNavigationControllerDelegate = originalNavigationControllerDelegate {
            navigationController?.delegate = originalNavigationControllerDelegate
        }
    }
}

extension ConversationsViewController: SearchTriggerRepresentation {

}

extension ContactsViewController: SearchTriggerRepresentation {

}

extension FeedsViewController: SearchTriggerRepresentation {

}

