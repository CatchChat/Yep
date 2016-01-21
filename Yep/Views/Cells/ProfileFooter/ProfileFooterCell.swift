//
//  ProfileFooterCell.swift
//  Yep
//
//  Created by NIX on 15/3/18.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import CoreLocation

class ProfileFooterCell: UICollectionViewCell {

    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!

    @IBOutlet weak var locationContainerView: UIView!
    @IBOutlet weak var locationLabel: UILabel!

    @IBOutlet weak var introductionLabel: UILabel!
    @IBOutlet weak var instroductionLabelLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var instroductionLabelRightConstraint: NSLayoutConstraint!

    private struct Listener {
        let userLocationName: String
    }

    private lazy var listener: Listener = {

        let suffix = NSUUID().UUIDString

        return Listener(userLocationName: "ProfileFooterCell.userLocationName" + suffix)
    }()

    deinit {
        YepUserDefaults.userLocationName.removeListenerWithName(listener.userLocationName)
    }

    private func updateUIWithUserLocationName(userLocationName: String?) {

        if let userLocationName = userLocationName {
            locationContainerView.hidden = false
            locationLabel.text = userLocationName

        } else {
            locationContainerView.hidden = true
        }
    }

    var profileUserIsMe = false {
        didSet {
            if profileUserIsMe {
                YepUserDefaults.userLocationName.bindAndFireListener(listener.userLocationName, action: { [weak self] userLocationName in
                    self?.updateUIWithUserLocationName(userLocationName)
                })
            }
        }
    }

    var newUserLocationName: String? {
        didSet {
            if profileUserIsMe {
                YepUserDefaults.userLocationName.value = newUserLocationName

            } else {
                updateUIWithUserLocationName(newUserLocationName)
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        instroductionLabelLeftConstraint.constant = YepConfig.Profile.leftEdgeInset
        instroductionLabelRightConstraint.constant = YepConfig.Profile.rightEdgeInset

        introductionLabel.font = YepConfig.Profile.introductionLabelFont
        introductionLabel.textColor = UIColor.yepGrayColor()

        newUserLocationName = nil
    }

    func configureWithProfileUser(profileUser: ProfileUser, introduction: String) {

        profileUserIsMe = profileUser.isMe

        configureWithNickname(profileUser.nickname ?? "", username: profileUser.username, introduction: introduction)

        switch profileUser {
        case .DiscoveredUserType(let discoveredUser):
            location = CLLocation(latitude: discoveredUser.latitude, longitude: discoveredUser.longitude)
        case .UserType(let user):
            location = CLLocation(latitude: user.latitude, longitude: user.longitude)
        }
    }

    private func configureWithNickname(nickname: String, username: String?, introduction: String) {

        nicknameLabel.text = nickname

        if let username = username {
            usernameLabel.text = "@" + username
        } else {
            usernameLabel.text = NSLocalizedString("No username", comment: "")
        }

        introductionLabel.text = introduction
    }

    var location: CLLocation? {
        didSet {
            if let location = location {

                // 优化，减少反向查询
                if let oldLocation = oldValue {
                    let distance = location.distanceFromLocation(oldLocation)
                    if distance < YepConfig.Location.distanceThreshold {
                        return
                    }
                }

                CLGeocoder().reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in

                    dispatch_async(dispatch_get_main_queue()) { [weak self] in
                        if (error != nil) {
                            println("\(location) reverse geodcode fail: \(error?.localizedDescription)")
                            self?.location = nil
                        }

                        if let placemarks = placemarks {
                            if let firstPlacemark = placemarks.first {
                                self?.newUserLocationName = firstPlacemark.locality ?? (firstPlacemark.name ?? firstPlacemark.country)
                            }
                        }
                    }
                })
            }
        }
    }
}
