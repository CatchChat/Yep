//
//  UISearchBar+Yep.swift
//  Yep
//
//  Created by NIX on 16/4/7.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import KeypathObserver

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

    func yep_makeSureCancelButtonAlwaysEnabled() -> KeypathObserver<UIButton, Bool>? {

        guard let cancelButton = yep_cancelButton else {
            println("Not cancelButton in searchBar!")
            return nil
        }

        return KeypathObserver(
            object: cancelButton,
            keypath: "enabled",
            valueTransformer: { $0 as? Bool },
            valueUpdated: { [weak self] enabled in
                guard let cancelButton = self?.yep_cancelButton else { return }
                guard let enabled = enabled else { return }
                if !enabled {
                    cancelButton.enabled = true
                }
            }
        )
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
