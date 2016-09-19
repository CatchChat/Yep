//
//  ProfileFooterCell.swift
//  Yep
//
//  Created by NIX on 15/3/18.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import CoreLocation
import YepKit
import RealmSwift

final class ProfileFooterCell: UICollectionViewCell {

    var tapUsernameAction: ((_ username: String) -> Void)?

    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!

    @IBOutlet weak var locationContainerView: UIView!
    @IBOutlet weak var locationLabel: UILabel!

    @IBOutlet weak var introductionTextView: ChatTextView!
    @IBOutlet weak var introductionTextViewLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var introductionTextViewRightConstraint: NSLayoutConstraint!

    fileprivate struct Listener {
        let userLocationName: String
    }

    fileprivate lazy var listener: Listener = {

        let suffix = UUID().uuidString

        return Listener(userLocationName: "ProfileFooterCell.userLocationName" + suffix)
    }()

    deinit {
        YepUserDefaults.userLocationName.removeListenerWithName(listener.userLocationName)
    }

    fileprivate func updateUIWithLocationName(_ userLocationName: String?) {

        if let userLocationName = userLocationName {
            locationContainerView.isHidden = false
            locationLabel.text = userLocationName

        } else {
            locationContainerView.isHidden = true
        }
    }

    var userID: String? {
        didSet {
            if let userID = userID, let realm = try? Realm(), let userLocationName = UserLocationName.withUserID(userID, inRealm: realm) {
                newLocationName = userLocationName.locationName
            }
        }
    }

    var profileUserIsMe = false {
        didSet {
            if profileUserIsMe {
                YepUserDefaults.userLocationName.bindAndFireListener(listener.userLocationName, action: { [weak self] userLocationName in
                    self?.updateUIWithLocationName(userLocationName)
                })
            }
        }
    }

    var newLocationName: String? {
        didSet {
            if profileUserIsMe {
                YepUserDefaults.userLocationName.value = newLocationName

            } else {
                updateUIWithLocationName(newLocationName)
            }

            // save it
            if let realm = try? Realm(), let userID = userID, let locationName = newLocationName {
                let userLocationName = UserLocationName(userID: userID, locationName: locationName)

                let _ = try? realm.write {
                    realm.add(userLocationName, update: true)
                }
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        introductionTextViewLeftConstraint.constant = YepConfig.Profile.leftEdgeInset
        introductionTextViewRightConstraint.constant = YepConfig.Profile.rightEdgeInset

        introductionTextView.isScrollEnabled = false
        introductionTextView.showsVerticalScrollIndicator = false
        introductionTextView.showsHorizontalScrollIndicator = false

        introductionTextView.textContainer.lineFragmentPadding = 0
        introductionTextView.font = YepConfig.Profile.introductionFont
        introductionTextView.textColor = UIColor.yepGrayColor()
        introductionTextView.backgroundColor = UIColor.clear
        introductionTextView.tintColor = UIColor.black
        introductionTextView.linkTextAttributes = [
            NSForegroundColorAttributeName: UIColor.yepTintColor(),
        ]
        introductionTextView.tapMentionAction = { [weak self] username in
            self?.tapUsernameAction?(username)
        }

        newLocationName = nil
    }

    func configureWithProfileUser(_ profileUser: ProfileUser, introduction: String) {

        userID = profileUser.userID
        profileUserIsMe = profileUser.isMe

        configureWithNickname(profileUser.nickname ?? "", username: profileUser.username, introduction: introduction)

        switch profileUser {
        case .DiscoveredUserType(let discoveredUser):
            location = CLLocation(latitude: discoveredUser.latitude, longitude: discoveredUser.longitude)
        case .UserType(let user):
            location = CLLocation(latitude: user.latitude, longitude: user.longitude)
        }
    }

    fileprivate func configureWithNickname(_ nickname: String, username: String?, introduction: String) {

        nicknameLabel.text = nickname

        if let username = username {
            usernameLabel.text = "@" + username
        } else {
            usernameLabel.text = String.trans_promptNoUsername
        }

        let attributedString = introductionTextView.createAttributedStringWithString(introduction)
        introductionTextView.attributedText = attributedString
    }

    var location: CLLocation? {
        didSet {
            guard let location = location else {
                return
            }

            // 优化，减少反向查询
            if let oldLocation = oldValue {
                let distance = location.distance(from: oldLocation)
                if distance < YepConfig.Location.distanceThreshold {
                    return
                }
            }

            CLGeocoder().reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in

                SafeDispatch.async { [weak self] in
                    if (error != nil) {
                        println("\(location) reverse geodcode fail: \(error?.localizedDescription)")
                        self?.location = nil

                    } else {
                        if let placemarks = placemarks, let firstPlacemark = placemarks.first {
                            self?.newLocationName = firstPlacemark.locality ?? (firstPlacemark.name ?? firstPlacemark.country)
                        }
                    }
                }
            })
        }
    }
}

