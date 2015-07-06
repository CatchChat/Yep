//
//  EditProfileMoreInfoCell.swift
//  Yep
//
//  Created by NIX on 15/4/27.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class EditProfileMoreInfoCell: UITableViewCell {

    @IBOutlet weak var annotationLabel: UILabel!

    @IBOutlet weak var infoTextView: UITextView!

    var infoTextViewDidEndEditingAction: (String -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .None

        infoTextView.font = YepConfig.EditProfile.introFont
        infoTextView.textContainer.lineFragmentPadding = 0
        infoTextView.textContainerInset = UIEdgeInsetsZero
        infoTextView.delegate = self
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

extension EditProfileMoreInfoCell: UITextViewDelegate {

    func textViewDidEndEditing(textView: UITextView) {
        if textView == infoTextView {
            let text = textView.text
            infoTextViewDidEndEditingAction?(text)
        }
    }
}