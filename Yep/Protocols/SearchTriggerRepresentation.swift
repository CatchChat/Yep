//
//  SearchTriggerRepresentation.swift
//  Yep
//
//  Created by NIX on 16/4/22.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

protocol SearchTriggerRepresentation: class {

    var originalNavigationControllerDelegate: UINavigationControllerDelegate? { get set }
    var searchTransition: SearchTransition { get }
}

extension SearchTriggerRepresentation where Self: UIViewController {

    func prepareSearchTransition() {
        // 在自定义 push 之前，记录原始的 NavigationControllerDelegate 以便 pop 后恢复
        originalNavigationControllerDelegate = navigationController?.delegate

        navigationController?.delegate = searchTransition
    }

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

