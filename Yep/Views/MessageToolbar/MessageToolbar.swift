//
//  MessageToolbar.swift
//  Yep
//
//  Created by NIX on 15/3/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

@IBDesignable
class MessageToolbar: UIToolbar {

    lazy var cameraButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "item_camera"), forState: .Normal)
        button.tintColor = UIColor.yepTintColor()
        return button
        }()

    lazy var messageTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .RoundedRect
        textField.returnKeyType = .Send
        return textField
        }()

    lazy var micButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "item_mic"), forState: .Normal)
        button.tintColor = UIColor.yepTintColor()
        return button
        }()

    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        makeUI()
    }

    func makeUI() {

        self.addSubview(cameraButton)
        cameraButton.setTranslatesAutoresizingMaskIntoConstraints(false)

        self.addSubview(messageTextField)
        messageTextField.setTranslatesAutoresizingMaskIntoConstraints(false)

        self.addSubview(micButton)
        micButton.setTranslatesAutoresizingMaskIntoConstraints(false)

        let viewsDictionary = [
            "cameraButton": cameraButton,
            "messageTextField": messageTextField,
            "micButton": micButton
        ]

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[cameraButton(==micButton)]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[cameraButton(48)][messageTextField][micButton(==cameraButton)]|", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(constraintsV)
        NSLayoutConstraint.activateConstraints(constraintsH)
    }

}
