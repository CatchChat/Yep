//
//  EditProfileViewController.swift
//  Yep
//
//  Created by NIX on 15/4/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class EditProfileViewController: UIViewController {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var mobileLabel: UILabel!

    @IBOutlet weak var editProfileTableView: UITableView!


    let editProfileLessInfoCellIdentifier = "EditProfileLessInfoCell"
    let editProfileMoreInfoCellIdentifier = "EditProfileMoreInfoCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Edit Profile", comment: "")

        let avatarSize = YepConfig.editProfileAvatarSize()
        avatarImageViewWidthConstraint.constant = avatarSize

        if let avatarURLString = YepUserDefaults.avatarURLString() {
            AvatarCache.sharedInstance.roundAvatarWithAvatarURLString(avatarURLString, withRadius: avatarSize * 0.5) { image in
                dispatch_async(dispatch_get_main_queue()) {
                    self.avatarImageView.image = image
                    UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut, animations: { () -> Void in
                        self.avatarImageView.alpha = 1
                    }, completion: { (finished) -> Void in
                    })
                }
            }
        }

        editProfileTableView.registerNib(UINib(nibName: editProfileLessInfoCellIdentifier, bundle: nil), forCellReuseIdentifier: editProfileLessInfoCellIdentifier)
        editProfileTableView.registerNib(UINib(nibName: editProfileMoreInfoCellIdentifier, bundle: nil), forCellReuseIdentifier: editProfileMoreInfoCellIdentifier)
    }

}

extension EditProfileViewController: UITableViewDataSource, UITableViewDelegate {
    enum Row: Int {
        case Name = 0
        case Intro
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.row {
        case Row.Name.rawValue:
            let cell = tableView.dequeueReusableCellWithIdentifier(editProfileLessInfoCellIdentifier) as! EditProfileLessInfoCell
            cell.annotationLabel.text = NSLocalizedString("Nickname", comment: "")
            cell.infoLabel.text = YepUserDefaults.nickname()
            return cell

        case Row.Intro.rawValue:
            let cell = tableView.dequeueReusableCellWithIdentifier(editProfileMoreInfoCellIdentifier) as! EditProfileMoreInfoCell
            cell.annotationLabel.text = NSLocalizedString("Introduction", comment: "")
            cell.infoLabel.text = "I'm good at iOS Development and Singing. Come here, let me teach you."
            return cell

        default:
            return UITableViewCell()
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.row {
        case Row.Name.rawValue:
            return 60
        case Row.Intro.rawValue:
            return 120
        default:
            return 0
        }
    }
}
