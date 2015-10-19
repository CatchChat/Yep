//
//  MessageToolbar.swift
//  Yep
//
//  Created by NIX on 15/3/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

enum MessageToolbarState: Int, CustomStringConvertible {

    case Default
    case BeginTextInput
    case TextInputing
    case VoiceRecord

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
        }
    }
}

@IBDesignable
class MessageToolbar: UIToolbar {

    var messageTextViewHeightConstraint: NSLayoutConstraint!

    let messageTextAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(15)]

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    struct Notification {
        static let updateDraft = "UpdateDraftOfConversation"
    }

    var conversation: Conversation? {
        willSet {
            if let _ = newValue {
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateDraft:", name: Notification.updateDraft, object: nil)
            }
        }
    }

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
                moreButton.setImage(UIImage(named: "item_more"), forState: .Normal)

                micButton.tintColor = UIColor.messageToolBarColor()
                moreButton.tintColor = UIColor.messageToolBarColor()

                hideVoiceButtonAnimation()

            case .BeginTextInput:
                moreButton.hidden = false
                sendButton.hidden = true
                //sendButton.setTitleColor(UIColor.messageToolBarHighlightColor(), forState: .Normal)
                moreButton.setImage(UIImage(named: "item_more"), forState: .Normal)

            case .TextInputing:
                moreButton.hidden = true
                sendButton.hidden = false
                //sendButton.setTitleColor(UIColor.yepTintColor(), forState: .Normal)

                messageTextView.hidden = false
                voiceRecordButton.hidden = true
                
                notifyTyping()

            case .VoiceRecord:
                moreButton.hidden = false
                sendButton.hidden = true
                
                messageTextView.hidden = true
                voiceRecordButton.hidden = false

                messageTextView.text = nil

                micButton.setImage(UIImage(named: "icon_keyboard"), forState: .Normal)
                moreButton.setImage(UIImage(named: "item_more"), forState: .Normal)

                micButton.tintColor = UIColor.messageToolBarColor()
                moreButton.tintColor = UIColor.messageToolBarColor()
                
                showVoiceButtonAnimation()
            }

            updateHeightOfMessageTextView()
        }

        didSet {
            switch state {
            case .BeginTextInput, .TextInputing:
                // 由用户手动触发键盘弹出，回复时要注意
                break
            default:
                messageTextView.resignFirstResponder()
            }
        }
    }

    var notifyTypingAction: (() -> Void)?

    var textSendAction: ((messageToolBar: MessageToolbar) -> Void)?

    var moreMessageTypesAction: (() -> Void)?

    var voiceRecordBeginAction: ((messageToolBar: MessageToolbar) -> Void)?
    
    var voiceRecordEndAction: ((messageToolBar: MessageToolbar) -> Void)?
    
    var voiceRecordCancelAction: ((messageToolBar: MessageToolbar) -> Void)?

    var voiceRecordingUpdateUIAction: ((topOffset: CGFloat) -> Void)?
    
    lazy var micButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "item_mic"), forState: .Normal)
        button.tintColor = UIColor.messageToolBarColor()
        button.tintAdjustmentMode = .Normal
        button.addTarget(self, action: "toggleRecordVoice", forControlEvents: UIControlEvents.TouchUpInside)
        return button
        }()

    let normalCornerRadius: CGFloat = 6

    lazy var messageTextView: UITextView = {
        let textView = UITextView()
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        textView.font = UIFont.systemFontOfSize(15)
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.yepMessageToolbarSubviewBorderColor().CGColor
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
        button.layer.borderColor = UIColor.yepMessageToolbarSubviewBorderColor().CGColor
        button.tintColor = UIColor.messageToolBarHighlightColor()

        button.touchesBegin = { [weak self] in
            self?.tryVoiceRecordBegin()
        }

        button.touchesEnded = { [weak self] needAbort in
            if needAbort {
                self?.tryVoiceRecordCancel()
            } else {
                self?.tryVoiceRecordEnd()
            }
        }

        button.touchesCancelled = { [weak self] in
            self?.tryVoiceRecordCancel()
        }

        button.checkAbort = { [weak self] topOffset in
            self?.voiceRecordingUpdateUIAction?(topOffset: topOffset)

            return topOffset > 40
        }

        return button
        }()

    lazy var moreButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "item_more"), forState: .Normal)
        button.tintColor = UIColor.messageToolBarColor()
        button.tintAdjustmentMode = .Normal
        button.addTarget(self, action: "moreMessageTypes", forControlEvents: UIControlEvents.TouchUpInside)
        return button
        }()

    lazy var sendButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("Send", comment: ""), forState: .Normal)
        button.tintColor = UIColor.messageToolBarHighlightColor()
        button.tintAdjustmentMode = .Normal
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
        messageTextView.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(micButton)
        micButton.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(voiceRecordButton)
        voiceRecordButton.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(moreButton)
        moreButton.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(sendButton)
        sendButton.translatesAutoresizingMaskIntoConstraints = false

        let viewsDictionary = [
            "moreButton": moreButton,
            "messageTextView": messageTextView,
            "micButton": micButton,
            "voiceRecordButton": voiceRecordButton,
            "sendButton": sendButton,
        ]

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[micButton(==moreButton)]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)

        let messageTextViewConstraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|-8-[messageTextView]-8-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)

        let textContainerInset = messageTextView.textContainerInset
        let constant = ceil(messageTextView.font!.lineHeight + textContainerInset.top + textContainerInset.bottom)
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
        let voiceRecordButtonConstraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|-8-[voiceRecordButton]-8-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)

        let voiceRecordButtonConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[micButton][voiceRecordButton][moreButton]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(voiceRecordButtonConstraintsV)
        NSLayoutConstraint.activateConstraints(voiceRecordButtonConstraintsH)
        
    }

    // MARK: Animations

    func showVoiceButtonAnimation() {
        
        let animation = CABasicAnimation(keyPath: "cornerRadius")

        animation.fromValue = normalCornerRadius
        let newCornerRadius: CGFloat = 17
        animation.toValue = newCornerRadius
        animation.timingFunction = CAMediaTimingFunction(name: "easeInEaseOut")
        animation.repeatCount = 0

        voiceRecordButton.layer.addAnimation(animation, forKey: "cornerRadius")
        
        voiceRecordButton.layer.cornerRadius = newCornerRadius
        messageTextView.layer.cornerRadius = newCornerRadius
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

    func updateDraft(notification: NSNotification) {

        if let conversation = conversation, realm = conversation.realm {

            if let draft = conversation.draft {

                let _ = try? realm.write { [weak self] in
                    if let strongSelf = self {
                        draft.messageToolbarState = strongSelf.state.rawValue

                        if strongSelf.state == .BeginTextInput || strongSelf.state == .TextInputing {
                            draft.text = strongSelf.messageTextView.text
                        }
                    }
                }

            } else {
                let draft = Draft()
                draft.messageToolbarState = state.rawValue
                
                let _ = try? realm.write {
                    conversation.draft = draft
                }
            }
        }
    }

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

    func moreMessageTypes() {
        moreMessageTypesAction?()
    }

    func tryVoiceRecordBegin() {

        voiceRecordButton.state = .Touched

        voiceRecordBeginAction?(messageToolBar: self)
    }
    
    func tryVoiceRecordEnd() {

        voiceRecordButton.state = .Default

        voiceRecordEndAction?(messageToolBar: self)
    }
    
    func tryVoiceRecordCancel() {

        voiceRecordButton.state = .Default

        voiceRecordCancelAction?(messageToolBar: self)
    }
    
    // Update status
    
    func notifyTyping() {

        notifyTypingAction?()
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

