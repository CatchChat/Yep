//
//  EditNicknameAndBadgeViewController.swift
//  Yep
//
//  Created by NIX on 15/7/2.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class EditNicknameAndBadgeViewController: UITableViewController {

    @IBOutlet weak var nicknameTextField: UITextField!

    @IBOutlet weak var centerLeft1GapConstraint: NSLayoutConstraint!
    @IBOutlet weak var centerRight1GapConstraint: NSLayoutConstraint!
    @IBOutlet weak var left1Left2GapConstraint: NSLayoutConstraint!
    @IBOutlet weak var right1Right2GapConstraint: NSLayoutConstraint!

    @IBOutlet weak var paletteBadgeView: BadgeView!
    @IBOutlet weak var planeBadgeView: BadgeView!
    @IBOutlet weak var heartBadgeView: BadgeView!
    @IBOutlet weak var starBadgeView: BadgeView!
    @IBOutlet weak var bubbleBadgeView: BadgeView!

    @IBOutlet weak var androidBadgeView: BadgeView!
    @IBOutlet weak var appleBadgeView: BadgeView!
    @IBOutlet weak var petBadgeView: BadgeView!
    @IBOutlet weak var wineBadgeView: BadgeView!
    @IBOutlet weak var musicBadgeView: BadgeView!

    @IBOutlet weak var steveBadgeView: BadgeView!
    @IBOutlet weak var cameraBadgeView: BadgeView!
    @IBOutlet weak var gameBadgeView: BadgeView!
    @IBOutlet weak var ballBadgeView: BadgeView!
    @IBOutlet weak var techBadgeView: BadgeView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Nickname", comment: "")

        nicknameTextField.text = YepUserDefaults.nickname.value
        nicknameTextField.delegate = self

        let gap = UIDevice.matchWidthFrom(10, 25, 32)
        centerLeft1GapConstraint.constant = gap
        centerRight1GapConstraint.constant = gap
        left1Left2GapConstraint.constant = gap
        right1Right2GapConstraint.constant = gap

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
    }
}

extension EditNicknameAndBadgeViewController: UITextFieldDelegate {

    func textFieldShouldReturn(textField: UITextField) -> Bool {

        if textField == nicknameTextField {

            textField.resignFirstResponder()

            let newNickname = textField.text

            if newNickname != YepUserDefaults.nickname.value {

                YepHUD.showActivityIndicator()

                updateMyselfWithInfo(["nickname": newNickname], failureHandler: { (reason, errorMessage) in
                    defaultFailureHandler(reason, errorMessage)

                    YepHUD.hideActivityIndicator()

                }, completion: { success in
                    dispatch_async(dispatch_get_main_queue()) {
                        YepUserDefaults.nickname.value = newNickname
                    }

                    YepHUD.hideActivityIndicator()
                })
            }
        }

        return true
    }
}