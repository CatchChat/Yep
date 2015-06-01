//
//  FriendsInContactsViewController.swift
//  Yep
//
//  Created by NIX on 15/6/1.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import APAddressBook

class FriendsInContactsViewController: UIViewController {

    lazy var addressBook: APAddressBook = {
        let addressBook = APAddressBook()
        addressBook.fieldsMask = APContactField(rawValue: APContactField.CompositeName.rawValue | APContactField.Phones.rawValue)
        return addressBook
        }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Available Friends", comment: "")


        addressBook.loadContacts{ (contacts: [AnyObject]!, error: NSError!) in
            if let contacts = contacts as? [APContact] {
                for contact in contacts {
                    println(contact.compositeName, contact.phones)
                }

            } else if (error != nil) {
                let alert = UIAlertView(title: "Error", message: error.localizedDescription,
                    delegate: nil, cancelButtonTitle: "OK")
                alert.show()
            }
        }
    }

}
