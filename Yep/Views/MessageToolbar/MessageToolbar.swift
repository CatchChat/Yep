//
//  MessageToolbar.swift
//  Yep
//
//  Created by NIX on 15/3/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Ruler
import YepKit

final class MessageToolbar: UIToolbar {
    
    var lastToolbarFrame: CGRect?

    var messageTextViewHeightConstraint: NSLayoutConstraint!

    let messageTextAttributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 15)]

    deinit {
        NotificationCenter.default.removeObserver(self)
        finishNotifyTypingTimer?.invalidate()
    }

    var conversation: Conversation? {
        willSet {
            if let _ = newValue {
                NotificationCenter.default.addObserver(self, selector: #selector(MessageToolbar.updateDraft(_:)), name: YepConfig.NotificationName.updateDraftOfConversation, object: nil)
            }
        }
    }

    var stateTransitionAction: ((_ messageToolbar: MessageToolbar, _ previousState: MessageToolbarState, _ currentState: MessageToolbarState) -> Void)?

    var previousState: MessageToolbarState = .default
    var state: MessageToolbarState = .default {
        willSet {
            updateHeightOfMessageTextView()

            previousState = state

            if let action = stateTransitionAction {
                action(self, previousState, newValue)
            }

            switch newValue {
            case .default:
                moreButton.isHidden = false
                sendButton.isHidden = true

                messageTextView.isHidden = false
                voiceRecordButton.isHidden = true

                micButton.setImage(UIImage.yep_itemMic, for: .normal)
                moreButton.setImage(UIImage.yep_itemMore, for: .normal)

                micButton.tintColor = UIColor.messageToolBarColor()
                moreButton.tintColor = UIColor.messageToolBarColor()

                hideVoiceButtonAnimation()

            case .beginTextInput:
                moreButton.isHidden = false
                sendButton.isHidden = true

                moreButton.setImage(UIImage.yep_itemMore, for: .normal)

            case .textInputing:
                moreButton.isHidden = true
                sendButton.isHidden = false

                messageTextView.isHidden = false
                voiceRecordButton.isHidden = true
                
                notifyTyping()

            case .voiceRecord:
                moreButton.isHidden = false
                sendButton.isHidden = true
                
                messageTextView.isHidden = true
                voiceRecordButton.isHidden = false

                messageTextView.text = ""

                micButton.setImage(UIImage.yep_iconKeyboard, for: .normal)
                moreButton.setImage(UIImage.yep_itemMore, for: .normal)

                micButton.tintColor = UIColor.messageToolBarColor()
                moreButton.tintColor = UIColor.messageToolBarColor()

                showVoiceButtonAnimation()
            }
        }

        didSet {
            switch state {
            case .beginTextInput, .textInputing:
                // 由用户手动触发键盘弹出，回复时要注意
                break
            default:
                messageTextView.resignFirstResponder()
            }
        }
    }

    var notifyTypingAction: (() -> Void)?

    var needDetectMention = false
    var initMentionUserAction: (() -> Void)?
    var tryMentionUserAction: ((_ usernamePrefix: String) -> Void)?
    var giveUpMentionUserAction: (() -> Void)?

    var textSendAction: ((_ messageToolBar: MessageToolbar) -> Void)?

    var moreMessageTypesAction: (() -> Void)?

    var voiceRecordBeginAction: ((_ messageToolBar: MessageToolbar) -> Void)?
    var voiceRecordEndAction: ((_ messageToolBar: MessageToolbar) -> Void)?
    var voiceRecordCancelAction: ((_ messageToolBar: MessageToolbar) -> Void)?

    var voiceRecordingUpdateUIAction: ((_ topOffset: CGFloat) -> Void)?
    
    lazy var micButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.yep_itemMic, for: .normal)
        button.tintColor = UIColor.messageToolBarColor()
        button.tintAdjustmentMode = .normal
        button.addTarget(self, action: #selector(MessageToolbar.toggleRecordVoice), for: UIControlEvents.touchUpInside)
        return button
    }()

    let normalCornerRadius: CGFloat = 6

    lazy var messageTextView: UITextView = {
        let textView = UITextView()
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        textView.font = UIFont.systemFont(ofSize: 15)
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.yepMessageToolbarSubviewBorderColor().cgColor
        textView.layer.cornerRadius = self.normalCornerRadius
        textView.delegate = self
        textView.isScrollEnabled = false // 重要：若没有它，换行时可能有 top inset 不正确
        return textView
    }()

    lazy var voiceRecordButton: VoiceRecordButton = {
        let button = VoiceRecordButton()

        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = self.normalCornerRadius
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.yepMessageToolbarSubviewBorderColor().cgColor
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
            self?.voiceRecordingUpdateUIAction?(topOffset)

            return topOffset > 40
        }

        return button
    }()

    lazy var moreButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.yep_itemMore, for: .normal)
        button.tintColor = UIColor.messageToolBarColor()
        button.tintAdjustmentMode = .normal
        button.addTarget(self, action: #selector(MessageToolbar.moreMessageTypes), for: UIControlEvents.touchUpInside)
        return button
    }()

    lazy var sendButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("Send", comment: ""), for: .normal)
        button.tintColor = UIColor.messageToolBarHighlightColor()
        button.tintAdjustmentMode = .normal
        button.setTitleColor(UIColor.messageToolBarHighlightColor(), for: .normal)
        button.addTarget(self, action: #selector(MessageToolbar.trySendTextMessage), for: UIControlEvents.touchUpInside)
        return button
    }()

    fileprivate var searchTask: CancelableTask?

    // MARK: UI
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        makeUI()

        state = .default
    }

    var messageTextViewMinHeight: CGFloat {
        let textContainerInset = messageTextView.textContainerInset
        return ceil(messageTextView.font!.lineHeight + textContainerInset.top + textContainerInset.bottom)
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

        let views: [String: Any] = [
            "moreButton": moreButton,
            "messageTextView": messageTextView,
            "micButton": micButton,
            "voiceRecordButton": voiceRecordButton,
            "sendButton": sendButton,
        ]

        let buttonBottom: CGFloat = 8
        let constraintsV1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=0)-[micButton]-(bottom)-|", options: [], metrics: ["bottom": buttonBottom], views: views)
        let constraintsV2 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=0)-[moreButton(==micButton)]-(bottom)-|", options: [], metrics: ["bottom": buttonBottom], views: views)
        let constraintsV3 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=0)-[sendButton(==micButton)]-(bottom)-|", options: [], metrics: ["bottom": buttonBottom], views: views)

        let messageTextViewConstraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|-7-[messageTextView]-8-|", options: [], metrics: nil, views: views)

        println("messageTextViewMinHeight: \(messageTextViewMinHeight)")
        messageTextViewHeightConstraint = NSLayoutConstraint(item: messageTextView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: messageTextViewMinHeight)
        messageTextViewHeightConstraint.priority = UILayoutPriorityDefaultHigh

        let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[micButton(48)][messageTextView][moreButton(==micButton)]|", options: [], metrics: nil, views: views)

        NSLayoutConstraint.activate(constraintsV1)
        NSLayoutConstraint.activate(constraintsV2)
        NSLayoutConstraint.activate(constraintsV3)
        NSLayoutConstraint.activate(constraintsH)
        NSLayoutConstraint.activate(messageTextViewConstraintsV)
        NSLayoutConstraint.activate([messageTextViewHeightConstraint])

        let sendButtonConstraintCenterY = NSLayoutConstraint(item: sendButton, attribute: .centerY, relatedBy: .equal, toItem: micButton, attribute: .centerY, multiplier: 1, constant: 0)

        let sendButtonConstraintHeight = NSLayoutConstraint(item: sendButton, attribute: .height, relatedBy: .equal, toItem: micButton, attribute: .height, multiplier: 1, constant: 0)

        let sendButtonConstraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:[messageTextView][sendButton(==moreButton)]|", options: [], metrics: nil, views: views)

        NSLayoutConstraint.activate([sendButtonConstraintCenterY])
        NSLayoutConstraint.activate([sendButtonConstraintHeight])
        NSLayoutConstraint.activate(sendButtonConstraintsH)

        // void record button
        let voiceRecordButtonConstraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|-7-[voiceRecordButton]-8-|", options: [], metrics: nil, views: views)

        let voiceRecordButtonConstraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[micButton][voiceRecordButton][moreButton]|", options: [], metrics: nil, views: views)

        let voiceRecordButtonHeightConstraint = NSLayoutConstraint(item: voiceRecordButton, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: messageTextViewMinHeight)
        voiceRecordButtonHeightConstraint.priority = UILayoutPriorityDefaultHigh

        NSLayoutConstraint.activate(voiceRecordButtonConstraintsV)
        NSLayoutConstraint.activate(voiceRecordButtonConstraintsH)
        NSLayoutConstraint.activate([voiceRecordButtonHeightConstraint])
    }

    // MARK: Animations

    func showVoiceButtonAnimation() {
        
        let animation = CABasicAnimation(keyPath: "cornerRadius")

        animation.fromValue = normalCornerRadius
        let newCornerRadius: CGFloat = 17
        animation.toValue = newCornerRadius
        animation.timingFunction = CAMediaTimingFunction(name: "easeInEaseOut")
        animation.repeatCount = 0

        voiceRecordButton.layer.add(animation, forKey: "cornerRadius")
        
        voiceRecordButton.layer.cornerRadius = newCornerRadius
        messageTextView.layer.cornerRadius = newCornerRadius

        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
            if let strongSelf = self {
                strongSelf.messageTextViewHeightConstraint.constant = strongSelf.messageTextViewMinHeight
                strongSelf.layoutIfNeeded()
            }
        }, completion: { _ in })
    }

    func hideVoiceButtonAnimation() {

        let animation = CABasicAnimation(keyPath: "cornerRadius")

        animation.fromValue = messageTextView.layer.cornerRadius
        animation.toValue = normalCornerRadius
        animation.repeatCount = 0
        
        animation.timingFunction = CAMediaTimingFunction(name: "easeInEaseOut")

        messageTextView.layer.add(animation, forKey: "cornerRadius")

        messageTextView.layer.cornerRadius = normalCornerRadius
        voiceRecordButton.layer.cornerRadius = normalCornerRadius
    }

    // Mark: Helpers

    func updateHeightOfMessageTextView() {

        let size = messageTextView.sizeThatFits(CGSize(width: messageTextView.bounds.width, height: CGFloat(FLT_MAX)))

        let newHeight = size.height
        let limitedNewHeight = min(Ruler.iPhoneVertical(60, 80, 100, 100).value, newHeight)

        //println("oldHeight: \(messageTextViewHeightConstraint.constant), newHeight: \(newHeight)")

        if newHeight != messageTextViewHeightConstraint.constant {

            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
                self?.messageTextViewHeightConstraint.constant = limitedNewHeight
                self?.layoutIfNeeded()

            }, completion: { [weak self] finished in
                // hack for scrollEnabled when input lots of text
                if finished, let strongSelf = self {
                    let enabled = newHeight > strongSelf.messageTextView.bounds.height
                    strongSelf.messageTextView.isScrollEnabled = enabled
                }
            })
        }
    }

    // MARK: Actions

    func updateDraft(_ notification: Foundation.Notification) {

        guard let conversation = conversation, !conversation.isInvalidated, let realm = conversation.realm else {
            return
        }

        if let draft = conversation.draft {

            let _ = try? realm.write { [weak self] in
                if let strongSelf = self {
                    draft.messageToolbarState = strongSelf.state.rawValue

                    //println("strongSelf.messageTextView.text: \(strongSelf.messageTextView.text)")
                    draft.text = strongSelf.messageTextView.text
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

    func trySendTextMessage() {

        if let textSendAction = textSendAction {
            textSendAction(self)
        }
    }

    func toggleRecordVoice() {

        if state == .voiceRecord {
            state = .default

        } else {
            state = .voiceRecord
        }
    }

    func moreMessageTypes() {
        moreMessageTypesAction?()
    }

    fileprivate var mentionUsernameRange: Range<String.Index>?

    func replaceMentionedUsername(_ username: String) {

        defer {
            mentionUsernameRange = nil
        }

        guard !username.isEmpty else {
            return
        }

        guard var text = messageTextView.text else {
            return
        }

        let mentionUsernameWithSpaceSuffix = "@" + username + " "

        if let range = mentionUsernameRange {
            text.replaceSubrange(range, with: mentionUsernameWithSpaceSuffix)

            messageTextView.text = text

            updateHeightOfMessageTextView()
        }
    }

    func tryVoiceRecordBegin() {

        voiceRecordButton.state = .touched

        voiceRecordBeginAction?(self)
    }
    
    func tryVoiceRecordEnd() {

        voiceRecordButton.state = .default

        voiceRecordEndAction?(self)
    }
    
    func tryVoiceRecordCancel() {

        voiceRecordButton.state = .default

        voiceRecordCancelAction?(self)
    }
    
    // Notify typing

    fileprivate var finishNotifyTypingTimer: Timer?
    fileprivate var inNotifyTyping: Bool = false
    
    fileprivate func notifyTyping() {

        if inNotifyTyping {
            //println("inNotifyTyping")
            return

        } else {
            inNotifyTyping = true

            //println("notifyTypingAction")
            notifyTypingAction?()

            finishNotifyTypingTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(MessageToolbar.finishNotifyTyping(_:)), userInfo: nil, repeats: false)
        }
    }

    @objc fileprivate func finishNotifyTyping(_ sender: Timer) {
        inNotifyTyping = false
    }
}

// MARK: UITextViewDelegate

extension MessageToolbar: UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {

        guard let text = textView.text else { return }

        state = text.isEmpty ? .beginTextInput : .textInputing
    }

    func textViewDidChange(_ textView: UITextView) {

        guard let text = textView.text else { return }

        state = text.isEmpty ? .beginTextInput : .textInputing

        if needDetectMention {

            cancel(searchTask)

            // 刚刚输入 @

            if text.hasSuffix("@") {
                mentionUsernameRange = text.characters.index(text.endIndex, offsetBy: -1)..<text.endIndex
                initMentionUserAction?()
                return
            }

            searchTask = delay(0.4) { [weak self] in

                // 对于拼音输入法等，输入时会先显示拼音，然后才上字，拼音间有空格（这个空格似乎不是普通空格）

                if let markedTextRange = textView.markedTextRange, let markedText = textView.text(in: markedTextRange) {

                    var text = text

                    let beginning = textView.beginningOfDocument
                    let start = markedTextRange.start
                    let end = markedTextRange.end
                    let location = textView.offset(from: beginning, to: start)

                    // 保证前面至少还有一个字符，for mentionNSRange
                    guard location > 0 else {
                        return
                    }

                    let length = textView.offset(from: start, to: end)
                    let nsRange = NSMakeRange(location, length)
                    let mentionNSRange = NSMakeRange(location - 1, length + 1)
                    guard let range = text.yep_rangeFromNSRange(nsRange), let mentionRange = text.yep_rangeFromNSRange(mentionNSRange) else {
                        return
                    }

                    text.removeSubrange(range)

                    if text.hasSuffix("@") {
                        self?.mentionUsernameRange = mentionRange

                        let wordString = markedText.yep_removeAllWhitespaces
                        //println("wordString from markedText: >\(wordString)<")
                        self?.tryMentionUserAction?(wordString)

                        return
                    }
                }

                // 正常查询 mention

                let currentLetterIndex = textView.selectedRange.location - 1

                if let (wordString, mentionWordRange) = text.yep_mentionWordInIndex(currentLetterIndex) {
                    //println("mentionWord: \(wordString), \(mentionWordRange)")

                    self?.mentionUsernameRange = mentionWordRange

                    let wordString = wordString.trimming(.whitespace)
                    self?.tryMentionUserAction?(wordString)

                    return
                }

                // 都没有就放弃

                self?.giveUpMentionUserAction?()
            }
        }
    }
}

