//
//  ChatRightBaseCell.swift
//  Yep
//
//  Created by NIX on 15/6/4.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

protocol MessageStateChanged {
    var dotImageView: UIImageView { get }
}

class ChatRightBaseCell: UICollectionViewCell {
    
    @IBOutlet weak var dotImageView: UIImageView!

    var messageSendState: MessageSendState = .NotSend {
        didSet {
            
        }
    }

    var message: Message!

    let sendingAnimationName = "RotationOnStateAnimation"

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "messageStateUpdated", name: MessageNotification.MessageStateChanged, object: nil)
    }

    func messageStateUpdated() {
        changeStateImage(message.sendState)
    }

    func changeStateImage(state: MessageSendState.RawValue) {
        switch state {
        case MessageSendState.NotSend.rawValue:
            dotImageView.hidden = false
            dotImageView.image = UIImage(named: "icon_dot_sending")
            rotationAnimationOnImageView()
        case MessageSendState.Successed.rawValue:
            dotImageView.hidden = false
            dotImageView.image = UIImage(named: "icon_dot_unread")
            removeSendingAnimation()
        case MessageSendState.Read.rawValue:
            removeSendingAnimation()
            dotImageView.hidden = true
        case MessageSendState.Failed.rawValue:
            removeSendingAnimation()
            dotImageView.hidden = true
        default:
            removeSendingAnimation()
            break
        }
    }

    func rotationAnimationOnImageView() {
        var animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0.0
        animation.toValue = 2*M_PI
        animation.duration = 3.0
        animation.repeatCount = MAXFLOAT
        dotImageView.layer.addAnimation(animation, forKey: sendingAnimationName)
    }

    func removeSendingAnimation() {
        dotImageView.layer.removeAnimationForKey(sendingAnimationName)
    }
}
