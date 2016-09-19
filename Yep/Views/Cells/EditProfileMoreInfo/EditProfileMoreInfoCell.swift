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

    var infoTextViewBeginEditingAction: ((_ infoTextView: UITextView) -> Void)?
    var infoTextViewIsDirtyAction: (() -> Void)?
    var infoTextViewDidEndEditingAction: ((String) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .none

        infoTextView.font = YepConfig.EditProfile.infoFont

        infoTextView.autocapitalizationType = .none
        infoTextView.autocorrectionType = .no
        infoTextView.spellCheckingType = .no

        infoTextView.textContainer.lineFragmentPadding = 0
        infoTextView.textContainerInset = UIEdgeInsets.zero

        infoTextView.delegate = self
    }
}

// MARK: - UITextViewDelegate

extension EditProfileMoreInfoCell: UITextViewDelegate {

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {

        infoTextViewBeginEditingAction?(textView)

        return true
    }

    func textViewDidChange(_ textView: UITextView) {

        infoTextViewIsDirtyAction?()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == infoTextView {
            let text = textView.text.trimming(.whitespaceAndNewline)
            textView.text = text
            infoTextViewDidEndEditingAction?(text)
        }
    }
}

