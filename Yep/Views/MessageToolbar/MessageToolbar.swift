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
    case VoiceRecord
}

@IBDesignable
class MessageToolbar: UIToolbar {

    var messageTextViewHeightConstraint: NSLayoutConstraint!

    let messageTextAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(15)]

    var state: MessageToolbarState = .Default {
        willSet {
            switch newValue {
            case .Default:
                moreButton.hidden = false
                sendButton.hidden = true

                messageTextView.hidden = false
                voiceRecordButton.hidden = true
                micButton.setImage(UIImage(named: "item_mic"), forState: .Normal)
                hideVoiceButtonAnimation()

            case .TextInput:
                moreButton.hidden = true
                sendButton.hidden = false

                messageTextView.hidden = false
                voiceRecordButton.hidden = true

            case .VoiceRecord:
                messageTextView.hidden = true
                voiceRecordButton.hidden = false
                messageTextView.endEditing(true)
                micButton.setImage(UIImage(named: "icon_keyboard"), forState: .Normal)
                showVoiceButtonAnimation()
                
            }

            updateHeightOfMessageTextView()
        }
    }

    var textSendAction: ((messageToolBar: MessageToolbar) -> ())?

    var imageSendAction: ((messageToolBar: MessageToolbar) -> ())?
    
    var voiceSendBeginAction: ((messageToolBar: MessageToolbar) -> ())?
    
    var voiceSendEndAction: ((messageToolBar: MessageToolbar) -> ())?
    
    var voiceSendCancelAction: ((messageToolBar: MessageToolbar) -> ())?


    lazy var micButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "item_mic"), forState: .Normal)
        button.tintColor = UIColor.lightGrayColor()
        button.addTarget(self, action: "toggleRecordVoice", forControlEvents: UIControlEvents.TouchUpInside)
        return button
        }()

    lazy var messageTextView: UITextView = {
        let textView = UITextView()
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        textView.font = UIFont.systemFontOfSize(15)
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.lightGrayColor().CGColor
        textView.layer.cornerRadius = 6
        textView.delegate = self
        textView.scrollEnabled = false // 重要：若没有它，换行时可能有 top inset 不正确
        return textView
        }()

    lazy var voiceRecordButton: YepButton = {
        let button = YepButton()

        button.setTitle("Hold For Voice", forState: UIControlState.Normal)
        button.backgroundColor = UIColor.whiteColor()
        button.layer.cornerRadius = 6
        button.titleLabel?.font = UIFont.systemFontOfSize(15.0)
        button.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.lightGrayColor().CGColor
        button.tintColor = UIColor.lightGrayColor()
        button.yepTouchBegin = {
            self.trySendVoiceMessageBegin()
        }
        button.yepTouchesEnded = {
            self.trySendVoiceMessageEnd()
        }
        button.yepTouchesCancelled = {
            self.trySendVoiceMessageCancel()
        }
        return button
        }()

    lazy var moreButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "item_more"), forState: .Normal)
        button.tintColor = UIColor.lightGrayColor()
        button.addTarget(self, action: "trySendImageMessage", forControlEvents: UIControlEvents.TouchUpInside)
        return button
        }()

    lazy var sendButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("Send", comment: ""), forState: .Normal)
        button.setTitleColor(UIColor.yepTintColor(), forState: .Normal)
        button.addTarget(self, action: "trySendTextMessage", forControlEvents: UIControlEvents.TouchUpInside)
        return button
        }()

    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        makeUI()

        state = .Default
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setUpVoiceButtonUI()
    }

    func makeUI() {

        self.addSubview(messageTextView)
        messageTextView.setTranslatesAutoresizingMaskIntoConstraints(false)

        self.addSubview(micButton)
        micButton.setTranslatesAutoresizingMaskIntoConstraints(false)

        self.addSubview(voiceRecordButton)
        voiceRecordButton.setTranslatesAutoresizingMaskIntoConstraints(false)

        self.addSubview(moreButton)
        moreButton.setTranslatesAutoresizingMaskIntoConstraints(false)

        self.addSubview(sendButton)
        sendButton.setTranslatesAutoresizingMaskIntoConstraints(false)

        let viewsDictionary = [
            "moreButton": moreButton,
            "messageTextView": messageTextView,
            "micButton": micButton,
            "voiceRecordButton": voiceRecordButton,
            "sendButton": sendButton,
        ]

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[micButton(==moreButton)]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        let messageTextViewConstraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|-8-[messageTextView]-8-|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        let textContainerInset = messageTextView.textContainerInset
        let constant = ceil(messageTextView.font.lineHeight + textContainerInset.top + textContainerInset.bottom)
        messageTextViewHeightConstraint = NSLayoutConstraint(item: messageTextView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: constant)

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[micButton(48)][messageTextView][moreButton(==micButton)]|", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(constraintsV)
        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints(messageTextViewConstraintsV)
        NSLayoutConstraint.activateConstraints([messageTextViewHeightConstraint])


        let sendButtonConstraintCenterY = NSLayoutConstraint(item: sendButton, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: micButton, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)

        let sendButtonConstraintHeight = NSLayoutConstraint(item: sendButton, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: micButton, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0)

        let sendButtonConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:[messageTextView][sendButton(==moreButton)]|", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints([sendButtonConstraintCenterY])
        NSLayoutConstraint.activateConstraints([sendButtonConstraintHeight])
        NSLayoutConstraint.activateConstraints(sendButtonConstraintsH)

        // void record button
        let voiceRecordButtonConstraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|-8-[voiceRecordButton]-8-|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        let voiceRecordButtonConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[micButton][voiceRecordButton][moreButton]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(voiceRecordButtonConstraintsV)
        NSLayoutConstraint.activateConstraints(voiceRecordButtonConstraintsH)
        
    }
    
    func setUpVoiceButtonUI() {
        
        var voiceButtonHeight = voiceRecordButton.frame.size.height
        var voiceButtonWidth = voiceRecordButton.frame.size.width
        
        var leftVoiceImageView = UIImageView(frame: CGRectMake(10.0, voiceButtonHeight/2.0 - 10.0 , 20.0, 20.0))
        leftVoiceImageView.contentMode = UIViewContentMode.ScaleAspectFit
        leftVoiceImageView.image = UIImage(named: "icon_voice_left")
        
        var rightVoiceImageView = UIImageView(frame: CGRectMake(voiceButtonWidth - 30.0,voiceButtonHeight/2.0 - 10.0, 20.0, 20.0))
        rightVoiceImageView.contentMode = UIViewContentMode.ScaleAspectFit
        rightVoiceImageView.image = UIImage(named: "icon_voice_right")
        
//        rightVoiceImageView.alpha = 0
//        leftVoiceImageView.alpha = 0
        
        voiceRecordButton.addSubview(leftVoiceImageView)
        voiceRecordButton.addSubview(rightVoiceImageView)
    }
    
    func showVoiceButtonAnimation() {
        let animation = CABasicAnimation(keyPath: "cornerRadius")
        
        // Set the starting value
        animation.fromValue = self.voiceRecordButton.layer.cornerRadius
        
        // Set the completion value
        animation.toValue = self.voiceRecordButton.frame.size.height*0.5
        
        animation.timingFunction = CAMediaTimingFunction(name: "easeInEaseOut")
        
        // How may times should the animation repeat?
        animation.repeatCount = 0
        
        // Finally, add the animation to the layer
        self.voiceRecordButton.layer.addAnimation(animation, forKey: "cornerRadius")
        
        self.voiceRecordButton.layer.cornerRadius = self.voiceRecordButton.frame.size.height*0.5
        
        self.messageTextView.layer.cornerRadius = self.messageTextView.frame.size.height*0.5
    }

    func hideVoiceButtonAnimation() {
        
        self.voiceRecordButton.layer.cornerRadius = 6
        
        let animation = CABasicAnimation(keyPath: "cornerRadius")
        
        // Set the starting value
        animation.fromValue = self.messageTextView.layer.cornerRadius
        
        // Set the completion value
        animation.toValue = 6
        
        // How may times should the animation repeat?
        animation.repeatCount = 0
        
        animation.timingFunction = CAMediaTimingFunction(name: "easeInEaseOut")
        
        // Finally, add the animation to the layer
        self.messageTextView.layer.addAnimation(animation, forKey: "cornerRadius")
        self.messageTextView.layer.cornerRadius = 6
        self.voiceRecordButton.layer.cornerRadius = 6

    }

    // Mark: Helpers

    func updateHeightOfMessageTextView() {

        let size = messageTextView.sizeThatFits(CGSize(width: CGRectGetWidth(messageTextView.bounds), height: CGFloat(FLT_MAX)))

        let newHeight = size.height

        //println("oldHeight: \(messageTextViewHeightConstraint.constant), newHeight: \(newHeight)")

        if newHeight != messageTextViewHeightConstraint.constant {
            UIView.animateWithDuration(0.1, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                self.messageTextViewHeightConstraint.constant = newHeight
                self.layoutIfNeeded()
            }, completion: { (finished) -> Void in
            })
        }
    }

    // MARK: Actions

    func trySendTextMessage() {
        if let textSendAction = textSendAction {
            textSendAction(messageToolBar: self)
        }
    }

    func toggleRecordVoice() {
        if state == .VoiceRecord {
            state = .Default
        } else {
            state = .VoiceRecord
        }
    }

    func trySendImageMessage() {
        if let imageSendAction = imageSendAction {
            imageSendAction(messageToolBar: self)
        }
    }
    
    func trySendVoiceMessageBegin() {
        if let textSendAction = voiceSendBeginAction {
            voiceRecordButton.backgroundColor = UIColor.lightGrayColor()
            textSendAction(messageToolBar: self)
        }
    }
    
    func trySendVoiceMessageEnd() {
        if let textSendAction = voiceSendEndAction {
            voiceRecordButton.backgroundColor = UIColor.whiteColor()
            textSendAction(messageToolBar: self)
        }
    }
    
    func trySendVoiceMessageCancel() {
        if let textSendAction = voiceSendCancelAction {
            voiceRecordButton.backgroundColor = UIColor.whiteColor()
            textSendAction(messageToolBar: self)
        }
    }
}

// MARK: UITextViewDelegate

extension MessageToolbar: UITextViewDelegate {

    func textViewDidChange(textView: UITextView) {
        let text = textView.text

        if text.isEmpty {
            self.state = .Default
        } else {
            self.state = .TextInput
        }
    }
}

