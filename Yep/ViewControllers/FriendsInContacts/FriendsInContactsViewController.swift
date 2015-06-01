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

                var uploadContacts = [UploadContact]()

                for contact in contacts {
                    println(contact.compositeName, contact.phones)

                    let name = contact.compositeName

                    if let phones = contact.phones as? [String] {
                        for phone in phones {
                            let uploadContact: UploadContact = ["name": name, "number": phone]
                            uploadContacts.append(uploadContact)
                        }
                    }
                }

                println(uploadContacts)

                friendsInContacts(uploadContacts, failureHandler: nil, completion: { x in
                    println(x)
                })

            } else if (error != nil) {
                YepAlert.alertSorry(message: error.localizedDescription, inViewController: self)
            }
        }
    }

}
