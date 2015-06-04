//
//  MessageToolbar.swift
//  Yep
//
//  Created by NIX on 15/3/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

enum MessageToolbarState: Int, Printable {
    case Default
    case BeginTextInput
    case TextInputing
    case VoiceRecord
    case MoreMessages

    var description: String {
        switch self {
        case .Default:
            return "Default"
        case .BeginTextInput:
            return "BeginTextInput"
        case .TextInputing:
            return "TextInputing"
        case .VoiceRecord:
            return "VoiceRecord"
        case .MoreMessages:
            return "MoreMessages"
        }
    }
}

@IBDesignable
class MessageToolbar: UIToolbar {

    var messageTextViewHeightConstraint: NSLayoutConstraint!

    let messageTextAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(15)]

    var stateTransitionAction: ((messageToolbar: MessageToolbar, previousState: MessageToolbarState, currentState: MessageToolbarState) -> Void)?

    var previousState: MessageToolbarState = .Default
    var state: MessageToolbarState = .Default {
        willSet {

            previousState = state

            if let action = stateTransitionAction {
                action(messageToolbar: self, previousState: previousState, currentState: newValue)
            }

            switch newValue {
            case .Default:
                moreButton.hidden = false
                sendButton.hidden = true

                messageTextView.hidden = false
                voiceRecordButton.hidden = true
                micButton.setImage(UIImage(named: "item_mic"), forState: .Normal)

                micButton.tintColor = UIColor.messageToolBarHighlightColor()
                moreButton.tintColor = UIColor.messageToolBarHighlightColor()

                hideVoiceButtonAnimation()

            case .BeginTextInput:
                moreButton.hidden = false
                sendButton.hidden = true

            case .TextInputing:
                moreButton.hidden = true
                sendButton.hidden = false

                messageTextView.hidden = false
                voiceRecordButton.hidden = true
                
                notifyTyping()

            case .VoiceRecord:
                moreButton.hidden = false
                sendButton.hidden = true
                
                messageTextView.hidden = true
                voiceRecordButton.hidden = false

                micButton.setImage(UIImage(named: "icon_keyboard"), forState: .Normal)

                micButton.tintColor = UIColor.messageToolBarNormalColor()
                moreButton.tintColor = UIColor.messageToolBarNormalColor()
                
                showVoiceButtonAnimation()

            case .MoreMessages:
                break
            }

            updateHeightOfMessageTextView()
        }

        didSet {
            switch state {
            case .BeginTextInput, .TextInputing:
                break
            default:
                messageTextView.resignFirstResponder()
            }
        }
    }

    var notifyTypingAction: (() -> Void)?

    var textSendAction: ((messageToolBar: MessageToolbar) -> Void)?

    var toggleMoreMessagesAction: ((messageToolBar: MessageToolbar) -> Void)?

    var voiceSendBeginAction: ((messageToolBar: MessageToolbar) -> Void)?
    
    var voiceSendEndAction: ((messageToolBar: MessageToolbar) -> Void)?
    
    var voiceSendCancelAction: ((messageToolBar: MessageToolbar) -> Void)?
    
    lazy var micButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "item_mic"), forState: .Normal)
        button.tintColor = UIColor.messageToolBarHighlightColor()
        button.addTarget(self, action: "toggleRecordVoice", forControlEvents: UIControlEvents.TouchUpInside)
        return button
        }()

    let normalCornerRadius: CGFloat = 6

    lazy var messageTextView: UITextView = {
        let textView = UITextView()
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        textView.font = UIFont.systemFontOfSize(15)
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.messageToolBarHighlightColor().CGColor
        textView.layer.cornerRadius = self.normalCornerRadius
        textView.delegate = self
        textView.scrollEnabled = false // 重要：若没有它，换行时可能有 top inset 不正确
        return textView
        }()

    lazy var voiceRecordButton: VoiceRecordButton = {
        let button = VoiceRecordButton()

        button.backgroundColor = UIColor.whiteColor()
        button.layer.cornerRadius = self.normalCornerRadius
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.messageToolBarHighlightColor().CGColor
        button.tintColor = UIColor.messageToolBarHighlightColor()

        button.yepTouchBegin = {
            self.trySendVoiceMessageBegin()
        }

        button.yepTouchesMoved = {
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
        button.tintColor = UIColor.messageToolBarHighlightColor()
        button.addTarget(self, action: "toggleMoreMessages", forControlEvents: UIControlEvents.TouchUpInside)
        return button
        }()

    lazy var sendButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("Send", comment: ""), forState: .Normal)
        button.setTitleColor(UIColor.messageToolBarHighlightColor(), forState: .Normal)
        button.addTarget(self, action: "trySendTextMessage", forControlEvents: UIControlEvents.TouchUpInside)
        return button
        }()


    // MARK: UI
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        makeUI()

        state = .Default
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

    // MARK: Animations

    func showVoiceButtonAnimation() {
        let animation = CABasicAnimation(keyPath: "cornerRadius")

        animation.fromValue = voiceRecordButton.layer.cornerRadius
        let newCornerRadius = CGRectGetHeight(voiceRecordButton.bounds) * 0.5
        animation.toValue = newCornerRadius
        animation.timingFunction = CAMediaTimingFunction(name: "easeInEaseOut")
        animation.repeatCount = 0

        voiceRecordButton.layer.addAnimation(animation, forKey: "cornerRadius")
        
        voiceRecordButton.layer.cornerRadius = newCornerRadius
        messageTextView.layer.cornerRadius = CGRectGetHeight(messageTextView.bounds) * 0.5
    }

    func hideVoiceButtonAnimation() {
        let animation = CABasicAnimation(keyPath: "cornerRadius")

        animation.fromValue = messageTextView.layer.cornerRadius
        animation.toValue = normalCornerRadius
        animation.repeatCount = 0
        
        animation.timingFunction = CAMediaTimingFunction(name: "easeInEaseOut")

        messageTextView.layer.addAnimation(animation, forKey: "cornerRadius")

        messageTextView.layer.cornerRadius = normalCornerRadius
        voiceRecordButton.layer.cornerRadius = normalCornerRadius
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

    func toggleMoreMessages() {
        if state != .MoreMessages {
            state = .MoreMessages
        } else {
            state = .Default
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
            println("Cancel")
            voiceRecordButton.backgroundColor = UIColor.whiteColor()
            textSendAction(messageToolBar: self)
        }
    }
    
    // Update status
    
    func notifyTyping() {
        if let notifyTypingAction = notifyTypingAction {
            notifyTypingAction()
        }
    }
}

// MARK: UITextViewDelegate

extension MessageToolbar: UITextViewDelegate {

    func textViewDidBeginEditing(textView: UITextView) {
        if let text = textView.text {
            state = text.isEmpty ? .BeginTextInput : .TextInputing
        }
    }

    func textViewDidChange(textView: UITextView) {
        if let text = textView.text {
            state = text.isEmpty ? .BeginTextInput : .TextInputing
        }
    }
}

