//
//  MessageToolbar.swift
//  Yep
//
//  Created by NIX on 15/3/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

enum MessageToolbarState {
    case Default
    case TextInput
}

@IBDesignable
class MessageToolbar: UIToolbar {

    var state: MessageToolbarState = .Default {
        willSet {
            switch newValue {
            case .Default:
                micButton.hidden = false
                sendButton.hidden = true

            case .TextInput:
                micButton.hidden = true
                sendButton.hidden = false
            }
        }
    }

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
        textField.delegate = self
        textField.addTarget(self, action: "editingChangedInTextField:", forControlEvents: UIControlEvents.EditingChanged)
        return textField
        }()

    lazy var micButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "item_mic"), forState: .Normal)
        button.tintColor = UIColor.yepTintColor()
        return button
        }()

    lazy var sendButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("Send", comment: ""), forState: .Normal)
        button.setTitleColor(UIColor.yepTintColor(), forState: .Normal)
        return button
        }()

    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        makeUI()

        state = .Default
    }

    func makeUI() {

        self.addSubview(cameraButton)
        cameraButton.setTranslatesAutoresizingMaskIntoConstraints(false)

        self.addSubview(messageTextField)
        messageTextField.setTranslatesAutoresizingMaskIntoConstraints(false)

        self.addSubview(micButton)
        micButton.setTranslatesAutoresizingMaskIntoConstraints(false)

        self.addSubview(sendButton)
        sendButton.setTranslatesAutoresizingMaskIntoConstraints(false)

        let viewsDictionary = [
            "cameraButton": cameraButton,
            "messageTextField": messageTextField,
            "micButton": micButton,
            "sendButton": sendButton,
        ]

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[cameraButton(==micButton)]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[cameraButton(48)][messageTextField][micButton(==cameraButton)]|", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(constraintsV)
        NSLayoutConstraint.activateConstraints(constraintsH)


        let sendButtonConstraintCenterY = NSLayoutConstraint(item: sendButton, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: cameraButton, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)

        let sendButtonConstraintHeight = NSLayoutConstraint(item: sendButton, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: cameraButton, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0)

        let sendButtonConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:[messageTextField][sendButton(==cameraButton)]|", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints([sendButtonConstraintCenterY])
        NSLayoutConstraint.activateConstraints([sendButtonConstraintHeight])
        NSLayoutConstraint.activateConstraints(sendButtonConstraintsH)
    }


    // Mark: TextField

    func editingChangedInTextField(textfiled: UITextField) {
        if textfiled.text.isEmpty {
            self.state = .Default
        } else {
            self.state = .TextInput
        }
    }
}

// MARK: UITextFieldDelegate

extension MessageToolbar: UITextFieldDelegate {

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        return true
    }
}

