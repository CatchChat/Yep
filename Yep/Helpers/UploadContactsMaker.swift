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

    fileprivate class func contacts() -> [CNContact] {

        let contactStore = CNContactStore()

        guard let containers = try? contactStore.containers(matching: nil) else {
            println("Error fetching containers")
            return []
        }

        let keysToFetch = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactPhoneNumbersKey,
        ] as [Any]

        var results: [CNContact] = []

        containers.forEach({

            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: $0.identifier)

            do {
                let containerResults = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch as! [CNKeyDescriptor])
                results.append(contentsOf: containerResults)

            } catch {
                println("Error fetching results for container")
            }
        })

        return results
    }

    class func make() -> [UploadContact] {

        var uploadContacts = [UploadContact]()

        for contact in contacts() {

            guard let compositeName = CNContactFormatter.string(from: contact, style: .fullName) else {
                continue
            }

            let phoneNumbers = contact.phoneNumbers
            for phoneNumber in phoneNumbers {
                let number = (phoneNumber.value ).stringValue
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

