//
//  UploadContactsMaker.swift
//  Yep
//
//  Created by NIX on 16/5/9.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import Contacts
import YepKit

class UploadContactsMaker {

    private class func contacts() -> [CNContact] {

        let contactStore = CNContactStore()

        guard let containers = try? contactStore.containersMatchingPredicate(nil) else {
            println("Error fetching containers")
            return []
        }

        let keysToFetch = [
            CNContactFormatter.descriptorForRequiredKeysForStyle(.FullName),
            CNContactPhoneNumbersKey,
        ]

        var results: [CNContact] = []

        containers.forEach({

            let fetchPredicate = CNContact.predicateForContactsInContainerWithIdentifier($0.identifier)

            do {
                let containerResults = try contactStore.unifiedContactsMatchingPredicate(fetchPredicate, keysToFetch: keysToFetch)
                results.appendContentsOf(containerResults)

            } catch {
                println("Error fetching results for container")
            }
        })

        return results
    }

    class func make() -> [UploadContact] {

        var uploadContacts = [UploadContact]()

        for contact in contacts() {

            guard let compositeName = CNContactFormatter.stringFromContact(contact, style: .FullName) else {
                continue
            }

            let phoneNumbers = contact.phoneNumbers
            for phoneNumber in phoneNumbers {
                let number = (phoneNumber.value as! CNPhoneNumber).stringValue
                let uploadContact: UploadContact = [
                    "name": compositeName,
                    "number": number
                ]
                uploadContacts.append(uploadContact)
            }
        }
        
        return uploadContacts
    }
}

