//
//  EditNicknameAndBadgeViewController.swift
//  Yep
//
//  Created by NIX on 15/7/2.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepNetworking
import Ruler

final class EditNicknameAndBadgeViewController: UITableViewController {

    @IBOutlet fileprivate weak var nicknameTextField: UITextField!

    @IBOutlet fileprivate weak var centerLeft1GapConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var centerRight1GapConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var left1Left2GapConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var right1Right2GapConstraint: NSLayoutConstraint!

    @IBOutlet fileprivate weak var promptPickBadgeLabel: UILabel!
    
    @IBOutlet fileprivate weak var badgeEnabledImageView: UIImageView!

    @IBOutlet fileprivate weak var paletteBadgeView: BadgeView!
    @IBOutlet fileprivate weak var planeBadgeView: BadgeView!
    @IBOutlet fileprivate weak var heartBadgeView: BadgeView!
    @IBOutlet fileprivate weak var starBadgeView: BadgeView!
    @IBOutlet fileprivate weak var bubbleBadgeView: BadgeView!

    @IBOutlet fileprivate weak var androidBadgeView: BadgeView!
    @IBOutlet fileprivate weak var appleBadgeView: BadgeView!
    @IBOutlet fileprivate weak var petBadgeView: BadgeView!
    @IBOutlet fileprivate weak var wineBadgeView: BadgeView!
    @IBOutlet fileprivate weak var musicBadgeView: BadgeView!

    @IBOutlet fileprivate weak var steveBadgeView: BadgeView!
    @IBOutlet fileprivate weak var cameraBadgeView: BadgeView!
    @IBOutlet fileprivate weak var gameBadgeView: BadgeView!
    @IBOutlet fileprivate weak var ballBadgeView: BadgeView!
    @IBOutlet fileprivate weak var techBadgeView: BadgeView!

    fileprivate var badgeViews = [BadgeView]()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = String.trans_titleNickname

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

                if self.badgeEnabledImageView.isHidden {
                    self.badgeEnabledImageViewAppearInCenter(badgeView.center)

                } else {
                    UIView.animate(withDuration: 0.2, delay: 0.0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.0, options: UIViewAnimationOptions(rawValue: 0), animations: { [weak self] in
                        self?.badgeEnabledImageView.center = badgeView.center
                    }, completion: nil)
                }

                // try save online & local

                let newBadgeName = badgeView.badge.rawValue

                updateMyselfWithInfo(["badge": newBadgeName], failureHandler: { [weak self] (reason, errorMessage) in
                    defaultFailureHandler(reason, errorMessage)

                    SafeDispatch.async {
                        badgeView.enabled = false
                    }

                    YepAlert.alertSorry(message: NSLocalizedString("Set badge failed!", comment: ""), inViewController: self)

                }, completion: { success in
                    SafeDispatch.async {
                        YepUserDefaults.badge.value = newBadgeName
                    }
                })
            }
        }
    }

    fileprivate func badgeEnabledImageViewAppearInCenter(_ center: CGPoint) {

        badgeEnabledImageView.center = center
        badgeEnabledImageView.alpha = 0
        badgeEnabledImageView.isHidden = false

        badgeEnabledImageView.transform = CGAffineTransform(scaleX: 0.0001, y: 0.0001)

        UIView.animate(withDuration: 0.2, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.0, options: UIViewAnimationOptions(rawValue: 0), animations: { [weak self] in
            self?.badgeEnabledImageView.alpha = 1
            self?.badgeEnabledImageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)

        }, completion: { [weak self] _ in
            self?.badgeEnabledImageView.transform = CGAffineTransform.identity
        })
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let badgeName = YepUserDefaults.badge.value {
            badgeViews.forEach { $0.enabled = ($0.badge.rawValue == badgeName) }
        }

        if let enabledBadgeView = badgeViews.filter({ $0.enabled }).first {
            badgeEnabledImageViewAppearInCenter(enabledBadgeView.center)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        view.endEditing(true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard let newNickname = nicknameTextField.text else {
            return
        }

        if newNickname != YepUserDefaults.nickname.value {

            updateMyselfWithInfo(["nickname": newNickname], failureHandler: nil, completion: { success in
                SafeDispatch.async {
                    YepUserDefaults.nickname.value = newNickname
                }
            })
        }
    }
}

extension EditNicknameAndBadgeViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        if textField == nicknameTextField {

            textField.resignFirstResponder()

            guard let newNickname = textField.text else {
                return true
            }

            if newNickname.isEmpty {
                YepAlert.alertSorry(message: NSLocalizedString("You did not enter any nickname!", comment: ""), inViewController: self, withDismissAction: {
                    SafeDispatch.async {
                        textField.text = YepUserDefaults.nickname.value
                    }
                })

            } else {
                if newNickname != YepUserDefaults.nickname.value {

                    updateMyselfWithInfo(["nickname": newNickname], failureHandler: { [weak self] reason, errorMessage in
                        defaultFailureHandler(reason, errorMessage)

                        YepAlert.alertSorry(message: NSLocalizedString("Update nickname failed!", comment: ""), inViewController: self)

                    }, completion: { success in
                        SafeDispatch.async {
                            YepUserDefaults.nickname.value = newNickname
                        }
                    })
                }
            }
        }

        return true
    }
}
