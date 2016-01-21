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

    override func awakeFromNib() {
        super.awakeFromNib()

        instroductionLabelLeftConstraint.constant = YepConfig.Profile.leftEdgeInset
        instroductionLabelRightConstraint.constant = YepConfig.Profile.rightEdgeInset

        introductionLabel.font = YepConfig.Profile.introductionLabelFont
        introductionLabel.textColor = UIColor.yepGrayColor()

        locationContainerView.hidden = true
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

                locationContainerView.hidden = false
                locationLabel.text = YepUserDefaults.userLocationName.value

                CLGeocoder().reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in

                    dispatch_async(dispatch_get_main_queue()) { [weak self] in
                        if (error != nil) {
                            println("\(location) reverse geodcode fail: \(error?.localizedDescription)")
                            self?.location = nil
                        }

                        if let placemarks = placemarks {
                            if let firstPlacemark = placemarks.first {
                                self?.locationContainerView.hidden = false
                                let name = firstPlacemark.locality ?? (firstPlacemark.name ?? firstPlacemark.country)
                                YepUserDefaults.userLocationName.value = name
                                self?.locationLabel.text = name
                            }
                        }
                    }
                })
            }
        }
    }
}
