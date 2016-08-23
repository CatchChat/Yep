//
//  ProfileHeaderCell.swift
//  Yep
//
//  Created by NIX on 15/3/18.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import CoreLocation
import YepKit
import FXBlurView
import Proposer
import Navi

final class ProfileHeaderCell: UICollectionViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarBlurImageView: UIImageView!
    @IBOutlet weak var locationLabel: UILabel!

    var updatePrettyColorAction: (UIColor -> Void)?
    
    var askedForPermission = false

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        locationLabel.hidden = true
    }

    var blurredAvatarImage: UIImage? {
        willSet {
            avatarBlurImageView.image = newValue
        }
    }

    func configureWithDiscoveredUser(discoveredUser: DiscoveredUser) {
        updateAvatarWithAvatarURLString(discoveredUser.avatarURLString)

        //location = CLLocation(latitude: discoveredUser.latitude, longitude: discoveredUser.longitude)
    }

    func configureWithUser(user: User) {

        updateAvatarWithAvatarURLString(user.avatarURLString)
    }

    func blurImage(image: UIImage, completion: UIImage -> Void) {

        if let blurredAvatarImage = blurredAvatarImage {
            completion(blurredAvatarImage)

        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                let blurredImage = image.blurredImageWithRadius(20, iterations: 20, tintColor: UIColor.blackColor())
                completion(blurredImage)
            }
        }
    }

    func updateAvatarWithAvatarURLString(avatarURLString: String) {

        if avatarImageView.image == nil {
            avatarImageView.alpha = 0
            avatarBlurImageView.alpha = 0
        }

        let avatarStyle = AvatarStyle.Original
        let plainAvatar = PlainAvatar(avatarURLString: avatarURLString, avatarStyle: avatarStyle)

        AvatarPod.wakeAvatar(plainAvatar) { [weak self] finished, image, _ in

            if finished {
                self?.blurImage(image) { blurredImage in
                    SafeDispatch.async {
                        self?.blurredAvatarImage = blurredImage
                    }
                }
            }

            SafeDispatch.async {
                self?.avatarImageView.image = image

                let avatarAvarageColor = image.yep_avarageColor
                let prettyColor = avatarAvarageColor.yep_profilePrettyColor
                self?.locationLabel.textColor = prettyColor

                self?.updatePrettyColorAction?(prettyColor)

                UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut, animations: { [weak self] in
                    self?.avatarImageView.alpha = 1
                }, completion: nil)
            }
        }
    }

    // MARK: Notifications
    
    func updateAddress() {
        locationLabel.text = YepLocationService.sharedManager.address
    }
}

