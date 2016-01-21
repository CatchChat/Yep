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

    override func awakeFromNib() {
        super.awakeFromNib()

        instroductionLabelLeftConstraint.constant = YepConfig.Profile.leftEdgeInset
        instroductionLabelRightConstraint.constant = YepConfig.Profile.rightEdgeInset

        introductionLabel.font = YepConfig.Profile.introductionLabelFont
        introductionLabel.textColor = UIColor.yepGrayColor()

        YepUserDefaults.userLocationName.bindAndFireListener(listener.userLocationName, action: { [weak self] userLocationName in

            if let userLocationName = userLocationName {
                self?.locationContainerView.hidden = false
                self?.locationLabel.text = userLocationName

            } else {
                self?.locationContainerView.hidden = true
            }
        })
    }

    func configureWithNickname(nickname: String, username: String?, introduction: String) {

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
                                let name = firstPlacemark.locality ?? (firstPlacemark.name ?? firstPlacemark.country)
                                YepUserDefaults.userLocationName.value = name
                            }
                        }
                    }
                })
            }
        }
    }
}
