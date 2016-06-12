//
//  EditProfileMoreInfoCell.swift
//  Yep
//
//  Created by NIX on 15/4/27.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class EditProfileMoreInfoCell: UITableViewCell {

    @IBOutlet weak var annotationLabel: UILabel!

    @IBOutlet weak var infoTextView: UITextView!

    var infoTextViewBeginEditingAction: ((infoTextView: UITextView) -> Void)?
    var infoTextViewIsDirtyAction: (() -> Void)?
    var infoTextViewDidEndEditingAction: (String -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .None

        infoTextView.font = YepConfig.EditProfile.infoFont

        infoTextView.autocapitalizationType = .None
        infoTextView.autocorrectionType = .No
        infoTextView.spellCheckingType = .No

        infoTextView.textContainer.lineFragmentPadding = 0
        infoTextView.textContainerInset = UIEdgeInsetsZero

        infoTextView.delegate = self
    }
}

// MARK: - UITextViewDelegate

extension EditProfileMoreInfoCell: UITextViewDelegate {

    func textViewShouldBeginEditing(textView: UITextView) -> Bool {

        infoTextViewBeginEditingAction?(infoTextView: textView)

        return true
    }

    func textViewDidChange(textView: UITextView) {

        infoTextViewIsDirtyAction?()
    }

    func textViewDidEndEditing(textView: UITextView) {
        if textView == infoTextView {
            let text = textView.text.trimming(.WhitespaceAndNewline)
            textView.text = text
            infoTextViewDidEndEditingAction?(text)
        }
    }
}

