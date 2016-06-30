//
//  UISearchBar+Yep.swift
//  Yep
//
//  Created by NIX on 16/4/7.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

extension UISearchBar {

    var yep_cancelButton: UIButton? {

        for subview in self.subviews {
            //println("subview: \(subview)")
            for subview in subview.subviews {
                //println("----subview: \(subview)")
                if let cancelButton = subview as? UIButton {
                    return cancelButton
                }
            }
        }

        return nil
    }

    func yep_enableCancelButton() {

        yep_cancelButton?.enabled = true
    }

    func yep_makeSureCancelButtonAlwaysEnabled() -> ObjectKeypathObserver<UIButton>? {

        guard let cancelButton = yep_cancelButton else {
            println("Not cancelButton in searchBar!")
            return nil
        }

        return ObjectKeypathObserver(object: cancelButton, keypath: "enabled", afterValueChanged: { object in
            let cancelButton = object
            if !cancelButton.enabled {
                cancelButton.enabled = true
            }
        })
    }

    var yep_textField: UITextField? {

        for subview in self.subviews {
            for subview in subview.subviews {
                if let textField = subview as? UITextField {
                    return textField
                }
            }
        }

        return nil
    }

    var yep_fullSearchText: String? {

        var searchText: String?

        if let
            textField = self.yep_textField,
            markedTextRange = textField.markedTextRange,
            markedText = textField.textInRange(markedTextRange) {

            if let text = self.text where !text.isEmpty {
                let beginning = textField.beginningOfDocument
                let start = markedTextRange.start
                let end = markedTextRange.end
                let location = textField.offsetFromPosition(beginning, toPosition: start)
                let length = textField.offsetFromPosition(start, toPosition: end)
                let nsRange = NSMakeRange(location, length)

                if let range = text.yep_rangeFromNSRange(nsRange) {
                    var text = text
                    text.removeRange(range)
                    searchText = text + markedText.yep_removeAllWhitespaces
                }
            }
        }

        return searchText
    }
}
