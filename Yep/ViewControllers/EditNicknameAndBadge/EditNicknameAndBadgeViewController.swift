//
//  EditNicknameAndBadgeViewController.swift
//  Yep
//
//  Created by NIX on 15/7/2.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Ruler

class EditNicknameAndBadgeViewController: UITableViewController {

    @IBOutlet private weak var nicknameTextField: UITextField!

    @IBOutlet private weak var centerLeft1GapConstraint: NSLayoutConstraint!
    @IBOutlet private weak var centerRight1GapConstraint: NSLayoutConstraint!
    @IBOutlet private weak var left1Left2GapConstraint: NSLayoutConstraint!
    @IBOutlet private weak var right1Right2GapConstraint: NSLayoutConstraint!

    @IBOutlet private weak var promptPickBadgeLabel: UILabel!
    
    @IBOutlet private weak var badgeEnabledImageView: UIImageView!

    @IBOutlet private weak var paletteBadgeView: BadgeView!
    @IBOutlet private weak var planeBadgeView: BadgeView!
    @IBOutlet private weak var heartBadgeView: BadgeView!
    @IBOutlet private weak var starBadgeView: BadgeView!
    @IBOutlet private weak var bubbleBadgeView: BadgeView!

    @IBOutlet private weak var androidBadgeView: BadgeView!
    @IBOutlet private weak var appleBadgeView: BadgeView!
    @IBOutlet private weak var petBadgeView: BadgeView!
    @IBOutlet private weak var wineBadgeView: BadgeView!
    @IBOutlet private weak var musicBadgeView: BadgeView!

    @IBOutlet private weak var steveBadgeView: BadgeView!
    @IBOutlet private weak var cameraBadgeView: BadgeView!
    @IBOutlet private weak var gameBadgeView: BadgeView!
    @IBOutlet private weak var ballBadgeView: BadgeView!
    @IBOutlet private weak var techBadgeView: BadgeView!

    private var badgeViews = [BadgeView]()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Nickname", comment: "")

        nicknameTextField.text = YepUserDefaults.nickname.value
        nicknameTextField.delegate = self

        let gap: CGFloat = Ruler.iPhoneHorizontal(10, 25, 32).value

        centerLeft1GapConstraint.constant = gap
        centerRight1GapConstraint.constant = gap
        left1Left2GapConstraint.constant = gap
        right1Right2GapConstraint.constant = gap

        promptPickBadgeLabel.text = NSLocalizedString("Pick a badge", comment: "")
        
        paletteBadgeView.badge = .Palette
        planeBadgeView.badge = .Plane
        heartBadgeView.badge = .Heart
        starBadgeView.badge = .Star
        bubbleBadgeView.badge = .Bubble

        androidBadgeView.badge = .Android
        appleBadgeView.badge = .Apple
        petBadgeView.badge = .Pet
        wineBadgeView.badge = .Wine
        musicBadgeView.badge = .Music

        steveBadgeView.badge = .Steve
        cameraBadgeView.badge = .Camera
        gameBadgeView.badge = .Game
        ballBadgeView.badge = .Ball
        techBadgeView.badge = .Tech

        badgeViews = [
            paletteBadgeView,
            planeBadgeView,
            heartBadgeView,
            starBadgeView,
            bubbleBadgeView,

            androidBadgeView,
            appleBadgeView,
            petBadgeView,
            wineBadgeView,
            musicBadgeView,

            steveBadgeView,
            cameraBadgeView,
            gameBadgeView,
            ballBadgeView,
            techBadgeView,
        ]

        let disableAllBadges: () -> Void = { [weak self] in
            self?.badgeViews.forEach { $0.enabled = false }
        }

        badgeViews.forEach {

            $0.tapAction = { badgeView in

                disableAllBadges()

                badgeView.enabled = true

                // select animation

                if self.badgeEnabledImageView.hidden {
                    self.badgeEnabledImageViewAppearInCenter(badgeView.center)

                } else {
                    UIView.animateWithDuration(0.2, delay: 0.0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.0, options: UIViewAnimationOptions(rawValue: 0), animations: { _ in
                        self.badgeEnabledImageView.center = badgeView.center
                    }, completion: { finished in
                    })
                }

                // try save online & local

                let newBadgeName = badgeView.badge.rawValue

                updateMyselfWithInfo(["badge": newBadgeName], failureHandler: { [weak self] (reason, errorMessage) in
                    defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                    dispatch_async(dispatch_get_main_queue()) {
                        badgeView.enabled = false
                    }

                    YepAlert.alertSorry(message: NSLocalizedString("Set badge failed!", comment: ""), inViewController: self)

                }, completion: { success in
                    dispatch_async(dispatch_get_main_queue()) {
                        YepUserDefaults.badge.value = newBadgeName
                    }
                })
            }
        }
    }

    private func badgeEnabledImageViewAppearInCenter(center: CGPoint) {

        badgeEnabledImageView.center = center
        badgeEnabledImageView.alpha = 0
        badgeEnabledImageView.hidden = false

        badgeEnabledImageView.transform = CGAffineTransformMakeScale(0.0001, 0.0001)

        UIView.animateWithDuration(0.2, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.0, options: UIViewAnimationOptions(rawValue: 0), animations: { _ in
            self.badgeEnabledImageView.alpha = 1
            self.badgeEnabledImageView.transform = CGAffineTransformMakeScale(1.0, 1.0)

        }, completion: { finished in
            self.badgeEnabledImageView.transform = CGAffineTransformIdentity
        })
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if let badgeName = YepUserDefaults.badge.value {
            badgeViews.forEach { $0.enabled = ($0.badge.rawValue == badgeName) }
        }

        if let enabledBadgeView = badgeViews.filter({ $0.enabled }).first {
            badgeEnabledImageViewAppearInCenter(enabledBadgeView.center)
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        view.endEditing(true)
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidAppear(animated)

        guard let newNickname = nicknameTextField.text else {
            return
        }

        if newNickname != YepUserDefaults.nickname.value {

            updateMyselfWithInfo(["nickname": newNickname], failureHandler: nil, completion: { success in
                dispatch_async(dispatch_get_main_queue()) {
                    YepUserDefaults.nickname.value = newNickname
                }
            })
        }
    }
}

extension EditNicknameAndBadgeViewController: UITextFieldDelegate {

    func textFieldShouldReturn(textField: UITextField) -> Bool {

        if textField == nicknameTextField {

            textField.resignFirstResponder()

            guard let newNickname = textField.text else {
                return true
            }

            if newNickname.isEmpty {
                YepAlert.alertSorry(message: NSLocalizedString("You did not enter any nickname!", comment: ""), inViewController: self, withDismissAction: {
                    dispatch_async(dispatch_get_main_queue()) {
                        textField.text = YepUserDefaults.nickname.value
                    }
                })

            } else {
                if newNickname != YepUserDefaults.nickname.value {

                    updateMyselfWithInfo(["nickname": newNickname], failureHandler: { [weak self] reason, errorMessage in
                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                        YepAlert.alertSorry(message: NSLocalizedString("Update nickname failed!", comment: ""), inViewController: self)

                    }, completion: { success in
                        dispatch_async(dispatch_get_main_queue()) {
                            YepUserDefaults.nickname.value = newNickname
                        }
                    })
                }
            }
        }

        return true
    }
}